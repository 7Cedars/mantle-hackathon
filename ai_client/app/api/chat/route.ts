import { GoogleGenAI, FunctionCallingConfigMode, mcpToTool} from '@google/genai';
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { NextRequest, NextResponse } from "next/server";

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

export async function POST(request: NextRequest) {
  try {
    const { message } = await request.json();

    if (!message) {
      return NextResponse.json(
        { error: "Message is required" },
        { status: 400 }
      );
    }

    // Create server parameters for Alchemy MCP server
    const serverParams = new StdioClientTransport({
      command: "npx",
      args: ["-y", "@alchemy/mcp-server@v0.1.5"],
      env: {
        ALCHEMY_API_KEY: alchemyApiKey || "",
      },
    });

    // Create MCP client
    const client = new Client({
      name: "gemini-chat-app",
      version: "1.0.0",
    });

    // Initialize the connection between client and server
    await client.connect(serverParams);

    try {
      // Send request to the model with MCP tools
      const response = await ai.models.generateContent({
        model: "gemini-2.5-pro",
        contents: message,
        config: {
          tools: [mcpToTool(client)], // uses the session, will automatically call the tool
          // Uncomment if you **don't** want the sdk to automatically call the tool
          // automaticFunctionCalling: {
          //   disable: true,
          // },
        },
      });

      return NextResponse.json({ 
        response: response.text 
      });
    } finally {
      // Close the connection
      await client.close();
    }
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    return NextResponse.json(
      { error: "Failed to get response from Gemini" },
      { status: 500 }
    );
  }
}
