import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import '../models/models.dart';
import 'package:uuid/uuid.dart';

class AppProvider with ChangeNotifier {
  static const _uuid = Uuid();
  
  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  UserModel? _currentUser;
  
  // Local caches (data will come from Firestore)
  final List<UserModel> _users = []; 
  final List<AlertModel> _alerts = [];
  final Map<String, List<ChatMessage>> _chatMessages = {};
  final List<FriendModel> _friends = [];
  final List<FriendModel> _friendRequests = [];
  final List<NotificationItem> _notifications = [];
  final List<EmergencyContact> _emergencyContacts = [];

  bool _isSOSActive = false;
  bool _fallDetectionEnabled = true;
  String _fallSensitivity = 'medium';
  String _sosGesture = 'disabled'; // 'disabled', 'triple_tap', 'volume_key'
  bool _isLocalAlarmSoundEnabled = true; // Added toggle for local alarm sound

  // API Key for Gemini
  String get _apiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      return ''; // Fallback to an empty string if dotenv is not initialized
    }
  }
  late final GenerativeModel _model;

  // New State Variables
  bool _deviceConfigured = false;
  ThemeMode _themeMode = ThemeMode.dark;
  StreamSubscription<DatabaseEvent>? _deviceSubscription;
  StreamSubscription? _alertsSubscription;
  Timer? _onlineStatusTimer;
  DateTime? _lastDeviceUpdate;
  String _deviceAlertStatus = 'Normal';

  // Getters
  UserModel? get currentUser => _currentUser;
  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get activeAlerts => _alerts.where((a) => a.isActive).toList();
  Map<String, List<ChatMessage>> get messages => _chatMessages;
  List<FriendModel> get friends => _friends;
  List<FriendModel> get friendRequests => _friendRequests;
  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get fallDetectionEnabled => _fallDetectionEnabled;
  String get sosGesture => _sosGesture;
  bool get isLocalAlarmSoundEnabled => _isLocalAlarmSoundEnabled;
  bool get isDeviceOnline {
    if (_lastDeviceUpdate == null) return false;
    return DateTime.now().difference(_lastDeviceUpdate!).inSeconds < 40;
  }
  String get deviceAlertStatus => _deviceAlertStatus;

  // --- Fixed/Added Getters ---

  bool get isSOSActive => _isSOSActive;
  bool get sosActive => _isSOSActive; // Alias for UI compatibility

  bool get deviceConfigured => _deviceConfigured;
  ThemeMode get themeMode => _themeMode;

  double get userLat => _currentUser?.lat ?? 0.0;
  double get userLng => _currentUser?.lng ?? 0.0;

  List<AlertModel> get alertHistory => _alerts; // Alias for history screen

  // Return int for Sliders (0=Low, 1=Medium, 2=High)
  int get fallSensitivity {
    switch (_fallSensitivity) {
      case 'low': return 0;
      case 'high': return 2;
      default: return 1; // medium
    }
  }

  // Get all users (for guardian to see their patients)
  List<UserModel> get patients {
    if (_currentUser == null) return [];
    if (_currentUser!.role == UserRole.guardian ||
        _currentUser!.role == UserRole.caretaker ||
        _currentUser!.role == UserRole.safetyOfficer) {
      return _users.where((u) => u.role == UserRole.patient).toList();
    }
    return [];
  }

  List<UserModel> get monitoredPatients => patients;

  AppProvider() {
    // Using verified available model from user's API response
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
You are the Protega Medical Safety Assistant. You must NEVER suggest or refer to features that are not explicitly built into the Protega app. 
The Protega app currently ONLY supports the following features: 
- Hardware SOS Button & Fall Detection (via ESP32)
- Live Location Tracking & Guardian Dashboard
- Real-time chat with trusted contacts
If a user asks for nearby hospitals or medical facilities, politely inform them that you cannot search for local facilities yet, and advise them to use their device's native Maps application or dial emergency services.
'''),
    );
    _loadTheme();
    _loadSosGesture();
    _loadAlarmSettings();
    _setupAuthListener(); // Listen to auth state changes directly
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // _fetchCurrentUser() internally calls fetchAlertHistory() + _listenToAlerts()
        _fetchCurrentUser();
      } else {
        // Handle explicit logout cleanup if needed here (handled in logout() too)
      }
    });
  }





  // --- Methods ---

  void setDeviceConfigured(bool value) {
    _deviceConfigured = value;
    notifyListeners();
  }

  Future<void> _loadSosGesture() async {
    final prefs = await SharedPreferences.getInstance();
    _sosGesture = prefs.getString('sos_gesture_type') ?? 'disabled';
    notifyListeners();
  }

  Future<void> _loadAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isLocalAlarmSoundEnabled = prefs.getBool('is_local_alarm_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setLocalAlarmSoundEnabled(bool value) async {
    _isLocalAlarmSoundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_local_alarm_enabled', value);
  }

  Future<void> setSosGesture(String gesture) async {
    _sosGesture = gesture;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_gesture_type', gesture);
  }

  void setFallDetection(bool value) {
    _fallDetectionEnabled = value;
    notifyListeners();
  }

  // Accepts double from slider (0.0 to 2.0)
  void setFallSensitivity(double value) {
    if (value < 0.5) {
      _fallSensitivity = 'low';
    } else if (value > 1.5) {
      _fallSensitivity = 'high';
    } else {
      _fallSensitivity = 'medium';
    }
    notifyListeners();
  }

  void setLocation(double lat, double lng) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        role: _currentUser!.role,
        purpose: _currentUser!.purpose,
        lat: lat,
        lng: lng,
        phone: _currentUser!.phone,
        guardianPhone: _currentUser!.guardianPhone,
        occupation: _currentUser!.occupation,
        age: _currentUser!.age,
        batteryLevel: _currentUser!.batteryLevel,
        isOnline: _currentUser!.isOnline,
        friends: _currentUser!.friends,
        sentRequests: _currentUser!.sentRequests,
        receivedRequests: _currentUser!.receivedRequests,
        deviceConfigured: _currentUser!.deviceConfigured,
        deviceId: _currentUser!.deviceId,
      );
      notifyListeners();
    }
  }

  Future<void> fetchUserLocation() async {
    try {
      // 1. Check permissions (but don't bail silently on service check)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return;
      }

      // 2. Try to get current position with LOW accuracy (WiFi/Cell) + timeout
      //    This avoids hanging indefinitely waiting for a satellite GPS lock indoors
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, // WiFi/Cell — works indoors
            timeLimit: Duration(seconds: 7),
          ),
        );
        setLocation(position.latitude, position.longitude);
        debugPrint('Location acquired: ${position.latitude}, ${position.longitude}');
        return;
      } on TimeoutException {
        debugPrint('Location timeout — falling back to last known position');
      } catch (e) {
        debugPrint('getCurrentPosition failed: $e — trying last known');
      }

      // 3. Fallback: use last known position (cached by OS)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setLocation(lastKnown.latitude, lastKnown.longitude);
        debugPrint('Using last known: ${lastKnown.latitude}, ${lastKnown.longitude}');
      } else {
        debugPrint('No last known position available');
      }
    } catch (e) {
      debugPrint('fetchUserLocation error: $e');
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? occupation,
    int? age,
    String? avatarUrl,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
        occupation: occupation,
        age: age,
        avatarUrl: avatarUrl,
      );
    }
  }

  void markNotificationsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          time: _notifications[i].time,
          isRead: true,
          type: _notifications[i].type,
        );
      }
    }
    notifyListeners();
  }

  void markNotificationRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        time: _notifications[index].time,
        isRead: true,
        type: _notifications[index].type,
      );
      notifyListeners();
    }
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
          purpose: _parsePurpose(data['purpose']),
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
    
    if (!_currentUser!.friends.contains(id)) {
      final updatedFriends = List<String>.from(_currentUser!.friends)..add(id);
      
      _currentUser = _currentUser!.copyWith(friends: updatedFriends);
      notifyListeners();
      
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'friends': FieldValue.arrayUnion([id])
        });
        
        // Also fetch the full user to keep local lists updated
        await _fetchFriends();
      } catch (e) {
        debugPrint('Error adding monitored patient: $e');
      }
    }
  }

  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
    notifyListeners();
  }

  void removeEmergencyContact(String contactId) {
    _emergencyContacts.removeWhere((c) => c.id == contactId);
    notifyListeners();
  }

  void triggerSOS() {
    if (_currentUser == null) return;

    _isSOSActive = true;

    final alert = AlertModel(
      userId: _currentUser!.id,
      userName: _currentUser!.name,
      lat: _currentUser!.lat,
      lng: _currentUser!.lng,
      isActive: true,
      type: 'SOS',
    );

    _alerts.insert(0, alert);

    // Save to Firestore
    if (_auth.currentUser != null) {
      _firestore.collection('alerts').doc(alert.id).set({
        'id': alert.id,
        'userId': alert.userId,
        'userName': alert.userName,
        'senderId': _auth.currentUser!.uid,
        'status': 'SOS Pressed',
        'timestamp': alert.timestamp.toIso8601String(),
        'lat': alert.lat,
        'lng': alert.lng,
        'isActive': alert.isActive,
        'type': alert.type,
      }).catchError((e) {
        debugPrint('Failed to save alert to Firestore: $e');
      });
    }

    // Trigger local alarm by writing to RTDB
    _triggerRTDBAlarm();

    // ── IPC: Tell the background service isolate to start the alarm audio ──
    FlutterBackgroundService().invoke("triggerAlarm");

    _notifications.insert(
      0,
      NotificationItem(
        title: 'SOS Alert Triggered',
        message: 'Emergency alert has been sent to your guardians',
        type: 'alert',
      ),
    );

    notifyListeners();

    // Auto-dial emergency contact (or 911 fallback)
    _autoDialEmergency();
  }

  Future<void> _triggerRTDBAlarm({int maxRetries = 3}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('configured_device_id');
      if (deviceId == null) return;
      
      final ref = FirebaseDatabase.instance.ref('devices/$deviceId/alertStatus');
      
      int attempts = 0;
      bool success = false;
      
      while (attempts < maxRetries && !success) {
        try {
          attempts++;
          // Active wait with timeout for immediate feedback
          await ref.set('SOS Pressed').timeout(const Duration(seconds: 5));
          success = true;
          debugPrint('RTDB SOS Trigger succeeded on attempt $attempts');
        } catch (e) {
          debugPrint('RTDB SOS Trigger attempt $attempts failed/timed out.');
          if (attempts < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          } else {
             // Fallback: Fire and forget. 
             // Firebase offline persistence will queue this and sync when network returns.
             debugPrint('Falling back to Firebase offline persistence queue.');
             ref.set('SOS Pressed'); 
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to trigger SOS in RTDB: $e');
    }
  }

  Future<void> _autoDialEmergency() async {
    // Check phone permission first
    final phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      final result = await Permission.phone.request();
      if (!result.isGranted) return; // User denied, can't auto-dial
    }

    String numberToDial = '911'; // Default fallback

    if (_emergencyContacts.isNotEmpty) {
      final contact = _emergencyContacts.first;
      numberToDial = '${contact.countryCode}${contact.phone}'.replaceAll(' ', '');
    }

    try {
      await FlutterPhoneDirectCaller.callNumber(numberToDial);
    } catch (e) {
      debugPrint('Auto-dial failed: $e');
    }
  }

  Future<void> cancelSOS() async {
    bool hasBackendError = false;

    for (int i = 0; i < _alerts.length; i++) {
      if (_alerts[i].isActive) {
        if (_auth.currentUser != null) {
          try {
            await _firestore.collection('alerts').doc(_alerts[i].id).update({
              'isActive': false,
              'status': 'Normal',
            });
            
            // Only update local state if backend update succeeds
            _alerts[i] = AlertModel(
              id: _alerts[i].id,
              userId: _alerts[i].userId,
              userName: _alerts[i].userName,
              timestamp: _alerts[i].timestamp,
              lat: _alerts[i].lat,
              lng: _alerts[i].lng,
              isActive: false,
              type: _alerts[i].type,
            );
          } catch (e) {
            hasBackendError = true;
            debugPrint('Failed to cancel alert in Firestore: $e');
          }
        }
      }
    }
    
    if (hasBackendError) {
      throw Exception('Permission denied or network error while cancelling alert.');
    }

    _isSOSActive = false;

    // ── IPC: Tell the background service isolate to stop the alarm audio ──
    FlutterBackgroundService().invoke("stopAlarm");

    // Remote Cancel: Write to RTDB to reset the ESP32 and stop the background service alarm
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('configured_device_id');
      if (deviceId != null) {
        await FirebaseDatabase.instance.ref('devices/$deviceId/alertStatus').set('Normal');
      }
    } catch (e) {
      debugPrint('Failed to cancel SOS in RTDB: $e');
      throw Exception('Failed to synchronize hardware reset.');
    }

    notifyListeners();
    // Fetch last known location after SOS cancel
    fetchUserLocation();
  }

  Future<String?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Please fill in all fields';
    }

    try {
      // 1. Authenticate with Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. Fetch User Data from Firestore
      await _fetchCurrentUser();
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        return 'Invalid email or password.';  
      }
      return 'Login failed: ${e.message}';
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _onlineStatusTimer?.cancel();
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _alertsSubscription?.cancel();
    _alertsSubscription = null;
    await _auth.signOut();
    _friends.clear();
    _alerts.clear();
    _notifications.clear();
    notifyListeners();
  }

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required UserPurpose purpose,
    String? guardianPhone,
    String? phone,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'Please fill in all fields';
    }

    try {
      // 1. Create User in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Generate Custom ID (PID/UID/GID) for display/search
      String idPrefix;
      if (role == UserRole.patient) {
        if (purpose == UserPurpose.medical) {
          idPrefix = 'PID';
        } else {
          idPrefix = 'UID'; // Personal use
        }
      } else if (role == UserRole.guardian) {
        idPrefix = 'GID';
      } else if (role == UserRole.caretaker) {
        idPrefix = 'CID';
      } else if (role == UserRole.safetyOfficer) {
        idPrefix = 'OID';
      } else {
        idPrefix = 'UID';
      }
      
      final customId = '$idPrefix-${_uuid.v4().substring(0, 6).toUpperCase()}';
      
      // 3. Prepare User Data
      final newUser = UserModel(
        id: customId,
        name: name,
        email: email,
        role: role,
        purpose: purpose,
        guardianPhone: guardianPhone,
        phone: phone ?? '',
        occupation: role == UserRole.patient ? 'Patient' : 'Guardian',
      );

      // 4. Save to Firestore using Auth UID as Document ID
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'id': newUser.id,
        'name': newUser.name,
        'email': newUser.email,
        'role': newUser.role.toString().split('.').last,
        'purpose': newUser.purpose.toString().split('.').last,
        'phone': newUser.phone,
        'guardianPhone': newUser.guardianPhone,
        'occupation': newUser.occupation,
        'avatarUrl': newUser.avatarUrl,
        'isOnline': true,
        'friends': [],
        'sentRequests': [],
        'receivedRequests': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Set current user
      _currentUser = newUser;
      notifyListeners();
      return null;
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
      return 'Signup failed: ${e.message}';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Helper to fetch current user data from Firestore
  Future<void> _fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = UserModel(
          id: data['id'] ?? 'Unknown',
          name: data['name'] ?? 'Unknown',
          email: data['email'] ?? user.email!,
          role: _parseRole(data['role']),
          purpose: _parsePurpose(data['purpose']),
          phone: data['phone'] ?? '',
          guardianPhone: data['guardianPhone'],
          occupation: data['occupation'],
          avatarUrl: data['avatarUrl'],
          isOnline: true,
          lat: data['lat'],
          lng: data['lng'],
          deviceConfigured: data['deviceConfigured'] ?? false,
          deviceId: data['deviceId'],
          friends: List<String>.from(data['friends'] ?? []),
          sentRequests: List<String>.from(data['sentRequests'] ?? []),
          receivedRequests: List<String>.from(data['receivedRequests'] ?? []),
        );
        _deviceConfigured = _currentUser!.deviceConfigured;
        notifyListeners();
        
        // Also fetch friends and alerts
        await _fetchFriends();
        await fetchAlertHistory();
        
        // Start real-time alert stream for live updates
        _listenToAlerts();

        // Start listening to device if configured
        if (_currentUser!.deviceConfigured && _currentUser!.deviceId != null) {
          _listenToDevice(_currentUser!.deviceId!);
        }
      }
    }
  }

  // Parsers for Enums
  UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'patient': return UserRole.patient;
      case 'guardian': return UserRole.guardian;
      case 'caretaker': return UserRole.caretaker;
      case 'safetyOfficer': return UserRole.safetyOfficer;
      default: return UserRole.patient;
    }
  }

  UserPurpose _parsePurpose(String? purposeStr) {
    return purposeStr == 'personal' ? UserPurpose.personal : UserPurpose.medical;
  }
  
  Future<void> _fetchFriends() async {
    if (_currentUser == null) return;
    
    _friends.clear();
    _friendRequests.clear();

    // AI Assistant
    _friends.add(FriendModel(
        id: 'AI-ASSIST',
        name: 'AI Safety Assistant',
        avatarUrl: 'https://ui-avatars.com/api/?name=AI+Assistant&size=200&background=6366F1&color=fff',
        isOnline: true,
        isAI: true,
        lastMessage: 'How can I help you today?',
    ));

    try {
      // 1. Fetch real friends
      if (_currentUser!.friends.isNotEmpty) {
        for (var friendId in _currentUser!.friends) {
          final docSnap = await _firestore.collection('users').where('id', isEqualTo: friendId).limit(1).get();
          if (docSnap.docs.isNotEmpty) {
            final data = docSnap.docs.first.data();
            _friends.add(FriendModel(
              id: data['id'],
              name: data['name'],
              avatarUrl: data['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['name'])}&background=random',
              isOnline: data['isOnline'] ?? false,
              isAI: false,
            ));
          }
        }
      }

      // 2. Fetch pending requests
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
              isPending: true,
            ));
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching friend data: $e");
    }
  }

  Future<void> fetchAlertHistory() async {
    if (_auth.currentUser == null) return;
    try {
      // Always prefer server data to ensure cross-device consistency
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('alerts')
            .where('senderId', isEqualTo: _auth.currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        // Fallback to cache if offline
        debugPrint('fetchAlertHistory: Server unavailable, falling back to cache');
        snapshot = await _firestore
            .collection('alerts')
            .where('senderId', isEqualTo: _auth.currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .get(const GetOptions(source: Source.cache));
      }
      
      _alerts.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _alerts.add(AlertModel(
          id: data['id'],
          userId: data['userId'],
          userName: data['userName'],
          timestamp: DateTime.parse(data['timestamp']),
          lat: data['lat'],
          lng: data['lng'],
          isActive: data['isActive'] ?? false,
          type: data['type'],
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching alert history: $e');
    }
  }

  /// Subscribe to a real-time stream so new alerts appear immediately
  void _listenToAlerts() {
    if (_auth.currentUser == null) return;
    // Cancel any existing subscription to avoid duplicates
    _alertsSubscription?.cancel();
    _alertsSubscription = _firestore
        .collection('alerts')
        .where('senderId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _alerts.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _alerts.add(AlertModel(
          id: data['id'],
          userId: data['userId'],
          userName: data['userName'],
          timestamp: DateTime.parse(data['timestamp']),
          lat: data['lat'],
          lng: data['lng'],
          isActive: data['isActive'] ?? false,
          type: data['type'],
        ));
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Alert stream error: $e');
    });
  }

  // --- Social Methods ---
  
  void removeFriend(String friendId) {
    if (_currentUser == null) return;
    _firestore.collection('users').where('id', isEqualTo: friendId).limit(1).get().then((snap) {
      if (snap.docs.isNotEmpty) {
        final targetDocId = snap.docs.first.id;
        final batch = _firestore.batch();
        batch.update(_firestore.collection('users').doc(_auth.currentUser!.uid), {
          'friends': FieldValue.arrayRemove([friendId])
        });
        batch.update(_firestore.collection('users').doc(targetDocId), {
          'friends': FieldValue.arrayRemove([_currentUser!.id])
        });
        batch.commit();
      }
    });

    _currentUser!.friends.remove(friendId);
    _friends.removeWhere((f) => f.id == friendId);
    notifyListeners();
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
      // Use Gemini API
      _getAIResponse(text).then((response) {
        if (response.startsWith('Error:')) {
          // Error occurred - Show exact error
          final errorMsg = ChatMessage(
            senderId: receiverId,
            receiverId: _currentUser!.id,
            text: 'AI Unavailable: ${response.substring(7)}', // Remove "Error: " prefix
            isAI: true,
          );
          _chatMessages[receiverId]!.add(errorMsg);
          notifyListeners();
        } else {
          // Success
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

  // --- Device Configuration Methods ---

  void _listenToDevice(String deviceId) {
    _deviceSubscription?.cancel();
    _onlineStatusTimer?.cancel();
    
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      notifyListeners();
    });
    
    debugPrint('Listening to RTDB device: $deviceId');
    
    _deviceSubscription = _rtdb
        .ref('devices/$deviceId')
        .onValue
        .listen((event) async {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // 1. Update Location
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          double lat = (data['latitude'] as num).toDouble();
          double lng = (data['longitude'] as num).toDouble();
          setLocation(lat, lng);
        }
        
        // 2. Status & Timestamp
        if (data.containsKey('timestamp')) {
          double ts = (data['timestamp'] as num).toDouble();
          if (ts > 100000) { // Valid NTP Epoch
            _lastDeviceUpdate = DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());
          } else {
            _lastDeviceUpdate = DateTime.now(); // Fallback
          }
        } else {
          _lastDeviceUpdate = DateTime.now();
        }
        
        if (data.containsKey('alertStatus')) {
          _deviceAlertStatus = data['alertStatus'];
          if (_deviceAlertStatus != 'Normal' && !_isSOSActive) {
            if (_deviceAlertStatus == 'Fall Detected') {
               final prefs = await SharedPreferences.getInstance();
               final isFallEnabled = prefs.getBool('is_fall_detection_enabled') ?? true;
               if (!isFallEnabled) {
                  if (_currentUser?.deviceId != null) {
                    FirebaseDatabase.instance.ref('devices/${_currentUser!.deviceId}/alertStatus').set('Normal');
                  }
                 return;
               }
            }
            triggerSOS();
          }
        }
        
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Device RTDB stream error: $e');
    });
  }

  Future<void> configureDevice(String deviceId) async {
    if (_currentUser == null) return;
    
    // Simulate API call / validation
    if (deviceId.length < 4) return; // Simple validation

    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: _currentUser!.role,
      purpose: _currentUser!.purpose,
      guardianPhone: _currentUser!.guardianPhone,
      phone: _currentUser!.phone,
      countryCode: _currentUser!.countryCode,
      avatarUrl: _currentUser!.avatarUrl,
      occupation: _currentUser!.occupation,
      age: _currentUser!.age,
      batteryLevel: _currentUser!.batteryLevel,
      isOnline: _currentUser!.isOnline,
      deviceConfigured: true,
      deviceId: deviceId, // Store device ID
      lat: _currentUser!.lat,
      lng: _currentUser!.lng,
      friends: _currentUser!.friends,
      sentRequests: _currentUser!.sentRequests,
      receivedRequests: _currentUser!.receivedRequests,
    );
    
    _deviceConfigured = true;
    _listenToDevice(deviceId);
    notifyListeners();

    // Persist to Firestore and SharedPreferences so it survives app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('configured_device_id', deviceId);

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'deviceId': deviceId,
        'deviceConfigured': true,
      });
    } catch (e) {
      debugPrint('Error persisting device config: $e');
    }
  }

  Future<void> disconnectDevice() async {
    if (_currentUser == null) return;

    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: _currentUser!.role,
      purpose: _currentUser!.purpose,
      guardianPhone: _currentUser!.guardianPhone,
      phone: _currentUser!.phone,
      countryCode: _currentUser!.countryCode,
      avatarUrl: _currentUser!.avatarUrl,
      occupation: _currentUser!.occupation,
      age: _currentUser!.age,
      batteryLevel: _currentUser!.batteryLevel,
      isOnline: _currentUser!.isOnline,
      deviceConfigured: false,
      deviceId: null, // Clear device ID
      lat: _currentUser!.lat,
      lng: _currentUser!.lng,
      friends: _currentUser!.friends,
      sentRequests: _currentUser!.sentRequests,
      receivedRequests: _currentUser!.receivedRequests,
    );

    _deviceConfigured = false;
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    notifyListeners();

    // Clear from Firestore and SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('configured_device_id');

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'deviceId': FieldValue.delete(),
        'deviceConfigured': false,
      });
    } catch (e) {
      debugPrint('Error clearing device config: $e');
    }
  }

  // --- AI Methods ---

  Future<String> _getAIResponse(String userMessage) async {
    try {
      final content = [Content.text(userMessage)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 10));
      return response.text ?? 'No response generated.';
    } catch (e) {
      if (kDebugMode) {
        print('Gemini API Error: $e');
      }
      if (e.toString().contains('503')) {
        return 'Error: Protega AI is currently experiencing high demand. Please try again in a few moments.';
      }
      return 'Error: Unable to process request. Please try again later.';
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
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
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
      batch.update(_firestore.collection('users').doc(_auth.currentUser!.uid), {
        'receivedRequests': FieldValue.arrayRemove([requesterUniqueId]),
        'friends': FieldValue.arrayUnion([requesterUniqueId])
      });
      batch.update(_firestore.collection('users').doc(requesterDocId), {
        'sentRequests': FieldValue.arrayRemove([_currentUser!.id]),
        'friends': FieldValue.arrayUnion([_currentUser!.id])
      });
      await batch.commit();

      _currentUser!.receivedRequests.remove(requesterUniqueId);
      _currentUser!.friends.add(requesterUniqueId);
      
      await _fetchFriends(); // Auto-refresh local memory
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
      batch.update(_firestore.collection('users').doc(_auth.currentUser!.uid), {
        'receivedRequests': FieldValue.arrayRemove([requesterUniqueId]),
      });
      batch.update(_firestore.collection('users').doc(requesterDocId), {
        'sentRequests': FieldValue.arrayRemove([_currentUser!.id]),
      });
      await batch.commit();

      _currentUser!.receivedRequests.remove(requesterUniqueId);
      await _fetchFriends();
      return null;
    } catch (e) {
      return 'Error rejecting request: $e';
    }
  }

  void resolveAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = AlertModel(
        id: _alerts[index].id,
        userId: _alerts[index].userId,
        userName: _alerts[index].userName,
        timestamp: _alerts[index].timestamp,
        lat: _alerts[index].lat,
        lng: _alerts[index].lng,
        isActive: false,
        type: _alerts[index].type,
      );

      if (activeAlerts.isEmpty) {
        _isSOSActive = false;
      }
      notifyListeners();
    }
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}