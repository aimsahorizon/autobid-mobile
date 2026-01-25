import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { hasPermission } from '@/lib/permissions'

export async function GET() {
  const supabase = createServerComponentClient({ cookies })

  // Verify admin authentication
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Verify user is admin with auction.monitor permission
  const { data: adminUser } = await supabase
    .from('admin_users')
    .select('id, admin_roles(role_name)')
    .eq('id', session.user.id)
    .single()

  if (!adminUser || !hasPermission(adminUser.admin_roles.role_name as any, 'auction.monitor')) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Fetch auction monitoring data
  const { data: auctions, error } = await supabase
    .from('admin_auction_monitoring')
    .select(`
      *,
      auctions (
        id,
        title,
        current_highest_bid,
        status
      )
    `)
    .order('is_final_two_minutes', { ascending: false })
    .order('time_remaining_seconds', { ascending: true })

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json(auctions)
}
