Gemini API quickstart

This quickstart shows you how to install our libraries and make your first Gemini API request.

Before you begin
You need a Gemini API key. If you don't already have one, you can get it for free in Google AI Studio.

Install the Google GenAI SDK
Python
JavaScript
Go
Java
Apps Script
Using Node.js v18+, install the Google Gen AI SDK for TypeScript and JavaScript using the following npm command:


npm install @google/genai
Make your first request
Here is an example that uses the generateContent method to send a request to the Gemini API using the Gemini 2.5 Flash model.

If you set your API key as the environment variable GEMINI_API_KEY, it will be picked up automatically by the client when using the Gemini API libraries. Otherwise you will need to pass your API key as an argument when initializing the client.

Note that all code samples in the Gemini API docs assume that you have set the environment variable GEMINI_API_KEY.

Python
JavaScript
Go
Java
Apps Script
REST

import { GoogleGenAI } from "@google/genai";

// The client gets the API key from the environment variable `GEMINI_API_KEY`.
const ai = new GoogleGenAI({});

async function main() {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: "Explain how AI works in a few words",
  });
  console.log(response.text);
}

main();
"Thinking" is on by default on many of our code samples
Many code samples on this site use the Gemini 2.5 Flash model, which has the "thinking" feature enabled by default to enhance response quality. You should be aware that this may increase response time and token usage. If you prioritize speed or wish to minimize costs, you can disable this feature by setting the thinking budget to zero, as shown in the examples below. For more details, see the thinking guide.

Note: Thinking is only available on Gemini 2.5 series models and can't be disabled on Gemini 2.5 Pro.
Python
JavaScript
Go
REST
Apps Script

import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

async function main() {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: "Explain how AI works in a few words",
    config: {
      thinkingConfig: {
        thinkingBudget: 0, // Disables thinking
      },
    }
  });
  console.log(response.text);
}

await main();
What's next
Now that you made your first API request, you might want to explore the following guides that show Gemini in action:

Thinking
Text generation
Vision
Long context
Embeddings