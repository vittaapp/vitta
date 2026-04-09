import 'package:flutter/material.dart';

/// Widget que muestra un título de sección con estilo tipográfico consistente.
class SectionTitleWidget extends StatelessWidget {
  const SectionTitleWidget({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Colors.grey.shade700,
      ),
    );
  }
}
