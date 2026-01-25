export type AuctionStatus = 
  | 'draft' 
  | 'pending_approval' 
  | 'scheduled' 
  | 'live' 
  | 'ended' 
  | 'cancelled' 
  | 'in_transaction' 
  | 'sold' 
  | 'deal_failed';

export interface AdminStats {
  pending_kyc_reviews: number;
  active_auctions: number;
  total_revenue_today: number;
  active_users: number;
}

export interface Auction {
  id: string;
  title: string;
  current_highest_bid: number;
  status: AuctionStatus;
  end_time: string;
}

export interface AuctionMonitorItem {
  id: string;
  auction_id: string;
  time_remaining_seconds: number;
  is_final_two_minutes: boolean;
  is_flagged: boolean;
  auctions: Auction;
}
