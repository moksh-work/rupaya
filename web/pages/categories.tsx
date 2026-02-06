import Head from 'next/head';
import { useEffect, useState } from 'react';
import { getCategories } from '../utils/api';

export default function Categories() {
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getCategories()
      .then(setCategories)
      .catch(e => setError(e.message || 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <Head>
        <title>Categories – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 500, width: '95%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Categories</h1>
          {loading && <p style={{ textAlign: 'center', marginTop: 24 }}>Loading...</p>}
          {error && <p style={{ color: 'red', textAlign: 'center', marginTop: 24 }}>{error}</p>}
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {categories.map((cat: any) => (
              <li key={cat.id || cat.category} style={{ marginBottom: 10, background: '#f6fafd', borderRadius: 8, padding: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 500 }}>{cat.category}</span>
                <span style={{ color: '#3EC6E0', fontWeight: 600 }}>₹{cat.totalSpent}</span>
              </li>
            ))}
          </ul>
          {categories.length === 0 && !loading && <p style={{ textAlign: 'center', marginTop: 24 }}>No categories found.</p>}
        </div>
      </main>
    </>
  );
}
