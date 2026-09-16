import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_text.dart';

/// A production-standard "Slide to Place Order / Pay" interactive slider
/// matching Zepto, Blinkit, and top quick-commerce apps.
class SlideToPay extends StatefulWidget {
  final double totalAmount;
  final String paymentMethod;
  final VoidCallback onSlideComplete;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onDisabledTap;
  final Color? primaryColor;
  final String? customLabel;

  const SlideToPay({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.onSlideComplete,
    this.isLoading = false,
    this.enabled = true,
    this.onDisabledTap,
    this.primaryColor,
    this.customLabel,
  });

  @override
  State<SlideToPay> createState() => _SlideToPayState();
}

class _SlideToPayState extends State<SlideToPay>
    with TickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  late AnimationController _springController;
  late Animation<double> _springAnimation;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  final double _sliderHeight = 56.0;
  final double _thumbMargin = 4.0;

  double get _thumbSize => _sliderHeight - (_thumbMargin * 2);

  @override
  void initState() {
    super.initState();

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _springAnimation = CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    );

    _springController.addListener(() {
      setState(() {
        _dragPosition = _springAnimation.value;
      });
    });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SlideToPay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset if loading finished or was cancelled
    if (oldWidget.isLoading && !widget.isLoading && _isCompleted) {
      _resetSlider();
    }
  }

  void _resetSlider() {
    setState(() {
      _isCompleted = false;
      _dragPosition = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themePrimary = widget.primaryColor ?? Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - (_thumbMargin * 2);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: _sliderHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.enabled
                ? themePrimary
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(_sliderHeight / 2),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: themePrimary.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_sliderHeight / 2),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 1. Progress Fill
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _dragPosition + _thumbSize + _thumbMargin,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981),
                          themePrimary,
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Animated Center Track Text & Arrows
                Center(
                  child: Opacity(
                    opacity: (1.0 - (progress * 1.8)).clamp(0.0, 1.0),
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 24),
                            CustomText(
                              widget.customLabel ??
                                  (widget.paymentMethod == 'COD'
                                      ? "SLIDE TO PLACE COD ORDER"
                                      : "SLIDE TO PAY ₹${widget.totalAmount.toStringAsFixed(0)}"),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.double_arrow_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // 3. Loading state text
                if (widget.isLoading)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        CustomText(
                          "Placing your order...",
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ],
                    ),
                  ),

                // 4. Interactive Slider Handle (Thumb)
                if (!widget.isLoading)
                  Positioned(
                    left: _thumbMargin + _dragPosition,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        if (!widget.enabled) {
                          widget.onDisabledTap?.call();
                          return;
                        }
                        HapticFeedback.lightImpact();
                      },
                      onHorizontalDragUpdate: (details) {
                        if (!widget.enabled || _isCompleted) return;

                        setState(() {
                          _dragPosition = (_dragPosition + details.delta.dx)
                              .clamp(0.0, maxDrag);
                        });

                        // Subtle haptic tick at threshold
                        if (progress >= 0.80 && !_isCompleted) {
                          HapticFeedback.selectionClick();
                        }
                      },
                      onHorizontalDragEnd: (_) {
                        if (!widget.enabled || _isCompleted) return;

                        if (progress >= 0.80) {
                          // Complete
                          setState(() {
                            _dragPosition = maxDrag;
                            _isCompleted = true;
                          });
                          HapticFeedback.heavyImpact();
                          widget.onSlideComplete();
                        } else {
                          // Spring back
                          HapticFeedback.lightImpact();
                          _springAnimation = Tween<double>(
                            begin: _dragPosition,
                            end: 0.0,
                          ).animate(
                            CurvedAnimation(
                              parent: _springController,
                              curve: Curves.easeOutBack,
                            ),
                          );
                          _springController.forward(from: 0.0);
                        }
                      },
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  color: themePrimary,
                                  size: 24,
                                )
                              : Icon(
                                  widget.paymentMethod == 'COD'
                                      ? Icons.local_shipping_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: themePrimary,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
