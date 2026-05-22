import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onPress;
  final int index;

  const EventCard({
    super.key,
    required this.event,
    this.onPress,
    this.index = 0,
  });

  static const _typeLabels = {
    'CULTO': 'Culto',
    'REUNIAO': 'Reunião',
    'ESTUDO': 'Estudo',
    'EVENTO_SOCIAL': 'Evento Social',
    'EVENTO_ESPECIAL': 'Evento Especial',
    'ESCOLA_DOMINICAL': 'Escola Dominical',
    'JEJUM': 'Jejum',
    'VIGILIA': 'Vigília',
    'RETIRO': 'Retiro',
    'OUTRO': 'Outro',
  };

  static const _typeColors = {
    'CULTO': Color(0xFF008CFF),
    'REUNIAO': Color(0xFF3B82F6),
    'ESTUDO': Color(0xFF10B981),
    'EVENTO_SOCIAL': Color(0xFFF59E0B),
    'EVENTO_ESPECIAL': Color(0xFFEC4899),
    'ESCOLA_DOMINICAL': Color(0xFF06B6D4),
    'JEJUM': Color(0xFF6B7280),
    'VIGILIA': Color(0xFF1E40AF),
    'RETIRO': Color(0xFF059669),
    'OUTRO': Color(0xFF9CA3AF),
  };

  String get _type => event['type'] as String? ?? 'OUTRO';
  Color get _typeColor => _typeColors[_type] ?? const Color(0xFF9CA3AF);
  String get _typeLabel => _typeLabels[_type] ?? 'Outro';
  String get _title => event['title'] as String? ?? '';
  String get _date => event['date'] as String? ?? '';
  String get _time => event['time'] as String? ?? '';
  String get _location => event['location'] as String? ?? '';
  int get _participants => (event['participants'] as List?)?.length ?? 0;

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final months = [
        'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      return '${d.day.toString().padLeft(2, '0')} de ${months[d.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onPress,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 128,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _typeColor.withValues(alpha: 0.8),
                      _typeColor.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isDark)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor.withValues(alpha: 0.8),
                                  borderRadius:
                                      BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  _typeLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (_participants > 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '👥',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_participants',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${_formatDate(_date)} às ${_formatTime(_time)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              if (_location.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '📍',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white
                                          .withValues(alpha: 0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
