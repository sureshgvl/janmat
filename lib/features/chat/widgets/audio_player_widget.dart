import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/message_formatter.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? mediaUrl;
  final bool isCurrentUser;

  const AudioPlayerWidget({
    super.key,
    required this.mediaUrl,
    required this.isCurrentUser,
  });

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();

    _audioPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer?.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer?.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });
  }

  Future<void> _playPauseAudio() async {
    if (_audioPlayer == null || widget.mediaUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        if (_audioPlayer!.audioSource == null) {
          setState(() {
            _isLoadingAudio = true;
          });

          await _audioPlayer!.setUrl(widget.mediaUrl!);

          setState(() {
            _isLoadingAudio = false;
          });
        }

        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _isLoadingAudio = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          IconButton(
            icon: _isLoadingAudio
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: widget.isCurrentUser
                        ? Colors.green.shade700
                        : Colors.blue.shade600,
                    size: 24,
                  ),
            onPressed: _playPauseAudio,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          // Waveform visualization (simplified)
          Container(
            width: 60,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                8,
                (index) => Container(
                  width: 2,
                  height: _isPlaying ? (8 + (index % 3) * 4).toDouble() : 4,
                  decoration: BoxDecoration(
                    color: widget.isCurrentUser
                        ? Colors.green.shade400
                        : Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),

          // Duration display
          Text(
            _audioDuration != Duration.zero
                ? '${MessageFormatter.formatDuration(_currentPosition)} / ${MessageFormatter.formatDuration(_audioDuration)}'
                : 'Voice message',
            style: TextStyle(
              color: widget.isCurrentUser
                  ? Colors.green.shade700
                  : Colors.blue.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

