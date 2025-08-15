import Navigation from './components/Navigation';
import HeroSection from './components/HeroSection';
import ClaimSection from './components/ClaimSection';

export default function Home() {
  return (
    <div className="h-screen bg-black snap-y snap-mandatory overflow-y-scroll pt-16">
      <Navigation />
      
      <section className="snap-start h-screen">
        <HeroSection />
      </section>
      
      <section className="snap-start h-screen">
        <ClaimSection />
      </section>
    </div>
  );
}
