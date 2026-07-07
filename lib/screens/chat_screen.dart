

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../theme/theme.dart';

import '../widgets/animated_background.dart';



class ChatScreen extends StatefulWidget {

  final String friendId;

  final String friendName;



  const ChatScreen({

    super.key,

    required this.friendId,

    required this.friendName,

  });



  @override

  State<ChatScreen> createState() => _ChatScreenState();

}



class _ChatScreenState extends State<ChatScreen> {

  final _msgCtrl = TextEditingController();

  final _scrollCtrl = ScrollController();

  bool _isTyping = false;



  @override

  void dispose() {

    _msgCtrl.dispose();

    _scrollCtrl.dispose();

    super.dispose();

  }



  void _sendMessage() {

    final text = _msgCtrl.text.trim();

    if (text.isEmpty) return;



    final provider = context.read<AppProvider>();

    // Fixed: Use named parameters and pass isAI flag

    provider.sendMessage(

      receiverId: widget.friendId,

      text: text,

      isAI: widget.friendId == 'AI-ASSIST', // Check if chatting with AI

    );

    _msgCtrl.clear();



    // Fixed: Use correct AI ID

    if (widget.friendId == 'AI-ASSIST') {

      setState(() => _isTyping = true);

      Future.delayed(const Duration(milliseconds: 1500), () {

        if (mounted) setState(() => _isTyping = false);

      });

    }



    _scrollToBottom();

  }



  void _scrollToBottom() {

    Future.delayed(const Duration(milliseconds: 200), () {

      if (_scrollCtrl.hasClients) {

        _scrollCtrl.animateTo(

          _scrollCtrl.position.maxScrollExtent + 80,

          duration: const Duration(milliseconds: 300),

          curve: Curves.easeOut,

        );

      }

    });

  }



  @override

