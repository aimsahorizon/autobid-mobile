export type AdminRole = 'super_admin' | 'moderator' | 'operations_admin' | 'finance_admin' | 'support_admin';

export type Permission =
  | 'dashboard.view'
  | 'kyc.review' | 'kyc.approve'
  | 'auction.monitor' | 'auction.cancel' | 'auction.flag'
  | 'payment.verify' | 'payment.refund'
  | 'user.view' | 'user.edit' | 'user.suspend'
  | 'support.view' | 'support.reply'
  | 'reports.financial' | 'reports.generate'
  | 'system.config'
  | 'audit.view';

// Permission matrix (matches admin_system_requirements.txt)
const ROLE_PERMISSIONS: Record<AdminRole, Permission[]> = {
  super_admin: [
    'dashboard.view', 'kyc.review', 'kyc.approve', 'auction.monitor',
    'auction.cancel', 'auction.flag', 'payment.verify', 'payment.refund',
    'user.view', 'user.edit', 'user.suspend', 'support.view', 'support.reply',
    'reports.financial', 'reports.generate', 'system.config', 'audit.view'
  ],
  moderator: [
    'dashboard.view', 'auction.monitor', 'auction.flag'
  ],
  operations_admin: [
    'dashboard.view', 'kyc.review', 'kyc.approve', 'user.view', 'user.edit'
  ],
  finance_admin: [
    'dashboard.view', 'payment.verify', 'payment.refund', 'reports.financial'
  ],
  support_admin: [
    'dashboard.view', 'support.view', 'support.reply', 'user.view'
  ],
};

export function hasPermission(role: AdminRole, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role]?.includes(permission) ?? false;
}

export function canAccessRoute(role: AdminRole, route: string): boolean {
  const routePermissionMap: Record<string, Permission> = {
    '/kyc': 'kyc.review',
    '/payments': 'payment.verify',
    '/auctions/monitor': 'auction.monitor',
    '/support': 'support.view',
    '/reports': 'reports.financial',
    '/settings': 'system.config',
    '/audit-logs': 'audit.view',
  };

  // Check prefix matches
  for (const [prefix, permission] of Object.entries(routePermissionMap)) {
    if (route.startsWith(prefix)) {
      return hasPermission(role, permission);
    }
  }

  return true; // Default allow for unspecified routes (like home)
}
