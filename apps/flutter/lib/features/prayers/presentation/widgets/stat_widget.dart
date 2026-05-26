import 'package:flutter/material.dart';

class StatWidget extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isDark;

  const StatWidget({required this.emoji, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text('$count',
            style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
      ],
    );
  }
}
