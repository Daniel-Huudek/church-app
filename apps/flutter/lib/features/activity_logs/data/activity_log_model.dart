class ActivityLogActor {
  final String id;
  final String? name;
  final String? email;

  const ActivityLogActor({
    required this.id,
    this.name,
    this.email,
  });

  factory ActivityLogActor.fromJson(Map<String, dynamic> json) {
    return ActivityLogActor(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return id;
  }
}

class ActivityLogModel {
  final String id;
  final String domain;
  final String action;
  final String entityId;
  final String? entityLabel;
  final String? changedById;
  final String? changedByRole;
  final ActivityLogActor? changedBy;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    required this.domain,
    required this.action,
    required this.entityId,
    this.entityLabel,
    this.changedById,
    this.changedByRole,
    this.changedBy,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    final actorRaw = json['changedBy'];
    return ActivityLogModel(
      id: json['id'] as String,
      domain: json['domain'] as String? ?? '',
      action: json['action'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      entityLabel: json['entityLabel'] as String?,
      changedById: json['changedById'] as String?,
      changedByRole: json['changedByRole'] as String?,
      changedBy: actorRaw is Map<String, dynamic>
          ? ActivityLogActor.fromJson(actorRaw)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get domainLabel {
    switch (domain) {
      case 'MEMBERS':
        return 'Membros';
      case 'FINANCE':
        return 'Financeiro';
      case 'EVENTS':
        return 'Eventos';
      case 'SCHEDULES':
        return 'Escalas';
      case 'PRAYERS':
        return 'Orações';
      default:
        return domain;
    }
  }

  String get actionLabel {
    switch (action) {
      case 'CREATED':
        return 'Criado';
      case 'UPDATED':
        return 'Atualizado';
      case 'DELETED':
        return 'Excluído';
      case 'CONFIRMED':
        return 'Confirmado';
      case 'CANCELLED':
        return 'Cancelado';
      case 'ANSWERED':
        return 'Respondido';
      default:
        return action;
    }
  }
}
