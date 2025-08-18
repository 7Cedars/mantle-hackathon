import { GoogleGenAI, Type, mcpToTool} from '@google/genai';
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { NextRequest, NextResponse } from "next/server";
import { createAddressAnalysisMessage } from '../../utils/createMessage';
import { categories } from '../../utils/categories';

// Get API key from environment variables
const apiKey = process.env.NEXT_PUBLIC_GEMINI_API_KEY;
const alchemyApiKey = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;

if (!apiKey) {
  throw new Error("GEMINI_API_KEY environment variable is not set");
}

if (!alchemyApiKey) {
  throw new Error("ALCHEMY_API_KEY environment variable is not set");
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

    // Create server parameters for Alchemy MCP server
    const serverParams = new StdioClientTransport({
      command: "npx",
      args: ["-y", "@alchemy/mcp-server@v0.1.5"],
      env: {
        ALCHEMY_API_KEY: alchemyApiKey || "",
      },
    });

    // Create MCP client with timeout
    const client = new Client({
      name: "gemini-address-analysis-app",
      version: "1.0.0",
    });

    // Set connection timeout for Vercel
    const connectionTimeout = setTimeout(() => {
      console.error("MCP connection timeout");
      throw new Error("MCP connection timeout - serverless environment may be too slow");
    }, 15000); // 15 seconds

    // Initialize the connection between client and server
    try {
      await client.connect(serverParams);
      console.log("MCP client connected successfully");
    } catch (connectionError) {
      console.error("Failed to connect MCP client:", connectionError);
      throw new Error(`MCP connection failed: ${connectionError}`);
    }

    try {
      // Create the analysis message using the utility function
      const analysisMessage = createAddressAnalysisMessage(address as `0x${string}`);

      // Get the dynamic category range
      const categoryRange = `1-${categories.length}`;

      // Send request to Gemini model with structured output and MCP tools
      const response = await ai.models.generateContent({
        model: "gemini-2.5-pro",
        contents: analysisMessage,
        config: {
          tools: [mcpToTool(client)], // uses the session, will automatically call the tool
          // responseMimeType: "application/json",
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
      // console.log("Raw response from Gemini:", responseText);
      // console.log("Response length:", responseText.length);
      
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
        
        // console.log("Cleaned text:", cleanedText);
        // console.log("Cleaned text length:", cleanedText.length);
        
        // Check if cleaned text is empty
        if (!cleanedText || cleanedText.trim().length === 0) {
          throw new Error("Empty response after cleaning markdown");
        }
        
        // Try to parse the cleaned response as JSON
        parsedResponse = JSON.parse(cleanedText);
      } catch (parseError) {
        // console.error("Failed to parse response as JSON:", responseText);
        // console.error("Parse error:", parseError);
        
        // Fallback: create a default response
        parsedResponse = {
          category: 5,
          explanation: "Unable to parse AI response. Defaulting to category 5."
        };
        
        // Try to extract category from the response text if it's not empty
        if (responseText && responseText.trim().length > 0) {
          // Look for category numbers in the text
          const categoryMatch = responseText.match(/category["\s]*:["\s]*(\d+)/i);
          if (categoryMatch) {
            const categoryNum = parseInt(categoryMatch[1]);
            if (categoryNum >= 1 && categoryNum <= categories.length) {
              parsedResponse.category = categoryNum;
              parsedResponse.explanation = "Category extracted from response text.";
            }
          }
        }
      }

      return NextResponse.json({ 
        response: JSON.stringify(parsedResponse),
        address: address
      });
    } finally {
      // Clear timeout and close the connection
      clearTimeout(connectionTimeout);
      try {
        await client.close();
        console.log("MCP client closed successfully");
      } catch (closeError) {
        console.error("Error closing MCP client:", closeError);
      }
    }
  } catch (error) {
    console.error("Error calling Gemini API for address analysis:", error);
    const errorResponse = JSON.stringify({
      category: 5,
      explanation: "I think the user best fits category 5 (mcp error: " + error + ")."
    });

    return NextResponse.json({ 
      response: errorResponse,
      address: address || "0x0000000000000000000000000000000000000000"
    });
  }
}
