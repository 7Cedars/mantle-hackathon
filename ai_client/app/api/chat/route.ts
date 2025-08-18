import { GoogleGenAI, FunctionCallingConfigMode, mcpToTool} from '@google/genai';
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { NextRequest, NextResponse } from "next/server";

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

export async function POST(request: NextRequest) {
  // Add immediate logging to confirm the route is being called
  // console.log('🚀 API ROUTE CALLED - /api/chat');
  // console.log('Request method:', request.method);
  // console.log('Request URL:', request.url);
  
  try {
    const { message } = await request.json();

    // Log the incoming request
    // console.log('=== INCOMING CHAT REQUEST ===');
    // console.log('Message:', message);
    // console.log('Timestamp:', new Date().toISOString());
    // console.log('=== END REQUEST LOG ===');

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

      // Extract the full text content from the response
      const responseText = response.candidates?.[0]?.content?.parts?.map((part: any) => part.text).join('') || response.text || 'No response generated';
      
      // Log the full response for debugging
      // console.log('=== GEMINI API RESPONSE DEBUG ===');
      // console.log('Full response object:', JSON.stringify(response, null, 2));
      // console.log('Extracted response text:', responseText);
      // console.log('Response candidates:', response.candidates);
      // console.log('Response parts:', response.candidates?.[0]?.content?.parts);
      // console.log('=== END DEBUG ===');
      
      // console.log('✅ SUCCESS: Sending response back to client');
      // console.log('Response length:', responseText.length);
      // console.log('Response preview:', responseText.substring(0, 200) + '...');
      
      return NextResponse.json({ 
        response: responseText
      });
    } finally {
      // Close the connection
      await client.close();
      console.log('🔌 MCP Client connection closed');
    }
  } catch (error) {
    // console.error("=== GEMINI API ERROR ===");
    // console.error("Error details:", error);
    // console.error("Error message:", error instanceof Error ? error.message : 'Unknown error');
    // console.error("Error stack:", error instanceof Error ? error.stack : 'No stack trace');
    // console.error("=== END ERROR LOG ===");
    
    return NextResponse.json(
      { error: "Failed to get response from Gemini" },
      { status: 500 }
    );
  }
}
