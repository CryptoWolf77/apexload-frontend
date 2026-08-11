import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/shared/widgets/platform_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A seamless, draggable ticker for ApexLoad's authoritative platform list.
class SupportedPlatformsCarousel extends StatefulWidget {
  const SupportedPlatformsCarousel({
    super.key,
    this.pixelsPerSecond = 24,
    this.resumeDelay = const Duration(milliseconds: 900),
  });

  final double pixelsPerSecond;
  final Duration resumeDelay;

  @override
  State<SupportedPlatformsCarousel> createState() =>
      _SupportedPlatformsCarouselState();
}

class _SupportedPlatformsCarouselState extends State<SupportedPlatformsCarousel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _copyCount = 9;
  static const _middleCopy = _copyCount ~/ 2;

  final _scrollController = ScrollController();
  final _middleSegmentKey = GlobalKey();

  late final Ticker _ticker;
  Timer? _resumeTimer;
  Duration? _lastTick;
  double _segmentExtent = 0;
  bool _measureScheduled = false;
  bool _motionDisabled = false;
  bool _pointerDown = false;
  bool _userScrollInProgress = false;
  late AppLifecycleState _lifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final shouldDisableMotion =
        mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true;
    if (_motionDisabled != shouldDisableMotion) {
      _motionDisabled = shouldDisableMotion;
      _resumeTimer?.cancel();
      _stopTicker();
      if (shouldDisableMotion) _segmentExtent = 0;
    }
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant SupportedPlatformsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pixelsPerSecond != widget.pixelsPerSecond) {
      _lastTick = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _startTickerIfPossible();
    } else {
      _resumeTimer?.cancel();
      _stopTicker();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeTimer?.cancel();
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleMeasure() {
    if (_measureScheduled || _motionDisabled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final renderBox =
          _middleSegmentKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null ||
          !renderBox.hasSize ||
          renderBox.size.width <= 0) {
        return;
      }

      final nextExtent = renderBox.size.width;
      final oldExtent = _segmentExtent;
      if ((nextExtent - oldExtent).abs() < 0.5) {
        _startTickerIfPossible();
        return;
      }

      var phase = 0.0;
      if (oldExtent > 0 && _scrollController.hasClients) {
        phase = (_scrollController.position.pixels % oldExtent) / oldExtent;
      }
      _segmentExtent = nextExtent;
      if (_scrollController.hasClients) {
        final target = (_middleCopy + phase) * nextExtent;
        _scrollController.jumpTo(
          target.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
      _startTickerIfPossible();
    });
  }

  void _onTick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null || !_scrollController.hasClients) return;

    final elapsedSeconds =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (elapsedSeconds <= 0) return;

    final position = _scrollController.position;
    final middleStart = _middleCopy * _segmentExtent;
    final unwrappedTarget =
        position.pixels + widget.pixelsPerSecond * elapsedSeconds;
    final target =
        middleStart + (unwrappedTarget - middleStart) % _segmentExtent;
    _scrollController.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  bool get _canAutoScroll =>
      mounted &&
      !_motionDisabled &&
      !_pointerDown &&
      !_userScrollInProgress &&
      _lifecycleState == AppLifecycleState.resumed &&
      _segmentExtent > 0 &&
      _scrollController.hasClients &&
      widget.pixelsPerSecond > 0;

  void _startTickerIfPossible() {
    if (!_canAutoScroll || _ticker.isActive) return;
    _lastTick = null;
    _ticker.start();
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop();
    _lastTick = null;
  }

  void _pauseForInteraction() {
    _resumeTimer?.cancel();
    _stopTicker();
  }

  void _finishInteraction() {
    _normalizeToMiddleCopy();
    _resumeTimer?.cancel();
    if (_motionDisabled) return;
    _resumeTimer = Timer(widget.resumeDelay, _startTickerIfPossible);
  }

  void _normalizeToMiddleCopy() {
    if (_segmentExtent <= 0 || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final phase = position.pixels % _segmentExtent;
    final target = _middleCopy * _segmentExtent + phase;
    _scrollController.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userScrollInProgress = true;
      _pauseForInteraction();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _userScrollInProgress = true;
      _pauseForInteraction();
    } else if (notification is ScrollEndNotification && _userScrollInProgress) {
      _userScrollInProgress = false;
      if (!_pointerDown) _finishInteraction();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final runwayHeight = _runwayHeight(context);
    final scrollBehavior = ScrollConfiguration.of(context);
    final dragDevices = {
      ...scrollBehavior.dragDevices,
      PointerDeviceKind.mouse,
    };

    if (_motionDisabled) {
      return SizedBox(
        height: runwayHeight,
        child: ScrollConfiguration(
          behavior: scrollBehavior.copyWith(dragDevices: dragDevices),
          child: ListView.separated(
            key: const ValueKey('supported-platforms-static-list'),
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.availablePlatforms.length,
            itemBuilder: (context, index) => PlatformChip(
              key: ValueKey(
                'supported-platform-${AppConstants.availablePlatforms[index]}',
              ),
              label: AppConstants.availablePlatforms[index],
            ),
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
      );
    }

    _scheduleMeasure();
    return SizedBox(
      height: runwayHeight,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, 0.055, 0.945, 1],
        ).createShader(bounds),
        child: Listener(
          onPointerDown: (_) {
            _pointerDown = true;
            _pauseForInteraction();
          },
          onPointerUp: (_) {
            _pointerDown = false;
            if (!_userScrollInProgress) _finishInteraction();
          },
          onPointerCancel: (_) {
            _pointerDown = false;
            if (!_userScrollInProgress) _finishInteraction();
          },
          onPointerSignal: (_) {
            _pauseForInteraction();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _finishInteraction();
            });
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: ScrollConfiguration(
              behavior: scrollBehavior.copyWith(dragDevices: dragDevices),
              child: SingleChildScrollView(
                key: const ValueKey('supported-platforms-auto-scroll-view'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var copyIndex = 0; copyIndex < _copyCount; copyIndex++)
                      ExcludeSemantics(
                        excluding: copyIndex != _middleCopy,
                        child: Container(
                          key: copyIndex == _middleCopy
                              ? _middleSegmentKey
                              : null,
                          child: _PlatformSegment(copyIndex: copyIndex),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _runwayHeight(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: DefaultTextStyle.of(context).style.merge(
          const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final contentHeight = textPainter.height > 17 ? textPainter.height : 17.0;
    textPainter.dispose();
    final measuredHeight = (contentHeight + 20).ceilToDouble();
    return measuredHeight > 42 ? measuredHeight : 42;
  }
}

class _PlatformSegment extends StatelessWidget {
  const _PlatformSegment({required this.copyIndex});

  final int copyIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final platform in AppConstants.availablePlatforms)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: PlatformChip(
              key: ValueKey('supported-platform-$copyIndex-$platform'),
              label: platform,
            ),
          ),
      ],
    );
  }
}
