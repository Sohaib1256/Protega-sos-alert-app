import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'auth_provider.dart';
import '../models/models.dart';

class HardwareProvider with ChangeNotifier {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AuthProvider? _authProvider;
  
  bool _deviceConfigured = false;
  ThemeMode _themeMode = ThemeMode.dark;
  String _sosGesture = 'disabled';
  bool _isLocalAlarmSoundEnabled = true;
  
  StreamSubscription<DatabaseEvent>? _deviceSubscription;
  Timer? _onlineStatusTimer;
  DateTime? _lastDeviceUpdate;
  String _deviceAlertStatus = 'Normal';

  // Callbacks to interact with EmergencyProvider without tight coupling
  void Function()? onSOSTriggered;
  void Function(double lat, double lng)? onLocationUpdated;
  bool Function()? getIsSOSActive;

  bool get deviceConfigured => _deviceConfigured;
  ThemeMode get themeMode => _themeMode;
  String get sosGesture => _sosGesture;
  bool get isLocalAlarmSoundEnabled => _isLocalAlarmSoundEnabled;
  String get deviceAlertStatus => _deviceAlertStatus;
  
  bool get isDeviceOnline {
    if (_lastDeviceUpdate == null) return false;
    return DateTime.now().difference(_lastDeviceUpdate!).inSeconds < 40;
  }

  UserModel? get _currentUser => _authProvider?.currentUser;

  HardwareProvider() {
    _loadTheme();
    _loadSosGesture();
    _loadAlarmSettings();
  }

  void update(AuthProvider authProvider) {
    final oldUid = _authProvider?.uid;
    _authProvider = authProvider;
    
    if (_currentUser != null) {
      if (!_deviceConfigured && _currentUser!.deviceConfigured) {
        _deviceConfigured = true;
        if (_currentUser!.deviceId != null) {
          _listenToDevice(_currentUser!.deviceId!);
        }
      } else if (oldUid != authProvider.uid && _currentUser!.deviceId != null && _currentUser!.deviceConfigured) {
        _listenToDevice(_currentUser!.deviceId!);
      }
    } else {
      _deviceConfigured = false;
      _deviceSubscription?.cancel();
      _deviceSubscription = null;
    }
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

  Future<void> _loadSosGesture() async {
    final prefs = await SharedPreferences.getInstance();
    _sosGesture = prefs.getString('sos_gesture_type') ?? 'disabled';
    notifyListeners();
  }

  Future<void> setSosGesture(String gesture) async {
    _sosGesture = gesture;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_gesture_type', gesture);
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
    FlutterBackgroundService().invoke('updateSettings', {'is_local_alarm_enabled': value});
  }
  
  void setDeviceConfigured(bool value) {
    _deviceConfigured = value;
    notifyListeners();
  }

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
        
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          double lat = (data['latitude'] as num).toDouble();
          double lng = (data['longitude'] as num).toDouble();
          onLocationUpdated?.call(lat, lng);
        }
        
        if (data.containsKey('timestamp')) {
          double ts = (data['timestamp'] as num).toDouble();
          if (ts > 100000) {
            _lastDeviceUpdate = DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());
          } else {
            _lastDeviceUpdate = DateTime.now();
          }
        } else {
          _lastDeviceUpdate = DateTime.now();
        }
        
        if (data.containsKey('alertStatus')) {
          _deviceAlertStatus = data['alertStatus'];
          final isSOSActive = getIsSOSActive?.call() ?? false;
          if (_deviceAlertStatus != 'Normal' && !isSOSActive) {
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
            onSOSTriggered?.call();
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
    if (deviceId.length < 4) return; 

    _deviceConfigured = true;
    _listenToDevice(deviceId);
    
    final updatedUser = _currentUser!.copyWith(
      deviceConfigured: true,
      deviceId: deviceId,
    );
    _authProvider!.updateCurrentUser(updatedUser);
    
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('configured_device_id', deviceId);
      FlutterBackgroundService().invoke('updateSettings', {'configured_device_id': deviceId});

      await _firestore.collection('users').doc(_authProvider!.uid).update({
        'deviceId': deviceId,
        'deviceConfigured': true,
      });
    } catch (e) {
      debugPrint('Error persisting device config: $e');
    }
  }

  Future<void> disconnectDevice() async {
    if (_currentUser == null) return;

    _deviceConfigured = false;
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    
    final updatedUser = _currentUser!.copyWith(
      deviceConfigured: false,
      deviceId: null,
    );
    // Passing null directly to copyWith doesn't work if it's not handled, assuming it's handled or we bypass it by doing it in auth provider.
    // Actually in auth_provider it's better to update it:
    _authProvider!.updateCurrentUser(
      UserModel(
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        role: updatedUser.role,
        guardianPhone: updatedUser.guardianPhone,
        phone: updatedUser.phone,
        countryCode: updatedUser.countryCode,
        avatarUrl: updatedUser.avatarUrl,
        occupation: updatedUser.occupation,
        age: updatedUser.age,
        batteryLevel: updatedUser.batteryLevel,
        isOnline: updatedUser.isOnline,
        deviceConfigured: false,
        deviceId: null,
        lat: updatedUser.lat,
        lng: updatedUser.lng,
        friends: updatedUser.friends,
        sentRequests: updatedUser.sentRequests,
        receivedRequests: updatedUser.receivedRequests,
      )
    );
    
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('configured_device_id');
      FlutterBackgroundService().invoke('updateSettings', {'configured_device_id': null});

      await _firestore.collection('users').doc(_authProvider!.uid).update({
        'deviceId': FieldValue.delete(),
        'deviceConfigured': false,
      });
    } catch (e) {
      debugPrint('Error clearing device config: $e');
    }
  }
}
