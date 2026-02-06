import Head from 'next/head';

export default function Authentication() {
  return (
    <>
      <Head>
        <title>Authentication – Rupaya</title>
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 400, width: '90%' }}>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 28, margin: 0 }}>Authentication</h1>
          <p style={{ marginTop: 24, textAlign: 'center' }}>
            Please login or sign up to continue.
          </p>
        </div>
      </main>
    </>
  );
}
