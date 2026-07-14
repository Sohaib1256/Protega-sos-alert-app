import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../providers/hardware_provider.dart';
import '../providers/emergency_provider.dart';
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

  final List<({DateTime time, Offset position})> _taps = [];
  final List<DateTime> _volumeTimestamps = [];
  static const _gestureWindow = Duration(milliseconds: 800);
  static const _requiredTaps = 3;

  static const MethodChannel _gestureChannel = MethodChannel('com.example.protega/gesture');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    
    // Listen for SOS triggered from native side via background service
    FlutterBackgroundService().on('nativeSosFired').listen((event) {
      if (!mounted) return;
      final em = Provider.of<EmergencyProvider>(context, listen: false);
      if (!em.isSOSActive) {
        debugPrint('UI: SOS fired from native/background — updating state');
        em.triggerSOS();
      }
    });

    _gestureChannel.setMethodCallHandler((call) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final em = Provider.of<EmergencyProvider>(context, listen: false);
      final hw = Provider.of<HardwareProvider>(context, listen: false);
      
      if (auth.currentUser?.role == UserRole.guardian) return;
      
      if (call.method == 'triggerSOS') {
        if (!em.isSOSActive && hw.sosGesture == 'volume_key') {
          debugPrint('Background MethodChannel SOS Trigger Received!');
          FlutterBackgroundService().invoke("triggerAlarm");
          em.triggerSOS();
        }
      }
    });

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
      _recheckPermissions();
    }
  }

  Future<void> _recheckPermissions() async {
    final role = Provider.of<AuthProvider>(context, listen: false).currentUser?.role ?? UserRole.user;
    final missing = await PermissionChecker.getMissingPermissions(role);
    if (missing.isNotEmpty && mounted) {
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
          break;
        }
      }
    }
  }

  void _handleTripleTap(BuildContext context, TapDownDetails details) {
    final auth = context.read<AuthProvider>();
    final hw = context.read<HardwareProvider>();
    final em = context.read<EmergencyProvider>();

    if (auth.currentUser?.role == UserRole.guardian) return;
    if (hw.sosGesture != 'triple_tap') return;
    if (em.sosActive) return;

    final now = DateTime.now();
    final pos = details.globalPosition;

    if (_taps.isNotEmpty) {
      final lastTap = _taps.last;
      final timeDiff = now.difference(lastTap.time);
      final dist = (pos - lastTap.position).distance;

      // Spatial and Temporal Guard: must be within 300ms and 30 logical pixels
      if (timeDiff.inMilliseconds > 300 || dist > 30) {
        _taps.clear();
      }
    }

    _taps.add((time: now, position: pos));

    if (_taps.length >= _requiredTaps) {
      _taps.clear();
      HapticFeedback.heavyImpact();
      em.triggerSOS();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚨 SOS triggered via gesture!'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    final auth = context.read<AuthProvider>();
    final hw = context.read<HardwareProvider>();
    final em = context.read<EmergencyProvider>();

    if (auth.currentUser?.role == UserRole.guardian) return false;
    if (event is! KeyDownEvent) return false;

    if (hw.sosGesture != 'volume_key') return false;
    if (em.sosActive) return false;

    if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
      final now = DateTime.now();
      _volumeTimestamps.add(now);
      _volumeTimestamps.removeWhere((t) => now.difference(t) > _gestureWindow);

      if (_volumeTimestamps.length >= _requiredTaps) {
        _volumeTimestamps.clear();
        HapticFeedback.heavyImpact();
        em.triggerSOS();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🚨 SOS triggered via volume key!'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return true; 
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole>((p) => p.currentUser?.role ?? UserRole.user);
    final sosActive = context.select<EmergencyProvider, bool>((p) => p.sosActive);
    final isGuardian = role == UserRole.guardian;

    return GestureDetector(
      onTapDown: (details) => _handleTripleTap(context, details),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: AnimatedBackground(
          isAlert: sosActive,
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
                      role: role,
                    ),
                  ),
                ),
                if (_showNotifications)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showNotifications = false),
                      child: Container(color: Colors.black26),
                    ),
                  ),
                if (_showNotifications)
                  Positioned(
                    top: 56,
                    right: 12,
                    child: _buildNotificationPanel(context),
                  ),
              ],
            ),
          ),
        ),
      ),
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
              setState(() => _showNotifications = !_showNotifications);
              if (_showNotifications) {
                context.read<EmergencyProvider>().markNotificationsRead();
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
                Selector<EmergencyProvider, bool>(
                  selector: (_, p) => p.unreadNotifications.isNotEmpty,
                  builder: (context, hasUnreadNotif, _) {
                    final hasUnreadReq = context.select<SocialProvider, bool>((s) => s.friendRequests.isNotEmpty);
                    final hasUnread = hasUnreadNotif || hasUnreadReq;
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
              context.read<AuthProvider>().logout();
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

  Widget _buildNotificationPanel(BuildContext context) {
    final emProvider = context.watch<EmergencyProvider>();
    final socialProvider = context.watch<SocialProvider>();
    
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${emProvider.notifications.length + socialProvider.friendRequests.length}',
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
          if (socialProvider.friendRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text('Friend Requests', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: socialProvider.friendRequests.length,
              separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withAlpha(5)),
              itemBuilder: (context, i) => _buildFriendRequestTile(socialProvider.friendRequests[i], socialProvider),
            ),
            Container(height: 1, color: Colors.white.withAlpha(8)),
          ],
          if (emProvider.notifications.isEmpty && socialProvider.friendRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else if (emProvider.notifications.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: emProvider.notifications.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withAlpha(5),
                ),
                itemBuilder: (context, i) {
                  final notif = emProvider.notifications[i];
                  return _notificationTile(notif);
                },
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.05, end: 0).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }

  Widget _buildFriendRequestTile(FriendModel req, SocialProvider provider) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: notif.type == 'sos'
                  ? AppTheme.danger.withAlpha(20)
                  : AppTheme.accent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notif.type == 'sos'
                  ? Icons.warning_rounded
                  : Icons.notifications_active_rounded,
              size: 14,
              color: notif.type == 'sos' ? AppTheme.danger : AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                        color: notif.isRead ? Colors.white60 : Colors.white,
                      ),
                    ),
                    Text(
                      _formatTime(notif.time),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withAlpha(100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notif.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(notif.isRead ? 150 : 220),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.month}/${time.day}';
  }
}