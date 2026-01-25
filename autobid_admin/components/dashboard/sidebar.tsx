'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { supabase } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  const navItems = [
    { label: 'Dashboard', href: '/', icon: '📊' },
    { label: 'Auction Monitoring', href: '/auctions/monitor', icon: '🏷️' },
    { label: 'KYC Review', href: '/kyc/queue', icon: '🆔' },
    { label: 'Payment Verification', href: '/payments/verify', icon: '💳' },
    { label: 'User Management', href: '/users', icon: '👥' },
    { label: 'System Settings', href: '/settings', icon: '⚙️' },
  ]

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <aside className="flex flex-col w-64 h-screen bg-gray-900 text-white shadow-xl">
      <div className="p-6">
        <h1 className="text-2xl font-bold tracking-tight">AutoBid Admin</h1>
        <p className="text-xs text-gray-400 mt-1 uppercase tracking-widest">Portal v1.0</p>
      </div>

      <nav className="flex-1 px-4 space-y-1 overflow-y-auto">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`
              flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200
              ${pathname === item.href
                ? 'bg-blue-600 text-white shadow-lg shadow-blue-900/20'
                : 'text-gray-400 hover:bg-gray-800 hover:text-white'
              }
            `}
          >
            <span className="text-xl">{item.icon}</span>
            <span className="font-medium">{item.label}</span>
          </Link>
        ))}
      </nav>

      <div className="p-4 border-t border-gray-800">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 w-full px-4 py-3 text-gray-400 hover:text-red-400 hover:bg-gray-800 rounded-lg transition-colors"
        >
          <span className="text-xl">🚪</span>
          <span className="font-medium">Sign Out</span>
        </button>
      </div>
    </aside>
  )
}
