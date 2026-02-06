import Head from 'next/head';
import Link from 'next/link';
import { useState } from 'react';
import { login as loginApi } from '../utils/api';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await loginApi(email, password);
      // Store token, redirect, etc.
      alert('Login successful!');
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <Head>
        <title>Login – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 400, width: '90%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Login</h1>
          <form onSubmit={handleSubmit} style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <input type="email" placeholder="Email" required value={email} onChange={e => setEmail(e.target.value)} style={{ padding: 12, borderRadius: 8, border: '1px solid #ccc' }} />
            <input type="password" placeholder="Password" required value={password} onChange={e => setPassword(e.target.value)} style={{ padding: 12, borderRadius: 8, border: '1px solid #ccc' }} />
            <button type="submit" disabled={loading} style={{ background: '#1A4D7A', color: 'white', borderRadius: 8, padding: '12px 0', fontWeight: 600, fontSize: 16, border: 'none' }}>{loading ? 'Logging in...' : 'Login'}</button>
          </form>
          {error && <div style={{ color: 'red', marginTop: 12, textAlign: 'center' }}>{error}</div>}
          <div style={{ marginTop: 16, textAlign: 'center' }}>
            <span>Don't have an account? </span>
            <Link href="/signup" style={{ color: '#3EC6E0', fontWeight: 500 }}>Sign up</Link>
          </div>
        </div>
      </main>
    </>
  );
}
