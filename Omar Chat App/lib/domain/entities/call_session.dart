enum CallType { voice, video }

enum CallPhase { ringing, connecting, connected, ended }

class CallSession {
  CallSession({
    required this.contactName,
    required this.type,
    this.isGroup = false,
  });

  final String contactName;
  final CallType type;
  final bool isGroup;

  CallPhase phase = CallPhase.ringing;
  int elapsedSeconds = 0;
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isVideoEnabled = true;
  bool isFrontCamera = true;
}
