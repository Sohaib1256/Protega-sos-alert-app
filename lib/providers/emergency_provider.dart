import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'hardware_provider.dart';

class EmergencyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AuthProvider? _authProvider;
  HardwareProvider? _hardwareProvider;

  final List<AlertModel> _alerts = [];
  final List<EmergencyContact> _emergencyContacts = [];
  final List<NotificationItem> _notifications = [];

  bool _isSOSActive = false;
  bool _fallDetectionEnabled = true;
  String _fallSensitivity = 'medium';

  StreamSubscription? _alertsSubscription;
  StreamSubscription? _friendAlertsSubscription;

  bool get isSOSActive => _isSOSActive;
  bool get sosActive => _isSOSActive;
  bool get fallDetectionEnabled => _fallDetectionEnabled;
  int get fallSensitivity {
    switch (_fallSensitivity) {
      case 'low': return 0;
      case 'high': return 2;
      default: return 1;
    }
  }

  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get activeAlerts => _alerts.where((a) => a.isActive).toList();
  List<AlertModel> get alertHistory => _alerts;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();

  UserModel? get _currentUser => _authProvider?.currentUser;
  String? get uid => _authProvider?.uid;

  EmergencyProvider() {
    _loadSettings();
  }

  void update(AuthProvider authProvider, HardwareProvider hardwareProvider) {
    final oldUid = _authProvider?.uid;
    _authProvider = authProvider;
    _hardwareProvider = hardwareProvider;
    
    _hardwareProvider?.onSOSTriggered = () {
      triggerSOS();
    };
    _hardwareProvider?.onLocationUpdated = (lat, lng) {
      setLocation(lat, lng);
    };
    _hardwareProvider?.getIsSOSActive = () => _isSOSActive;

    if (oldUid != authProvider.uid) {
      if (authProvider.uid != null) {
        fetchAlertHistory();
        _listenToAlerts();
        if (_currentUser?.role == UserRole.guardian) {
          _listenToFriendAlerts();
        }
      } else {
        _alertsSubscription?.cancel();
        _friendAlertsSubscription?.cancel();
        _alerts.clear();
        _notifications.clear();
        _isSOSActive = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fallDetectionEnabled = prefs.getBool('is_fall_detection_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setFallDetection(bool value) async {
    _fallDetectionEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_fall_detection_enabled', value);
    FlutterBackgroundService().invoke('updateSettings', {'is_fall_detection_enabled': value});
  }

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
      final updatedUser = _currentUser!.copyWith(lat: lat, lng: lng);
      _authProvider!.updateCurrentUser(updatedUser);
    }
  }

  Future<void> fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        setLocation(position.latitude, position.longitude);
        return;
      } on TimeoutException {
        debugPrint('High accuracy location timeout, falling back to medium...');
      } catch (e) {
        debugPrint('getCurrentPosition (high) failed: $e, falling back to medium...');
      }

      // Fallback: Medium Accuracy
      try {
        final fallbackPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        setLocation(fallbackPosition.latitude, fallbackPosition.longitude);
        return;
      } catch (e) {
        debugPrint('Fallback getCurrentPosition failed: $e');
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setLocation(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (e) {
      debugPrint('fetchUserLocation error: $e');
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
    if (_currentUser!.role == UserRole.guardian) return;

    if (_isSOSActive) return; // Prevent multiple triggers
    
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

    if (uid != null) {
      _firestore.collection('alerts').doc(alert.id).set({
        'id': alert.id,
        'userId': alert.userId,
        'userName': alert.userName,
        'senderId': uid,
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

    _triggerRTDBAlarm();
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
          await ref.set('SOS Pressed').timeout(const Duration(seconds: 5));
          success = true;
        } catch (e) {
          if (attempts < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          } else {
             ref.set('SOS Pressed'); 
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to trigger SOS in RTDB: $e');
    }
  }

  Future<void> _autoDialEmergency() async {
    final phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      final result = await Permission.phone.request();
      if (!result.isGranted) return;
    }

    String numberToDial = '911'; 
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
        if (uid != null) {
          try {
            await _firestore.collection('alerts').doc(_alerts[i].id).update({
              'isActive': false,
              'status': 'Normal',
            });
            
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
          }
        }
      }
    }
    
    if (hasBackendError) {
      throw Exception('Permission denied or network error while cancelling alert.');
    }

    _isSOSActive = false;

    FlutterBackgroundService().invoke("stopAlarm");

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('configured_device_id');
      if (deviceId != null) {
        await FirebaseDatabase.instance.ref('devices/$deviceId/alertStatus').set('Normal');
      }
    } catch (e) {
      throw Exception('Failed to synchronize hardware reset.');
    }

    notifyListeners();
    fetchUserLocation();
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

  Future<void> fetchAlertHistory() async {
    if (uid == null) return;
    try {
      final snapshot = await _firestore
          .collection('alerts')
          .where('senderId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();
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
    } catch (e) {
      debugPrint('Error fetching alert history: $e');
    }
  }

  void _listenToAlerts() {
    if (uid == null) return;
    _alertsSubscription?.cancel();
    _alertsSubscription = _firestore
        .collection('alerts')
        .where('senderId', isEqualTo: uid)
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
    });
  }

  void _listenToFriendAlerts() {
    _friendAlertsSubscription?.cancel();
    if (_currentUser == null || _currentUser!.friends.isEmpty) return;

    _friendAlertsSubscription = _firestore
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final alertUserId = data['userId'] as String?;
        if (alertUserId != null && _currentUser!.friends.contains(alertUserId)) {
          if (!_isSOSActive) {
            _isSOSActive = true;
            FlutterBackgroundService().invoke("triggerAlarm");
            _notifications.insert(
              0,
              NotificationItem(
                title: '\u{1F6A8} Friend SOS Alert!',
                message: '${data['userName'] ?? 'A friend'} has triggered an emergency SOS',
                type: 'sos',
              ),
            );
            notifyListeners();
          }
          return;
        }
      }
      if (_isSOSActive && _currentUser!.role == UserRole.guardian) {
        _isSOSActive = false;
        FlutterBackgroundService().invoke("stopAlarm");
        notifyListeners();
      }
    });
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
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
}
