class Group {
  final int chatId;
  final String name;
  final List<int> memberIds;

  const Group({
    required this.chatId,
    required this.name,
    required this.memberIds,
  });
}
