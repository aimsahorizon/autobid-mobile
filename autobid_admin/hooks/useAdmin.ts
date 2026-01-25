'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { useAdminStore } from '../store/useAdminStore'
import { AdminRole } from '../permissions'

export function useAdmin() {
  const { admin, role, setAdmin, clearAdmin } = useAdminStore()
  const [isLoading, setIsLoading] = useState(!admin)

  useEffect(() => {
    if (admin) return

    const fetchAdmin = async () => {
      const { data: { user } } = await supabase.auth.getUser()
      
      if (user) {
        const { data: adminUser } = await supabase
          .from('admin_users')
          .select('*, admin_roles(role_name)')
          .eq('id', user.id)
          .single()

        if (adminUser) {
          setAdmin(adminUser, adminUser.admin_roles.role_name as AdminRole)
        } else {
          clearAdmin()
        }
      } else {
        clearAdmin()
      }
      setIsLoading(false)
    }

    fetchAdmin()
  }, [admin, setAdmin, clearAdmin])

  return { admin, role, isLoading }
}
