'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase/client'
import { AuctionMonitorTable } from '@/components/auctions/auction-monitor-table'

export default function AuctionMonitorPage() {
  const [auctions, setAuctions] = useState<any[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const fetchAuctions = async () => {
    const { data, error } = await supabase
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

    if (!error) {
      setAuctions(data ?? [])
    }
    setIsLoading(false)
  }

  useEffect(() => {
    fetchAuctions()

    // Refresh every 10 seconds
    const interval = setInterval(fetchAuctions, 10000)

    // Subscribe to real-time changes
    const channel = supabase
      .channel('admin-monitoring')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'admin_auction_monitoring'
      }, () => {
        fetchAuctions()
      })
      .subscribe()

    return () => {
      clearInterval(interval)
      supabase.removeChannel(channel)
    }
  }, [])

  const handleFlag = async (auctionId: string, reason: string) => {
    // Implement flag logic
    console.log('Flagging auction:', auctionId, reason)
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Live Auction Monitoring</h1>
        <p className="text-gray-500 mt-2">Real-time status of active auctions and critical alerts.</p>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      ) : (
        <AuctionMonitorTable 
          auctions={auctions} 
          onFlag={handleFlag}
        />
      )}
    </div>
  )
}
