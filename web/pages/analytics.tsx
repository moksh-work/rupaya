import Head from 'next/head';
import { useEffect, useState } from 'react';
import { getAnalytics } from '../utils/api';

export default function Analytics() {
  const [analytics, setAnalytics] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getAnalytics()
      .then(setAnalytics)
      .catch(e => setError(e.message || 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  // Simple bar chart using divs (no external lib)
  const Chart = ({ data }: { data: { label: string; value: number }[] }) => {
    const max = Math.max(...data.map(d => d.value), 1);
    return (
      <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', height: 120, margin: '24px 0' }}>
        {data.map(d => (
          <div key={d.label} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 40 }}>
            <div style={{ background: '#3EC6E0', width: 24, height: `${(d.value / max) * 100}%`, borderRadius: 6, marginBottom: 4 }} />
            <span style={{ fontSize: 12, color: '#1A4D7A' }}>{d.label}</span>
          </div>
        ))}
      </div>
    );
  };

  return (
    <>
      <Head>
        <title>Analytics – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 540, width: '95%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Analytics</h1>
          {loading && <p style={{ textAlign: 'center', marginTop: 24 }}>Loading...</p>}
          {error && <p style={{ color: 'red', textAlign: 'center', marginTop: 24 }}>{error}</p>}
          {analytics && (
            <>
              <div style={{ textAlign: 'center', margin: '16px 0' }}>
                <span style={{ fontWeight: 600, color: '#1A4D7A', fontSize: 20 }}>Total Spent: </span>
                <span style={{ color: '#e74c3c', fontWeight: 700, fontSize: 20 }}>₹{analytics.totalSpent}</span>
              </div>
              <Chart data={analytics.categoryBreakdown.map((c: any) => ({ label: c.category, value: c.amount }))} />
              <h3 style={{ color: '#1A4D7A', marginTop: 24, fontSize: 18 }}>Category Breakdown</h3>
              <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                {analytics.categoryBreakdown.map((c: any) => (
                  <li key={c.category} style={{ marginBottom: 10, background: '#f6fafd', borderRadius: 8, padding: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 500 }}>{c.category}</span>
                    <span style={{ color: '#3EC6E0', fontWeight: 600 }}>₹{c.amount}</span>
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>
      </main>
    </>
  );
}
