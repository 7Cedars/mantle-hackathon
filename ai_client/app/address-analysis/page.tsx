'use client';

import { useState } from 'react';
import { categories } from '../utils/categories';

export default function AddressAnalysis() {
  const [address, setAddress] = useState('');

  const handleAddressChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    // Only allow valid Ethereum address format
    if (value === '' || /^0x[a-fA-F0-9]*$/.test(value)) {
      setAddress(value);
    }
  };

  return (
    <div className="address-analysis-container">
      <h1 style={{ textAlign: 'center', marginBottom: '30px' }}>
        Address Analysis
      </h1>
      
      <div className="categories-grid">
        {categories.map((category) => (
          <div key={category.id} className="category-box">
            <div className="category-number">{category.id}</div>
            <h3 className="category-title">{category.title}</h3>
            <p className="category-description">{category.description}</p>
          </div>
        ))}
      </div>

      <div className="address-input-section">
        <div className="input-container">
          <input
            type="text"
            value={address}
            onChange={handleAddressChange}
            placeholder="Enter Ethereum address (0x...)"
            className="address-input"
            maxLength={42}
          />
          <button 
            className="analyze-button"
            disabled={!address || address.length < 42}
          >
            Analyze Address
          </button>
        </div>
        <p className="input-hint">
          Enter a valid Ethereum address starting with 0x followed by 40 hexadecimal characters
        </p>
      </div>
    </div>
  );
}
