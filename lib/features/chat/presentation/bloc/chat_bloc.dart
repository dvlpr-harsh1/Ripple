import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripple/features/chat/presentation/bloc/chat_event.dart';
import 'package:ripple/features/chat/presentation/bloc/chat_state.dart';
import '../../data/repositories/chat_repository_impl.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepositoryImpl repository;
  String? _otherUid;
  String? _myUid;

  StreamSubscription? _messagesSub;
  StreamSubscription? _chatDocSub;
  StreamSubscription? _userDocSub;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<ChatInitialized>(_onInit);
    on<ChatMessageSent>(_onSend);
    on<ChatTypingChanged>(_onTyping);
    on<ChatMessageDeleted>(_onDelete);
    on<ChatMarkedAsRead>(_onMarkRead);
    on<ChatDocUpdated>(_onChatDocUpdated);
    on<ChatUserDocUpdated>(_onUserDocUpdated);
  }

  Future<void> _onInit(ChatInitialized event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    // ✅ Save both UIDs for use in other handlers

    _myUid = event.myUid;

    _otherUid = event.otherUid;

    await _messagesSub?.cancel();

    await _chatDocSub?.cancel();

    await _userDocSub?.cancel();

    await repository.createChatIfNotExists(
      myUid: event.myUid,

      otherUid: event.otherUid,
    );

    await repository.markAsRead(myUid: event.myUid, otherUid: event.otherUid);

    _startChatDocStream(event.myUid, event.otherUid);

    _startUserDocStream(event.otherUid);

    await emit.forEach(
      repository.getMessages(myUid: event.myUid, otherUid: event.otherUid),

      onData: (messages) {
        final current = state;

        return ChatLoaded(
          messages: messages,

          isOtherTyping: current is ChatLoaded ? current.isOtherTyping : false,

          isOtherOnline: current is ChatLoaded ? current.isOtherOnline : false,
        );
      },

      onError: (e, _) => ChatError(message: e.toString()),
    );
  }

  void _startChatDocStream(String myUid, String otherUid) {
    _chatDocSub = repository
        .getChatDocStream(myUid: myUid, otherUid: otherUid)
        .listen((data) => add(ChatDocUpdated(chatData: data)));
  }

  void _startUserDocStream(String otherUid) {
    _userDocSub = repository
        .getUserDocStream(otherUid: otherUid)
        .listen((data) => add(ChatUserDocUpdated(userData: data)));
  }

  void _onChatDocUpdated(ChatDocUpdated event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;

    final current = state as ChatLoaded;
    final typing = Map<String, dynamic>.from(event.chatData['typing'] ?? {});
    final isOtherTyping = typing[_otherUid] == true;

    emit(current.copyWith(isOtherTyping: isOtherTyping));
  }

  void _onUserDocUpdated(ChatUserDocUpdated event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    emit(current.copyWith(isOtherOnline: event.userData['isOnline'] ?? false));
  }

  Future<void> _onSend(ChatMessageSent event, Emitter<ChatState> emit) async {
    await repository.sentMessages(
      myUid: event.myUid,
      otherUid: event.otherUid,
      text: event.text,
    );
  }

  Future<void> _onTyping(
    ChatTypingChanged event,
    Emitter<ChatState> emit,
  ) async {
    await repository.setTyping(
      myUid: event.myUid,
      otherUid: event.otherUid,
      isTyping: event.isTyping,
    );
  }

  Future<void> _onDelete(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    await repository.deleteMessage(
      myUid: event.myUid,
      otherUid: event.otherUid,
      messageId: event.messageId,
      deleteForEveryOne: event.forEveryone,
    );
  }

  Future<void> _onMarkRead(
    ChatMarkedAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await repository.markAsRead(myUid: event.myUid, otherUid: event.otherUid);
  }

  @override
  Future<void> close() async {
    await _messagesSub?.cancel();
    await _chatDocSub?.cancel();
    await _userDocSub?.cancel();
    return super.close();
  }
}
