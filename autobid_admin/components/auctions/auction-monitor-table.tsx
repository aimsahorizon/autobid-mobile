'use client'

interface AuctionMonitorTableProps {
  auctions: any[]
  onFlag?: (id: string, reason: string) => void
  onViewDetails?: (id: string) => void
}

export function AuctionMonitorTable({ auctions, onFlag, onViewDetails }: AuctionMonitorTableProps) {
  return (
    <div className="overflow-x-auto bg-white rounded-xl shadow-sm border border-gray-200">
      <table className="w-full text-left border-collapse">
        <thead>
          <tr className="bg-gray-50 border-b border-gray-200">
            <th className="px-6 py-4 text-sm font-semibold text-gray-600">Auction</th>
            <th className="px-6 py-4 text-sm font-semibold text-gray-600">Status</th>
            <th className="px-6 py-4 text-sm font-semibold text-gray-600">Current Bid</th>
            <th className="px-6 py-4 text-sm font-semibold text-gray-600">Time Left</th>
            <th className="px-6 py-4 text-sm font-semibold text-gray-600 text-right">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y border-gray-100">
          {auctions.length === 0 ? (
            <tr>
              <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                No active auctions monitored.
              </td>
            </tr>
          ) : (
            auctions.map((item) => {
              const auction = item.auctions
              const isUrgent = item.is_final_two_minutes
              const isFlagged = item.is_flagged

              return (
                <tr key={item.id} className={`${isUrgent ? 'bg-red-50' : ''} hover:bg-gray-50 transition-colors`}>
                  <td className="px-6 py-4">
                    <div className="font-medium text-gray-900">{auction.title}</div>
                    <div className="text-xs text-gray-500">ID: {auction.id.substring(0, 8)}</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs font-bold rounded-full uppercase ${
                      isFlagged ? 'bg-orange-100 text-orange-700' : 'bg-green-100 text-green-700'
                    }`}>
                      {isFlagged ? 'Flagged' : auction.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-semibold text-gray-900">
                    ₱{auction.current_highest_bid?.toLocaleString() ?? '0'}
                  </td>
                  <td className="px-6 py-4">
                    <div className={`text-sm font-mono ${isUrgent ? 'text-red-600 font-bold animate-pulse' : 'text-gray-600'}`}>
                      {Math.floor(item.time_remaining_seconds / 60)}m {item.time_remaining_seconds % 60}s
                    </div>
                  </td>
                  <td className="px-6 py-4 text-right space-x-2">
                    <button 
                      onClick={() => onViewDetails?.(auction.id)}
                      className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                    >
                      View
                    </button>
                    <button 
                      onClick={() => onFlag?.(auction.id, 'Suspicious activity')}
                      className="text-orange-600 hover:text-orange-800 text-sm font-medium"
                    >
                      Flag
                    </button>
                  </td>
                </tr>
              )
            })
          )}
        </tbody>
      </table>
    </div>
  )
}
