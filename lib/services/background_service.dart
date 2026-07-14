import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

// ──────────────────────────────────────────────
// Channel IDs
// ──────────────────────────────────────────────
const String _serviceChannelId = 'protega_service_channel';
const String _sosAlarmChannelId = 'protega_sos_alarm_channel';

Future<void> initializeBackgroundService() async {
  if (!await Permission.location.isGranted || !await Permission.notification.isGranted) {
    debugPrint('Background Service delayed: Location or Notification permissions not yet granted.');
    return;
  }

  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Channel 1: Silent persistent foreground service notification ──
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    _serviceChannelId,
    'Protega Background Service',
    description: 'Persistent notification for the background safety monitor.',
    importance: Importance.low, // Low = silent, no popup
  );

  // ── Channel 2: SOS Alarm — max importance, DND bypass, vibration ──
  const AndroidNotificationChannel sosAlarmChannel = AndroidNotificationChannel(
    _sosAlarmChannelId,
    'SOS Emergency Alarm',
    description: 'Critical alarm channel for SOS and Fall Detection alerts.',
    importance: Importance.max,
    enableVibration: true,
    playSound: true, // Default; conditionally overridden per-notification
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(serviceChannel);
  await androidPlugin?.createNotificationChannel(sosAlarmChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      // Use the LOW-importance service channel for the persistent notification
      notificationChannelId: _serviceChannelId,
      initialNotificationTitle: 'Protega Safety Guardian',
      initialNotificationContent: 'Monitoring for emergencies in the background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Audioplayers: reinforcement loop for sustained alarm ──
  final audioPlayer = AudioPlayer();
  audioPlayer.setReleaseMode(ReleaseMode.loop);
  
  await audioPlayer.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.alarm, // Alarm stream: plays at alarm volume, bypasses silent/vibrate modes
        audioFocus: AndroidAudioFocus.gainTransientExclusive,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ),
  );
  
  bool isAlarmPlaying = false;
  bool isSoundEnabled = true;
  bool isFallEnabled = true;
  String? localAlarmPath;
  String? configuredDeviceId;
  
  // Read the persistently cached asset path and initial settings
  final initialPrefs = await SharedPreferences.getInstance();
  await initialPrefs.reload();
  localAlarmPath = initialPrefs.getString('cached_alarm_path');
  isSoundEnabled = initialPrefs.getBool('is_local_alarm_enabled') ?? true;
  isFallEnabled = initialPrefs.getBool('is_fall_detection_enabled') ?? true;
  configuredDeviceId = initialPrefs.getString('configured_device_id');
  debugPrint('BG_SERVICE_BOOT: Retrieved cached_alarm_path from SharedPreferences -> $localAlarmPath');
  
  // Fallback: if key is missing, try to locate alarm.mp3 in documents directory
  if (localAlarmPath == null || !File(localAlarmPath).existsSync()) {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fallbackFile = File('${directory.path}/alarm.mp3');
      if (await fallbackFile.exists() && await fallbackFile.length() > 0) {
        localAlarmPath = fallbackFile.path;
        debugPrint('BG_SERVICE_BOOT: Fallback found alarm.mp3 at $localAlarmPath');
      } else {
        debugPrint('BG_SERVICE_BOOT: WARNING - alarm.mp3 not found in documents directory either');
      }
    } catch (e) {
      debugPrint('BG_SERVICE_BOOT: Fallback path resolution failed: $e');
    }
  }
  
  // Manual loop fallback in case Android MediaPlayer ignores ReleaseMode.loop
  audioPlayer.onPlayerComplete.listen((_) async {
    if (isAlarmPlaying && localAlarmPath != null) {
      try {
        await audioPlayer.play(DeviceFileSource(localAlarmPath), volume: 1.0);
      } catch (e) {
        debugPrint('BG_SERVICE: Loop replay failed: $e');
      }
    }
  });

  // ── REUSABLE TRIGGER LOGIC ──
  Future<void> executeEmergencyTrigger(String triggerSource) async {
    // ── ROBUST CONFIGURATION LOOKUP ──
    bool soundEnabledAtTrigger = isSoundEnabled;

    // ── FIRE SOS NOTIFICATION ──
    try {
      flutterLocalNotificationsPlugin.show(
        999,
        '🚨 Emergency! Alert Triggered',
        'Your device triggered an emergency alert: $triggerSource',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _sosAlarmChannelId,
            'SOS Emergency Alarm',
            icon: 'launcher_icon',
            importance: Importance.max,
            priority: Priority.max,
            ongoing: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
            playSound: soundEnabledAtTrigger,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          ),
        ),
      );
    } catch (e) {
      debugPrint('BG_SERVICE_TRIGGER: Notification dispatch failed (will still attempt audio): $e');
    }

    // ── REINFORCEMENT: Audioplayers sustained loop ──
    debugPrint('BG_SERVICE_TRIGGER: soundEnabled=$soundEnabledAtTrigger, isAlarmPlaying=$isAlarmPlaying, localAlarmPath=$localAlarmPath');
    if (soundEnabledAtTrigger && !isAlarmPlaying) {
      debugPrint('BG_SERVICE_TRIGGER: Starting audioplayer reinforcement loop');
      try {
        isAlarmPlaying = true;
        if (localAlarmPath != null && File(localAlarmPath).existsSync()) {
           await audioPlayer.play(DeviceFileSource(localAlarmPath), volume: 1.0);
        } else {
           debugPrint('BG_SERVICE_TRIGGER: Local alarm path invalid, attempting fallback to AssetSource.');
           await audioPlayer.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);
        }
        debugPrint("DEBUG_AUDIO: Play command executed successfully!");
      } catch (e) {
        debugPrint('BG_SERVICE_TRIGGER: audioPlayer.play() failed: $e');
        isAlarmPlaying = false;
      }
    }
  }

  // ── BRIDGE LISTENER: Triggered from Foreground UI Isolate ──
  service.on('triggerAlarm').listen((event) {
    debugPrint('BG_SERVICE_IPC: triggerAlarm received from UI isolate');
    executeEmergencyTrigger("UI SOS Button");
  });

  // ── STOP LISTENER: Cancellation from Foreground UI Isolate ──
  service.on('stopAlarm').listen((event) async {
    debugPrint('BG_SERVICE_IPC: stopAlarm received from UI isolate');
    if (isAlarmPlaying) {
      try {
        await audioPlayer.stop();
        await audioPlayer.release();
      } catch (e) {
        debugPrint('BG_SERVICE_IPC: audioPlayer.stop/release failed: $e');
      }
      isAlarmPlaying = false;
    }
    // Dismiss the SOS notification
    flutterLocalNotificationsPlugin.cancel(999);

    // Safety net: also write 'Normal' to RTDB in case the UI write was delayed
    try {
      if (configuredDeviceId != null) {
        await FirebaseDatabase.instance.ref('devices/$configuredDeviceId/alertStatus').set('Normal');
      }
    } catch (e) {
      debugPrint('BG_SERVICE_IPC: RTDB safety-net write failed: $e');
    }
  });

  // ── SETTINGS UPDATE LISTENER ──
  service.on('updateSettings').listen((event) async {
    debugPrint('BG_SERVICE_IPC: updateSettings received: $event');
    if (event == null) return;
    
    if (event.containsKey('is_local_alarm_enabled')) {
      isSoundEnabled = event['is_local_alarm_enabled'];
      if (!isSoundEnabled && isAlarmPlaying) {
        await audioPlayer.stop();
        isAlarmPlaying = false;
      }
    }
    
    if (event.containsKey('is_fall_detection_enabled')) {
      isFallEnabled = event['is_fall_detection_enabled'];
    }
    
    if (event.containsKey('configured_device_id')) {
      configuredDeviceId = event['configured_device_id'];
    }
  });

  // ── NATIVE SOS LISTENER: Event-driven trigger from SosBroadcastReceiver via servicePipe ──
  service.on('nativeSosFired').listen((event) async {
    debugPrint('BG_SERVICE_IPC: nativeSosFired received from native AccessibilityService!');
    await executeEmergencyTrigger('Volume Key SOS');
    // Notify the UI isolate if it's alive so it can update EmergencyProvider state
    service.invoke('nativeSosFired');
  });

  String? lastAlertStatus;
  StreamSubscription<DatabaseEvent>? deviceSubscription;

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final deviceId = configuredDeviceId;
        
        // If alarm is playing but user disabled it in settings, stop it
        if (!isSoundEnabled && isAlarmPlaying) {
          await audioPlayer.stop();
          isAlarmPlaying = false;
        }
        
        if (deviceId != null && deviceSubscription == null) {
          // Initialize listener for this device
          deviceSubscription = FirebaseDatabase.instance
              .ref('devices/$deviceId')
              .onValue
              .listen((event) async {
            if (event.snapshot.value != null) {
              final data = Map<String, dynamic>.from(event.snapshot.value as Map);
              if (data.containsKey('alertStatus')) {
                final status = data['alertStatus'];
                
                if (status != lastAlertStatus) {
                  lastAlertStatus = status;
                  
                  if (status == 'SOS Pressed' || status == 'Fall Detected') {
                    if (status == 'Fall Detected') {
                      if (!isFallEnabled) {
                        await FirebaseDatabase.instance.ref('devices/$deviceId/alertStatus').set('Normal');
                        return;
                      }
                    }
                    
                    await executeEmergencyTrigger(status);
                  } else if (status == 'Normal') {
                    // Stop alarm when status is normal
                    if (isAlarmPlaying) {
                      await audioPlayer.stop();
                      isAlarmPlaying = false;
                    }
                    flutterLocalNotificationsPlugin.cancel(999);
                  }
                }
              }
            }
          });
        } else if (deviceId == null && deviceSubscription != null) {
          // Disconnected
          deviceSubscription?.cancel();
          deviceSubscription = null;
          if (isAlarmPlaying) {
            await audioPlayer.stop();
            isAlarmPlaying = false;
          }
        }
      }
    }
  });
}
