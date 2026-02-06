import Head from 'next/head';
import { useEffect, useState } from 'react';
import { getAccounts } from '../utils/api';

export default function Accounts() {
  const [accounts, setAccounts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getAccounts()
      .then(setAccounts)
      .catch(e => setError(e.message || 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <Head>
        <title>Accounts – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 500, width: '95%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Accounts</h1>
          {loading && <p style={{ textAlign: 'center', marginTop: 24 }}>Loading...</p>}
          {error && <p style={{ color: 'red', textAlign: 'center', marginTop: 24 }}>{error}</p>}
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {accounts.map(acc => (
              <li key={acc.id} style={{ marginBottom: 14, background: '#f6fafd', borderRadius: 8, padding: 16, display: 'flex', flexDirection: 'column', gap: 4 }}>
                <span style={{ fontWeight: 600, color: '#1A4D7A', fontSize: 18 }}>{acc.name}</span>
                <span style={{ color: '#3EC6E0', fontWeight: 500 }}>₹{acc.balance}</span>
                <span style={{ color: '#888', fontSize: 13 }}>{acc.type}</span>
              </li>
            ))}
          </ul>
          {accounts.length === 0 && !loading && <p style={{ textAlign: 'center', marginTop: 24 }}>No accounts found.</p>}
        </div>
      </main>
    </>
  );
}
