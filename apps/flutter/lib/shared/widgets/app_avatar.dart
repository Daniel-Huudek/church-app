import 'package:flutter/material.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/config/api_config.dart';

class AppAvatar extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showBorder;
  final bool authenticated;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.showBorder = false,
    this.authenticated = false,
  });

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    if (widget.authenticated && widget.imageUrl != null) {
      SecureStorage.getAccessToken().then((token) {
        if (!mounted || token == null) return;
        setState(() => _headers = {'Authorization': 'Bearer $token'});
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.authenticated &&
        widget.imageUrl != null &&
        widget.imageUrl != oldWidget.imageUrl) {
      SecureStorage.getAccessToken().then((token) {
        if (!mounted || token == null) return;
        setState(() => _headers = {'Authorization': 'Bearer $token'});
      });
    }
  }

  String? get _resolvedUrl {
    final raw = widget.imageUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${ApiConfig.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final initials = Formatters.getInitials(widget.name);
    final url = _resolvedUrl;

    if (url != null && (!widget.authenticated || _headers != null)) {
      return ClipOval(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            headers: _headers,
            errorBuilder: (_, __, ___) => _buildFallback(initials),
          ),
        ),
      );
    }

    return _buildFallback(initials);
  }

  Widget _buildFallback(String initials) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary100,
        border: widget.showBorder
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.primary700,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
