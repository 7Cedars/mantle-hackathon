import { GoogleGenAI, Type } from '@google/genai';
import { NextRequest, NextResponse } from "next/server";
import { createAddressAnalysisMessage } from '../../utils/createMessage';
import { categories } from '../../utils/categories';

// Get API key from environment variables
const apiKey = process.env.NEXT_PUBLIC_GEMINI_API_KEY;

if (!apiKey) {
  throw new Error("GEMINI_API_KEY environment variable is not set");
}

const ai = new GoogleGenAI({ apiKey });

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const address = searchParams.get('address');

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

    try {
    // Create the analysis message using the utility function (now async)
    const analysisMessage = await createAddressAnalysisMessage(address as `0x${string}`);
    console.log("ANALYSIS MESSAGE: ", analysisMessage)

    // Get the dynamic category range based on actual category IDs
    const categoryIds = categories.map(cat => cat.id).sort((a, b) => a - b);
    const categoryRange = `${categoryIds[0]}-${categoryIds[categoryIds.length - 1]}`;

    // Send request to Gemini model with structured output
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash", // gemini-2.5-pro or gemini-2.5-flash
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

      // Extract the response text and try to parse it as JSON
      const responseText = response.text || '';
      let parsedResponse;
      
      // Log the raw response for debugging
      console.log("Raw response from Gemini:", responseText);
      console.log("Response length:", responseText.length);
      
      try {
        // Check if response is empty or only whitespace
        if (!responseText || responseText.trim().length === 0) {
          throw new Error("Empty response from Gemini API");
        }
        
        // Clean the response text by removing markdown code blocks
        let cleanedText = responseText.trim();
        
        // Remove markdown code blocks if present
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText.replace(/^```json\s*/, '').replace(/\s*```$/, '');
        } else if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText.replace(/^```\s*/, '').replace(/\s*```$/, '');
        }
        
        console.log("Cleaned text:", cleanedText);
        console.log("Cleaned text length:", cleanedText.length);
        
        // Check if cleaned text is empty
        if (!cleanedText || cleanedText.trim().length === 0) {
          throw new Error("Empty response after cleaning markdown");
        }
        
        // Try to parse the cleaned response as JSON
        parsedResponse = JSON.parse(cleanedText);
      } catch (parseError) {
        console.error("Failed to parse response as JSON:", responseText);
        console.error("Parse error:", parseError);
        
        // Fallback: create a default response
        parsedResponse = {
          category: 5,
          explanation: "Unable to parse AI response. Defaulting to category 5."
        };
      }

      return NextResponse.json({ 
        response: JSON.stringify(parsedResponse),
        address: address
      });
  } catch (error) {
    console.error("Error calling Gemini API for address analysis:", error);
    const errorResponse = JSON.stringify({
      category: 5,
      explanation: "I think the user best fits category 5 (error: " + error + ")."
    });

    return NextResponse.json({ 
      response: errorResponse,
      address: address || "0x0000000000000000000000000000000000000000"
    });
  }
}
