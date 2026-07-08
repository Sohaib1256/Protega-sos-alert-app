import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


import '../widgets/glass_card.dart';
import '../widgets/glass_chip.dart';



class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});



  @override

  State<SettingsScreen> createState() => _SettingsScreenState();

}



class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _isAccessibilityEnabled = false;
  bool _isBatteryUnrestricted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemStatus();
    }
  }

  Future<void> _checkSystemStatus() async {
    bool accEnabled = false;
    try {
      const platform = MethodChannel('com.example.protega/gesture');
      accEnabled = await platform.invokeMethod('isAccessibilityServiceEnabled');
    } catch (e) {
      debugPrint('Error checking accessibility: $e');
    }

    bool battUnrestricted = false;
    try {
      const platform = MethodChannel('com.example.protega/gesture');
      battUnrestricted = await platform.invokeMethod('isIgnoringBatteryOptimizations');
    } catch (e) {
      debugPrint('Error checking battery: $e');
    }

    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = accEnabled;
        _isBatteryUnrestricted = battUnrestricted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<AppProvider>(

      builder: (context, provider, _) {

        final user = provider.currentUser;

        if (user == null) return const SizedBox.shrink();

        final isGuardian = user.role == UserRole.guardian;

        return SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              SizedBox(height: 8),

              Text(

                'Settings',

                style: TextStyle(

                  fontSize: 22,

                  fontWeight: FontWeight.w700,

                ),

              )

                  .animate()

                  .fadeIn(duration: 500.ms)

                  .slideX(begin: -0.05),

              const SizedBox(height: 20),

              _buildProfileCard(user)

                  .animate()

                  .fadeIn(delay: 100.ms, duration: 500.ms)

                  .slideY(begin: 0.05),

              const SizedBox(height: 14),

              _buildSection(

                'Safety',

                [

                  _buildFallDetectionTile(provider),

                  if (provider.fallDetectionEnabled)

                    _buildSensitivitySlider(provider),

                  _buildAlarmSoundTile(provider),

                ],

              )

                  .animate()

                  .fadeIn(delay: 200.ms, duration: 500.ms)

                  .slideY(begin: 0.05),

              const SizedBox(height: 14),

              if (!isGuardian)
                _buildSection(

                  'Emergency Gestures',

                  [
                    _buildGestureOption(
                      provider,
                      'Disabled',
                      'No gesture shortcut',
                      Icons.block_rounded,
                      'disabled',
                    ),
                    _buildGestureOption(
                      provider,
                      'Triple-Tap Screen',
                      'Tap screen 3× rapidly to trigger SOS',
                      Icons.touch_app_rounded,
                      'triple_tap',
                    ),
                    _buildGestureOption(
                      provider,
                      'Volume Key Combo',
                      'Press Volume Up 3× rapidly to trigger SOS',
                      Icons.volume_up_rounded,
                      'volume_key',
                    ),

                  ],

                )

                    .animate()

                    .fadeIn(delay: 250.ms, duration: 500.ms)

                    .slideY(begin: 0.05),

              if (!isGuardian)
                const SizedBox(height: 14),

              _buildSection(
                'System Permissions & Status',
                [
                  if (!isGuardian)
                    _buildStatusTile(
                      title: 'Background Hardware Gestures',
                      isOk: _isAccessibilityEnabled,
                      actionText: 'Enable Layer',
                      onAction: () async {
                        const platform = MethodChannel('com.example.protega/gesture');
                        await platform.invokeMethod('openAccessibilitySettings');
                        // Wait a bit before re-checking
                        await Future.delayed(const Duration(seconds: 1));
                        _checkSystemStatus();
                      },
                    ),
                  _buildStatusTile(
                    title: 'Battery Optimization',
                    isOk: _isBatteryUnrestricted,
                    actionText: 'Configure',
                    onAction: () async {
                      const platform = MethodChannel('com.example.protega/gesture');
                      await platform.invokeMethod('openAppInfoSettings');
                      await Future.delayed(const Duration(seconds: 1));
                      _checkSystemStatus();
                    },
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.05),

              if (!isGuardian)
                const SizedBox(height: 14),

              if (!isGuardian)
                _buildSection(

                  'Emergency Contacts',

                  [

                    ...provider.emergencyContacts.map(

                          (c) => _buildContactTile(c, provider),

                    ),

                    _buildAddContactTile(context),

                  ],

                )

                    .animate()

                    .fadeIn(delay: 300.ms, duration: 500.ms)

                    .slideY(begin: 0.05),

              const SizedBox(height: 14),

              _buildSection(

                'Device',

                [

                  _buildDeviceSetupTile(context, provider),

                ],

              )

                  .animate()

                  .fadeIn(delay: 400.ms, duration: 500.ms)

                  .slideY(begin: 0.05),

              const SizedBox(height: 14),

              _buildSection(

                'Appearance',

                [

                  _buildThemeToggleTile(provider),

                ],

              )

                  .animate()

                  .fadeIn(delay: 450.ms, duration: 500.ms)

                  .slideY(begin: 0.05),

              const SizedBox(height: 14),

              _buildSection(

                'Account',

                [

                  _buildMenuTile(

                    'Your ID',

                    user.id,

                    Icons.fingerprint_rounded,

                    AppTheme.accentCyan,

                    onTap: () {

                      Clipboard.setData(ClipboardData(text: user.id));

                      ScaffoldMessenger.of(context).showSnackBar(

                        SnackBar(

                          content: Text('ID copied: ${user.id}'),

                          backgroundColor: Theme.of(context).cardColor,

                          behavior: SnackBarBehavior.floating,

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(12),

                          ),

                        ),

                      );

                    },

                  ),

                  _buildMenuTile(
                    'Privacy Policy',
                    'View our policies',
                    Icons.privacy_tip_outlined,
                    Theme.of(context).textTheme.bodySmall!.color!,
                    onTap: () => _showTextModal(
                      context,
                      'Privacy Policy',
                      'Effective Date: June 30, 2026\n\n1. Data Collection & Transmission: Protega collects and transmits real-time geographic location coordinates (latitude and longitude) and user profile information exclusively during an active emergency SOS event. This data is securely sent to your designated guardians and stored in our protected cloud database to maintain an accurate incident timeline.\n\n2. Use of Accessibility Service API: Protega requires the activation of an Android Accessibility Service to fulfill its core safety function. This service monitors physical hardware key combinations (specifically rapid presses of the volume hardware keys). This tracking operates continuously in the background, even when the application is closed, killed, or the device screen is locked/turned off.\n\n* Data Privacy Guarantee: The Accessibility Service is strictly utilized to intercept the emergency key trigger combination. Protega never collects, stores, logs, or monitors user text input, passwords, personal data, on-screen content, or general app activity.\n\n3. Battery and Background Processing: To ensure uninterrupted safety operational stability, Protega requires unrestricted background processing access. No personal activity telemetry is harvested during routine background system execution.',
                    ),
                  ),
                  _buildMenuTile(
                    'About Protega',
                    'Version 1.0.0',
                    Icons.info_outline_rounded,
                    Theme.of(context).textTheme.bodySmall!.color!,
                    onTap: () => _showTextModal(
                      context,
                      'About Protega',
                      'Protega is an advanced personal safety guardian application engineered to provide real-time monitoring and automated emergency dispatch. Designed for vulnerable individuals, patients, and lone workers, Protega seamlessly bridges hardware and software environments. Utilizing native system-level background integrations, the application monitors hardware interaction grids to instantly broadcast distress signals, precision GPS coordinates, and real-time telemetry metrics to designated emergency guardians the moment an incident occurs.',
                    ),
                  ),
                ],

              )

                  .animate()

                  .fadeIn(delay: 500.ms, duration: 500.ms)

                  .slideY(begin: 0.05),

              const SizedBox(height: 100),

            ],

          ),

        );

      },

    );

  }



  Widget _buildProfileCard(UserModel user) {

    return GlassCard(

      padding: const EdgeInsets.all(18),

      child: Column(

        children: [

          Row(

            children: [

              Stack(

                children: [

                  Container(

                    width: 60,

                    height: 60,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      border: Border.all(

                        color: AppTheme.accent.withAlpha(60),

                        width: 2.5,

                      ),

                      image: DecorationImage(
                        image: user.avatarUrl.startsWith('http')
                            ? NetworkImage(user.avatarUrl)
                            : FileImage(File(user.avatarUrl)) as ImageProvider,
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),

                    ),

                  ),

                  Positioned(

                    right: 0,

                    bottom: 0,

                    child: Container(

                      padding: const EdgeInsets.all(4),

                      decoration: BoxDecoration(

                        color: AppTheme.accent,

                        shape: BoxShape.circle,

                        border: Border.all(

                          color: Theme.of(context).scaffoldBackgroundColor,

                          width: 2,

                        ),

                      ),

                      child: Icon(Icons.camera_alt_rounded,

                          size: 10, color: Colors.white),

                    ),

                  ),

                ],

              ),

              const SizedBox(width: 14),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      user.name,

                      style: TextStyle(

                        fontSize: 17,

                        fontWeight: FontWeight.w700,

                      ),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                    ),

                    const SizedBox(height: 2),

                    Text(

                      user.email,

                      style: TextStyle(

                        fontSize: 12,

                      ),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                    ),

                    const SizedBox(height: 4),

                    GlassChip(

                      label: user.displayRole,

                      icon: user.roleIcon,

                      color: AppTheme.accentIndigo,

                      isActive: true,

                    ),

                  ],

                ),

              ),

              GestureDetector(

                onTap: () => _showEditProfile(context, user),

                child: Container(

                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(

                    color: Colors.white.withAlpha(8),

                    borderRadius: BorderRadius.circular(10),

                    border: Border.all(color: Colors.white.withAlpha(15)),

                  ),

                  child: const Icon(Icons.edit_rounded,

                      size: 16, color: AppTheme.accent),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildThemeToggleTile(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBorder.color),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.dark_mode_rounded,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Toggle between light and dark themes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: provider.themeMode == ThemeMode.dark,
            onChanged: (v) => context.read<AppProvider>().toggleTheme(v),
            activeTrackColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Padding(

          padding: const EdgeInsets.only(left: 4, bottom: 8),

          child: Text(

            title.toUpperCase(),

            style: TextStyle(

              fontSize: 11,

              fontWeight: FontWeight.w700,

              letterSpacing: 1.2,

            ),

          ),

        ),

        GlassCard(

          padding: const EdgeInsets.symmetric(vertical: 4),

          child: Column(children: children),

        ),

      ],

    );

  }



  Widget _buildFallDetectionTile(AppProvider provider) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

      child: Row(

        children: [

          Container(

            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(

              color: AppTheme.warning.withAlpha(20),

              borderRadius: BorderRadius.circular(10),

            ),

            child: Icon(Icons.accessibility_new_rounded,

                color: AppTheme.warning, size: 18),

          ),

          const SizedBox(width: 12),

          const Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  'Fall Detection',

                  style: TextStyle(

                    fontSize: 14,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                Text(

                  'Auto-detect falls and alert guardians',

                  style: TextStyle(

                    fontSize: 11,

                  ),

                ),

              ],

            ),

          ),

          Switch.adaptive(

            value: provider.fallDetectionEnabled,

            onChanged: (v) => provider.setFallDetection(v),

            activeTrackColor: AppTheme.accent,

          ),

        ],

      ),

    );

  }



  Widget _buildAlarmSoundTile(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.volume_up_rounded,
                color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Alarm Sound on Trigger',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Play loud alarm sound during emergencies',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: provider.isLocalAlarmSoundEnabled,
            onChanged: (v) => provider.setLocalAlarmSoundEnabled(v),
            activeTrackColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }



  Widget _buildSensitivitySlider(AppProvider provider) {

    final labels = ['Low', 'Medium', 'High'];

    return Padding(

      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Text(

                'Sensitivity',

                style: TextStyle(

                  fontSize: 12,

                ),

              ),

              Container(

                padding: const EdgeInsets.symmetric(

                    horizontal: 8, vertical: 3),

                decoration: BoxDecoration(

                  color: AppTheme.accent.withAlpha(20),

                  borderRadius: BorderRadius.circular(6),

                ),

                child: Text(

                  labels[provider.fallSensitivity],

                  style: const TextStyle(

                    fontSize: 10,

                    fontWeight: FontWeight.w600,

                    color: AppTheme.accent,

                  ),

                ),

              ),

            ],

          ),

          SliderTheme(

            data: SliderThemeData(

              activeTrackColor: AppTheme.accent,

              inactiveTrackColor: Colors.white.withAlpha(15),

              thumbColor: AppTheme.accent,

              overlayColor: AppTheme.accent.withAlpha(30),

              trackHeight: 4,

            ),

            child: Slider(

              value: provider.fallSensitivity.toDouble(),

              min: 0,

              max: 2,

              divisions: 2,

              onChanged: (v) =>

                  provider.setFallSensitivity(v),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildGestureOption(
    AppProvider provider,
    String title,
    String subtitle,
    IconData icon,
    String value,
  ) {
    final isSelected = provider.sosGesture == value;
    final color = isSelected ? AppTheme.accent : Theme.of(context).textTheme.bodySmall!.color!;

    return GestureDetector(
      onTap: () {
        provider.setSosGesture(value);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSelected ? AppTheme.accent : color).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? AppTheme.accent : color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.accent : color.withAlpha(80),
                  width: 2,
                ),
                color: isSelected ? AppTheme.accent.withAlpha(20) : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showTextModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.75,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(204),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTile(EmergencyContact contact, AppProvider provider) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

      child: Row(

        children: [

          Container(

            width: 36,

            height: 36,

            decoration: BoxDecoration(

              color: AppTheme.danger.withAlpha(20),

              borderRadius: BorderRadius.circular(10),

            ),

            child: Center(

              child: Text(

                contact.name[0].toUpperCase(),

                style: TextStyle(

                  fontWeight: FontWeight.w700,

                  color: AppTheme.danger,

                  fontSize: 14,

                ),

              ),

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  contact.name,

                  style: TextStyle(

                    fontSize: 13,

                    fontWeight: FontWeight.w600,

                  ),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                ),

                Text(

                  '${contact.countryCode} ${contact.phone} • ${contact.relation}',

                  style: TextStyle(

                    fontSize: 11,

                  ),

                ),

              ],

            ),

          ),

          GestureDetector(

            onTap: () => provider.removeEmergencyContact(contact.id),

            child: Container(

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(

                color: AppTheme.danger.withAlpha(15),

                borderRadius: BorderRadius.circular(8),

              ),

              child: const Icon(Icons.close_rounded,

                  size: 14, color: AppTheme.danger),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildAddContactTile(BuildContext context) {

    return GestureDetector(

      onTap: () => _showAddContactModal(context),

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

        child: Row(

          children: [

            Container(

              width: 36,

              height: 36,

              decoration: BoxDecoration(

                color: AppTheme.accent.withAlpha(15),

                borderRadius: BorderRadius.circular(10),

                border: Border.all(

                  color: AppTheme.accent.withAlpha(40),

                  style: BorderStyle.solid,

                ),

              ),

              child: const Icon(Icons.add_rounded,

                  size: 18, color: AppTheme.accent),

            ),

            const SizedBox(width: 12),

            const Text(

              'Add Emergency Contact',

              style: TextStyle(

                fontSize: 13,

                fontWeight: FontWeight.w600,

                color: AppTheme.accent,

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildDeviceSetupTile(

      BuildContext context, AppProvider provider) {

    return GestureDetector(

      onTap: () => _showDeviceSetup(context, provider),

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        child: Row(

          children: [

            Container(

              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(

                color: AppTheme.accentCyan.withAlpha(20),

                borderRadius: BorderRadius.circular(10),

              ),

              child: Icon(Icons.wifi_rounded,

                  color: AppTheme.accentCyan, size: 18),

            ),

            const SizedBox(width: 12),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'Device Setup',

                    style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  Text(

                    provider.deviceConfigured

                        ? 'Connected & Synced'

                        : 'Tap to configure',

                    style: TextStyle(

                      fontSize: 11,

                      color: provider.deviceConfigured

                          ? AppTheme.success

                          : Theme.of(context).textTheme.bodySmall!.color!,

                    ),

                  ),

                ],

              ),

            ),

            PulsingDot(

              color: provider.deviceConfigured

                  ? AppTheme.success

                  : Theme.of(context).textTheme.bodySmall!.color!,

            ),

            const SizedBox(width: 8),

            Icon(Icons.chevron_right_rounded, size: 18),

          ],

        ),

      ),

    );

  }



  Widget _buildMenuTile(

      String title,

      String subtitle,

      IconData icon,

      Color color, {

        VoidCallback? onTap,

      }) {

    return GestureDetector(

      onTap: onTap,

      behavior: HitTestBehavior.opaque,

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        child: Row(

          children: [

            Container(

              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(

                color: color.withAlpha(20),

                borderRadius: BorderRadius.circular(10),

              ),

              child: Icon(icon, color: color, size: 18),

            ),

            SizedBox(width: 12),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  Text(

                    subtitle,

                    style: TextStyle(

                      fontSize: 11,

                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                  ),

                ],

              ),

            ),

            if (onTap != null)

              Icon(Icons.chevron_right_rounded, size: 18),

          ],

        ),

      ),

    );

  }



  void _showEditProfile(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final occCtrl = TextEditingController(text: user.occupation ?? '');
    final ageCtrl = TextEditingController(text: user.age?.toString() ?? '');
    final avatarCtrl = TextEditingController(text: user.avatarUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 24, 24, MediaQuery.viewInsetsOf(ctx).bottom + MediaQuery.paddingOf(ctx).bottom + 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SingleChildScrollView( child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.accent.withAlpha(100), width: 2),
                                image: DecorationImage(
                                  image: avatarCtrl.text.startsWith('http')
                                      ? NetworkImage(avatarCtrl.text)
                                      : FileImage(File(avatarCtrl.text)) as ImageProvider,
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    setModalState(() {
                                      avatarCtrl.text = image.path;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                  ),
                                  child: Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameCtrl,
                        maxLength: 15,
                        cursorColor: AppTheme.accent,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          counterText: '',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: Theme.of(context).iconTheme.color, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: occCtrl,
                        cursorColor: AppTheme.accent,
                        decoration: InputDecoration(
                          hintText: 'Occupation',
                          prefixIcon: Icon(Icons.work_outline_rounded, color: Theme.of(context).iconTheme.color, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        cursorColor: AppTheme.accent,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined, color: Theme.of(context).iconTheme.color, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          ctx.read<AppProvider>().updateProfile(
                            name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                            occupation: occCtrl.text.trim().isNotEmpty ? occCtrl.text.trim() : null,
                            age: int.tryParse(ageCtrl.text),
                            avatarUrl: avatarCtrl.text.trim().isNotEmpty ? avatarCtrl.text.trim() : null,
                          );
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppTheme.accent,
                          ),
                          child: const Center(
                            child: Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),),
            );
          },
        );
      },
    );
  }



  void _showAddContactModal(BuildContext context) {

    final nameCtrl = TextEditingController();

    final phoneCtrl = TextEditingController();

    final relationCtrl = TextEditingController();

    String? error;



    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) {

        return StatefulBuilder(

          builder: (ctx, setModalState) {

            return Container(

                   padding: EdgeInsets.fromLTRB(24, 24, 24,

                       MediaQuery.viewInsetsOf(ctx).bottom + MediaQuery.paddingOf(ctx).bottom + 24),

                   decoration: BoxDecoration(

                     color: Theme.of(context).cardColor,

                     borderRadius: const BorderRadius.vertical(

                         top: Radius.circular(24)),

                     border:

                     Border.all(color: Colors.white.withAlpha(15)),

                   ),

                   child: SingleChildScrollView( child: Column(

                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [

                      Center(

                        child: Container(

                          width: 40,

                          height: 4,

                          decoration: BoxDecoration(

                            color: Colors.white.withAlpha(30),

                            borderRadius: BorderRadius.circular(2),

                          ),

                        ),

                      ),

                      SizedBox(height: 20),

                      Text(

                        'Add Emergency Contact',

                        style: TextStyle(

                          fontSize: 20,

                          fontWeight: FontWeight.w700,

                        ),

                        textAlign: TextAlign.center,

                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: nameCtrl,
                        maxLength: 15,
                        cursorColor: AppTheme.accent,
                        decoration: InputDecoration(
                          hintText: 'Contact Name',
                          counterText: '',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.number,
                        cursorColor: AppTheme.accent,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Phone (10 digits)',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 6),
                            child: Text(
                              '+92',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: relationCtrl,
                        cursorColor: AppTheme.accent,
                        decoration: InputDecoration(
                          hintText: 'Relation (e.g., Doctor, Family)',
                          prefixIcon: Icon(
                            Icons.group_outlined,
                            color: Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                      ),

                      if (error != null) ...[

                        const SizedBox(height: 12),

                        Text(

                          error!,

                          style: const TextStyle(

                            fontSize: 12,

                            color: AppTheme.danger,

                          ),

                          textAlign: TextAlign.center,

                        ),

                      ],

                      const SizedBox(height: 20),

                      GestureDetector(

                        onTap: () {

                          final name = nameCtrl.text.trim();

                          final phone = phoneCtrl.text.trim();

                          final relation = relationCtrl.text.trim();



                          if (name.isEmpty ||

                              phone.isEmpty ||

                              relation.isEmpty) {

                            setModalState(() =>

                            error = 'Please fill all fields');

                            return;

                          }

                          if (phone.length != 10) {

                            setModalState(() => error =

                            'Phone must be exactly 10 digits');

                            return;

                          }



                          ctx.read<AppProvider>().addEmergencyContact(

                            EmergencyContact(

                              name: name,

                              phone: phone,

                              relation: relation,

                            ),

                          );

                          Navigator.pop(ctx);

                        },

                        child: Container(

                          height: 48,

                          decoration: BoxDecoration(

                            borderRadius: BorderRadius.circular(14),

                            color: AppTheme.accent,

                          ),

                          child: const Center(

                            child: Text(

                              'Add Contact',

                              style: TextStyle(

                                fontSize: 15,

                                fontWeight: FontWeight.w700,

                                color: Colors.white,

                              ),

                            ),

                          ),

                        ),

                      ),

                    ],
                  ),),

            );

          },

        );

      },

    );

  }



  void _showDeviceSetup(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DeviceSetupSheet(
          isConfigured: provider.deviceConfigured,
          deviceId: provider.currentUser?.deviceId,
          onConfigured: (deviceId) {
            provider.configureDevice(deviceId);
            Navigator.pop(ctx);
          },
          onDisconnect: () {
            provider.disconnectDevice();
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  Widget _buildStatusTile({
    required String title,
    required bool isOk,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isOk ? AppTheme.accent : AppTheme.dangerSoft,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isOk)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerSoft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppTheme.dangerSoft.withAlpha(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                actionText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else
            const Text(
              'Active',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

}



class _DeviceSetupSheet extends StatefulWidget {

  final bool isConfigured;
  final String? deviceId;
  final Function(String) onConfigured;
  final VoidCallback onDisconnect;

  const _DeviceSetupSheet({
    required this.isConfigured,
    this.deviceId,
    required this.onConfigured,
    required this.onDisconnect,
  });



  @override

  State<_DeviceSetupSheet> createState() => _DeviceSetupSheetState();

}



class _DeviceSetupSheetState extends State<_DeviceSetupSheet>
    with SingleTickerProviderStateMixin {
  bool _syncing = false;
  double _progress = 0;
  late AnimationController _progressCtrl;
  final _deviceIdCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressCtrl.addListener(() {
      setState(() => _progress = _progressCtrl.value);
    });
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onConfigured(_deviceIdCtrl.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  void _startSync() {
    if (_deviceIdCtrl.text.trim().length < 4) {
      setState(() => _error = 'Invalid Device ID');
      return;
    }
    setState(() {
      _error = null;
      _syncing = true;
    });
    FocusScope.of(context).unfocus();
    _progressCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: EdgeInsets.fromLTRB(
               24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom + 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: SingleChildScrollView( child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isConfigured 
                      ? AppTheme.success.withAlpha(20)
                      : AppTheme.accentCyan.withAlpha(20),
                ),
                child: Icon(
                  _syncing
                      ? Icons.sync_rounded
                      : widget.isConfigured
                      ? Icons.check_circle_rounded
                      : Icons.wifi_rounded,
                  color: widget.isConfigured ? AppTheme.success : AppTheme.accentCyan,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _syncing
                    ? 'Syncing Device...'
                    : widget.isConfigured
                    ? 'Device Connected'
                    : 'Device Setup',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _syncing
                    ? 'Configuring your safety device'
                    : widget.isConfigured
                    ? 'Device ID: ${widget.deviceId}'
                    : 'Enter your Protega Device ID',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (_syncing) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withAlpha(15),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentCyan,
                  ),
                ),
              ] else if (!widget.isConfigured) ...[
                TextField(
                  controller: _deviceIdCtrl,
                  style: TextStyle( fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Device ID (e.g., PRO-1234)',
                    prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _startSync,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.accentCyan,
                    ),
                    child: const Center(
                      child: Text(
                        'Connect & Sync',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: widget.onDisconnect,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.danger.withAlpha(20),
                      border: Border.all(color: AppTheme.danger.withAlpha(50)),
                    ),
                    child: const Center(
                      child: Text(
                        'Disconnect Device',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
    ),);
  }
}