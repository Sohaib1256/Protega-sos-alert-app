import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import '../models/models.dart';

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserRole role;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getNavItems();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => _buildNavItem(
            items[index],
            index == currentIndex,
            () {
              HapticFeedback.selectionClick();
              onTap(index);
            },
          ),
        ),
      ),
    );
  }

  List<BottomNavItem> _getNavItems() {
    final isGuardian = role == UserRole.guardian;
    
    return [
      const BottomNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dash',
      ),
      BottomNavItem(
        icon: isGuardian ? Icons.people_outline_rounded : Icons.history_rounded,
        activeIcon: isGuardian ? Icons.people_rounded : Icons.history_edu_rounded,
        label: isGuardian ? 'Family' : 'History',
      ),
      const BottomNavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Social',
      ),
      const BottomNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',

      ),
    ];
  }

  Widget _buildNavItem(BottomNavItem item, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accent.withAlpha(20) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
                size: 22,
              ),
            ),
            SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
