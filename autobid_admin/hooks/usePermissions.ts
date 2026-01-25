import { useAdmin } from './useAdmin'
import { hasPermission, Permission } from '../lib/permissions'

export function usePermissions() {
  const { role } = useAdmin()

  const checkPermission = (permission: Permission) => {
    if (!role) return false
    return hasPermission(role, permission)
  }

  return { checkPermission, role }
}
