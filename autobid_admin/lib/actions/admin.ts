'use server'

import { createClient } from '../supabase/server'
import { revalidatePath } from 'next/cache'

export async function flagAuction(auctionId: string, reason: string) {
  const supabase = createClient()

  const { data: { session } } = await supabase.auth.getSession()
  if (!session) throw new Error('Unauthorized')

  const { error } = await supabase
    .from('admin_auction_monitoring')
    .update({
      is_flagged: true,
      flag_reason: reason,
      monitored_by: session.user.id
    })
    .eq('auction_id', auctionId)

  if (error) throw error

  // Log audit
  await supabase.from('admin_audit_log').insert({
    admin_id: session.user.id,
    action: 'auction.flagged',
    resource_type: 'auction',
    resource_id: auctionId,
    details: { reason }
  })

  revalidatePath('/auctions/monitor')
}
