import { useAuthStore } from '../store';

export type Permission = 
  | 'users_read' | 'users_write' | 'users_delete'
  | 'members_read' | 'members_write' | 'members_delete' | 'members_export' | 'members_import'
  | 'events_read' | 'events_write' | 'events_delete'
  | 'prayers_read' | 'prayers_write' | 'prayers_delete'
  | 'finance_read' | 'finance_write' | 'finance_delete' | 'finance_export' | 'finance_audit';

export function usePermission() {
  const user = useAuthStore((s) => s.user);

  const hasPermission = (permission: Permission): boolean => {
    if (!user) return false;
    
    // Admin tem todas as permissões
    if (user.role === 'ADMINISTRADOR') return true;
    
    // Pastor tem permissões de leitura e escrita
    if (user.role === 'PASTOR') {
      const pastorPermissions = [
        'events_read', 'events_write', 'events_delete',
        'prayers_read', 'prayers_write',
        'members_read', 'members_write',
      ];
      if (pastorPermissions.includes(permission)) return true;
    }
    
    // Verificar permissões específicas do usuário
    const userPermissions = user.permissions || [];
    return userPermissions.includes(permission);
  };

  const canCreateEvent = () => hasPermission('events_write') || user?.role === 'ADMINISTRADOR' || user?.role === 'PASTOR';
  const canEditEvent = () => hasPermission('events_write') || user?.role === 'ADMINISTRADOR' || user?.role === 'PASTOR';
  const canDeleteEvent = () => hasPermission('events_delete') || user?.role === 'ADMINISTRADOR';

  return {
    hasPermission,
    canCreateEvent,
    canEditEvent,
    canDeleteEvent,
  };
}