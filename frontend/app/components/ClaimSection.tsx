'use client';

import Image from 'next/image';
import { useLaw } from '@/hooks/useLaw';
import { usePrivy } from '@privy-io/react-auth';
import { CLAIM_LAW_ID, POWERS_ADDRESS } from '@/config/constants';
import TrackProgress from './TrackProgress';
import { useState, useEffect } from 'react';
import { useAddressCheck } from '@/hooks/useAddressCheck';
import { categories } from '../utils/categories';

export default function ClaimSection() {
  const { user, authenticated } = usePrivy();
  const address = user?.wallet?.address as `0x${string}` | undefined;
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
    const nonce = generateRandomNonce();
    await execute(POWERS_ADDRESS as `0x${string}`, CLAIM_LAW_ID, "0x", nonce, "Request for address analysis.");
    setHasClaimed(true);
    // Store in localStorage
    localStorage.setItem('hasClaimed', 'true');
  };

  const handleOrbClick = () => {
    if (analysis) {
      // Navigate to user powers page with the assigned category
      window.location.href = `/user-powers?category=${analysis.roleId}`;
    } else {
      // If no analysis yet, trigger the claim process
      handleClaim();
    }
  };



  // Helper function to get category details
  const getCategoryDetails = (categoryId: number) => {
    return categories.find((cat: { id: number; title: string; description: string }) => cat.id === categoryId);
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
            // Call checkAddress with the correct parameters
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

  // Additional effect to trigger check when timer completes
  useEffect(() => {
    if (hasClaimed && address && analysis === undefined) {
      const startTime = localStorage.getItem('trackProgressStartTime');
      if (startTime) {
        const elapsed = Date.now() - parseInt(startTime);
        const seventySevenMinutes = 77 * 60 * 1000;
        
        // If timer has already completed, check immediately
        if (elapsed >= seventySevenMinutes) {
          checkAddress(CLAIM_LAW_ID, POWERS_ADDRESS as `0x${string}`, address);
        }
      }
    }
  }, [hasClaimed, address, analysis, checkAddress]);

  return (
    <section className="h-screen flex flex-col justify-start relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-24">
        <div className="text-center mb-12 pt-16">
          <h2 className="text-4xl font-bold text-white mb-4">
            {analysis ? 'Powers claimed!' : 'Claim Your Powers'}
          </h2>
          <p className="text-xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
            {analysis ? 'Press the orb to view your powers' : 'Press the orb to claim your powers'}
          </p>
        </div>

        {/* Circle Section */}
        <div className="flex justify-center">
          <button 
            className={`w-[calc(4*theme(spacing.32)+3*theme(spacing.4))] h-[calc(4*theme(spacing.32)+3*theme(spacing.4))] rounded-full shadow-2xl transition-all duration-200 relative overflow-hidden ${
              analysis 
                ? 'bg-green-500 hover:bg-green-400 hover:scale-105' 
                : hasClaimed 
                ? 'animate-spin-slow bg-red-500' 
                : 'hover:shadow-primary/25 hover:scale-105'
            }`}
            onClick={handleOrbClick}
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
      {/* Track Progress Component or Category Display */}
      {analysis ? (
        <div className="text-center mt-8">
          <div className="bg-black rounded-lg p-6 max-w-md mx-auto">
            <div className="text-center">
              {(() => {
                const categoryDetails = getCategoryDetails(analysis.category);
                return categoryDetails ? (
                  <div>
                    <div className="text-3xl font-bold text-primary mb-3">{categoryDetails.title}</div>
                    <div className="text-base text-gray-300 max-w-sm mx-auto">{categoryDetails.description}</div>
                  </div>
                ) : (
                  <span className="text-4xl font-bold text-primary">Category {analysis.category}</span>
                );
              })()}
            </div>
          </div>
        </div>
      ) : (
        <div className="text-center mt-8">
          <TrackProgress showCountdown={hasClaimed} />
        </div>
      )}



      

      {/* Footer */}
      <div className="absolute bottom-0 left-0 right-0 bg-gray-900 border-t border-gray-800 w-full">
        <div className="w-full px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-12 text-sm text-gray-400">
            <a 
              href="https://github.com/7Cedars/mantle-hackathon" 
              target="_blank" 
              rel="noopener noreferrer"
              className="hover:text-primary transition-colors cursor-pointer"
            >
              Github Repository
            </a>
            <span>made with ❤️ by 7cedars</span>
          </div>
        </div>
      </div>
    </section>
  );
}
