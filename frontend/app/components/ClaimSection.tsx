'use client';

import Image from 'next/image';
import { useLaw } from '@/hooks/useLaw';
import { useAccount } from 'wagmi';
import { CLAIM_LAW_ID, POWERS_ADDRESS } from '@/config/constants';

export default function ClaimSection() {
  const { address } = useAccount();
  const { status, error, executions, simulation, resetStatus, simulate, execute, fetchExecutions } = useLaw();
  
  // Function to generate a random nonce between 1 and 999999999
  const generateRandomNonce = (): bigint => {
    const min = 1;
    const max = 999999999;
    const randomNumber = Math.floor(Math.random() * (max - min + 1)) + min;
    return BigInt(randomNumber);
  };

  const handleClaim = async () => {
    console.log("handleClaim");
    const nonce = generateRandomNonce();
    console.log("nonce", nonce);
    await execute(POWERS_ADDRESS as `0x${string}`, CLAIM_LAW_ID, "0x", nonce, "Request for address analysis.");
    console.log("executed");
  };

  return (
    <section className="h-screen flex flex-col justify-start relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-24">
        <div className="text-center mb-12 pt-16">
          <h2 className="text-4xl font-bold text-white mb-4">
            Claim Your Powers
          </h2>
          <p className="text-xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
            Press the orb to claim your powers
          </p>
        </div>

        {/* Circle Section */}
        <div className="flex justify-center">
          <button 
            className="w-[calc(4*theme(spacing.32)+3*theme(spacing.4))] h-[calc(4*theme(spacing.32)+3*theme(spacing.4))] rounded-full shadow-2xl hover:shadow-primary/25 transform hover:scale-105 transition-all duration-200 relative overflow-hidden"
            onClick={handleClaim}
          >
            <Image
              src="/bg-circular.png"
              alt="Circular background"
              fill
              className="object-cover rounded-full"
            />
          </button>
        </div>
      </div>

      {/* Footer */}
      <div className="absolute bottom-0 left-0 right-0 bg-gray-900 border-t border-gray-800 w-full">
        <div className="w-full px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-12 text-sm text-gray-400">
            <span className="hover:text-primary transition-colors cursor-pointer">Github Repository</span>
            <span>made with ❤️ by 7cedars</span>
          </div>
        </div>
      </div>
    </section>
  );
}
