import 'package:flutter/material.dart';
import 'package:trackerapp/res/colors.dart';

class LoadingWidget extends StatefulWidget {
  final bool showLogo;
  final double size;

  const LoadingWidget({
    super.key,
    this.showLogo = true,
    this.size = 80,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(
      begin: 0.92,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _iconOpacity = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return widget.showLogo
              ? Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size + 15,
                height: widget.size + 15,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                  AlwaysStoppedAnimation(AppColors.primary),
                  backgroundColor:
                  AppColors.primary.withOpacity(0.15),
                ),
              ),
              Transform.scale(
                scale: _iconScale.value,
                child: Opacity(
                  opacity: _iconOpacity.value,
                  child: Image.asset(
                    'assets/images/logo_without_bg.png',
                    width: widget.size - 10,
                    height: widget.size - 10,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          )
              : SizedBox(
            width: widget.size - 20,
            height: widget.size - 20,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
              AlwaysStoppedAnimation(AppColors.primary),
            ),
          );
        },
      ),
    );
  }
}