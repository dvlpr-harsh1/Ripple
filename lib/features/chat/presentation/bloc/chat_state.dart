import 'package:equatable/equatable.dart';

import '../../domain/entities/message_entity.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatError extends ChatState {
  final String message;
  ChatError({required this.message});
  @override
  List<Object?> get props => [message];
}

class ChatLoaded extends ChatState {
  final List<MessageEntity> messages;
  final bool isOtherTyping;
  final bool isOtherOnline;

  ChatLoaded({
    required this.messages,
    this.isOtherTyping = false,
    this.isOtherOnline = false,
  });

  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    bool? isOtherTyping,
    bool? isOtherOnline,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      isOtherOnline: isOtherOnline ?? this.isOtherOnline,
    );
  }

  @override
  List<Object?> get props => [messages, isOtherTyping, isOtherOnline];
}
