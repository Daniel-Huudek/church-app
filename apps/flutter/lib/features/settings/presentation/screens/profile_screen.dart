import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/menu_section.dart';

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
                              StatCard(
                                icon: '📅', value: '0', label: 'Escalas',
                                color: const Color(0xFF008CFF),
                                cardBg: cardBg, textSecondary: textSecondary,
                              ),
                              const SizedBox(width: 10),
                              StatCard(
                                icon: '🎉', value: '0', label: 'Eventos',
                                color: const Color(0xFF3B82F6),
                                cardBg: cardBg, textSecondary: textSecondary,
                              ),
                              const SizedBox(width: 10),
                              StatCard(
                                icon: '🙏', value: '0', label: 'Orações',
                                color: const Color(0xFF10B981),
                                cardBg: cardBg, textSecondary: textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

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

                      MenuSection(
                        title: 'Menu',
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                        items: [
                          MenuItemData(icon: '👤', label: 'Editar Perfil', color: const Color(0xFF008CFF)),
                          MenuItemData(icon: '⚙️', label: 'Configurações', color: const Color(0xFF3B82F6)),
                          MenuItemData(icon: '🔔', label: 'Notificações', color: const Color(0xFFF59E0B)),
                          MenuItemData(icon: '📅', label: 'Minhas Escalas', color: const Color(0xFF10B981)),
                          MenuItemData(icon: '🎉', label: 'Meus Eventos', color: const Color(0xFFEC4899)),
                          MenuItemData(icon: '🙏', label: 'Minhas Orações', color: const Color(0xFF06B6D4)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      MenuSection(
                        title: 'Preferências',
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                        items: [
                          MenuItemData(
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
