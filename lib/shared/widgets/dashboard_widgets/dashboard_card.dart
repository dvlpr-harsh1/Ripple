import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../features/dashboard/domain/entities/known_user_entity.dart';
import '../../common_widgets/custom_loading_widget.dart';



// Instagram gradient — single source of truth
const _igGradient = LinearGradient(
  colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ChatCard extends StatelessWidget {
  final KnownUserEntity knownUserEntity;
  const ChatCard({required this.knownUserEntity, super.key});

  @override
  Widget build(BuildContext context) {
    final nameInitial = knownUserEntity.name.split('')[0].toUpperCase();
    final hasUnread = knownUserEntity.receivedMessagesCount > 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        // Unread = gradient border, read = subtle border
        // border: Border.all(
        //   color: hasUnread
        //       ? const Color(0xFF833AB4).withOpacity(0.7)
        //       : Colors.white.withOpacity(0.07),
        //   width: hasUnread ? 1.0 : 0.5,
        // ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar — gradient ring when online
          _Avatar(
            nameInitial: nameInitial,
            imgUrl: knownUserEntity.imgUrl,
            isOnline: knownUserEntity.isOnline,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + mood icon + time + badge
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              knownUserEntity.name,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                         
                        ],
                      ),
                    ),
                    Text(
                      knownUserEntity.receivedMessagesTime,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: _igGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          knownUserEntity.receivedMessagesCount.toString(),
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                // Typing / last message
                knownUserEntity.isTyping
                    ? Row(
                        children: [
                          CustomLoadingWidget(),
                          const SizedBox(width: 6),
                          ShaderMask(
                            shaderCallback: (b) => _igGradient.createShader(b),
                            child: Text(
                              'typing...',
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        knownUserEntity.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: hasUnread ? Colors.white70 : Colors.white38,
                        ),
                      ),

                // Actions
                Row(
                  children: [
                    knownUserEntity.isBlocked
                        ? _customButton(
                            context,
                            icon: CupertinoIcons.lock_open,
                            label: 'Unblock',
                            labelColor: const Color(0xFFEF5350),
                            angle: 0,
                            onTap: () {},
                          )
                        : _customButton(
                            context,
                            icon: Icons.send,
                            label: 'Quick Reply',
                            labelColor: Colors.white38,
                            angle: -0.8,
                            onTap: () {},
                          ),
                    IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.phone,
                        size: 20,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        CupertinoIcons.video_camera,
                        size: 20,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color labelColor,
    required double angle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      splashFactory: InkRipple.splashFactory,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
        child: Row(
          children: [
            Transform.rotate(
              angle: angle,
              child: knownUserEntity.isOnline
                  ? ShaderMask(
                      shaderCallback: (bounds) =>
                          _igGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Icon(icon, size: 14, color: Colors.white),
                    )
                  : Icon(icon, size: 14, color: labelColor),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted avatar widget — gradient ring when online
class _Avatar extends StatelessWidget {
  final String nameInitial;
  final String imgUrl;
  final bool isOnline;

  const _Avatar({
    required this.nameInitial,
    required this.imgUrl,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient ring
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            gradient: isOnline
                ? _igGradient
                : const LinearGradient(
                    colors: [Colors.white12, Colors.white12],
                  ),
            shape: BoxShape.circle,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              child: imgUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        imgUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          nameInitial,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    )
                  : Text(
                      nameInitial,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
            ),
          ),
        ),

        // Online dot
        // if (isOnline)
        //   Positioned(
        //     bottom: 2,
        //     right: 2,
        //     child: Container(
        //       width: 12,
        //       height: 12,
        //       decoration: BoxDecoration(
        //         color: Colors.greenAccent,
        //         shape: BoxShape.circle,
        //         border: Border.all(color: Colors.black, width: 1.5),
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}
