import Head from 'next/head';
import { useEffect, useState } from 'react';
import { getDashboard } from '../utils/api';

export default function Dashboard() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getDashboard()
      .then(setData)
      .catch(e => setError(e.message || 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <Head>
        <title>Dashboard – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 500, width: '95%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Dashboard</h1>
          {loading && <p style={{ textAlign: 'center', marginTop: 24 }}>Loading...</p>}
          {error && <p style={{ color: 'red', textAlign: 'center', marginTop: 24 }}>{error}</p>}
          {data && (
            <>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16, marginTop: 24 }}>
                <div style={{ background: '#3EC6E0', color: 'white', borderRadius: 16, padding: 20, textAlign: 'center', fontSize: 22, fontWeight: 600 }}>
                  Balance: ₹{data.balance?.toLocaleString('en-IN', { minimumFractionDigits: 2 }) || '0.00'}
                </div>
                <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
                  <button style={{ background: '#1A4D7A', color: 'white', borderRadius: 8, padding: '10px 18px', fontWeight: 600, border: 'none' }}>Add Money</button>
                  <button style={{ background: '#fff', color: '#1A4D7A', border: '2px solid #1A4D7A', borderRadius: 8, padding: '10px 18px', fontWeight: 600 }}>Transfer</button>
                </div>
              </div>
              <div style={{ marginTop: 32 }}>
                <h2 style={{ fontSize: 20, color: '#1A4D7A', marginBottom: 12 }}>Recent Activity</h2>
                <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                  {(data.recentTransactions || []).slice(0, 5).map((tx: any) => (
                    <li key={tx.id} style={{ marginBottom: 10, background: '#f6fafd', borderRadius: 8, padding: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontWeight: 500 }}>{tx.description || tx.category}</span>
                      <span style={{ color: tx.type === 'credit' ? '#2ecc40' : '#e74c3c', fontWeight: 600 }}>{tx.type === 'credit' ? '+' : '-'}₹{tx.amount}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </>
          )}
        </div>
      </main>
    </>
  );
}
