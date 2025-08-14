'use client';

import { useState } from 'react';
import { categories } from '../utils/categories';

interface AnalysisResult {
  category: number;
  explanation: string;
  address: string;
}

export default function AddressAnalysis() {
  const [address, setAddress] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleAddressChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    // Only allow valid Ethereum address format
    if (value === '' || /^0x[a-fA-F0-9]*$/.test(value)) {
      setAddress(value);
    }
  };

  const handleAnalyze = async () => {
    if (!address || address.length < 42) return;

    setIsAnalyzing(true);
    setError(null);
    setAnalysisResult(null);

    console.log("Address:", address);
    console.log("Encoded Address:", encodeURIComponent(address))

    try {
      const response = await fetch(`/api/address-analysis?address=${encodeURIComponent(address)}`, {
        method: 'GET',
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to analyze address');
      }

      const result = await response.json();
      console.log("Result:", result);
      
      // Parse the structured response from Gemini
      let parsedResponse;
      try {
        parsedResponse = JSON.parse(result.response);
      } catch (parseError) {
        throw new Error('Invalid response format from AI model: ' + parseError);
      }

      // Create the analysis result with the parsed data
      const analysisResult: AnalysisResult = {
        category: parsedResponse.category,
        explanation: parsedResponse.explanation,
        address: result.address
      };

      setAnalysisResult(analysisResult);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setIsAnalyzing(false);
    }
  };

  const getCategoryInfo = (categoryNumber: number) => {
    return categories.find(cat => cat.id === categoryNumber);
  };

  return (
    <div className="address-analysis-container">
      <h1 style={{ textAlign: 'center', marginBottom: '30px' }}>
        Address Analysis
      </h1>
      
      <div className="categories-grid">
        {categories.map((category) => (
          <div 
            key={category.id} 
            className="category-box"
            style={{
              border: analysisResult && analysisResult.category === category.id ? '3px solid #007bff' : '1px solid #ccc',
              backgroundColor: analysisResult && analysisResult.category === category.id ? '#e3f2fd' : 'transparent',
              transform: analysisResult && analysisResult.category === category.id ? 'scale(1.02)' : 'scale(1)',
              transition: 'all 0.2s ease-in-out'
            }}
          >
            <div className="category-number">{category.id}</div>
            <h3 className="category-title">{category.title}</h3>
            <p className="category-description">{category.description}</p>
          </div>
        ))}
      </div>

      <div className="explanation-section" style={{ marginBottom: '30px' }}>
        <h3 style={{ marginBottom: '15px', textAlign: 'center' }}>Model Explanation</h3>
        <div
          className="explanation-display"
          style={{
            width: '100%',
            minHeight: '100px',
            padding: '12px',
            border: '1px solid #ccc',
            borderRadius: '8px',
            backgroundColor: analysisResult ? '#ffffff' : '#f9f9f9',
            fontFamily: 'inherit',
            fontSize: '14px',
            display: 'flex',
            alignItems: analysisResult ? 'flex-start' : 'center',
            justifyContent: analysisResult ? 'flex-start' : 'center',
            color: analysisResult ? '#000' : '#666',
            whiteSpace: 'pre-wrap'
          }}
        >
          {analysisResult ? (
            analysisResult.explanation
          ) : (
            <em>Explanation will appear here after analysis...</em>
          )}
        </div>
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
            disabled={!address || address.length < 42 || isAnalyzing}
            onClick={handleAnalyze}
          >
            {isAnalyzing ? 'Analyzing...' : 'Analyze Address'}
          </button>
        </div>
        <p className="input-hint">
          Enter a valid Ethereum address starting with 0x followed by 40 hexadecimal characters
        </p>
      </div>

      {error && (
        <div className="error-message" style={{ color: 'red', textAlign: 'center', marginTop: '20px' }}>
          {error}
        </div>
      )}
    </div>
  );
}
