
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:provider/provider.dart';

import '../models/models.dart';

import '../providers/app_provider.dart';

import '../theme/theme.dart';

import '../widgets/animated_background.dart';

import '../widgets/bottom_nav.dart';

import 'patient_dashboard.dart';

import 'guardian_dashboard.dart';

import 'social_screen.dart';

import 'settings_screen.dart';

import 'package:permission_handler/permission_handler.dart';

import 'permissions_setup_screen.dart';

import 'history_screen.dart';



class HomeShell extends StatefulWidget {

  const HomeShell({super.key});



  @override

  State<HomeShell> createState() => _HomeShellState();

}



class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {

  int _currentTab = 0;

  bool _showNotifications = false;

  // --- SOS Gesture Detection State ---
  final List<DateTime> _tapTimestamps = [];
  final List<DateTime> _volumeTimestamps = [];
  static const _gestureWindow = Duration(milliseconds: 800);
  static const _requiredTaps = 3;

  static const MethodChannel _gestureChannel = MethodChannel('com.example.protega/gesture');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    
    // Listen for background gesture triggers from native Android
    _gestureChannel.setMethodCallHandler((call) async {
      if (call.method == 'triggerSOS') {
        final provider = Provider.of<AppProvider>(context, listen: false);
        if (!provider.isSOSActive && provider.sosGesture == 'volume_key') {
          debugPrint('Background MethodChannel SOS Trigger Received!');
          FlutterBackgroundService().invoke("triggerAlarm");
          provider.triggerSOS();
        }
      }
    });

