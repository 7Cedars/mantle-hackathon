import Navigation from './components/Navigation';
import HeroSection from './components/HeroSection';
import ClaimSection from './components/ClaimSection';

export default function Home() {
  return (
    <div className="min-h-screen bg-black snap-y snap-mandatory pt-16">
      <Navigation />
      
      <main className="snap-start">
        <HeroSection />
      </main>
      
      <main className="snap-start">
        <ClaimSection />
      </main>
    </div>
  );
}
