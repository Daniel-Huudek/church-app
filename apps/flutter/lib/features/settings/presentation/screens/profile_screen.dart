import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../core/config/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  _RoleData _roleConfig(String key) {
    switch (key) {
      case 'ADMINISTRADOR': return const _RoleData('Administrador', Color(0xFFEF4444), '👑');
      case 'PASTOR': return const _RoleData('Pastor', Color(0xFF008CFF), '✝️');
      case 'FINANCEIRO': return const _RoleData('Financeiro', Color(0xFF3B82F6), '💰');
      case 'LIDER': return const _RoleData('Líder', Color(0xFFF59E0B), '⭐');
      case 'VISITANTE': return const _RoleData('Visitante', Color(0xFF6B7280), '👋');
      default: return const _RoleData('Membro', Color(0xFF10B981), '🙂');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);
    final user = authState.user;
    final isDark = themeState.isDark;

    final bgColor = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final name = user?.name ?? 'Usuário';
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join()
        .toUpperCase();
    final roleKey = user?.role ?? 'MEMBRO';
    final roleData = _roleConfig(roleKey);

    final avatarSize = 80.0;

    Widget _avatarCircle(String initials) {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF008CFF),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    Widget _avatar() {
      if (user?.avatar != null) {
        final cacheKey = user?.updatedAt.millisecondsSinceEpoch ?? 0;
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: '${user!.avatar!}?v=$cacheKey',
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _avatarCircle(initials),
            placeholder: (_, __) => _avatarCircle(initials),
          ),
        );
      }
      return _avatarCircle(initials);
    }

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  height: 120,
                  color: const Color(0xFF008CFF),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: -40,
                        left: 0,
                        right: 0,
                        child: Center(child: _avatar()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Name + Email + Role
                      Center(
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: roleData.color.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(roleData.icon),
                                  const SizedBox(width: 6),
                                  Text(
                                    roleData.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: roleData.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      if (user?.phone != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(child: Text('📱')),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Telefone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    user!.phone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estatísticas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatCard(
                                icon: '📅', value: '0', label: 'Escalas',
                                color: const Color(0xFF008CFF),
                                cardBg: cardBg, textSecondary: textSecondary,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: '🎉', value: '0', label: 'Eventos',
                                color: const Color(0xFF3B82F6),
                                cardBg: cardBg, textSecondary: textSecondary,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: '🙏', value: '0', label: 'Orações',
                                color: const Color(0xFF10B981),
                                cardBg: cardBg, textSecondary: textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Ministries
                      if (user?.ministries != null &&
                          (user!.ministries as List).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ministérios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (user.ministries as List<String>)
                                  .map((m) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Text(
                                          m,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      if (user?.ministries != null &&
                          (user!.ministries as List).isNotEmpty)
                        const SizedBox(height: 20),

                      // Menu
                      _MenuSection(
                        title: 'Menu',
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                        items: [
                          _MenuItemData(icon: '👤', label: 'Editar Perfil', color: const Color(0xFF008CFF)),
                          _MenuItemData(icon: '⚙️', label: 'Configurações', color: const Color(0xFF3B82F6)),
                          _MenuItemData(icon: '🔔', label: 'Notificações', color: const Color(0xFFF59E0B)),
                          _MenuItemData(icon: '📅', label: 'Minhas Escalas', color: const Color(0xFF10B981)),
                          _MenuItemData(icon: '🎉', label: 'Meus Eventos', color: const Color(0xFFEC4899)),
                          _MenuItemData(icon: '🙏', label: 'Minhas Orações', color: const Color(0xFF06B6D4)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Preferences
                      _MenuSection(
                        title: 'Preferências',
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                        items: [
                          _MenuItemData(
                            icon: isDark ? '🌙' : '☀️',
                            label: 'Tema',
                            color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                            trailing: Text(
                              isDark ? 'Escuro' : 'Claro',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF008CFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        onItemTap: (index) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Logout
                      GestureDetector(
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🚪', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                'Sair da Conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleData {
  final String label;
  final Color color;
  final String icon;
  const _RoleData(this.label, this.color, this.icon);
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  final Color cardBg;
  final Color textSecondary;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cardBg,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  final String icon;
  final String label;
  final Color color;
  final Widget? trailing;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
  });
}

class _MenuSection extends StatelessWidget {
  final String title;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final List<_MenuItemData> items;
  final void Function(int index)? onItemTap;

  const _MenuSection({
    required this.title,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return GestureDetector(
                onTap: onItemTap != null ? () => onItemTap!(index) : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: index < items.length - 1
                        ? Border(bottom: BorderSide(color: borderColor, width: 1))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            item.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (item.trailing != null) ...[
                        item.trailing!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '›',
                        style: TextStyle(
                          fontSize: 20,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
