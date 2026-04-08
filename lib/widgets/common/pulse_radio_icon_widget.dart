import 'package:flutter/material.dart';

/// Widget que muestra un ícono de radio button con animación de pulso.
/// 
/// Anima escala y opacidad continuamente para simular un pulso.
/// Útil para indicar estados activos o en progreso.
/// 
/// Parámetro:
/// - `color`: Color del ícono
class PulseRadioIconWidget extends StatefulWidget {
  const PulseRadioIconWidget({
    Key? key,
    required this.color,
  }) : super(key: key);

  final Color color;

  @override
  State<PulseRadioIconWidget> createState() => _PulseRadioIconWidgetState();
}

class _PulseRadioIconWidgetState extends State<PulseRadioIconWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 0.92 + (t * 0.18);
        final opacity = 0.75 + (t * 0.25);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.radio_button_checked_rounded,
              color: widget.color,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
