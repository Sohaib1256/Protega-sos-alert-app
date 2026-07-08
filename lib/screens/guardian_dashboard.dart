
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import '../widgets/glass_card.dart';

class GuardianDashboard extends StatelessWidget {
  const GuardianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: -0.05),
              const SizedBox(height: 16),
              _buildStatsGrid(provider)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideY(begin: 0.05),
              if (provider.activeAlerts.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildActiveAlertBanner(context, provider.activeAlerts.first),
              ],
              const SizedBox(height: 20),
              _buildSectionTitle(
                'Monitored Patients',
                trailing: '${provider.monitoredPatients.length} Active',
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 10),
              ...provider.monitoredPatients.asMap().entries.map(
                    (entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildPatientCard(entry.value)
                        .animate()
                        .fadeIn(
                      delay: Duration(milliseconds: 250 + entry.key * 80),
                      duration: 500.ms,
                    )
                        .slideX(begin: 0.05),
                  );
                },
              ),
              const SizedBox(height: 14),
              _buildAddPatientButton(context)
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms),
              const SizedBox(height: 100),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel user) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentIndigo.withAlpha(80),
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
              const Text(
                'Guardian Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentIndigo,
                  fontWeight: FontWeight.w600,
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
        const GlassChip(
          label: 'Guardian',
          icon: Icons.shield_rounded,
          color: AppTheme.accentIndigo,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AppProvider provider) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.people_rounded,
              iconColor: AppTheme.accent,
              label: 'Monitored',
              value: '${provider.monitoredPatients.length}',
            ),
          ),
          SizedBox(width: 10),
          const Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              iconColor: AppTheme.success,
              label: 'System',
              value: 'Active',
              isPulsing: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.warning_rounded,
              iconColor: provider.activeAlerts.isNotEmpty
                  ? AppTheme.danger
                  : AppTheme.textMuted,
              label: 'Alerts',
              value: '${provider.activeAlerts.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertBanner(BuildContext context, AlertModel alert) {
    return GlassCard(
      border: Border.all(color: AppTheme.danger.withAlpha(120)),
      color: AppTheme.danger.withAlpha((255 * 0.1).round()),
      padding: const EdgeInsets.all(14),
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
                child: Icon(Icons.emergency_rounded,
                    color: AppTheme.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 ACTIVE ALERT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.danger,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${alert.userName} triggered SOS',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                alert.timeAgo,
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _alertActionBtn(
                  'Track Live',
                  Icons.location_on_rounded,
                  AppTheme.accent,
                      () {
                    if (alert.lat != null && alert.lng != null) {
                      launchUrl(
                        Uri.parse(
                            'https://www.google.com/maps?q=${alert.lat},${alert.lng}'),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _alertActionBtn(
                  'Call 911',
                  Icons.phone_rounded,
                  AppTheme.danger,
                      () => launchUrl(Uri.parse('tel:1122')),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
      duration: 2000.ms,
      color: AppTheme.danger.withAlpha(25),
    );
  }

  Widget _alertActionBtn(
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

  Widget _buildPatientCard(UserModel patient) {
    final isOnline = patient.isOnline;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(patient.avatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppTheme.success : AppTheme.textMuted,
                    border: Border.all(
                      color: AppTheme.bgDeep,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    GlassChip(
                      label: isOnline ? 'Online' : 'Offline',
                      color: isOnline ? AppTheme.success : AppTheme.textMuted,
                      isActive: isOnline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.person_remove_rounded, size: 20, color: Colors.white54),
              onPressed: () {
                showDialog(
                  context: ctx,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1F2C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Remove Patient', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to stop monitoring this patient?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          ctx.read<AppProvider>().removeConnection(patient.id);
                        },
                        child: const Text('Remove', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPatientButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddPatientModal(context),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              const Icon(Icons.add_rounded, color: AppTheme.accent, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add Patient to Monitor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  void _showAddPatientModal(BuildContext context) {
    final searchCtrl = TextEditingController();
    UserModel? found;
    String? searchError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.paddingOf(ctx).bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
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
                        'Add Patient',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Search by Patient ID (e.g., PID-A1B2C3)',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: searchCtrl,
                        style: TextStyle(
                          
                          fontSize: 14,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Enter Patient ID',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () async {
                          final provider = ctx.read<AppProvider>();
                          final result =
                          await provider.searchUserById(searchCtrl.text.trim());
                          setModalState(() {
                            found = result;
                            searchError =
                            result == null ? 'No user found with that ID' : null;
                          });
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppTheme.accent,
                          ),
                          child: Center(
                            child: Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (searchError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          searchError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (found != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.accent.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(found!.avatarUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      found!.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      found!.id,
                                      style: TextStyle(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ctx
                                      .read<AppProvider>()
                                      .addMonitoredPatient(found!.id);
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.accent.withAlpha(60),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accent,
                                    ),
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
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isPulsing;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 18),
              if (isPulsing) ...[
                SizedBox(width: 4),
                PulsingDot(color: iconColor, size: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// --- Missing Classes ---

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
            color: widget.color.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}