    // Check permissions on first load
    _recheckPermissions();
  }

  @override
  void dispose() {
    _gestureChannel.setMethodCallHandler(null);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check when user comes back from system settings
      _recheckPermissions();
    }
  }

  Future<void> _recheckPermissions() async {
    final missing = await PermissionChecker.getMissingPermissions();
    if (missing.isNotEmpty && mounted) {
      // Show a snackbar prompting user to re-enable
      for (final p in missing) {
        String label = '';
        if (p == Permission.locationWhenInUse) label = 'Location';
        if (p == Permission.phone) label = 'Phone Calls';
        if (label.isEmpty) continue;

        final result = await p.request();
        if (!result.isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label permission is required for full functionality.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
              backgroundColor: const Color(0xFF1A1E2E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          break; // Only show one snackbar at a time
        }
      }
    }
  }

  // --- Gesture: Triple-Tap Detection ---
  void _handleTripleTap(AppProvider provider) {
    if (provider.sosGesture != 'triple_tap') return;
    if (provider.sosActive) return;

    final now = DateTime.now();
    _tapTimestamps.add(now);
    // Remove timestamps older than the window
    _tapTimestamps.removeWhere((t) => now.difference(t) > _gestureWindow);

    if (_tapTimestamps.length >= _requiredTaps) {
      _tapTimestamps.clear();
      HapticFeedback.heavyImpact();
      provider.triggerSOS();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('\u{1F6A8} SOS triggered via gesture!'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Gesture: Volume Key Combo Detection ---
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final provider = context.read<AppProvider>();
    if (provider.sosGesture != 'volume_key') return false;
    if (provider.sosActive) return false;

    // Check for Volume Up key
    if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
      final now = DateTime.now();
      _volumeTimestamps.add(now);
      _volumeTimestamps.removeWhere((t) => now.difference(t) > _gestureWindow);

      if (_volumeTimestamps.length >= _requiredTaps) {
        _volumeTimestamps.clear();
        HapticFeedback.heavyImpact();
        provider.triggerSOS();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('\u{1F6A8} SOS triggered via volume key!'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return true; // Consume the event
      }
    }
    return false;
  }



  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({UserRole role, bool sosActive})>(
      selector: (_, provider) => (
        role: provider.currentUser?.role ?? UserRole.patient,
        sosActive: provider.sosActive,
      ),
      builder: (context, data, _) {
        final isGuardian = data.role == UserRole.guardian;

        return GestureDetector(
          onTap: () => _handleTripleTap(context.read<AppProvider>()),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(

          body: AnimatedBackground(
            isAlert: data.sosActive,

            child: SafeArea(

              bottom: false,

              child: Stack(

                children: [

                  Column(

                    children: [

                      _buildHeader(),

                      Expanded(

                        child: AnimatedSwitcher(

                          duration: const Duration(milliseconds: 300),

                          transitionBuilder: (child, anim) {

                            return FadeTransition(

                              opacity: anim,

                              child: child,

                            );

                          },

                          child: _buildTab(isGuardian),

                        ),

                      ),

                    ],

                  ),

                  Positioned(

                    bottom: 0,

                    left: 0,

                    right: 0,

                    child: SafeArea(

                      child: GlassBottomNav(

                        currentIndex: _currentTab,

                        onTap: (i) => setState(() {

                          _currentTab = i;

                          _showNotifications = false;

                        }),

                        role: data.role,

                      ),

                    ),

                  ),

                  if (_showNotifications)

                    Positioned.fill(

                      child: GestureDetector(

                        onTap: () =>

                            setState(() => _showNotifications = false),

                        child: Container(color: Colors.black26),

                      ),

                    ),

                  if (_showNotifications)

                    Positioned(

                      top: 56,

                      right: 12,

                      child: _buildNotificationPanel(context.watch<AppProvider>()),

                    ),

                ],

              ),

            ),

          ),

        ),);
      },
    );

  }



  Widget _buildHeader() {

    return Container(

      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),

      child: Row(

        children: [

          Container(

            width: 34,

            height: 34,

            decoration: const BoxDecoration(

              shape: BoxShape.circle,

              color: AppTheme.accent,

            ),

            child: const Icon(

              Icons.shield_rounded,

              color: Colors.white,

              size: 18,

            ),

          ),

          const SizedBox(width: 10),

          Text(

            'PROTEGA',

            style: const TextStyle(

              fontSize: 16,

              fontWeight: FontWeight.w800,

              letterSpacing: 3,

              color: AppTheme.accent,

            ),

          ),

          const Spacer(),

          GestureDetector(

            onTap: () {

              HapticFeedback.selectionClick();

              setState(

                      () => _showNotifications = !_showNotifications);

              if (_showNotifications) {
                context.read<AppProvider>().markNotificationsRead();
              }

            },

            child: Stack(

              children: [

                Container(

                  width: 38,

                  height: 38,

                  decoration: BoxDecoration(

                    color: Colors.white.withAlpha(8),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),

                  child: Icon(

                    Icons.notifications_rounded,

                    size: 20,

                  ),

                ),

                Selector<AppProvider, bool>(
                  selector: (_, p) => p.unreadNotifications.isNotEmpty || p.friendRequests.isNotEmpty,
                  builder: (context, hasUnread, _) {
                    if (hasUnread) {
                      return Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.danger,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

              ],

            ),

          ),

          const SizedBox(width: 8),

          GestureDetector(

            onTap: () {

              HapticFeedback.mediumImpact();
              context.read<AppProvider>().logout();

            },

            child: Container(

              width: 38,

              height: 38,

              decoration: BoxDecoration(

                color: Colors.white.withAlpha(8),

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: Colors.white.withAlpha(15)),

              ),

              child: Icon(

                Icons.logout_rounded,

                size: 18,

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildTab(bool isGuardian) {

    switch (_currentTab) {

      case 0:

        return isGuardian

            ? const GuardianDashboard(key: ValueKey('guardian'))

            : const PatientDashboard(key: ValueKey('patient'));

      case 1:

        return isGuardian

            ? const FamilyScreen(key: ValueKey('family'))

            : const HistoryScreen(key: ValueKey('history'));

      case 2:

        return const SocialScreen(key: ValueKey('social'));

      case 3:

        return const SettingsScreen(key: ValueKey('settings'));

      default:

        return const SizedBox.shrink();

    }

  }



  Widget _buildNotificationPanel(AppProvider provider) {

    return Container(

          width: 300,

          constraints: const BoxConstraints(maxHeight: 360),

          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Padding(

                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Container(

                      padding: const EdgeInsets.symmetric(

                          horizontal: 8, vertical: 3),

                      decoration: BoxDecoration(

                        color: AppTheme.accent.withAlpha(20),

                        borderRadius: BorderRadius.circular(8),

                      ),

                      child: Text(

                        '${provider.notifications.length + provider.friendRequests.length}',

                        style: TextStyle(

                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: AppTheme.accent,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

              Container(height: 1, color: Colors.white.withAlpha(8)),

              if (provider.friendRequests.isNotEmpty) ...[

                const Padding(

                  padding: EdgeInsets.fromLTRB(16, 10, 16, 4),

                  child: Text('Friend Requests', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),

                ),

                ListView.separated(

                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  padding: EdgeInsets.zero,

                  itemCount: provider.friendRequests.length,

                  separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withAlpha(5)),

                  itemBuilder: (context, i) => _buildFriendRequestTile(provider.friendRequests[i], provider),

                ),

                Container(height: 1, color: Colors.white.withAlpha(8)),

              ],

              if (provider.notifications.isEmpty && provider.friendRequests.isEmpty)

                const Padding(

                  padding: EdgeInsets.all(24),

                  child: Center(

                    child: Text(

                      'No notifications',

                      style: TextStyle(

                        

                        fontSize: 13,

                      ),

                    ),

                  ),

                )

              else if (provider.notifications.isNotEmpty)

                Flexible(

                  child: ListView.separated(

                    shrinkWrap: true,

                    padding: const EdgeInsets.symmetric(vertical: 4),

                    itemCount: provider.notifications.length,

                    separatorBuilder: (_, __) => Container(

                      height: 1,

                      margin:

                      const EdgeInsets.symmetric(horizontal: 16),

                      color: Colors.white.withAlpha(5),

                    ),

                    itemBuilder: (context, i) {

                      final notif = provider.notifications[i];

                      return _notificationTile(notif);

                    },

                  ),

                ),

            ],

          ),

    )

        .animate()

        .fadeIn(duration: 250.ms)

        .slideY(begin: -0.05, end: 0)

        .scale(

      begin: const Offset(0.95, 0.95),

      end: const Offset(1.0, 1.0),

    );

  }



  Widget _buildFriendRequestTile(FriendModel req, AppProvider provider) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

      child: Row(

        children: [

          CircleAvatar(

            radius: 14,

            backgroundImage: NetworkImage(req.avatarUrl),

            backgroundColor: AppTheme.accentIndigo.withAlpha(50),

          ),

          SizedBox(width: 10),

          Expanded(

            child: Text(

              '${req.name} sent you a friend request',

              style: TextStyle(fontSize: 12),

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

            ),

          ),

          IconButton(

            icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(),

            onPressed: () => provider.acceptFriendRequest(req.id),

          ),

          const SizedBox(width: 12),

          IconButton(

            icon: const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 22),

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(),

            onPressed: () => provider.rejectFriendRequest(req.id),

          ),

        ],

      ),

    );

  }



  Widget _notificationTile(NotificationItem notif) {

    IconData icon;

    Color color;

    switch (notif.type) {

      case 'sos':

        icon = Icons.emergency_rounded;

        color = AppTheme.danger;

        break;

      case 'device':

        icon = Icons.wifi_rounded;

        color = AppTheme.accentCyan;

        break;

      default:

        icon = Icons.info_outline_rounded;

        color = AppTheme.accent;

    }



    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            padding: const EdgeInsets.all(6),

            decoration: BoxDecoration(

              color: color.withAlpha(20),

              borderRadius: BorderRadius.circular(8),

            ),

            child: Icon(icon, size: 14, color: color),

          ),

          SizedBox(width: 10),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  notif.title,

                  style: TextStyle(

                    fontSize: 12,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 2),

                Text(

                  notif.message,

                  style: TextStyle(

                    fontSize: 11,

                  ),

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}