import Head from 'next/head';

export default function Settings() {
  return (
    <>
      <Head>
        <title>Settings – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 400, width: '90%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Settings</h1>
          <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <label style={{ fontWeight: 500 }}>
              <span style={{ marginRight: 8 }}>Dark Mode</span>
              <input type="checkbox" />
            </label>
            <label style={{ fontWeight: 500 }}>
              <span style={{ marginRight: 8 }}>Notifications</span>
              <input type="checkbox" />
            </label>
            <button style={{ background: '#1A4D7A', color: 'white', borderRadius: 8, padding: '12px 0', fontWeight: 600, fontSize: 16, border: 'none', marginTop: 16 }}>Save Settings</button>
          </div>
        </div>
      </main>
    </>
  );
}
