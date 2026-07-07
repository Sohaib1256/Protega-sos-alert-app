import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../theme/theme.dart';

import '../widgets/glass_card.dart';
import '../widgets/glass_chip.dart';
import '../models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {

  const HistoryScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Consumer<AppProvider>(

      builder: (context, provider, _) {

        final history = provider.alertHistory;



        return Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'Alert History',

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight: FontWeight.w700,

                    ),

                  )

                      .animate()

                      .fadeIn(duration: 500.ms)

                      .slideX(begin: -0.05),

                  const SizedBox(height: 4),

                  Text(

                    '${history.length} past alerts',

                    style: TextStyle(

                      fontSize: 13,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 12),

            Expanded(

              child: history.isEmpty

                  ? Center(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Icon(Icons.shield_rounded,

                        size: 56,

                        color: AppTheme.success.withAlpha(80)),

                    const SizedBox(height: 14),

                    Text(

                      'All Clear!',

                      style: TextStyle(

                        fontSize: 18,

                        fontWeight: FontWeight.w700,

                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      'No past alerts recorded',

                      style: TextStyle(

                        fontSize: 13,

                      ),

                    ),

                  ],

                )

                    .animate()

                    .fadeIn(duration: 600.ms)

                    .scale(

                  begin: const Offset(0.9, 0.9),

                  end: const Offset(1.0, 1.0),

                ),

              )

                  : ListView.separated(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                itemCount: history.length,

                separatorBuilder: (_, __) =>

                const SizedBox(height: 10),

                itemBuilder: (context, i) {

                  final alert = history[i];

                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => _showAlertLocation(context, alert),
                    child: Row(

                      children: [

                        Container(

                          width: 42,

                          height: 42,

                          decoration: BoxDecoration(

                            color: alert.type == 'SOS'

                                ? AppTheme.danger.withAlpha(20)

                                : AppTheme.warning.withAlpha(20),

                            borderRadius:

                            BorderRadius.circular(12),

                          ),

                          child: Icon(

                            alert.type == 'SOS'

                                ? Icons.emergency_rounded

                                : Icons

                                .accessibility_new_rounded,

                            color: alert.type == 'SOS'

                                ? AppTheme.danger

                                : AppTheme.warning,

                            size: 20,

                          ),

                        ),

                        SizedBox(width: 12),

                        Expanded(

                          child: Column(

                            crossAxisAlignment:

                            CrossAxisAlignment.start,

                            children: [

                              Row(

                                children: [

                                  GlassChip(

                                    label: alert.type,

                                    color: alert.type == 'SOS'

                                        ? AppTheme.danger

                                        : AppTheme.warning,

                                    isActive: true,

                                  ),

                                  const SizedBox(width: 8),

                                  Flexible(

                                    child: Text(

                                      alert.userName,

                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),

                                      maxLines: 1,

                                      overflow:

                                      TextOverflow.ellipsis,

                                    ),

                                  ),

                                ],

                              ),

                              const SizedBox(height: 4),

                              if (alert.note != null)

                                Text(

                                  alert.note!,

                                  style: TextStyle(

                                    fontSize: 11,

                                  ),

                                  maxLines: 2,

                                  overflow:

                                  TextOverflow.ellipsis,

                                ),

                            ],

                          ),

                        ),

                        const SizedBox(width: 8),

                        Text(

                          alert.timeAgo,

                          style: TextStyle(

                            fontSize: 10,

                            fontWeight: FontWeight.w500,

                          ),

                        ),

                      ],

                    ),

                  )

                      .animate()

                      .fadeIn(

                    delay: Duration(

                        milliseconds: 100 + i * 80),

                    duration: 500.ms,

                  )

                      .slideX(begin: 0.04);

                },

              ),

            ),

          ],

        );

      },
    );
  }

  void _showAlertLocation(BuildContext context, AlertModel alert) {
    if (alert.lat == null || alert.lng == null || (alert.lat == 0.0 && alert.lng == 0.0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location data not available for this alert.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${alert.type} Alert Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Triggered by ${alert.userName}',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Open in Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${alert.lat},${alert.lng}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}



class FamilyScreen extends StatelessWidget {

  const FamilyScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Consumer<AppProvider>(

      builder: (context, provider, _) {

        final patients = provider.monitoredPatients;



        return Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'Family Monitoring',

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight: FontWeight.w700,

                    ),

                  )

                      .animate()

                      .fadeIn(duration: 500.ms)

                      .slideX(begin: -0.05),

                  const SizedBox(height: 4),

                  Text(

                    '${patients.length} patients monitored',

                    style: TextStyle(

                      fontSize: 13,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 12),

            Expanded(

              child: patients.isEmpty

                  ? Center(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Icon(Icons.people_outline_rounded,

                        size: 56),

                    const SizedBox(height: 14),

                    Text(

                      'No patients yet',

                      style: TextStyle(

                        fontSize: 18,

                        fontWeight: FontWeight.w700,

                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      'Add patients from the dashboard',

                      style: TextStyle(

                        fontSize: 13,

                      ),

                    ),

                  ],

                ),

              )

                  : ListView.separated(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                itemCount: patients.length,

                separatorBuilder: (_, __) =>

                const SizedBox(height: 10),

                itemBuilder: (context, i) {

                  final patient = patients[i];

                  return GlassCard(

                    padding: const EdgeInsets.all(16),

                    child: Column(

                      children: [

                        Row(

                          children: [

                            Stack(

                              children: [

                                Container(

                                  width: 48,

                                  height: 48,

                                  decoration: BoxDecoration(

                                    shape: BoxShape.circle,

                                    image: DecorationImage(

                                      image: NetworkImage(

                                          patient.avatarUrl),

                                      fit: BoxFit.cover,

                                    ),

                                  ),

                                ),

                                Positioned(

                                  right: 0,

                                  bottom: 0,

                                  child: Container(

                                    width: 14,

                                    height: 14,

                                    decoration: BoxDecoration(

                                      shape: BoxShape.circle,

                                      color: patient.isOnline

                                          ? AppTheme.success

                                          : Theme.of(context).textTheme.bodySmall!.color!,

                                      border: Border.all(

                                        color: Theme.of(context).scaffoldBackgroundColor,

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

                                crossAxisAlignment:

                                CrossAxisAlignment.start,

                                children: [

                                  Text(

                                    patient.name,

                                    style: TextStyle(

                                      fontSize: 15,

                                      fontWeight: FontWeight.w600,

                                    ),

                                    maxLines: 1,

                                    overflow:

                                    TextOverflow.ellipsis,

                                  ),

                                  const SizedBox(height: 2),

                                  Text(

                                    'ID: ${patient.id}',

                                    style: TextStyle(

                                      fontSize: 11,

                                      fontFamily: 'monospace',

                                    ),

                                  ),

                                ],

                              ),

                            ),

                            Column(

                              crossAxisAlignment:

                              CrossAxisAlignment.end,

                              children: [



                                Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Icon(

                                      Icons.battery_std_rounded,

                                      size: 12,

                                      color:

                                      patient.batteryLevel >

                                          50

                                          ? AppTheme.success

                                          : AppTheme.warning,

                                    ),

                                    const SizedBox(width: 3),

                                    Text(

                                      '${patient.batteryLevel}%',

                                      style: const TextStyle(

                                        fontSize: 11,

                                        fontWeight:

                                        FontWeight.w600,

                                        color: AppTheme

                                            .textSecondary,

                                      ),

                                    ),

                                  ],

                                ),

                              ],

                            ),

                          ],

                        ),

                      ],

                    ),

                  )

                      .animate()

                      .fadeIn(

                    delay: Duration(

                        milliseconds: 150 + i * 80),

                    duration: 500.ms,

                  )

                      .slideX(begin: 0.04);

                },

              ),

            ),

          ],

        );

      },

    );

  }

}