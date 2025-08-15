'use client';

import { categories } from '../utils/categories';
import { useSearchParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import Navigation from '../components/Navigation';

export default function UserPowersPage() {
  const searchParams = useSearchParams();
  const categoryId = searchParams.get('category');
  
  // Find the category based on the ID
  const category = categories.find(cat => cat.id.toString() === categoryId);
  
  // If category not found, show a default or error state
  if (!category) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-white mb-4">Category Not Found</h1>
          <p className="text-xl text-gray-300 mb-8">The requested user category could not be found.</p>
          <Link 
            href="/" 
            className="inline-block bg-primary hover:bg-primary-light text-white font-semibold py-3 px-6 rounded-lg transition-colors"
          >
            Return Home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black">
      <Navigation />
      
      {/* Hero Section */}
      <section className="py-16 pt-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h1 className="text-5xl font-bold text-white mb-6">
              Powers for {category.title}s
            </h1>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto leading-relaxed">
              {category.description}
            </p>
          </div>

          {/* Main Content Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-16">
            {/* Left Column - User Type Info */}
            <div className="space-y-8">
              <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700">
                <h2 className="text-2xl font-bold text-white mb-4">User Type Analysis</h2>
                <div className="space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-primary mb-2">Category</h3>
                    <p className="text-gray-300">{category.title}</p>
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-primary mb-2">Description</h3>
                    <p className="text-gray-300">{category.description}</p>
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-primary mb-2">Category ID</h3>
                    <p className="text-gray-300">{category.id}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700">
                <h2 className="text-2xl font-bold text-white mb-4">AI Analysis Process</h2>
                <p className="text-gray-300 mb-4">
                  This user type was identified through AI analysis of transaction history patterns, 
                  including frequency, types of interactions, and behavioral characteristics.
                </p>
                <div className="space-y-3">
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-primary rounded-full"></div>
                    <span className="text-gray-300">Transaction pattern analysis</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-primary rounded-full"></div>
                    <span className="text-gray-300">Behavioral classification</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-primary rounded-full"></div>
                    <span className="text-gray-300">Power assignment based on usage</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column - Powers Display */}
            <div className="space-y-8">
              <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700">
                <h2 className="text-2xl font-bold text-white mb-6">Assigned Powers</h2>
                <div className="space-y-6">
                  {/* Placeholder powers - these would be dynamic based on the category */}
                  <div className="bg-gray-700/50 rounded-xl p-6 border border-gray-600">
                    <h3 className="text-lg font-semibold text-primary mb-2">Governance Participation</h3>
                    <p className="text-gray-300 text-sm">
                      Ability to participate in governance decisions based on user type characteristics.
                    </p>
                  </div>
                  
                  <div className="bg-gray-700/50 rounded-xl p-6 border border-gray-600">
                    <h3 className="text-lg font-semibold text-primary mb-2">Voting Rights</h3>
                    <p className="text-gray-300 text-sm">
                      Specific voting mechanisms tailored to this user category's behavior patterns.
                    </p>
                  </div>
                  
                  <div className="bg-gray-700/50 rounded-xl p-6 border border-gray-600">
                    <h3 className="text-lg font-semibold text-primary mb-2">Proposal Creation</h3>
                    <p className="text-gray-300 text-sm">
                      Rights to create proposals relevant to this user type's interests and activities.
                    </p>
                  </div>
                  
                  <div className="bg-gray-700/50 rounded-xl p-6 border border-gray-600">
                    <h3 className="text-lg font-semibold text-primary mb-2">Special Privileges</h3>
                    <p className="text-gray-300 text-sm">
                      Category-specific privileges that align with user behavior and contribution patterns.
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700">
                <h2 className="text-2xl font-bold text-white mb-4">Power Distribution</h2>
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Governance Weight</span>
                    <span className="text-primary font-semibold">Variable</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Voting Power</span>
                    <span className="text-primary font-semibold">Category-based</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Proposal Rights</span>
                    <span className="text-primary font-semibold">Enabled</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Return to Main Page Button */}
          <div className="text-center">
            <Link 
              href="/" 
              className="inline-flex items-center space-x-2 bg-primary hover:bg-primary-light text-white font-semibold py-4 px-8 rounded-lg transition-colors"
            >
              <svg 
                className="w-5 h-5" 
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24" 
                xmlns="http://www.w3.org/2000/svg"
              >
                <path 
                  strokeLinecap="round" 
                  strokeLinejoin="round" 
                  strokeWidth={2} 
                  d="M10 19l-7-7m0 0l7-7m-7 7h18" 
                />
              </svg>
              <span>Return to Main Page</span>
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
