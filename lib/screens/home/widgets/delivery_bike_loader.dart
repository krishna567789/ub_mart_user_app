import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../../../theme/app_theme.dart';

class DeliveryBikeLoader extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const DeliveryBikeLoader({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return Stack(
          children: <Widget>[
            child,
            if (controller.value > 0.0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The road
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.grey.shade300,
                        ),
                      ),
                      // The moving bike
                      Positioned(
                        left: -50 + (MediaQuery.of(context).size.width + 100) * controller.value,
                        bottom: 10,
                        child: Icon(
                          Icons.moped,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                      ),
                      // The speed lines (if spinning/refreshing)
                      if (controller.isLoading)
                        Positioned(
                          left: -50 + (MediaQuery.of(context).size.width + 100) * controller.value - 20,
                          bottom: 15,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 2,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 4,
                                height: 2,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
