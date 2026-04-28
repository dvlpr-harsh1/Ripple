import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ added
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/const/theme/app_colors.dart';
import 'package:ripple/features/chat/domain/entities/message_entity.dart';
import 'package:ripple/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ripple/features/chat/presentation/bloc/chat_event.dart';
import 'package:ripple/features/chat/presentation/bloc/chat_state.dart';
import 'package:ripple/features/dashboard/domain/entities/known_user_entity.dart';
import 'package:ripple/shared/common_widgets/custom_loading_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHAT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final KnownUserEntity knownUser;
  const ChatPage({required this.knownUser, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final _msgController = TextEditingController();
  final _quickReplyController = TextEditingController(); // ✅ quick reply
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _quickReplyFocusNode = FocusNode(); // ✅
  bool _showAttachMenu = false;
  bool _isRecording = false;
  String? _replyingTo;
  late AnimationController _typingController;
  late AnimationController _recordController;
  late AnimationController _attachController;
  late String _myUid;
  late String _otherUid;
  late String _otherName; // ✅ store name for avatar
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _otherUid = widget.knownUser.id;
    _otherName = widget.knownUser.name; // ✅

    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(ChatInitialized(myUid: _myUid, otherUid: _otherUid));

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _recordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _attachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _chatBloc.add(
          ChatTypingChanged(
            myUid: _myUid,
            otherUid: _otherUid,
            isTyping: false,
          ),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _chatBloc.add(
      ChatTypingChanged(myUid: _myUid, otherUid: _otherUid, isTyping: false),
    );
    _msgController.dispose();
    _quickReplyController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _quickReplyFocusNode.dispose();
    _typingController.dispose();
    _recordController.dispose();
    _attachController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleAttach() {
    setState(() => _showAttachMenu = !_showAttachMenu);
    _showAttachMenu ? _attachController.forward() : _attachController.reverse();
  }

  void _onSend() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _chatBloc.add(
      ChatMessageSent(myUid: _myUid, otherUid: _otherUid, text: text),
    );
    _chatBloc.add(
      ChatTypingChanged(myUid: _myUid, otherUid: _otherUid, isTyping: false),
    );
    setState(() {
      _msgController.clear();
      _replyingTo = null;
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gradientPurple.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gradientPink.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (prev, curr) =>
                      curr is ChatLoaded &&
                      (prev is! ChatLoaded ||
                          (prev as ChatLoaded).isOtherTyping !=
                              curr.isOtherTyping ||
                          (prev as ChatLoaded).isOtherOnline !=
                              curr.isOtherOnline),
                  builder: (context, state) {
                    final isTyping = state is ChatLoaded
                        ? state.isOtherTyping
                        : false;
                    final isOnline = state is ChatLoaded
                        ? state.isOtherOnline
                        : widget.knownUser.isOnline;
                    return _Header(
                      entity: widget.knownUser,
                      typingController: _typingController,
                      isTypingLive: isTyping,
                      isOnlineLive: isOnline,
                    );
                  },
                ),
                Expanded(
                  child: BlocConsumer<ChatBloc, ChatState>(
                    listener: (context, state) {
                      if (state is ChatLoaded) {
                        _chatBloc.add(
                          ChatMarkedAsRead(myUid: _myUid, otherUid: _otherUid),
                        );
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is ChatLoading) {
                        return Center(child: CustomLoadingWidget());
                      }
                      if (state is ChatError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is ChatLoaded) {
                        return GestureDetector(
                          onTap: () {
                            _focusNode.unfocus();
                            if (_showAttachMenu) _toggleAttach();
                          },
                          child: _MessageList(
                            messages: state.messages,
                            myUid: _myUid,
                            otherName: _otherName, // ✅ pass name
                            scrollController: _scrollController,
                            onReply: (text) =>
                                setState(() => _replyingTo = text),
                            onDelete: (messageId, forEveryone) {
                              _chatBloc.add(
                                ChatMessageDeleted(
                                  myUid: _myUid,
                                  otherUid: _otherUid,
                                  messageId: messageId,
                                  forEveryone: forEveryone,
                                ),
                              );
                            },
                            // ✅ Quick reply send callback
                            onQuickReply: (text) {
                              if (text.trim().isEmpty) return;
                              _chatBloc.add(
                                ChatMessageSent(
                                  myUid: _myUid,
                                  otherUid: _otherUid,
                                  text: text,
                                ),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                if (_replyingTo != null)
                  _ReplyBar(
                    text: _replyingTo!,
                    onDismiss: () => setState(() => _replyingTo = null),
                  ),
                AnimatedBuilder(
                  animation: _attachController,
                  builder: (_, __) {
                    if (_attachController.value == 0) return const SizedBox();
                    return SizeTransition(
                      sizeFactor: _attachController,
                      child: const _AttachMenu(),
                    );
                  },
                ),
                _InputBar(
                  controller: _msgController,
                  focusNode: _focusNode,
                  isRecording: _isRecording,
                  recordController: _recordController,
                  showAttachMenu: _showAttachMenu,
                  onAttachTap: _toggleAttach,
                  onSend: _onSend,
                  onTyping: (isTyping) {
                    _chatBloc.add(
                      ChatTypingChanged(
                        myUid: _myUid,
                        otherUid: _otherUid,
                        isTyping: isTyping,
                      ),
                    );
                  },
                  onRecordToggle: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isRecording = !_isRecording);
                  },
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final KnownUserEntity entity;
  final AnimationController typingController;
  final bool isTypingLive; // ✅
  final bool isOnlineLive; // ✅

  const _Header({
    required this.entity,
    required this.typingController,
    required this.isTypingLive,
    required this.isOnlineLive,
  });

  @override
  Widget build(BuildContext context) {
    // Replace entity.isTyping → isTypingLive
    // Replace entity.isOnline → isOnlineLive
    // Everything else stays the same

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      // ✅ Gradient ring only when online
                      gradient: isOnlineLive ? AppColors.igGradient : null,
                      color: isOnlineLive ? null : Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: CircleAvatar(
                        backgroundColor: AppColors.gradientPurple.withOpacity(
                          0.25,
                        ),
                        child: Text(
                          entity.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ✅ Online dot
                  // if (isOnlineLive)
                  //   Positioned(
                  //     bottom: 1,
                  //     right: 1,
                  //     child: Container(
                  //       width: 11,
                  //       height: 11,
                  //       decoration: BoxDecoration(
                  //         color: AppColors.online,
                  //         shape: BoxShape.circle,
                  //         border: Border.all(color: AppColors.black, width: 2),
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // ✅ Use live values
                    isTypingLive
                        ? _TypingStatus(controller: typingController)
                        : Text(
                            isOnlineLive ? 'Online now' : 'Last seen recently',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnlineLive
                                  ? AppColors.online
                                  : AppColors.textHint,
                            ),
                          ),
                  ],
                ),
              ),
              _HeaderAction(icon: Icons.phone_outlined, onTap: () {}),
              const SizedBox(width: 8),
              _HeaderAction(icon: CupertinoIcons.video_camera, onTap: () {}),
              const SizedBox(width: 8),
              _HeaderAction(
                icon: CupertinoIcons.ellipsis_vertical,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 17),
      ),
    );
  }
}

class _TypingStatus extends StatelessWidget {
  final AnimationController controller;
  const _TypingStatus({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.igGradient.createShader(b),
          child: const Text(
            'typing',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final offset = (controller.value - i * 0.15).clamp(0.0, 1.0);
              final opacity = (sin(offset * pi)).clamp(0.2, 1.0);
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.gradientPink,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE LIST — ✅ now uses MessageEntity + myUid + onDelete
// ─────────────────────────────────────────────────────────────────────────────
class _MessageList extends StatefulWidget {
  // ✅ StatefulWidget now
  final List<MessageEntity> messages;
  final String myUid;
  final String otherName;
  final ScrollController scrollController;
  final Function(String) onReply;
  final Function(String messageId, bool forEveryone) onDelete;
  final Function(String text) onQuickReply;

  const _MessageList({
    required this.messages,
    required this.myUid,
    required this.otherName,
    required this.scrollController,
    required this.onReply,
    required this.onDelete,
    required this.onQuickReply,
  });

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  // ✅ Only one message ID can be "active" at a time — null = none open
  String? _activeMessageId;

  void _setActive(String? id) {
    if (_activeMessageId != id) {
      setState(() => _activeMessageId = id);
    }
  }

  bool _showDateSeparator(int i) {
    if (i == 0) return true;
    final a = widget.messages[i - 1].timestamp;
    final b = widget.messages[i].timestamp;
    return a.day != b.day;
  }

  bool _isGrouped(int i) {
    if (i == 0) return false;
    final prev = widget.messages[i - 1];
    final curr = widget.messages[i];
    return prev.isMine(widget.myUid) == curr.isMine(widget.myUid) &&
        curr.timestamp.difference(prev.timestamp).inMinutes < 3;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nSay hello! 👋',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textHint, fontSize: 14),
        ),
      );
    }

    return GestureDetector(
      // ✅ Tap anywhere on the list → close active bar
      onTap: () => _setActive(null),
      behavior: HitTestBehavior.translucent,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.messages.length,
        itemBuilder: (context, i) {
          final msg = widget.messages[i];
          final grouped = _isGrouped(i);
          return Column(
            children: [
              if (_showDateSeparator(i)) _DateSeparator(date: msg.timestamp),
              _MessageBubble(
                msg: msg,
                myUid: widget.myUid,
                otherName: widget.otherName,
                grouped: grouped,
                // ✅ Bubble knows if IT is the active one
                isActionsVisible: _activeMessageId == msg.id,
                // ✅ Bubble tells list which ID to activate
                onActionsToggle: (id) =>
                    _setActive(_activeMessageId == id ? null : id),
                onReply: () => widget.onReply(msg.text),
                onDelete: widget.onDelete,
                onQuickReply: widget.onQuickReply,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return 'Today';
    if (date.day == now.day - 1 && date.month == now.month) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              _label(),
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;

  const _ReplyBar({required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientPurple, AppColors.gradientPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.igGradient.createShader(b),
                  child: const Text(
                    'Replying to',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachMenu extends StatelessWidget {
  const _AttachMenu();

  @override
  Widget build(BuildContext context) {
    final items = [
      (CupertinoIcons.photo_on_rectangle, 'Gallery', const Color(0xFF9C27B0)),
      (CupertinoIcons.camera, 'Camera', const Color(0xFFE91E63)),
      (CupertinoIcons.doc, 'File', const Color(0xFF2196F3)),
      (Icons.location_on_outlined, 'Location', const Color(0xFF4CAF50)),
      (CupertinoIcons.music_note, 'Audio', const Color(0xFFFF9800)),
      (Icons.gif_box_outlined, 'GIF', const Color(0xFF00BCD4)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return GestureDetector(
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.$3.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: item.$3.withOpacity(0.3)),
                  ),
                  child: Icon(item.$1, color: item.$3, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isRecording;
  final bool showAttachMenu;
  final AnimationController recordController;
  final VoidCallback onAttachTap;
  final VoidCallback onSend;
  final VoidCallback onRecordToggle;
  final Function(bool) onTyping;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isRecording,
    required this.recordController,
    required this.showAttachMenu,
    required this.onAttachTap,
    required this.onSend,
    required this.onRecordToggle,
    required this.onTyping,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: widget.isRecording
          ? _RecordingBar(
              controller: widget.recordController,
              onCancel: widget.onRecordToggle,
              onSend: widget.onRecordToggle,
            )
          : Row(
              children: [
                AnimatedRotation(
                  turns: widget.showAttachMenu ? 0.125 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: _CircleBtn(
                    icon: Icons.add_rounded,
                    onTap: widget.onAttachTap,
                    gradient: widget.showAttachMenu
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientPurple,
                              AppColors.gradientPink,
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            maxLines: null,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            onChanged: (text) {
                              widget.onTyping(text.trim().isNotEmpty);
                            },
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Message...',
                              hintStyle: TextStyle(
                                // color: AppColors.textHint,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 1),
                            child: Icon(
                              CupertinoIcons.smiley,
                              color: AppColors.textHint,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: _hasText
                      ? _SendBtn(
                          key: const ValueKey('send'),
                          onTap: widget.onSend,
                        )
                      : _CircleBtn(
                          key: const ValueKey('mic'),
                          icon: CupertinoIcons.mic,
                          onTap: widget.onRecordToggle,
                        ),
                ),
              ],
            ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final LinearGradient? gradient;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: gradient == null ? AppColors.inputFill : null,
          border: Border.all(
            color: gradient != null
                ? Colors.transparent
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SendBtn({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.gradientPurple, AppColors.gradientPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x55833AB4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _RecordingBar({
    required this.controller,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(
                        0.4 + controller.value * 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) => AppColors.igGradient.createShader(b),
                  child: const Text(
                    'Recording...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.gradientPurple, AppColors.gradientPink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55833AB4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE — ✅ uses MessageEntity
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final MessageEntity msg;
  final String myUid;
  final String otherName;
  final bool grouped;
  final bool isActionsVisible;
  final Function(String id) onActionsToggle; 
  final VoidCallback onReply;
  final Function(String messageId, bool forEveryone) onDelete;
  final Function(String text) onQuickReply;

  const _MessageBubble({
    required this.msg,
    required this.myUid,
    required this.otherName,
    required this.grouped,
    required this.isActionsVisible,
    required this.onActionsToggle,
    required this.onReply,
    required this.onDelete,
    required this.onQuickReply,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<double> _enterAnim;

  bool _showQuickReply = false;
  final _quickReplyController = TextEditingController();
  final _quickReplyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _enterAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutBack,
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _quickReplyController.dispose();
    _quickReplyFocus.dispose();
    super.dispose();
  }

  // ✅ When parent closes this bubble's actions, also close quick reply
  @override
  void didUpdateWidget(_MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActionsVisible && _showQuickReply) {
      setState(() => _showQuickReply = false);
      _quickReplyFocus.unfocus();
    }
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _sendQuickReply() {
    final text = _quickReplyController.text.trim();
    if (text.isEmpty) return;
    widget.onQuickReply(text);
    _quickReplyController.clear();
    _quickReplyFocus.unfocus();
    setState(() => _showQuickReply = false);
    // ✅ Close action bar after sending
    widget.onActionsToggle(widget.msg.id);
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final isMine = msg.isMine(widget.myUid);
    final topPadding = widget.grouped ? 2.0 : 10.0;
    final avatarInitial = widget.otherName.isNotEmpty
        ? widget.otherName[0].toUpperCase()
        : '?';

    return ScaleTransition(
      scale: _enterAnim,
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          // ✅ Tell parent to toggle THIS message — parent closes others
          widget.onActionsToggle(msg.id);
        },
        onDoubleTap: widget.onReply,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // ✅ Actions bar — driven by isActionsVisible from parent
              if (widget.isActionsVisible)
                _QuickActions(
                  onReply: () {
                    widget.onReply();
                    // Close after tapping reply
                    widget.onActionsToggle(msg.id);
                  },
                  onQuickReply: () {
                    setState(() => _showQuickReply = !_showQuickReply);
                    if (_showQuickReply) {
                      Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _quickReplyFocus.requestFocus(),
                      );
                    } else {
                      _quickReplyFocus.unfocus();
                    }
                  },
                  onDelete: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surface,
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMine)
                            ListTile(
                              leading: const Icon(
                                Icons.delete_forever,
                                color: AppColors.error,
                              ),
                              title: const Text(
                                'Delete for everyone',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onDelete(msg.id, true);
                              },
                            ),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_outline,
                              color: AppColors.textHint,
                            ),
                            title: const Text(
                              'Delete for me',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onDelete(msg.id, false);
                            },
                          ),
                        ],
                      ),
                    );
                    // Close bar when delete sheet opens
                    widget.onActionsToggle(msg.id);
                  },
                ),

              Row(
                mainAxisAlignment: isMine
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMine && !widget.grouped) ...[
                    _MiniAvatar(initial: avatarInitial),
                    const SizedBox(width: 8),
                  ] else if (!isMine) ...[
                    const SizedBox(width: 32 + 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        _BubbleContent(msg: msg, isMine: isMine),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.timestamp),
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              _StatusIcon(isRead: msg.isRead),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Quick reply inline field
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _showQuickReply
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(22),
                                  // border: Border.all(
                                  //   color: AppColors.gradientPurple.withOpacity(
                                  //     0.4,
                                  //   ),
                                  // ),
                                ),
                                child: TextField(
                                  controller: _quickReplyController,
                                  focusNode: _quickReplyFocus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration.collapsed(
                                    hintText:
                                        'Reply to "${msg.text.length > 20 ? '${msg.text.substring(0, 20)}...' : msg.text}"',
                                    hintStyle: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendQuickReply(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendQuickReply,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gradientPurple,
                                      AppColors.gradientPink,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                _quickReplyFocus.unfocus();
                                setState(() => _showQuickReply = false);
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.inputFill,
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textHint,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String initial;
  const _MiniAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.gradientPurple.withOpacity(0.6),
            AppColors.gradientPink.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE CONTENT — ✅ uses MessageEntity + isMine
// ─────────────────────────────────────────────────────────────────────────────
class _BubbleContent extends StatelessWidget {
  final MessageEntity msg;
  final bool isMine;
  const _BubbleContent({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    if (msg.isDeleted) return _DeletedBubble(isMine: isMine);
    // text is only type for now — extend when you add image/voice support
    return _TextBubble(text: msg.text, isMine: isMine);
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  const _TextBubble({required this.text, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMine
            ? const LinearGradient(
                colors: [Color(0xFF9B2FD6), Color(0xFFD6306C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMine ? null : AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        border: isMine
            ? null
            : Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: isMine
            ? [
                BoxShadow(
                  color: AppColors.gradientPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isMine ? Colors.white : AppColors.textSecondary,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isMine;
  const _DeletedBubble({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.delete, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          const Text(
            'This message was deleted',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS ICON — ✅ now uses bool isRead instead of _MsgStatus enum
// ─────────────────────────────────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final bool isRead;
  const _StatusIcon({required this.isRead});

  @override
  Widget build(BuildContext context) {
    if (isRead) {
      return ShaderMask(
        shaderCallback: (b) => AppColors.igGradient.createShader(b),
        child: const Icon(Icons.done_all, size: 13, color: Colors.white),
      );
    }
    return const Icon(Icons.done_all, size: 13, color: AppColors.textHint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS — ✅ onDelete added
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onReply;
  final VoidCallback onQuickReply; // ✅
  final VoidCallback onDelete;

  const _QuickActions({
    required this.onReply,
    required this.onQuickReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientPurple.withOpacity(0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in ['❤️', '😂', '😮', '😢', '👍', '🙏'])
            GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white10,
          ),
          _ActionBtn(icon: Icons.reply_rounded, onTap: onReply),
          // ✅ Quick reply button — opens inline field
          _ActionBtn(icon: Icons.quickreply_rounded, onTap: onQuickReply),
          _ActionBtn(icon: Icons.copy_rounded, onTap: () {}),
          _ActionBtn(icon: CupertinoIcons.delete, onTap: onDelete),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}
