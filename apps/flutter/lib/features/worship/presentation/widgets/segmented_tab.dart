import 'package:flutter/material.dart';

class SegmentedTab extends StatelessWidget {
  final bool isDark;
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final List<String> labels;

  const SegmentedTab({
    super.key,
    required this.isDark,
    required this.currentTab,
    required this.onTabChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF008CFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: currentTab == i ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: currentTab == i ? const Color(0xFF008CFF) : Colors.white,
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }
}
