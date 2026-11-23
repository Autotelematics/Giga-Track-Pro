import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleAnimatedMarker extends StatefulWidget {
  final Set<Marker> animatedMarkers;
  final Set<Marker> staticMarkers;
  final Widget Function(BuildContext context, Set<Marker> markers) builder;
  final Function(MarkerId, LatLng)? onMarkerUpdate;
  final Duration duration;
  final Curve curve;
  final int fps;

  const VehicleAnimatedMarker({
    super.key,
    required this.animatedMarkers,
    this.staticMarkers = const {},
    required this.builder,
    this.onMarkerUpdate,
    this.duration = const Duration(seconds: 15),
    this.curve = Curves.ease,
    this.fps = 30,
  });

  Map<MarkerId, Marker> get allMarkersMap {
    return {
      for (var marker in staticMarkers) marker.markerId: marker,
      for (var marker in animatedMarkers) marker.markerId: marker,
    };
  }

  @override
  State<VehicleAnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<VehicleAnimatedMarker> {
  late final ValueNotifier<Set<Marker>> _markersNotifier;
  final Map<MarkerId, Marker> _transitioningMarkers = {};
  
  Timer? _tickerTimer;
  late double _animationSteps;
  late Duration _animationInterval;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _markersNotifier = ValueNotifier<Set<Marker>>(widget.allMarkersMap.values.toSet());
    _transitioningMarkers.addAll(widget.allMarkersMap);
    _calculateTiming();
  }

  void _calculateTiming() {
    _animationSteps = (widget.fps * widget.duration.inMilliseconds / 1000).toDouble();
    if (_animationSteps < 1) _animationSteps = 1;
    _animationInterval = Duration(milliseconds: (1000 / widget.fps).round());
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _markersNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VehicleAnimatedMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.duration != widget.duration || oldWidget.fps != widget.fps) {
      _calculateTiming();
    }

    final Map<Marker, Marker> updatedMarkerPairs = {};

    for (final marker in widget.animatedMarkers) {
      final oldMarker = _transitioningMarkers[marker.markerId] ?? 
                        oldWidget.allMarkersMap[marker.markerId];

      if (oldMarker != null && oldMarker.position != marker.position) {
        updatedMarkerPairs[oldMarker] = marker;
      } else {
        _transitioningMarkers[marker.markerId] = marker;
      }
    }

    for (final marker in widget.staticMarkers) {
      final oldPos = _transitioningMarkers[marker.markerId]?.position;
      _transitioningMarkers[marker.markerId] = marker;
      
      // ✅ Notify even if static, so camera follows initial placement or stops
      if (oldPos != marker.position) {
        widget.onMarkerUpdate?.call(marker.markerId, marker.position);
      }
    }

    if (updatedMarkerPairs.isEmpty) {
      _tickerTimer?.cancel();
      _isAnimating = false;
      _markersNotifier.value = widget.allMarkersMap.values.toSet();
      return;
    }

    _tickerTimer?.cancel();
    _isAnimating = true;
    int currentTick = 0;

    _tickerTimer = Timer.periodic(_animationInterval, (timer) {
      currentTick++;
      
      if (currentTick >= _animationSteps) {
        _isAnimating = false;
        for (final entry in updatedMarkerPairs.entries) {
          _transitioningMarkers[entry.value.markerId] = entry.value;
          widget.onMarkerUpdate?.call(entry.value.markerId, entry.value.position);
        }
        _markersNotifier.value = widget.allMarkersMap.values.toSet();
        timer.cancel();
        return;
      }

      final double fraction = (currentTick / _animationSteps).clamp(0.0, 1.0);
      final double curveFraction = widget.curve.transform(fraction);

      for (final entry in updatedMarkerPairs.entries) {
        final oldMarker = entry.key;
        final newMarker = entry.value;

        final interpolatedLatLng = LatLng(
          oldMarker.position.latitude +
              (newMarker.position.latitude - oldMarker.position.latitude) * curveFraction,
          oldMarker.position.longitude +
              (newMarker.position.longitude - oldMarker.position.longitude) * curveFraction,
        );

        widget.onMarkerUpdate?.call(newMarker.markerId, interpolatedLatLng);

        double oldRot = oldMarker.rotation % 360;
        double newRot = newMarker.rotation % 360;
        if ((newRot - oldRot).abs() > 180) {
          if (newRot > oldRot) oldRot += 360; else newRot += 360;
        }
        final interpolatedRotation = oldRot + (newRot - oldRot) * curveFraction;

        _transitioningMarkers[newMarker.markerId] = newMarker.copyWith(
          positionParam: interpolatedLatLng,
          rotationParam: interpolatedRotation,
        );
      }

      final currentSet = <Marker>{};
      currentSet.addAll(_transitioningMarkers.values);
      currentSet.addAll(widget.staticMarkers);
      _markersNotifier.value = currentSet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<Marker>>(
      valueListenable: _markersNotifier,
      builder: (context, markers, _) {
        return widget.builder(context, markers);
      },
    );
  }
}