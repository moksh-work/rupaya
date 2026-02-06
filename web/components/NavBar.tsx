import Link from 'next/link';
import { useRouter } from 'next/router';

const navItems = [
  { href: '/dashboard', label: 'Dashboard' },
  { href: '/transactions', label: 'Transactions' },
  { href: '/accounts', label: 'Accounts' },
  { href: '/analytics', label: 'Analytics' },
  { href: '/categories', label: 'Categories' },
  { href: '/settings', label: 'Settings' },
];

export default function NavBar() {
  const router = useRouter();
  return (
    <nav style={{
      width: '100%',
      background: '#1A4D7A',
      padding: '8px 0',
      display: 'flex',
      justifyContent: 'center',
      position: 'fixed',
      bottom: 0,
      left: 0,
      zIndex: 100,
    }}>
      <div style={{ display: 'flex', gap: 16 }}>
        {navItems.map((item) => (
          <Link key={item.href} href={item.href} legacyBehavior>
            <a style={{
              color: router.pathname === item.href ? '#3EC6E0' : '#fff',
              fontWeight: router.pathname === item.href ? 700 : 500,
              textDecoration: 'none',
              fontSize: 16,
              padding: '8px 12px',
              borderRadius: 6,
              background: router.pathname === item.href ? 'rgba(62,198,224,0.12)' : 'transparent',
              transition: 'background 0.2s',
            }}>{item.label}</a>
          </Link>
        ))}
      </div>
    </nav>
  );
}
