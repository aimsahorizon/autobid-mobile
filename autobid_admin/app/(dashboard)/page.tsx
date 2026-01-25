import { createClient } from '@/lib/supabase/server'

export default async function DashboardPage() {
  const supabase = createClient()
  
  // Fetch some basic stats
  const { data: metrics } = await supabase
    .from('admin_dashboard_metrics')
    .select('*')
    .order('metric_date', { ascending: false })
    .limit(1)
    .single()

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500 mt-2">Welcome back to the AutoBid administration portal.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <MetricCard 
          title="Active Auctions" 
          value={metrics?.active_auctions ?? 0} 
          icon="🏷️" 
          color="blue" 
        />
        <MetricCard 
          title="Pending KYC" 
          value={metrics?.pending_kyc_reviews ?? 0} 
          icon="🆔" 
          color="orange" 
        />
        <MetricCard 
          title="Today's Revenue" 
          value={`₱${(metrics?.total_revenue_today ?? 0).toLocaleString()}`} 
          icon="💰" 
          color="green" 
        />
        <MetricCard 
          title="Active Users" 
          value={metrics?.active_users ?? 0} 
          icon="👥" 
          color="purple" 
        />
      </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
        <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <QuickAction title="Review KYC Queue" href="/kyc/queue" />
          <QuickAction title="Monitor Live Auctions" href="/auctions/monitor" />
          <QuickAction title="Verify Payments" href="/payments/verify" />
        </div>
      </div>
    </div>
  )
}

function MetricCard({ title, value, icon, color }: any) {
  const colorClasses: any = {
    blue: "bg-blue-50 text-blue-600 border-blue-100",
    orange: "bg-orange-50 text-orange-600 border-orange-100",
    green: "bg-green-50 text-green-600 border-green-100",
    purple: "bg-purple-50 text-purple-600 border-purple-100",
  }

  return (
    <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 flex items-center gap-4">
      <div className={`w-12 h-12 rounded-full flex items-center justify-center text-2xl border ${colorClasses[color]}`}>
        {icon}
      </div>
      <div>
        <p className="text-sm font-medium text-gray-500">{title}</p>
        <p className="text-2xl font-bold text-gray-900">{value}</p>
      </div>
    </div>
  )
}

function QuickAction({ title, href }: { title: string, href: string }) {
  return (
    <a 
      href={href}
      className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors flex items-center justify-between group"
    >
      <span className="font-medium text-gray-700">{title}</span>
      <span className="text-gray-400 group-hover:translate-x-1 transition-transform">→</span>
    </a>
  )
}
