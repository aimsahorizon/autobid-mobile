import { create } from 'zustand'
import { AdminRole } from '../permissions'

interface AdminState {
  admin: any | null
  role: AdminRole | null
  setAdmin: (admin: any, role: AdminRole) => void
  clearAdmin: () => void
}

export const useAdminStore = create<AdminState>((set) => ({
  admin: null,
  role: null,
  setAdmin: (admin, role) => set({ admin, role }),
  clearAdmin: () => set({ admin: null, role: null }),
}))
