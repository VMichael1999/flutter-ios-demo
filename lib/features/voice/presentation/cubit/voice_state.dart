part of 'voice_conversation_cubit.dart';

enum VoiceStatus { idle, listening, thinking, speaking, failure }

final class VoiceState extends Equatable {
  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.reply = '',
    this.errorMessage,
  });

  final VoiceStatus status;

  /// Lo que dijo la persona en el turno actual.
  final String transcript;

  /// La respuesta de NOVA en el turno actual.
  final String reply;

  /// Solo tiene valor cuando [status] es [VoiceStatus.failure].
  final String? errorMessage;

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    String? reply,
    String? errorMessage,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      reply: reply ?? this.reply,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transcript, reply, errorMessage];
}
