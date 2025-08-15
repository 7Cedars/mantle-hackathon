import { GoogleGenAI, Type, mcpToTool} from '@google/genai';
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { NextRequest, NextResponse } from "next/server";
import { createAddressAnalysisMessage } from '../../utils/createMessage';
import { categories } from '../../utils/categories';

// Get API key from environment variables
const apiKey = process.env.GEMINI_API_KEY;
const alchemyApiKey = process.env.ALCHEMY_API_KEY;

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
    // const serverParams = new StdioClientTransport({
    //   command: "npx",
    //   args: ["-y", "@alchemy/mcp-server@v0.1.5"],
    //   env: {
    //     ALCHEMY_API_KEY: alchemyApiKey || "",
    //   },
    // });

    // Create MCP client
    const client = new Client({
      name: "gemini-address-analysis-app",
      version: "1.0.0",
    });

    // Initialize the connection between client and server
    // await client.connect(serverParams);

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
          // tools: [mcpToTool(client)], // uses the session, will automatically call the tool
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
    } finally {
      // Close the connection
      await client.close();
    }
  } catch (error) {
    console.error("Error calling Gemini API for address analysis:", error);
    const errorResponse = JSON.stringify({
      category: 9,
      explanation: "Error calling Gemini API for address analysis"
    });

    return NextResponse.json({ 
      response: errorResponse,
      address: address || "0x0000000000000000000000000000000000000000"
    });
  }
}