  Widget build(BuildContext context) {

    final isAI = widget.friendId == 'AI-ASSIST';



    return Scaffold(

      body: AnimatedBackground(

        child: SafeArea(

          child: Column(

            children: [

              _buildHeader(isAI),

              Expanded(

                child: Consumer<AppProvider>(

                  builder: (context, provider, _) {

                    final messages =

                        provider.messages[widget.friendId] ?? [];



                    if (messages.isEmpty) {

                      return Center(

                        child: Column(

                          mainAxisSize: MainAxisSize.min,

                          children: [

                            Icon(

                              isAI

                                  ? Icons.auto_awesome_rounded

                                  : Icons.chat_bubble_outline_rounded,

                              size: 48,

                            ),

                            SizedBox(height: 12),

                            Text(

                              isAI

                                  ? 'Ask Protega AI anything about\nhealth & safety'

                                  : 'Start a conversation',

                              style: TextStyle(

                                

                                fontSize: 14,

                              ),

                              textAlign: TextAlign.center,

                            ),

                          ],

                        ),

                      );

                    }



                    return ListView.builder(

                      controller: _scrollCtrl,

                      padding: const EdgeInsets.symmetric(

                        horizontal: 16,

                        vertical: 12,

                      ),

                      itemCount: messages.length + (_isTyping ? 1 : 0),

                      itemBuilder: (context, i) {

                        if (i == messages.length && _isTyping) {

                          return _buildTypingIndicator();

                        }

                        final msg = messages[i];

                        final isMe =

                            msg.senderId != widget.friendId;

                        return _buildMessageBubble(msg.text, isMe, msg.isAI, i);

                      },

                    );

                  },

                ),

              ),

              _buildInputBar(),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildHeader(bool isAI) {

    return Container(

          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),

          decoration: BoxDecoration(

            color: Theme.of(context).cardColor,

            border: Border(

              bottom: BorderSide(color: Theme.of(context).dividerColor),

            ),

          ),

          child: Row(

            children: [

              IconButton(

                onPressed: () => Navigator.pop(context),

                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),

              ),

              Container(

                width: 36,

                height: 36,

                decoration: BoxDecoration(

                  shape: BoxShape.circle,

                  gradient: isAI

                      ? const LinearGradient(

                    colors: [

                      AppTheme.accentIndigo,

                      AppTheme.accentPurple

                    ],

                  )

                      : null,

                  color: isAI ? null : Theme.of(context).cardColor,

                  border: isAI

                      ? null

                      : Border.all(

                      color: Colors.white.withAlpha(15)),

                ),

                child: isAI

                    ? const Icon(Icons.auto_awesome_rounded,

                    color: Colors.white, size: 18)

                    : Center(

                  child: Text(

                    widget.friendName[0].toUpperCase(),

                    style: TextStyle(

                      

                      fontWeight: FontWeight.w700,

                    ),

                  ),

                ),

              ),

              const SizedBox(width: 10),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      widget.friendName,

                      style: TextStyle(

                        fontSize: 15,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    Text(

                      isAI

                          ? 'Medical Safety Assistant'

                          : 'Online',

                      style: TextStyle(

                        fontSize: 11,

                        color: isAI

                            ? AppTheme.accentIndigo

                            : AppTheme.success,

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                  ],

                ),

              ),

              if (isAI)

                Container(

                  padding: const EdgeInsets.symmetric(

                      horizontal: 8, vertical: 4),

                  decoration: BoxDecoration(

                    color: AppTheme.accentIndigo.withAlpha(20),

                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(

                      color: AppTheme.accentIndigo.withAlpha(40),

                    ),

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

    );

  }



  Widget _buildMessageBubble(

      String text, bool isMe, bool isAI, int index) {

    return Align(

      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(

        margin: const EdgeInsets.only(bottom: 10),

        constraints: BoxConstraints(

          maxWidth: MediaQuery.sizeOf(context).width * 0.78,

        ),

          child: Container(

              padding: const EdgeInsets.symmetric(

                  horizontal: 14, vertical: 10),

              decoration: BoxDecoration(

                color: isMe

                    ? AppTheme.accent.withAlpha(30)

                    : isAI

                    ? AppTheme.accentIndigo.withAlpha(20)

                    : Theme.of(context).cardColor,

                borderRadius: BorderRadius.only(

                  topLeft: const Radius.circular(18),

                  topRight: const Radius.circular(18),

                  bottomLeft: Radius.circular(isMe ? 18 : 4),

                  bottomRight: Radius.circular(isMe ? 4 : 18),

                ),

                border: Border.all(

                  color: isMe

                      ? AppTheme.accent.withAlpha(40)

                      : isAI

                      ? AppTheme.accentIndigo.withAlpha(30)

                      : Colors.white.withAlpha(10),

                ),

              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  if (isAI && !isMe) ...[

                   Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                         Icon(Icons.auto_awesome_rounded,

                            size: 10, color: AppTheme.accentIndigo),

                         SizedBox(width: 4),

                        Text(

                          'Protega AI',

                          style: TextStyle(

                            fontSize: 10,

                            fontWeight: FontWeight.w600,

                            color: AppTheme.accentIndigo,

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 4),

                  ],

                  Text(

                    text,

                    style: TextStyle(

                      fontSize: 13,

                      color: isMe

                          ? Theme.of(context).textTheme.bodyLarge!.color!

                          : Theme.of(context).textTheme.bodyLarge!.color!,

                      height: 1.4,

                    ),

                  ),

                ],

              ),

            ),

          ),

    )

        .animate()

        .fadeIn(duration: 300.ms)

        .slideY(begin: 0.1, end: 0);

  }



  Widget _buildTypingIndicator() {

    return Align(

      alignment: Alignment.centerLeft,

      child: Container(

        margin: const EdgeInsets.only(bottom: 10),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(

          color: AppTheme.accentIndigo.withAlpha(15),

          borderRadius: const BorderRadius.only(

            topLeft: Radius.circular(18),

            topRight: Radius.circular(18),

            bottomRight: Radius.circular(18),

            bottomLeft: Radius.circular(4),

          ),

          border: Border.all(

            color: AppTheme.accentIndigo.withAlpha(20),

          ),

        ),

        child: Row(

          mainAxisSize: MainAxisSize.min,

          children: List.generate(3, (i) {

            return Container(

              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),

              child: const _TypingDot(),

            )

                .animate(

                onPlay: (c) => c.repeat(reverse: true))

                .fadeIn(

              delay: Duration(milliseconds: i * 200),

              duration: 600.ms,

            )

                .slideY(

              begin: 0.3,

              delay: Duration(milliseconds: i * 200),

              duration: 600.ms,

            );

          }),

        ),

      ),

    ).animate().fadeIn(duration: 300.ms);

  }



  Widget _buildInputBar() {

    return Container(

      padding: EdgeInsets.fromLTRB(

        12,

        10,

        12,

        MediaQuery.paddingOf(context).bottom + 10,

      ),

      decoration: BoxDecoration(

        color: Colors.white.withAlpha(5),

        border: Border(

          top: BorderSide(color: Colors.white.withAlpha(10)),

        ),

      ),

      child: Row(

        children: [

          Expanded(

            child: Container(

              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
                cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                textAlignVertical: TextAlignVertical.center,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.friendId == 'AI-ASSIST'
                      ? 'Ask about health & safety...'
                      : 'Type a message...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

            ),

          ),

          const SizedBox(width: 8),

          GestureDetector(

            onTap: _sendMessage,

            child: Container(

              width: 44,

              height: 44,

              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(

                Icons.send_rounded,

                color: Colors.white,

                size: 20,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _TypingDot extends StatelessWidget {

  const _TypingDot();



  @override

  Widget build(BuildContext context) {

    return Container(

      width: 7,

      height: 7,

      decoration: BoxDecoration(

        shape: BoxShape.circle,

        color: AppTheme.accentIndigo.withAlpha(150),

      ),

    );

  }

}