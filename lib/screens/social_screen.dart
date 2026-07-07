import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:provider/provider.dart';

import '../models/models.dart';

import '../providers/app_provider.dart';

import '../theme/theme.dart';

import '../widgets/glass_card.dart';

import 'chat_screen.dart';



class SocialScreen extends StatefulWidget {

  const SocialScreen({super.key});



  @override

  State<SocialScreen> createState() => _SocialScreenState();

}



class _SocialScreenState extends State<SocialScreen> {

  final _searchCtrl = TextEditingController();

  String _searchQuery = '';



  @override

  void dispose() {

    _searchCtrl.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Consumer<AppProvider>(

      builder: (context, provider, _) {

        final friends = provider.friends.where((f) {
          if (f.id == 'AI-ASSIST' || f.isAI) return false;
          if (_searchQuery.isEmpty) return true;
          return f.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
        }).toList();



        return Column(

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Social Hub',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _showAddFriendDialog,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.05),

                  const SizedBox(height: 4),

                  Text(

                    'Messages & Safety Network',

                    style: TextStyle(

                      fontSize: 13,

                    ),

                  ),

                  const SizedBox(height: 14),

                  TextField(

                    controller: _searchCtrl,

                    onChanged: (v) => setState(() => _searchQuery = v),

                    style: TextStyle(

                      

                      fontSize: 14,

                    ),

                    decoration: InputDecoration(

                      hintText: 'Search friends or AI assistant...',

                      prefixIcon: Icon(Icons.search_rounded, size: 20),

                      suffixIcon: _searchQuery.isNotEmpty

                          ? IconButton(

                        icon: Icon(Icons.close_rounded, size: 18),

                        onPressed: () {

                          _searchCtrl.clear();

                          setState(() => _searchQuery = '');

                        },

                      )

                          : null,

                    ),

                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                ],

              ),

            ),

            Expanded(

              child: ListView(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                children: [

                  // AI Assistant — always pinned at top
                  if (_searchQuery.isEmpty || 'protega ai'.contains(_searchQuery.toLowerCase()))
                    _buildAIAssistantTile(context),

                  if (_searchQuery.isEmpty || 'protega ai'.contains(_searchQuery.toLowerCase()))
                    const SizedBox(height: 8),

                  // Friends list
                  ...friends.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildFriendTile(context, e.value, e.key + 1),
                    );
                  }),

                  if (friends.isEmpty && !(_searchQuery.isEmpty || 'protega ai'.contains(_searchQuery.toLowerCase())))
                    Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48),
                            SizedBox(height: 12),
                            Text('No results found', style: TextStyle( fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

            ),

          ],

        );

      },

    );

  }



  Widget _buildAIAssistantTile(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ChatScreen(
              friendId: 'AI-ASSIST',
              friendName: 'Protega AI',
            ),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentIndigo, AppTheme.accentPurple],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protega AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Medical Safety Assistant • Always Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentIndigo,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentIndigo.withAlpha(40)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 12, color: AppTheme.accentIndigo),
                SizedBox(width: 4),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentIndigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _buildFriendTile(

      BuildContext context, FriendModel friend, int index) {

    return GlassCard(

      padding: const EdgeInsets.all(12),

      onTap: () {

        HapticFeedback.selectionClick();

        Navigator.of(context).push(

          PageRouteBuilder(

            pageBuilder: (_, __, ___) =>

                ChatScreen(friendId: friend.id, friendName: friend.name),

            transitionDuration: const Duration(milliseconds: 300),

            transitionsBuilder: (_, anim, __, child) {

              return SlideTransition(

                position: Tween<Offset>(

                  begin: const Offset(1, 0),

                  end: Offset.zero,

                ).animate(CurvedAnimation(

                  parent: anim,

                  curve: Curves.easeOutCubic,

                )),

                child: child,

              );

            },

          ),

        );

      },

      child: Row(

        children: [

          Stack(

            children: [

              Container(

                width: 48,

                height: 48,

                decoration: BoxDecoration(

                  shape: BoxShape.circle,

                  border: Border.all(

                    color: friend.isAI

                        ? AppTheme.accentIndigo.withAlpha(80)

                        : friend.isOnline

                        ? AppTheme.success.withAlpha(60)

                        : Colors.white.withAlpha(15),

                    width: 2,

                  ),

                  image: DecorationImage(

                    image: NetworkImage(friend.avatarUrl),

                    fit: BoxFit.cover,

                  ),

                ),

              ),

              if (friend.isAI)

                Positioned(

                  right: 0,

                  bottom: 0,

                  child: Container(

                    padding: const EdgeInsets.all(2),

                    decoration: BoxDecoration(

                      color: AppTheme.accentIndigo,

                      shape: BoxShape.circle,

                      border: Border.all(

                        color: Theme.of(context).scaffoldBackgroundColor,

                        width: 2,

                      ),

                    ),

                    child: Icon(

                      Icons.auto_awesome_rounded,

                      size: 8,

                      color: Colors.white,

                    ),

                  ),

                )

              else

                Positioned(

                  right: 0,

                  bottom: 0,

                  child: Container(

                    width: 12,

                    height: 12,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      color: friend.isOnline

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

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    Flexible(

                      child: Text(

                        friend.name,

                        style: TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.w600,

                        ),

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                      ),

                    ),

                    if (friend.isAI) ...[

                      const SizedBox(width: 6),

                      Container(

                        padding: const EdgeInsets.symmetric(

                            horizontal: 6, vertical: 2),

                        decoration: BoxDecoration(

                          color: AppTheme.accentIndigo.withAlpha(30),

                          borderRadius: BorderRadius.circular(6),

                        ),

                        child: const Text(

                          'AI',

                          style: TextStyle(

                            fontSize: 9,

                            fontWeight: FontWeight.w700,

                            color: AppTheme.accentIndigo,

                          ),

                        ),

                      ),

                    ],

                  ],

                ),

                if (friend.lastMessage != null) ...[

                  const SizedBox(height: 3),

                  Text(

                    friend.lastMessage!,

                    style: TextStyle(

                      fontSize: 12,

                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                  ),

                ],

              ],

            ),

          ),

          Icon(

            Icons.chevron_right_rounded,

            size: 20,

          ),

        ],

      ),

    )

        .animate()

        .fadeIn(

      delay: Duration(milliseconds: 200 + index * 60),

      duration: 500.ms,

    )

        .slideX(begin: 0.04, end: 0);
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Friend',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the unique User ID of your friend/patient.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. PID-123456',
                hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Add Friend', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              
              Navigator.pop(ctx); // Close dialog
              
              // Show loading snackbar or just wait
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: const Text('Searching for user...'),
                   duration: const Duration(seconds: 1),
                   backgroundColor: Theme.of(context).cardColor, 
                 ),
              );

              final provider = context.read<AppProvider>();
              final error = await provider.sendFriendRequest(id);
              
              if (mounted) {
                 if (error == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Friend request sent!'), backgroundColor: AppTheme.success),
                   );
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(error), backgroundColor: AppTheme.danger),
                   );
                 }
              }
            },
          ),
        ],
      ),
    );
  }
}