import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/sos_button.dart';

// If GlassChip is in ../widgets/glass_chip.dart, keep this import.
// If not, use the class definition at the bottom of this file.
// import '../widgets/glass_chip.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  void _requestLocation() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      provider.fetchUserLocation();
    });
  }

  void _openMapsLink() async {
    final provider = context.read<AppProvider>();
    final lat = provider.userLat;
    final lng = provider.userLng;

    // userLat is double, checking != 0.0 is safer than null if it defaults to 0.0
    if (lat != 0.0 && lng != 0.0) {
      final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _handleSOSTrigger() {
    context.read<AppProvider>().triggerSOS();
  }

  void _handleCancelSOS() async {
    final provider = context.read<AppProvider>();
    try {
      await provider.cancelSOS();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SOS Alert cancelled successfully.', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildWelcomeHeader(user)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: -0.05, end: 0),
              const SizedBox(height: 16),
              _buildStatusHUD(provider)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: 24),
              Center(
                child: SOSButton(
                  onTrigger: _handleSOSTrigger,
                  isActive: provider.sosActive,
                  // onCancel removed as it was not defined in the widget
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
              ),
              if (provider.sosActive) ...[
                const SizedBox(height: 16),
                _buildSOSActiveCard(provider),
              ],
              const SizedBox(height: 24),
              _buildLocationCard(provider)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(UserModel user) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accent.withAlpha(80),
              width: 2,
            ),
            image: DecorationImage(
              image: NetworkImage(user.avatarUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GlassChip(
          label: user.displayRole,
          icon: Icons.person_rounded,
          color: AppTheme.accentIndigo,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildStatusHUD(AppProvider provider) {
    final isOnline = provider.isDeviceOnline;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statusItem(
            'Device',
            isOnline ? 'Online' : 'Offline',
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            isOnline ? AppTheme.success : Theme.of(context).textTheme.bodySmall!.color!,
          ),
          _divider(),
          _statusItem(
            'Battery',
            '--%',
            Icons.battery_unknown_rounded,
            Theme.of(context).textTheme.bodySmall!.color!,
          ),
          _divider(),
          _statusItem(
            'GPS',
            provider.userLat != 0.0 ? 'Active' : 'Off',
            Icons.gps_fixed_rounded,
            provider.userLat != 0.0 ? AppTheme.success : Theme.of(context).textTheme.bodySmall!.color!,
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(10),
    );
  }

  Widget _buildSOSActiveCard(AppProvider provider) {
    return GlassCard(
      border: Border.all(color: AppTheme.danger.withAlpha(100)),
      color: AppTheme.danger.withAlpha((255 * 0.08).round()),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_rounded,
                    color: AppTheme.danger, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 SOS TRIGGERED',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.danger,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Emergency alert sent to guardians',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Open Maps',
                  Icons.map_rounded,
                  AppTheme.accent,
                  _openMapsLink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  'Call 1122',
                  Icons.phone_rounded,
                  AppTheme.danger,
                      () async {
                    final uri = Uri.parse('tel:1122');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              'Cancel Alert',
              Icons.close_rounded,
              Theme.of(context).textTheme.bodyMedium!.color!,
              () => _handleCancelSOS(),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
      duration: 2000.ms,
      color: AppTheme.danger.withAlpha(30),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(AppProvider provider) {
    final lat = provider.userLat;
    final lng = provider.userLng;
    final isSOSActive = provider.sosActive;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PulsingDot(
                color: lat != 0.0 ? AppTheme.success : Theme.of(context).textTheme.bodySmall!.color!,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lat != 0.0 && lng != 0.0) ...[
            if (isSOSActive) ...[
              // SOS Active: Show full location details and map button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed_rounded,
                            size: 14, color: AppTheme.accentCyan),
                        const SizedBox(width: 6),
                        Text(
                          '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _openMapsLink,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accent.withAlpha(50),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded,
                                size: 14, color: AppTheme.accent),
                            SizedBox(width: 6),
                            Text(
                              'Open in Google Maps',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded,
                                size: 12, color: AppTheme.accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // SOS Inactive: Show secure monitoring message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.success.withAlpha(30),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded,
                        size: 16, color: AppTheme.success),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location monitoring active (Secure)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_disabled_rounded,
                      size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acquiring GPS signal...',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Helper Classes ---

class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isActive;

  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? effectiveColor.withAlpha(30)
            : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? effectiveColor.withAlpha(80)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isActive ? effectiveColor : Theme.of(context).textTheme.bodySmall!.color!,
            ),
            SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? effectiveColor : Theme.of(context).textTheme.bodySmall!.color!,
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Fixed: withOpacity deprecated -> withValues(alpha: ...)
            color: widget.color.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}