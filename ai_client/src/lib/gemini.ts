import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize the Gemini API client
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GEMINI_API_KEY!);

// Create a model instance for Gemini 2.5 Pro
export const geminiModel = genAI.getGenerativeModel({
  model: 'gemini-2.0-flash-exp',
  generationConfig: {
    temperature: 0.7,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 8192,
  },
});

// Interface for chat message
export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

// Chat history management
export class ChatSession {
  private history: ChatMessage[] = [];

  addMessage(role: 'user' | 'assistant', content: string) {
    this.history.push({
      role,
      content,
      timestamp: new Date(),
    });
  }

  getHistory(): ChatMessage[] {
    return [...this.history];
  }

  clearHistory() {
    this.history = [];
  }

  // Convert chat history to Gemini format
  toGeminiFormat() {
    return this.history.map(msg => ({
      role: msg.role,
      parts: [{ text: msg.content }],
    }));
  }
}

// Main function to generate response
export async function generateResponse(
  prompt: string,
  chatSession: ChatSession
): Promise<string> {
  try {
    // Add user message to history
    chatSession.addMessage('user', prompt);

    // Create chat session with Gemini
    const chat = geminiModel.startChat({
      history: chatSession.toGeminiFormat().slice(0, -1), // Exclude the last message
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      },
    });

    // Generate response
    const result = await chat.sendMessage(prompt);
    const response = await result.response;
    const responseText = response.text();

    // Add assistant response to history
    chatSession.addMessage('assistant', responseText);

    return responseText;
  } catch (error) {
    console.error('Error generating response:', error);
    throw new Error('Failed to generate response from Gemini');
  }
}

// Utility function to check if API key is configured
export function isGeminiConfigured(): boolean {
  return !!process.env.GOOGLE_GEMINI_API_KEY && 
         process.env.GOOGLE_GEMINI_API_KEY !== 'your_gemini_api_key_here';
} 