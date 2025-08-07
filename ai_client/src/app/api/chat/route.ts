import { NextRequest, NextResponse } from 'next/server';
import { generateResponse, ChatSession } from '@/lib/gemini';

export async function POST(request: NextRequest) {
  try {
    const { message, history } = await request.json();

    if (!message || typeof message !== 'string') {
      return NextResponse.json(
        { error: 'Message is required and must be a string' },
        { status: 400 }
      );
    }

    // Create a chat session with history
    const chatSession = new ChatSession();
    if (history && Array.isArray(history)) {
      history.forEach((msg: { role: 'user' | 'assistant'; content: string }) => {
        chatSession.addMessage(msg.role, msg.content);
      });
    }

    // Generate response
    const response = await generateResponse(message, chatSession);

    return NextResponse.json({
      response,
      history: chatSession.getHistory(),
    });

  } catch (error) {
    console.error('Chat API error:', error);
    return NextResponse.json(
      { error: 'Failed to generate response' },
      { status: 500 }
    );
  }
} 