Model context protocol (MCP)
Model Context Protocol (MCP) is an open standard for connecting AI applications with external tools and data. MCP provides a common protocol for models to access context, such as functions (tools), data sources (resources), or predefined prompts.

The Gemini SDKs have built-in support for the MCP, reducing boilerplate code and offering automatic tool calling for MCP tools. When the model generates an MCP tool call, the Python and JavaScript client SDK can automatically execute the MCP tool and send the response back to the model in a subsequent request, continuing this loop until no more tool calls are made by the model.

Here, you can find an example of how to use a local MCP server with Gemini and mcp SDK.

Python
JavaScript
Make sure the latest version of the mcp SDK is installed on your platform of choice.


npm install @modelcontextprotocol/sdk
Note: JavaScript supports automatic tool calling by wrapping the client with mcpToTool. If you want to disable it, you can provide automaticFunctionCalling with disabled true.

import { GoogleGenAI, FunctionCallingConfigMode , mcpToTool} from '@google/genai';
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

// Create server parameters for stdio connection
const serverParams = new StdioClientTransport({
  command: "npx", // Executable
  args: ["-y", "@philschmid/weather-mcp"] // MCP Server
});

const client = new Client(
  {
    name: "example-client",
    version: "1.0.0"
  }
);

// Configure the client
const ai = new GoogleGenAI({});

// Initialize the connection between client and server
await client.connect(serverParams);

// Send request to the model with MCP tools
const response = await ai.models.generateContent({
  model: "gemini-2.5-flash",
  contents: `What is the weather in London in ${new Date().toLocaleDateString()}?`,
  config: {
    tools: [mcpToTool(client)],  // uses the session, will automatically call the tool
    // Uncomment if you **don't** want the sdk to automatically call the tool
    // automaticFunctionCalling: {
    //   disable: true,
    // },
  },
});
console.log(response.text)

// Close the connection
await client.close();
Limitations with built-in MCP support
Built-in MCP support is a experimental feature in our SDKs and has the following limitations:

Only tools are supported, not resources nor prompts
It is available for the Python and JavaScript/TypeScript SDK.
Breaking changes might occur in future releases.
Manual integration of MCP servers is always an option if these limit what you're building.

Supported models
This section lists models and their function calling capabilities. Experimental models are not included. You can find a comprehensive capabilities overview on the model overview page.

Model	Function Calling	Parallel Function Calling	Compositional Function Calling
Gemini 2.5 Pro	✔️	✔️	✔️
Gemini 2.5 Flash	✔️	✔️	✔️
Gemini 2.5 Flash-Lite	✔️	✔️	✔️
Gemini 2.0 Flash	✔️	✔️	✔️
Gemini 2.0 Flash-Lite	X	X	X
Best practices
Function and Parameter Descriptions: Be extremely clear and specific in your descriptions. The model relies on these to choose the correct function and provide appropriate arguments.
Naming: Use descriptive function names (without spaces, periods, or dashes).
Strong Typing: Use specific types (integer, string, enum) for parameters to reduce errors. If a parameter has a limited set of valid values, use an enum.
Tool Selection: While the model can use an arbitrary number of tools, providing too many can increase the risk of selecting an incorrect or suboptimal tool. For best results, aim to provide only the relevant tools for the context or task, ideally keeping the active set to a maximum of 10-20. Consider dynamic tool selection based on conversation context if you have a large total number of tools.
Prompt Engineering:
Provide context: Tell the model its role (e.g., "You are a helpful weather assistant.").
Give instructions: Specify how and when to use functions (e.g., "Don't guess dates; always use a future date for forecasts.").
Encourage clarification: Instruct the model to ask clarifying questions if needed.
Temperature: Use a low temperature (e.g., 0) for more deterministic and reliable function calls.
Validation: If a function call has significant consequences (e.g., placing an order), validate the call with the user before executing it.
Error Handling: Implement robust error handling in your functions to gracefully handle unexpected inputs or API failures. Return informative error messages that the model can use to generate helpful responses to the user.
Security: Be mindful of security when calling external APIs. Use appropriate authentication and authorization mechanisms. Avoid exposing sensitive data in function calls.
Token Limits: Function descriptions and parameters count towards your input token limit. If you're hitting token limits, consider limiting the number of functions or the length of the descriptions, break down complex tasks into smaller, more focused function sets.
Notes and limitations
Only a subset of the OpenAPI schema is supported.
Supported parameter types in Python are limited.
Automatic function calling is a Python SDK feature only.