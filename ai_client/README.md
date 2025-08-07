# Gemini Chat App

A simple Next.js chat application that uses Google's Gemini 2.5 Pro API.

## Setup

1. Install dependencies:
```bash
yarn install
```

2. Set up your Gemini API key:
   - Get your API key from [Google AI Studio](https://aistudio.google.com/)
   - Create a `.env.local` file in the root directory
   - Add your API key: `GEMINI_API_KEY=your_api_key_here`

3. Run the development server:
```bash
yarn dev
```

4. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Features

- Simple chat interface
- Real-time communication with Gemini 2.5 Pro
- Responsive design
- Loading states
- Error handling

## Usage

1. Type your message in the input field
2. Press Enter or click Send
3. Wait for Gemini's response
4. Continue the conversation

## Environment Variables

- `GEMINI_API_KEY`: Your Google Gemini API key (required)

## Technologies Used

- Next.js 14
- React 18
- TypeScript
- Google GenAI SDK
- CSS for styling
