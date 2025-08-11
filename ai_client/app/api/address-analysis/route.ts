import { GoogleGenAI, Type } from '@google/genai';
import { NextRequest, NextResponse } from "next/server";
import { createAddressAnalysisMessage } from '../../utils/createMessage';
import { categories } from '../../utils/categories';

// Get API key from environment variables
const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
  throw new Error("GEMINI_API_KEY environment variable is not set");
}

const ai = new GoogleGenAI({ apiKey });

export async function POST(request: NextRequest) {
  try {
    const { address } = await request.json();

    if (!address) {
      return NextResponse.json(
        { error: "Address is required" },
        { status: 400 }
      );
    }

    // Validate Ethereum address format
    if (!/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return NextResponse.json(
        { error: "Invalid Ethereum address format" },
        { status: 400 }
      );
    }

    // Create the analysis message using the utility function
    const analysisMessage = createAddressAnalysisMessage(address as `0x${string}`);

    // Get the dynamic category range
    const categoryRange = `1-${categories.length}`;

    // Send request to Gemini model with structured output
    const response = await ai.models.generateContent({
      model: "gemini-2.5-pro",
      contents: analysisMessage,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            category: {
              type: Type.NUMBER,
              description: `The category number (${categoryRange}) that best fits the analyzed address`
            },
            explanation: {
              type: Type.STRING,
              description: "Detailed explanation of why this address falls into the chosen category"
            }
          },
          required: ["category", "explanation"],
          propertyOrdering: ["category", "explanation"]
        },
      },
    });

    return NextResponse.json({ 
      response: response.text,
      address: address
    });
  } catch (error) {
    console.error("Error calling Gemini API for address analysis:", error);
    return NextResponse.json(
      { error: "Failed to analyze address" },
      { status: 500 }
    );
  }
}
