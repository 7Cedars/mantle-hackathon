/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#5faaa6',
        secondary: '#4ade80',
        accent: '#22c55e',
        'primary-dark': '#4a8a87',
        'primary-light': '#7bc4c0',
      },
      animation: {
        'spin-slow': 'spin 60s linear infinite',
      },
    },
  },
  plugins: [],
}
