'use client';

import { categories } from '../utils/categories';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { POWERS_ADDRESS } from '../../config/constants';

export default function HeroSection() {
  const router = useRouter();

  const handleLargeImageClick = () => {
    router.push(`https://powers-protocol.vercel.app/5003/${POWERS_ADDRESS}`);
  };

  const handleSmallImageClick = (categoryId: number) => {
    router.push(`/user-powers?category=${categoryId}`);
  };

  return (
    <section className="h-screen flex flex-col justify-center">
      <div className="max-w-7xl mx-auto px-4 sm:pt-6 lg:pt-8">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-white mb-4">
            AI x Blockchain: Powers to You
          </h1>
          <p className="text-xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
            A small set of tokenholders control governance in most on-chain organisations - including Mantle. 
            This PoC uses AI to identify different types of users based on their transaction history, not token holdings, 
            and assigns powers accordingly.
          </p>
        </div>

        {/* Images Section */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-16">
          {/* Large Image on Left */}
          <div className="lg:col-span-2">
            <div 
              className="h-[calc(4*theme(spacing.32)+3*theme(spacing.4))] rounded-2xl flex items-end justify-start relative overflow-hidden cursor-pointer group hover:shadow-xl hover:border-primary border border-transparent transition-all"
              onClick={handleLargeImageClick}
            >
              <Image
                src="/bg3.png"
                alt="User Council on Powers"
                fill
                className="object-cover"
                priority
              />
              <div className="absolute inset-0 bg-black/40 group-hover:bg-black/30 transition-colors"></div>
              <div className="text-white z-10 relative p-8">
                <h3 className="text-2xl font-bold mb-2 group-hover:text-primary transition-colors">View the User Council on Powers</h3>
                <p className="text-lg opacity-90">Discover how AI-powered governance works</p>
              </div>
            </div>
          </div>

          {/* Four Smaller Images on Right */}
          <div className="lg:col-span-1 grid grid-cols-1 gap-4">
            {categories.slice(0, 4).map((category, index) => (
              <div 
                key={category.id}
                className="bg-gray-900 rounded-xl shadow-lg border border-gray-800 hover:shadow-xl hover:border-primary transition-all cursor-pointer group h-32 relative overflow-hidden"
                onClick={() => handleSmallImageClick(category.id)}
              >
                <Image
                  src={`/bg${index + 2}.png`}
                  alt={category.title}
                  fill
                  className="object-cover opacity-20 group-hover:opacity-30 transition-opacity"
                />
                <div className="relative z-10 p-4 flex flex-col justify-end h-full">
                  <h4 className="font-semibold text-white mb-1 group-hover:text-primary transition-colors">
                    View {category.title}
                  </h4>
                  <p className="text-sm text-gray-400 line-clamp-2">
                    {category.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
        
        {/* Scroll Down Indicator */}
        <div className="flex justify-center mt-24 pt-24">
          <div>
            <svg 
              className="w-24 h-24 text-primary cursor-pointer opacity-50 hover:text-primary-light transition-colors transform rotate-180" 
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24" 
              xmlns="http://www.w3.org/2000/svg"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M5 15l7-7 7 7" 
              />
            </svg>
          </div>
        </div>
      </div>
    </section>
  );
}
