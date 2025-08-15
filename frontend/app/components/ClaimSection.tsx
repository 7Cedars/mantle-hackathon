'use client';

import Image from 'next/image';
import { useLaw } from '@/hooks/useLaw';
import { useAccount } from 'wagmi';
import { CLAIM_LAW_ID, POWERS_ADDRESS } from '@/config/constants';
import TrackProgress from './TrackProgress';
import { useState, useEffect } from 'react';
import { useAddressCheck } from '@/hooks/useAddressCheck';

export default function ClaimSection() {
  const { address } = useAccount();
  const { status, error, executions, simulation, resetStatus, simulate, execute, fetchExecutions } = useLaw();
  const { checkAddress, analysis, status: addressCheckStatus } = useAddressCheck();
  const [hasClaimed, setHasClaimed] = useState(() => {
    // Check localStorage on component mount
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('hasClaimed');
      return saved === 'true';
    }
    return false;
  });
  
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
    setHasClaimed(true);
    // Store in localStorage
    localStorage.setItem('hasClaimed', 'true');
  };

  // Auto-check for role assignment when timer completes
  useEffect(() => {
    if (hasClaimed && address && analysis === undefined) {
      // Check if 77 minutes (4620 seconds) have elapsed since claim
      const checkTimeElapsed = () => {
        const startTime = localStorage.getItem('trackProgressStartTime');
        if (startTime) {
          const elapsed = Date.now() - parseInt(startTime);
          const seventySevenMinutes = 77 * 60 * 1000; // 77 minutes in milliseconds
          
          if (elapsed >= seventySevenMinutes) {
            console.log("Timer completed, checking for role assignment...");
            checkAddress(CLAIM_LAW_ID, POWERS_ADDRESS as `0x${string}`, address);
          }
        }
      };

      // Check immediately and then every 30 seconds
      checkTimeElapsed();
      const interval = setInterval(checkTimeElapsed, 30000);
      
      return () => clearInterval(interval);
    }
  }, [hasClaimed, address, analysis, checkAddress]);

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
            className={`w-[calc(4*theme(spacing.32)+3*theme(spacing.4))] h-[calc(4*theme(spacing.32)+3*theme(spacing.4))] rounded-full shadow-2xl transition-all duration-200 relative overflow-hidden ${
              hasClaimed 
                ? 'animate-spin-slow bg-red-500' 
                : 'hover:shadow-primary/25 hover:scale-105'
            }`}
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
      {/* Track Progress Component */}
      <TrackProgress showCountdown={hasClaimed} />

      {/* Analysis Results */}
      {analysis && (
        <div className="text-center mt-8">
          <h3 className="text-2xl font-bold text-white mb-4">
            Role Assignment Complete! 
          </h3>
          <div className="bg-gray-800 rounded-lg p-6 max-w-2xl mx-auto">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-left">
              <div>
                <span className="text-gray-400">Category:</span>
                <span className="text-white ml-2 font-semibold">{analysis.category}</span>
              </div>
              <div>
                <span className="text-gray-400">Role ID:</span>
                <span className="text-white ml-2 font-semibold">{analysis.roleId}</span>
              </div>
              <div className="md:col-span-2">
                <span className="text-gray-400">Explanation:</span>
                <p className="text-white mt-1">{analysis.explanation}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      

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
