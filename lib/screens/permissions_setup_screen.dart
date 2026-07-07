import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/theme.dart';

/// Full-screen onboarding permissions setup.
/// Shown once after first login. Re-checks permissions on every HomeShell init.
class PermissionsSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PermissionsSetupScreen({super.key, required this.onComplete});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  int _currentStep = 0;
  bool _processing = false;

  final List<_PermStep> _steps = [
    _PermStep(
      icon: Icons.location_on_rounded,
      color: Color(0xFF4FC3F7),
      title: 'Precise Location',
      description:
          'Protega needs your precise location to share it with guardians during emergencies and display your real-time position on the map.',
      permission: Permission.locationWhenInUse,
    ),
    _PermStep(
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFF81C784),
      title: 'Location Accuracy',
      description:
          'For a better experience, your device will need to use High-Accuracy Location powered by Google Play Services.',
      permission: null, // handled separately with the `location` package
    ),
    _PermStep(
      icon: Icons.phone_rounded,
      color: Color(0xFFE57373),
      title: 'Phone Calls',
      description:
          'Allow Protega to make and manage phone calls so it can automatically dial your emergency contacts when SOS is triggered.',
      permission: Permission.phone,
    ),

    _PermStep(
      icon: Icons.settings_accessibility,
      color: Color(0xFFAB47BC),
      title: 'Background Hardware SOS',
      description:
          'Allow Protega to monitor your device\'s hardware volume buttons to trigger emergency SOS alerts even when the screen is locked.',
      permission: null, // Custom MethodChannel handling
    ),
    _PermStep(
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFFFFB74D),
      title: 'System Stability & Sleep Prevention (Required)',
      description:
          'To trigger the SOS when your screen is turned off or locked, you must grant these two settings on the next screen:\n1. Tap \'Battery\' -> Select \'Unrestricted\'\n2. Toggle OFF \'Remove permissions if app is unused\'',
      permission: null,
      actionText: 'Configure Stability',
    ),
  ];

  Future<void> _handleGrant() async {
    if (_processing) return;
    setState(() => _processing = true);

    final step = _steps[_currentStep];

    if (step.title == 'Location Accuracy') {
      // Use the `location` package to trigger the Google Play Services dialog
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // This will prompt the user to enable location services
        await Geolocator.getCurrentPosition();
      }
    } else if (step.title == 'Background Hardware SOS') {
      const platform = MethodChannel('com.example.protega/gesture');
      try {
        final bool isEnabled = await platform.invokeMethod('isAccessibilityServiceEnabled');
        if (!isEnabled) {
          await platform.invokeMethod('openAccessibilitySettings');
          setState(() => _processing = false);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text('Restricted Setting Warning', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'If the accessibility setting is greyed out as "Restricted":\n\n1. Open App Info for Protega\n2. Click the 3-dot overflow menu at the top right\n3. Select "Allow restricted settings"\n4. Come back and enable the service.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Understood', style: TextStyle(color: AppTheme.accent)),
                  ),
                ],
              ),
            );
          }
          return; // Do not advance until enabled
        }
      } catch (e) {
        debugPrint('Failed to check accessibility: $e');
      }
    } else if (step.title == 'System Stability & Sleep Prevention (Required)') {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } else if (step.permission != null) {
      final status = await step.permission!.status;
      if (!status.isGranted) {
        await step.permission!.request();
      }
    }

    _advance();
  }

  void _handleSkip() {
    _advance();
  }

  void _advance() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _processing = false;
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: 30),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.color.withAlpha(25),
                  border: Border.all(
                    color: step.color.withAlpha(70),
                    width: 2,
                  ),
                ),
                child: Icon(step.icon, color: step.color, size: 44),
              )
                  .animate(key: ValueKey(_currentStep))
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
              const SizedBox(height: 32),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              )
                  .animate(key: ValueKey('t$_currentStep'))
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 14),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              )
                  .animate(key: ValueKey('d$_currentStep'))
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1),
              const Spacer(flex: 3),
              // Allow button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _processing ? null : _handleGrant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          step.actionText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _processing ? null : _handleSkip,
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermStep {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final Permission? permission;
  final String actionText;

  const _PermStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.permission,
    this.actionText = 'Allow',
  });
}

/// Utility to re-verify critical permissions at runtime.
/// Returns a list of permissions that are currently denied.
class PermissionChecker {
  static Future<List<Permission>> getMissingPermissions() async {
    final required = [
      Permission.locationWhenInUse,
      Permission.phone,
    ];
    final missing = <Permission>[];
    for (final p in required) {
      if (!(await p.isGranted)) {
        missing.add(p);
      }
    }
    return missing;
  }

  /// Request a single permission and return true if granted.
  static Future<bool> requestIfDenied(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }
}
