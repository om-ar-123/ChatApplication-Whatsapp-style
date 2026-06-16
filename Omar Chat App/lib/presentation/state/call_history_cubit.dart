import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/call_record.dart';
import '../../data/repositories/call_repository.dart';

class CallHistoryState extends Equatable {
  const CallHistoryState({
    this.calls = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CallRecord> calls;
  final bool isLoading;
  final String? error;

  CallHistoryState copyWith({
    List<CallRecord>? calls,
    bool? isLoading,
    String? error,
  }) =>
      CallHistoryState(
        calls: calls ?? this.calls,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [calls, isLoading, error];
}

class CallHistoryCubit extends Cubit<CallHistoryState> {
  CallHistoryCubit({CallRepository? callRepository})
      : _callRepository = callRepository ?? CallRepository(),
        super(const CallHistoryState());

  final CallRepository _callRepository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final calls = await _callRepository.getAll();
      emit(state.copyWith(calls: calls, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
