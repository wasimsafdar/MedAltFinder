part of 'llama32vision_bloc.dart';

@immutable
sealed class Llama32visionState extends Equatable {
  const Llama32visionState();

  @override
  List<Object> get props => [];
}

final class Llama32visionInitial extends Llama32visionState {}

final class Llama32visionLoading extends Llama32visionState {}

final class Llama32visionFailure extends Llama32visionState {}

final class Llama32visionSuccess extends Llama32visionState {
  final String responseText;
  const Llama32visionSuccess(this.responseText);

  @override
  List<Object> get props => [responseText];
}
