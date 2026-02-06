import Head from 'next/head';

export default function Home() {
  return (
    <>
      <Head>
        <title>Rupaya – Modern Finance App</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="description" content="Rupaya: Modern, secure, and mobile-first finance app for everyone." />
      </Head>
      <main style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #3EC6E0 0%, #1A4D7A 100%)' }}>
        <div style={{ background: 'white', borderRadius: 24, padding: 32, boxShadow: '0 8px 32px rgba(0,0,0,0.12)', maxWidth: 400, width: '90%' }}>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 24 }}>
            <svg width="96" height="96" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <radialGradient id="bg" cx="50%" cy="50%" r="80%">
                  <stop offset="0%" stopColor="#3EC6E0"/>
                  <stop offset="100%" stopColor="#1A4D7A"/>
                </radialGradient>
              </defs>
              <rect width="1024" height="1024" rx="220" fill="url(#bg)"/>
              <text x="50%" y="58%" textAnchor="middle" fontSize="600" fontFamily="Arial, Helvetica, sans-serif" fill="#fff" fontWeight="bold" dominantBaseline="middle">₹</text>
            </svg>
          </div>
          <h1 style={{ textAlign: 'center', color: '#1A4D7A', fontWeight: 700, fontSize: 32, margin: 0 }}>Rupaya</h1>
          <p style={{ textAlign: 'center', color: '#333', margin: '16px 0 0 0' }}>
            Modern, secure, and mobile-first finance app for everyone.<br />
            <span style={{ color: '#3EC6E0', fontWeight: 500 }}>Now on Web, iOS, and Android.</span>
          </p>
          <div style={{ marginTop: 32, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <a href="/dashboard" style={{ background: '#1A4D7A', color: 'white', borderRadius: 8, padding: '12px 0', textAlign: 'center', textDecoration: 'none', fontWeight: 600, fontSize: 18 }}>Get Started</a>
            <a href="/analytics" style={{ color: '#1A4D7A', textAlign: 'center', textDecoration: 'underline', fontWeight: 500 }}>Learn More</a>
          </div>
        </div>
      </main>
    </>
  );
}
