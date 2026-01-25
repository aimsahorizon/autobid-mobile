import Link from 'next/link'

export default function UnauthorizedPage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-100 p-4 text-center">
      <h1 className="text-6xl font-bold text-red-600 mb-4">403</h1>
      <h2 className="text-2xl font-semibold text-gray-900 mb-2">Access Denied</h2>
      <p className="text-gray-600 mb-8 max-w-md">
        You do not have the necessary permissions to access this page. Please contact a Super Admin if you believe this is an error.
      </p>
      <Link 
        href="/"
        className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
      >
        Return to Dashboard
      </Link>
    </div>
  )
}
