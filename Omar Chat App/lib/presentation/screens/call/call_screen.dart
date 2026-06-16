import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/entities/call_session.dart';
import '../../../domain/usecases/save_call_usecase.dart';
import '../../widgets/profile_avatar.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.contactName,
    required this.type,
    this.isGroup = false,
  });

  final String contactName;
  final CallType type;
  final bool isGroup;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  late final CallSession _session;
  late final AnimationController _pulseController;
  Timer? _ringTimer;
  Timer? _durationTimer;
  String _statusText = 'Calling…';

  @override
  void initState() {
    super.initState();
    _session = CallSession(
      contactName: widget.contactName,
      type: widget.type,
      isGroup: widget.isGroup,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _session.phase == CallPhase.ended) return;
      setState(() {
        _session.phase = CallPhase.connecting;
        _statusText = 'Connecting…';
      });
      Timer(const Duration(milliseconds: 900), _onConnected);
    });
  }

  void _onConnected() {
    if (!mounted || _session.phase == CallPhase.ended) return;
    setState(() {
      _session.phase = CallPhase.connected;
      _statusText = _formatDuration(_session.elapsedSeconds);
    });
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _session.phase != CallPhase.connected) return;
      setState(() {
        _session.elapsedSeconds++;
        _statusText = _formatDuration(_session.elapsedSeconds);
      });
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    _ringTimer?.cancel();
    _durationTimer?.cancel();
    _session.phase = CallPhase.ended;
    Navigator.pop(context, {
      'type': widget.type == CallType.video ? 'video' : 'voice',
      'duration': _session.elapsedSeconds,
      'contact': widget.contactName,
    });
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _durationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: SafeArea(
        child: widget.type == CallType.video ? _buildVideoCall() : _buildVoiceCall(),
      ),
    );
  }

  Widget _buildVoiceCall() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F2C34), Color(0xFF0B141A)],
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 48),
            _buildHeader(),
            const Spacer(),
            ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: widget.isGroup
                  ? CircleAvatar(
                      radius: 72,
                      backgroundColor: AppColors.appBar,
                      child: const Icon(Icons.groups, size: 72, color: Colors.white),
                    )
                  : ProfileAvatar(name: widget.contactName, radius: 72),
            ),
            const SizedBox(height: 24),
            Text(
              widget.contactName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _phaseLabel(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 16),
            ),
            if (_session.phase == CallPhase.connected) ...[
              const SizedBox(height: 8),
              Text(
                'Encrypted · Simulated call',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
              ),
            ],
            const Spacer(),
            _buildVoiceControls(),
            const SizedBox(height: 32),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoCall() {
    final showRemoteVideo = _session.phase == CallPhase.connected && _session.isVideoEnabled;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: showRemoteVideo
                  ? [const Color(0xFF2A3942), const Color(0xFF111B21)]
                  : [const Color(0xFF1A1A1A), const Color(0xFF0B141A)],
            ),
          ),
        ),
        if (showRemoteVideo)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.isGroup
                    ? const Icon(Icons.groups, size: 120, color: Colors.white54)
                    : ProfileAvatar(name: widget.contactName, radius: 80),
                const SizedBox(height: 16),
                Text(
                  widget.contactName,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulated video feed',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                ),
              ],
            ),
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  _phaseLabel(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                ),
              ],
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildHeader(compact: true),
        ),
        if (_session.phase == CallPhase.connected && _session.isVideoEnabled)
          Positioned(
            top: 72,
            right: 16,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProfileAvatar(name: 'OMAR', radius: 28),
                  const SizedBox(height: 8),
                  Text(
                    'You',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: _buildVideoControls(),
        ),
      ],
    );
  }

  Widget _buildHeader({bool compact = false}) {
    return Row(
      children: [
        IconButton(
          onPressed: _endCall,
          icon: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: compact ? 0.9 : 0.7)),
        ),
        if (!compact) ...[
          const Spacer(),
          Icon(Icons.lock, size: 14, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            'End-to-end encrypted (demo)',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
          const Spacer(),
        ] else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _phaseLabel(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        if (compact) const SizedBox(width: 48),
      ],
    );
  }

  String _phaseLabel() {
    switch (_session.phase) {
      case CallPhase.ringing:
        return widget.type == CallType.video ? 'Ringing…' : 'Calling…';
      case CallPhase.connecting:
        return 'Connecting…';
      case CallPhase.connected:
        return _statusText;
      case CallPhase.ended:
        return 'Call ended';
    }
  }

  Widget _buildVoiceControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallControlButton(
            icon: _session.isMuted ? Icons.mic_off : Icons.mic,
            label: _session.isMuted ? 'Unmute' : 'Mute',
            onTap: () => setState(() => _session.isMuted = !_session.isMuted),
          ),
          _CallControlButton(
            icon: Icons.call_end,
            label: 'End',
            isEnd: true,
            onTap: _endCall,
          ),
          _CallControlButton(
            icon: _session.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: 'Speaker',
            active: _session.isSpeakerOn,
            onTap: () => setState(() => _session.isSpeakerOn = !_session.isSpeakerOn),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallControlButton(
            icon: _session.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: 'Video',
            active: _session.isVideoEnabled,
            onTap: () => setState(() => _session.isVideoEnabled = !_session.isVideoEnabled),
          ),
          _CallControlButton(
            icon: _session.isMuted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            onTap: () => setState(() => _session.isMuted = !_session.isMuted),
          ),
          _CallControlButton(
            icon: Icons.call_end,
            label: 'End',
            isEnd: true,
            onTap: _endCall,
          ),
          _CallControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: () => setState(() => _session.isFrontCamera = !_session.isFrontCamera),
          ),
        ],
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEnd = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEnd;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = isEnd
        ? Colors.red.shade600
        : active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.15);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(isEnd ? 18 : 16),
              child: Icon(
                icon,
                color: isEnd
                    ? Colors.white
                    : active
                        ? Colors.black87
                        : Colors.white,
                size: isEnd ? 32 : 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
        ),
      ],
    );
  }
}

/// Opens a simulated voice or video call screen.
Future<void> openSimulatedCall(
  BuildContext context, {
  required String contactName,
  required CallType type,
  bool isGroup = false,
  int? chatId,
  int? contactUserId,
}) async {
  final result = await Navigator.pushNamed(
    context,
    AppRoutes.call,
    arguments: {
      'name': contactName,
      'type': type == CallType.video ? 'video' : 'voice',
      'isGroup': isGroup,
    },
  );

  if (!context.mounted || result is! Map) return;

  final callType = result['type'] == 'video' ? 'video' : 'voice';
  final duration = result['duration'] as int? ?? 0;
  final durationText = duration > 0
      ? ' · ${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}'
      : '';

  await SaveCallUseCase().execute(
    contactName: contactName,
    callType: callType,
    durationSeconds: duration,
    contactUserId: contactUserId,
    chatId: chatId,
    isGroup: isGroup,
    isOutgoing: true,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${callType == 'video' ? 'Video' : 'Voice'} call ended$durationText')),
  );
}
