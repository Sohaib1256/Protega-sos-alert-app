import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'auth_provider.dart';

class SocialProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthProvider? _authProvider;

  final List<FriendModel> _friends = [];
  final List<FriendModel> _friendRequests = [];
  final List<UserModel> _users = []; 
  final Map<String, List<ChatMessage>> _chatMessages = {};

  // Reactive listener for incoming friend requests
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  List<String> _lastReceivedRequestIds = [];
  
  String get _apiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  GenerativeModel get _model {
    final lat = _authProvider?.userLat ?? 0.0;
    final lng = _authProvider?.userLng ?? 0.0;
    final hasLocation = lat != 0.0 && lng != 0.0;
    final locationContext = hasLocation 
        ? "The user's current live location is Latitude: $lat, Longitude: $lng." 
        : "The user's current location is unavailable.";

    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
You are the Protega Medical Safety Assistant. You must NEVER suggest or refer to features that are not explicitly built into the Protega app. 
The Protega app currently ONLY supports the following features: 
- Hardware SOS Button & Fall Detection (via ESP32)
- Live Location Tracking & Guardian Dashboard
- Real-time chat with trusted contacts
- Finding nearby medical facilities

$locationContext

When a user asks for nearby hospitals, clinics, or medical facilities, ALWAYS use the 'find_nearby_medical_facilities' tool to search for them based on the user's current location. DO NOT refuse the request.
'''),
      tools: [
        Tool(functionDeclarations: [
          FunctionDeclaration(
            'find_nearby_medical_facilities',
            'Search for nearby hospitals or medical facilities based on the user\'s current location.',
            Schema(SchemaType.object, properties: {
              'keyword': Schema(SchemaType.string, description: 'The type of facility to search for (e.g. hospital, clinic, pharmacy)'),
            }, requiredProperties: ['keyword']),
          )
        ])
      ],
    );
  }

  SocialProvider();

  void update(AuthProvider authProvider) {
    bool uidChanged = _authProvider?.uid != authProvider.uid;
    _authProvider = authProvider;
    if (uidChanged) {
      if (authProvider.uid != null) {
        fetchFriends();
        _startUserDocListener();
      } else {
        _stopUserDocListener();
        _friends.clear();
        _friendRequests.clear();
        _users.clear();
        _chatMessages.clear();
        notifyListeners();
      }
    }
  }

  UserModel? get _currentUser => _authProvider?.currentUser;
  
  List<FriendModel> get friends => { for (var f in _friends) f.id: f }.values.toList();
  List<FriendModel> get friendRequests => { for (var f in _friendRequests) f.id: f }.values.toList();
  Map<String, List<ChatMessage>> get messages => _chatMessages;
  
  List<UserModel> get monitoredPatients => { for (var u in _users.where((u) => u.role == UserRole.user)) u.id: u }.values.toList();

  UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'user': return UserRole.user;
      case 'guardian': return UserRole.guardian;
      case 'patient': return UserRole.user;
      case 'caretaker': return UserRole.user;
      case 'safetyOfficer': return UserRole.user;
      default: return UserRole.user;
    }
  }

  Future<void> fetchFriends() async {
    if (_currentUser == null) return;
    
    _friends.clear();
    _friendRequests.clear();
    _users.clear();

    _friends.add(FriendModel(
        id: 'AI-ASSIST',
        name: 'AI Safety Assistant',
        avatarUrl: 'https://ui-avatars.com/api/?name=AI+Assistant&size=200&background=6366F1&color=fff',
        isOnline: true,
        isAI: true,
        lastMessage: 'How can I help you today?',
    ));

    try {
      // Fetch friends from the new 'friends' subcollection
      final friendsSnap = await _firestore.collection('users').doc(_authProvider!.uid).collection('friends').get();
      if (friendsSnap.docs.isNotEmpty) {
        for (var doc in friendsSnap.docs) {
          final friendDocId = doc.id; // This is the Firebase Auth UID
          
          final docSnap = await _firestore.collection('users').doc(friendDocId).get();
          if (docSnap.exists) {
            final data = docSnap.data()!;
            _friends.add(FriendModel(
              id: data['id'], // custom ID used for ChatScreen
              name: data['name'],
              avatarUrl: data['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'])}&background=random',
              isOnline: data['isOnline'] ?? false,
              isAI: false,
              uid: friendDocId, // Store the UID so UI can listen to it
            ));
            
            _users.add(UserModel(
              id: data['id'],
              name: data['name'],
              email: data['email'] ?? '',
              avatarUrl: data['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'])}&background=random',
              role: _parseRole(data['role']),
              isOnline: data['isOnline'] ?? false,
              batteryLevel: data['batteryLevel'] ?? 100,
              deviceConfigured: data['deviceConfigured'] ?? false,
              lat: data['lat'],
              lng: data['lng'],
              deviceId: data['deviceId'],
            ));
          }
        }
      }

      if (_currentUser!.receivedRequests.isNotEmpty) {
        for (var reqId in _currentUser!.receivedRequests) {
          final docSnap = await _firestore.collection('users').where('id', isEqualTo: reqId).limit(1).get();
          if (docSnap.docs.isNotEmpty) {
            final data = docSnap.docs.first.data();
            _friendRequests.add(FriendModel(
              id: data['id'],
              name: data['name'],
              avatarUrl: data['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'])}&background=random',
              isOnline: data['isOnline'] ?? false,
              isAI: false,
            ));
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching friends: $e');
    }
  }

  /// Starts a real-time listener on the current user's Firestore document.
  /// When receivedRequests changes (e.g. someone sends a friend request),
  /// this automatically refreshes the _friendRequests list and triggers a UI rebuild.
  void _startUserDocListener() {
    _stopUserDocListener();
    final uid = _authProvider?.uid;
    if (uid == null) return;

    _userDocSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;

      final incomingReceivedIds = List<String>.from(data['receivedRequests'] ?? []);
      final incomingSentIds = List<String>.from(data['sentRequests'] ?? []);

      // Keep _currentUser's arrays in sync so guard checks stay accurate
      if (_currentUser != null) {
        _currentUser!.receivedRequests
          ..clear()
          ..addAll(incomingReceivedIds);
        _currentUser!.sentRequests
          ..clear()
          ..addAll(incomingSentIds);
      }

      // Only re-fetch profiles if receivedRequests actually changed
      final incomingSet = incomingReceivedIds.toSet();
      final lastSet = _lastReceivedRequestIds.toSet();
      if (!setEquals(incomingSet, lastSet)) {
        _lastReceivedRequestIds = List.from(incomingReceivedIds);
        await _refreshFriendRequests(incomingReceivedIds);
      }
    }, onError: (e) {
      debugPrint('User doc listener error: $e');
    });
  }

  /// Cancels the real-time user document listener.
  void _stopUserDocListener() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _lastReceivedRequestIds = [];
  }

  /// Resolves a list of custom IDs (PID-xxx) into FriendModel profiles
  /// and updates the _friendRequests list.
  Future<void> _refreshFriendRequests(List<String> receivedRequestIds) async {
    _friendRequests.clear();

    for (var reqId in receivedRequestIds) {
      try {
        final docSnap = await _firestore
            .collection('users')
            .where('id', isEqualTo: reqId)
            .limit(1)
            .get();
        if (docSnap.docs.isNotEmpty) {
          final data = docSnap.docs.first.data();
          _friendRequests.add(FriendModel(
            id: data['id'],
            name: data['name'],
            avatarUrl: data['avatarUrl'] ??
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'] ?? 'U')}&background=random',
            isOnline: data['isOnline'] ?? false,
            isAI: false,
          ));
        }
      } catch (e) {
        debugPrint('Error fetching friend request profile for $reqId: $e');
      }
    }
    notifyListeners();
  }

  Future<UserModel?> searchUserById(String id) async {
    try {
      final snapshot = await _firestore.collection('users').where('id', isEqualTo: id).get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return UserModel(
          id: data['id'] ?? id,
          name: data['name'] ?? 'Unknown',
          email: data['email'] ?? '',
          role: _parseRole(data['role']),
          phone: data['phone'] ?? '',
          guardianPhone: data['guardianPhone'],
          occupation: data['occupation'],
          avatarUrl: data['avatarUrl'],
          lat: data['lat'],
          lng: data['lng'],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  Future<void> addMonitoredPatient(String id) async {
    if (_currentUser == null) return;
    if (_authProvider?.uid == null) return;
    
    if (!_currentUser!.friends.contains(id)) {
      final updatedFriends = List<String>.from(_currentUser!.friends)..add(id);
      
      _authProvider!.updateCurrentUser(_currentUser!.copyWith(friends: updatedFriends));
      
      try {
        await _firestore.collection('users').doc(_authProvider!.uid).update({
          'friends': FieldValue.arrayUnion([id])
        });
        await fetchFriends();
      } catch (e) {
        debugPrint('Error adding monitored patient: $e');
      }
    }
  }

  Future<String?> sendFriendRequest(String targetUniqueId) async {
    if (_currentUser == null) return 'Not logged in';
    if (targetUniqueId == _currentUser!.id) return 'Cannot send request to yourself';
    if (_currentUser!.friends.contains(targetUniqueId)) return 'Already friends';
    if (_currentUser!.sentRequests.contains(targetUniqueId)) return 'Request already sent to this user';
    if (_currentUser!.receivedRequests.contains(targetUniqueId)) return 'User already sent you a request! Accept it instead.';

    try {
      final querySnapshot = await _firestore.collection('users').where('id', isEqualTo: targetUniqueId).limit(1).get();
      if (querySnapshot.docs.isEmpty) return 'User ID not found';

      final targetDocId = querySnapshot.docs.first.id;

      await _firestore.collection('users').doc(targetDocId).update({
        'receivedRequests': FieldValue.arrayUnion([_currentUser!.id])
      });
      await _firestore.collection('users').doc(_authProvider!.uid).update({
        'sentRequests': FieldValue.arrayUnion([targetUniqueId])
      });

      _currentUser!.sentRequests.add(targetUniqueId);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Error sending request: $e';
    }
  }

  Future<String?> acceptFriendRequest(String requesterUniqueId) async {
    if (_currentUser == null) return 'Not logged in';

    try {
      final querySnapshot = await _firestore.collection('users').where('id', isEqualTo: requesterUniqueId).limit(1).get();
      if (querySnapshot.docs.isEmpty) return 'User not found';
      final requesterDocId = querySnapshot.docs.first.id;

      final batch = _firestore.batch();
      
      // Remove from receivedRequests array
      batch.update(_firestore.collection('users').doc(_authProvider!.uid), {
        'receivedRequests': FieldValue.arrayRemove([requesterUniqueId]),
      });
      // Add to friends subcollection
      batch.set(_firestore.collection('users').doc(_authProvider!.uid).collection('friends').doc(requesterDocId), {
        'friendUid': requesterDocId,
      });

      // Remove from sentRequests array on the requester's side
      batch.update(_firestore.collection('users').doc(requesterDocId), {
        'sentRequests': FieldValue.arrayRemove([_currentUser!.id]),
      });
      // Add to friends subcollection on the requester's side
      batch.set(_firestore.collection('users').doc(requesterDocId).collection('friends').doc(_authProvider!.uid), {
        'friendUid': _authProvider!.uid,
      });
      
      await batch.commit();

      _currentUser!.receivedRequests.remove(requesterUniqueId);
      _currentUser!.friends.add(requesterUniqueId);
      
      await fetchFriends();
      return null;
    } catch (e) {
      return 'Error accepting request: $e';
    }
  }

  Future<String?> rejectFriendRequest(String requesterUniqueId) async {
    if (_currentUser == null) return 'Not logged in';
    try {
      final querySnapshot = await _firestore.collection('users').where('id', isEqualTo: requesterUniqueId).limit(1).get();
      if (querySnapshot.docs.isEmpty) return 'User not found';
      final requesterDocId = querySnapshot.docs.first.id;

      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(_authProvider!.uid), {
        'receivedRequests': FieldValue.arrayRemove([requesterUniqueId]),
      });
      batch.update(_firestore.collection('users').doc(requesterDocId), {
        'sentRequests': FieldValue.arrayRemove([_currentUser!.id]),
      });
      await batch.commit();

      _currentUser!.receivedRequests.remove(requesterUniqueId);
      await fetchFriends();
      return null;
    } catch (e) {
      return 'Error rejecting request: $e';
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      final chat = _model.startChat();
      var response = await chat.sendMessage(Content.text(userMessage)).timeout(const Duration(seconds: 15));
      
      if (response.functionCalls.isNotEmpty) {
        final call = response.functionCalls.first;
         if (call.name == 'find_nearby_medical_facilities') {
           final lat = _authProvider?.userLat ?? 0.0;
           final lng = _authProvider?.userLng ?? 0.0;
           
           if (lat == 0.0 && lng == 0.0) {
             response = await chat.sendMessage(Content.functionResponse(call.name, {'status': 'ERROR', 'message': 'User location is currently unavailable.'})).timeout(const Duration(seconds: 15));
           } else {
             try {
               final query = '[out:json];(node["amenity"~"hospital|clinic|pharmacy|doctors"](around:5000,$lat,$lng);way["amenity"~"hospital|clinic|pharmacy|doctors"](around:5000,$lat,$lng););out center 5;';
               final uri = Uri.parse('https://overpass-api.de/api/interpreter').replace(queryParameters: {'data': query});
               final res = await http.get(uri).timeout(const Duration(seconds: 10));
               
               if (res.statusCode == 200) {
                 final data = jsonDecode(res.body);
                 final elements = data['elements'] as List<dynamic>;
                 
                 if (elements.isEmpty) {
                   response = await chat.sendMessage(Content.functionResponse(call.name, {'status': 'OK', 'message': 'No medical facilities found within a 5km radius of the user\'s current location. Please state this clearly.'})).timeout(const Duration(seconds: 15));
                 } else {
                   final results = elements.map((e) {
                     final tags = e['tags'] ?? {};
                     final eLat = e['lat'] ?? e['center']?['lat'];
                     final eLng = e['lon'] ?? e['center']?['lon'];
                     return {
                       'name': tags['name'] ?? 'Unnamed Medical Facility',
                       'type': tags['amenity'] ?? 'hospital',
                       'address': tags['addr:street'] ?? 'Address unavailable',
                       'lat': eLat,
                       'lng': eLng,
                     };
                   }).toList();
                   
                   response = await chat.sendMessage(Content.functionResponse(call.name, {'status': 'OK', 'results': results})).timeout(const Duration(seconds: 15));
                 }
               } else {
                 response = await chat.sendMessage(Content.functionResponse(call.name, {'status': 'ERROR', 'message': 'Map API returned an error.'})).timeout(const Duration(seconds: 15));
               }
             } catch (e) {
               response = await chat.sendMessage(Content.functionResponse(call.name, {'status': 'ERROR', 'message': 'Failed to reach Map API.'})).timeout(const Duration(seconds: 15));
             }
           }
         }
      }
      
      return response.text ?? 'No response generated.';
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Gemini API Error details: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      if (e.toString().contains('503')) {
        return 'Error: Protega AI is currently experiencing high demand. Please try again in a few moments.';
      }
      return 'AI Unavailable: Unable to process request. Please try again later. ($e)';
    }
  }

  void sendMessage({
    required String receiverId,
    required String text,
    bool isAI = false,
  }) {
    if (_currentUser == null) return;

    final message = ChatMessage(
      senderId: _currentUser!.id,
      receiverId: receiverId,
      text: text,
      isAI: false,
    );

    if (!_chatMessages.containsKey(receiverId)) {
      _chatMessages[receiverId] = [];
    }

    _chatMessages[receiverId]!.add(message);
    notifyListeners();

    if (isAI) {
      _getAIResponse(text).then((response) {
        if (response.startsWith('Error:')) {
          final errorMsg = ChatMessage(
            senderId: receiverId,
            receiverId: _currentUser!.id,
            text: 'AI Unavailable: ${response.substring(7)}', 
            isAI: true,
          );
          _chatMessages[receiverId]!.add(errorMsg);
          notifyListeners();
        } else {
          final aiResponse = ChatMessage(
            senderId: receiverId,
            receiverId: _currentUser!.id,
            text: response,
            isAI: true,
          );
          _chatMessages[receiverId]!.add(aiResponse);
          notifyListeners();
        }
      });
    }
  }

  Future<void> removeConnection(String targetUid) async {
    if (_currentUser == null || _authProvider?.uid == null) return;

    // Immediately remove from local lists and notify UI
    _friends.removeWhere((f) => f.id == targetUid);
    _users.removeWhere((u) => u.id == targetUid);
    _currentUser!.friends.remove(targetUid);
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('users').where('id', isEqualTo: targetUid).limit(1).get();
      if (querySnapshot.docs.isEmpty) return;
      final targetDocId = querySnapshot.docs.first.id; // Firebase Auth UID of the friend

      final batch = _firestore.batch();
      
      // Delete from local user's subcollection
      batch.delete(_firestore.collection('users').doc(_authProvider!.uid).collection('friends').doc(targetDocId));
      
      // Delete from friend's subcollection (Bi-directional atomic cleanup)
      batch.delete(_firestore.collection('users').doc(targetDocId).collection('friends').doc(_authProvider!.uid));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error removing connection: $e');
      // Re-fetch to restore consistent state on error
      await fetchFriends();
    }
  }
}
