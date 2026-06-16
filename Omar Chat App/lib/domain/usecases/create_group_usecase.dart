import '../../data/repositories/group_repository.dart';

class CreateGroupUseCase {
  CreateGroupUseCase({GroupRepository? groupRepository})
      : _groupRepository = groupRepository ?? GroupRepository();

  final GroupRepository _groupRepository;

  Future<int> execute(String title, List<int> memberIds) {
    final name = title.trim();
    if (name.isEmpty) {
      throw Exception('Enter a group name');
    }
    if (memberIds.length < 2) {
      throw Exception('Select at least one other member for the group');
    }
    return _groupRepository.createGroup(name, memberIds);
  }
}
