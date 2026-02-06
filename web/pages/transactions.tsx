import Head from 'next/head';
import { useEffect, useState } from 'react';
import { getTransactions } from '../utils/api';

export default function Transactions() {
  const [transactions, setTransactions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'credit' | 'debit'>('all');

  useEffect(() => {
    getTransactions()
      .then(setTransactions)
      .catch(e => setError(e.message || 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  const filtered = filter === 'all' ? transactions : transactions.filter((t: any) => t.type === filter);

  return (
    <>
      <Head>
        <title>Transactions – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 500, width: '95%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Transactions</h1>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', margin: '24px 0 12px 0' }}>
            <button onClick={() => setFilter('all')} style={{ background: filter === 'all' ? '#3EC6E0' : '#f6fafd', color: filter === 'all' ? 'white' : '#1A4D7A', border: 'none', borderRadius: 8, padding: '8px 16px', fontWeight: 600 }}>All</button>
            <button onClick={() => setFilter('credit')} style={{ background: filter === 'credit' ? '#2ecc40' : '#f6fafd', color: filter === 'credit' ? 'white' : '#1A4D7A', border: 'none', borderRadius: 8, padding: '8px 16px', fontWeight: 600 }}>Credit</button>
            <button onClick={() => setFilter('debit')} style={{ background: filter === 'debit' ? '#e74c3c' : '#f6fafd', color: filter === 'debit' ? 'white' : '#1A4D7A', border: 'none', borderRadius: 8, padding: '8px 16px', fontWeight: 600 }}>Debit</button>
          </div>
          {loading && <p style={{ textAlign: 'center', marginTop: 24 }}>Loading...</p>}
          {error && <p style={{ color: 'red', textAlign: 'center', marginTop: 24 }}>{error}</p>}
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {filtered.map((tx: any) => (
              <li key={tx.id} style={{ marginBottom: 10, background: '#f6fafd', borderRadius: 8, padding: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 500 }}>{tx.description || tx.category}</span>
                <span style={{ color: tx.type === 'credit' ? '#2ecc40' : '#e74c3c', fontWeight: 600 }}>{tx.type === 'credit' ? '+' : '-'}₹{tx.amount}</span>
              </li>
            ))}
          </ul>
          {filtered.length === 0 && !loading && <p style={{ textAlign: 'center', marginTop: 24 }}>No transactions found.</p>}
        </div>
      </main>
    </>
  );
}
