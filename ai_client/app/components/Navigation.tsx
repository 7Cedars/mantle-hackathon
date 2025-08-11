'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function Navigation() {
  const pathname = usePathname();

  return (
    <nav className="navigation">
      <div className="nav-container">
        <div className="nav-brand">
          <Link href="/" className="nav-logo">
            Gemini & Alchemy
          </Link>
        </div>
        
        <div className="nav-links">
          <Link 
            href="/" 
            className={`nav-link ${pathname === '/' ? 'active' : ''}`}
          >
            Chat
          </Link>
          <Link 
            href="/address-analysis" 
            className={`nav-link ${pathname === '/address-analysis' ? 'active' : ''}`}
          >
            Address Analysis
          </Link>
        </div>
      </div>
    </nav>
  );
}
