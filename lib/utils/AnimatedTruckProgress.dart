import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class AnimatedTruckProgress extends AnimatedWidget {
  static const double _progressBarHeight = 20.0;
  static const double _truckIconSize = 40.0;

  const AnimatedTruckProgress({
    Key? key,
    required Animation<double> animation,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final value = animation.value;

    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.8),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double containerWidth =
                  constraints.maxWidth > 0 ? constraints.maxWidth : 250;
              final double progressBarWidth = containerWidth * 0.7;
              final double barHorizontalPadding =
                  (containerWidth - progressBarWidth) / 2;

              double truckLeftPosition = barHorizontalPadding +
                  (value * progressBarWidth) -
                  (_truckIconSize / 2);

              final double minClamp =
                  barHorizontalPadding - (_truckIconSize / 2);
              final double maxClamp = barHorizontalPadding +
                  progressBarWidth -
                  (_truckIconSize / 2);

              truckLeftPosition = truckLeftPosition.clamp(minClamp, maxClamp);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: containerWidth,
                    height: _truckIconSize + _progressBarHeight,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: progressBarWidth,
                            height: _progressBarHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius:
                                  BorderRadius.circular(_progressBarHeight / 2),
                              border: Border.all(
                                  color: Colors.teal.shade700, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(_progressBarHeight / 2),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: progressBarWidth * value,
                                  height: _progressBarHeight,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: truckLeftPosition,
                          bottom: _progressBarHeight - 7,
                          child: const Icon(
                            Icons.local_shipping,
                            color: AppColors.primary,
                            size: _truckIconSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
