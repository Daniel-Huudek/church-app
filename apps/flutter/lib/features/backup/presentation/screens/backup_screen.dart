import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/utils/error_helper.dart';
import '../../data/backup_api.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _exporting = false;
  bool _restoring = false;

  BackupApi get _api => BackupApi(ref.read(apiClientProvider));

  Future<void> _exportBackup() async {
    if (_exporting || _restoring) return;
    setState(() => _exporting = true);
    try {
      final file = await _api.downloadBackupFile();
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Backup IPI Avaré',
        text: 'Backup dos dados da igreja',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup gerado. Salve o arquivo em local seguro.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatError(e))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_exporting || _restoring) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Restaurar backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Isso substitui os dados atuais pelos do arquivo. '
                'Digite RESTAURAR para confirmar.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmação',
                  hintText: 'RESTAURAR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().toUpperCase() == 'RESTAURAR') {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: false,
    );
    if (picked == null || picked.files.isEmpty || !mounted) return;
    final file = picked.files.single;
    final path = file.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler o arquivo selecionado')),
      );
      return;
    }

    setState(() => _restoring = true);
    try {
      await _api.restoreFromFile(
        filePath: path,
        filename: file.name.isNotEmpty ? file.name : 'backup.json',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restaurado com sucesso')),
      );
      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatError(e))),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final busy = _exporting || _restoring;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Backup', style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
        backgroundColor: bg,
        foregroundColor: t1,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.bottomNavClearance,
        ),
        children: [
          Text(
            'Salve uma cópia dos dados da igreja ou recupere a partir de um arquivo.',
            style: TextStyle(color: t2, height: 1.4),
          ),
          const SizedBox(height: 20),
          _actionCard(
            card: card,
            border: border,
            t1: t1,
            t2: t2,
            icon: Icons.cloud_download_rounded,
            iconColor: AppColors.primary,
            title: 'Fazer backup',
            subtitle: 'Gera um arquivo JSON com membros, escalas, financeiro, louvor e demais dados.',
            buttonLabel: _exporting ? 'Gerando...' : 'Baixar backup',
            onPressed: busy ? null : _exportBackup,
            loading: _exporting,
          ),
          const SizedBox(height: 14),
          _actionCard(
            card: card,
            border: border,
            t1: t1,
            t2: t2,
            icon: Icons.cloud_upload_rounded,
            iconColor: AppColors.warning,
            title: 'Restaurar backup',
            subtitle: 'Envia um arquivo de backup e substitui os dados atuais. Use com cuidado.',
            buttonLabel: _restoring ? 'Restaurando...' : 'Enviar arquivo',
            onPressed: busy ? null : _restoreBackup,
            loading: _restoring,
            danger: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Arquivos de mídia no armazenamento (fotos/S3) não entram neste backup.',
            style: TextStyle(color: t2, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required Color card,
    required Color border,
    required Color t1,
    required Color t2,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback? onPressed,
    required bool loading,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: t1)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(color: t2, height: 1.35)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: danger ? AppColors.warning : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(danger ? Icons.upload_file_rounded : Icons.download_rounded),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
