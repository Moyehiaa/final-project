class ChatMessageModel {
  final String text;
  final bool isMe;
  final DateTime time;

  const ChatMessageModel({
    required this.text,
    required this.isMe,
    required this.time,
  });
}
