part of 'llama32vision_bloc.dart';

@immutable
sealed class Llama32visionEvent extends Equatable {
  const Llama32visionEvent();

  @override
  List<Object> get props => [];
}

class FetchResponseFromPrompt extends Llama32visionEvent {
  final String promptText;
  final String imageURL;

  const FetchResponseFromPrompt(this.promptText, this.imageURL);

  @override
  List<Object> get props => [promptText, imageURL];
}
