import 'dart:async';
import 'dart:io';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPanel extends StatefulWidget {
  const VideoPreviewPanel({
    super.key,
    required this.localFilePath,
    required this.range,
    required this.onDurationChanged,
  });

  final String localFilePath;
  final RangeValues range;
  final ValueChanged<double> onDurationChanged;

  @override
  State<VideoPreviewPanel> createState() => _VideoPreviewPanelState();
}

class _VideoPreviewPanelState extends State<VideoPreviewPanel> {
  VideoPlayerController? _controller;
  Timer? _timer;
  var _initializing = false;
  var _unavailable = false;
  var _previewingSelection = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(VideoPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localFilePath != widget.localFilePath) {
      _disposeController();
      _init();
    }
    if (_previewingSelection &&
        _position.inMilliseconds / 1000 >= widget.range.end) {
      _pause();
    }
  }

  Future<void> _init() async {
    final path = widget.localFilePath.trim();
    if (path.isEmpty || !File(path).existsSync()) {
      setState(() => _unavailable = true);
      return;
    }
    setState(() {
      _initializing = true;
      _unavailable = false;
    });
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      controller.setLooping(false);
      _controller = controller;
      widget.onDurationChanged(controller.value.duration.inMilliseconds / 1000);
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final active = _controller;
        if (!mounted || active == null) return;
        final position = active.value.position;
        if (_previewingSelection &&
            position.inMilliseconds / 1000 >= widget.range.end) {
          _pause();
        }
        setState(() => _position = position);
      });
      if (mounted) setState(() => _initializing = false);
    } on Object {
      if (mounted) {
        setState(() {
          _initializing = false;
          _unavailable = true;
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await _pause();
      return;
    }
    _previewingSelection = false;
    await controller.play();
    setState(() {});
  }

  Future<void> _previewSelection() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final start = Duration(milliseconds: (widget.range.start * 1000).round());
    _previewingSelection = true;
    await controller.seekTo(start);
    await controller.play();
    setState(() {});
  }

  Future<void> _pause() async {
    _previewingSelection = false;
    await _controller?.pause();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _timer?.cancel();
    _timer = null;
    _controller?.dispose();
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = _controller;

    if (_unavailable) {
      return _PreviewFrame(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.t('videoPreviewUnavailable'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
          ),
        ),
      );
    }

    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const _PreviewFrame(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isPlaying = controller.value.isPlaying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewFrame(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton.filled(
              onPressed: _togglePlay,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_position),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _previewSelection,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: Text(l.t('previewSelection')),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final total = duration.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          color: AppTone.cardSecondary(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTone.border(context)),
        ),
        child: child,
      ),
    );
  }
}
