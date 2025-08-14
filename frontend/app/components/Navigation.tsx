'use client';

import Link from 'next/link';
import ConnectButton from './ConnectButton';

export default function Navigation() {
  return (
    <nav className="bg-gray-900 shadow-lg border-b border-gray-800 w-full fixed top-0 left-0 z-50">
      <div className="w-full px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo/Brand */}
          <Link 
            href="/" 
            className="text-xl font-bold text-white hover:text-primary transition-colors"
          >
            Demo: Mantle x Powers
          </Link>

          {/* Connect Button */}
          <ConnectButton />
        </div>
      </div>
    </nav>
  );
}
