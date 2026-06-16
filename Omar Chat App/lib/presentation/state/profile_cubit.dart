import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/db_constants.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';

class ProfileState extends Equatable {
  final User? user;
  final bool isLoading;
  final bool saved;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.saved = false,
    this.error,
  });

  ProfileState copyWith({
    User? user,
    bool? isLoading,
    bool? saved,
    String? error,
  }) =>
      ProfileState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        saved: saved ?? this.saved,
        error: error,
      );

  @override
  List<Object?> get props => [user, isLoading, saved, error];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({UserRepository? userRepository, this.userId})
      : _userRepository = userRepository ?? UserRepository(),
        super(const ProfileState());

  final UserRepository _userRepository;
  final int? userId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final id = userId ?? DbConstants.currentUserId;
      final user = await _userRepository.getById(id);
      emit(state.copyWith(user: user, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> update(UserModel model) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _userRepository.update(model);
      await load();
      emit(state.copyWith(saved: true, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
