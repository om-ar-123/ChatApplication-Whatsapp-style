import 'package:flutter/material.dart';
import '../../services/media_service.dart';

class VoiceMessageWidget extends StatefulWidget {
  const VoiceMessageWidget({super.key, required this.path});

  final String path;

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final MediaService _media = MediaService();
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
          onPressed: () async {
            if (_playing) {
              await _media.stopPlayback();
            } else {
              await _media.playAudio(widget.path);
            }
            setState(() => _playing = !_playing);
          },
        ),
        const Text('Voice message'),
      ],
    );
  }
}
