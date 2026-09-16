import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'custom_text.dart';

enum VoiceState { listening, recognized, paused }

class VoiceSearchModal extends StatefulWidget {
  final Function(String query) onQuerySelected;

  const VoiceSearchModal({
    super.key,
    required this.onQuerySelected,
  });

  /// Static helper to show the VoiceSearchModal bottom sheet easily from anywhere
  static Future<void> show(
    BuildContext context, {
    required Function(String query) onQuerySelected,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceSearchModal(onQuerySelected: onQuerySelected),
    );
  }

  @override
  State<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<VoiceSearchModal>
    with TickerProviderStateMixin {
  VoiceState _state = VoiceState.listening;
  String _recognizedQuery = '';
  int _promptIndex = 0;
  Timer? _promptTimer;

  // Concentric Ripple Ring Controllers
  late AnimationController _rippleController;
  late AnimationController _waveController;

  static const List<String> _rotatingPrompts = [
    "Say 'Amul Taaza Milk 500ml'",
    "Say 'Aashirvaad Shudh Chakki Atta'",
    "Say 'Fortune Sunlite Refined Oil'",
    "Say 'Britannia 100% Whole Wheat Bread'",
    "Say 'Surf Excel Matic Liquid'",
    "Say 'Fresh Farm Eggs 6 pcs'",
    "Say 'Cadbury Dairy Milk Silk'",
    "Say 'Tata Tea Gold 500g'",
    "Say 'Maggi 2-Minute Noodles'",
  ];

  static const List<Map<String, dynamic>> _quickVoiceCategories = [
    {
      'cat': '🥛 Dairy',
      'items': ['Amul Milk 500ml', 'Mother Dairy Curd', 'Amul Butter 100g'],
    },
    {
      'cat': '🌾 Staples',
      'items': ['Aashirvaad Atta 5kg', 'Fortune Sunflower Oil', 'Tata Salt 1kg'],
    },
    {
      'cat': '🍿 Snacks',
      'items': ['Maggi 2-Minute Masala', 'Lays Classic Salted', 'Britannia Good Day'],
    },
    {
      'cat': '🥤 Drinks',
      'items': ['Coca-Cola 750ml', 'Real Mixed Fruit Juice', 'Tata Tea Gold'],
    },
  ];

  @override
  void initState() {
    super.initState();

    // Concentric radiating rings
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Audio Equalizer Wavebars
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    // Rotate sample prompts every 2.4 seconds
    _promptTimer = Timer.periodic(const Duration(milliseconds: 2400), (timer) {
      if (!mounted) return;
      if (_state == VoiceState.listening) {
        setState(() {
          _promptIndex = (_promptIndex + 1) % _rotatingPrompts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _rippleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onSelectQuery(String query) {
    HapticFeedback.lightImpact();
    setState(() {
      _recognizedQuery = query;
      _state = VoiceState.recognized;
    });

    // Auto navigate after short visual confirmation
    Future.delayed(const Duration(milliseconds: 480), () {
      if (mounted) {
        Navigator.pop(context);
        widget.onQuerySelected(query);
      }
    });
  }

  void _toggleListening() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_state == VoiceState.listening) {
        _state = VoiceState.paused;
        _rippleController.stop();
        _waveController.stop();
      } else {
        _state = VoiceState.listening;
        _recognizedQuery = '';
        _rippleController.repeat();
        _waveController.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
            blurRadius: 36,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle Bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Top Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _state == VoiceState.listening
                            ? const Color(0xFF10B981)
                            : (_state == VoiceState.recognized
                                ? primaryColor
                                : const Color(0xFF94A3B8)),
                        boxShadow: _state == VoiceState.listening
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      _state == VoiceState.listening
                          ? "VOICE SEARCH ACTIVE"
                          : (_state == VoiceState.recognized
                              ? "RECOGNIZED"
                              : "LISTENING PAUSED"),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: _state == VoiceState.listening
                          ? const Color(0xFF10B981)
                          : (_state == VoiceState.recognized
                              ? primaryColor
                              : const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Headline Title & Animated Rotating Speech Prompts
            if (_state == VoiceState.recognized) ...[
              CustomText(
                "Recognized Command",
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: CustomText(
                        '"$_recognizedQuery"',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              CustomText(
                _state == VoiceState.listening
                    ? "Listening for items..."
                    : "Mic is Paused",
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: CustomText(
                    _rotatingPrompts[_promptIndex],
                    key: ValueKey<int>(_promptIndex),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Concentric Glowing Rings + Pulsing Mic
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Concentric Expanding Ripples (3 rings)
                  if (_state == VoiceState.listening)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            alignment: Alignment.center,
                            children: List.generate(3, (index) {
                              final progress =
                                  (_rippleController.value + (index * 0.33)) % 1.0;
                              final size = 90 + (progress * 80);
                              final opacity = (1.0 - progress) * 0.35;
                              return Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: opacity),
                                    width: 1.8,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(width: 170, height: 170),

                  // Center Microphone Button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _state == VoiceState.listening
                              ? [primaryColor, primaryColor.withValues(alpha: 0.85)]
                              : (_state == VoiceState.recognized
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFF64748B), const Color(0xFF475569)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_state == VoiceState.listening
                                    ? primaryColor
                                    : const Color(0xFF10B981))
                                .withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _state == VoiceState.recognized
                            ? Icons.check_rounded
                            : (_state == VoiceState.listening
                                ? Icons.mic_rounded
                                : Icons.mic_off_rounded),
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Audio Wave Equalizer (7 dynamic animated vertical bars)
            _buildAudioWaveBars(primaryColor),
            const SizedBox(height: 10),

            CustomText(
              _state == VoiceState.listening
                  ? "Tap mic to pause"
                  : "Tap mic to resume listening",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 24),

            // Divider with "OR QUICK SEARCH"
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CustomText(
                    "OR TAP POPULAR GROCERY",
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categorized Quick Voice Chips
            ..._quickVoiceCategories.map((group) {
              final cat = group['cat'] as String;
              final items = group['items'] as List<String>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      cat,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items.map((item) {
                        return GestureDetector(
                          onTap: () => _onSelectQuery(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic_none_rounded,
                                  size: 13,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 5),
                                CustomText(
                                  item,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Live Audio Equalizer Wavebars
  Widget _buildAudioWaveBars(Color primaryColor) {
    if (_state != VoiceState.listening) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 3.5,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      );
    }

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            // Dynamic multi-frequency height variation
            final phase = (index * 0.45);
            final wave = math.sin((_waveController.value * math.pi * 2) + phase);
            final normalized = (wave.abs() * 0.7) + 0.3;
            final height = 10.0 + (normalized * (index % 2 == 0 ? 24.0 : 16.0));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    const Color(0xFF10B981),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
