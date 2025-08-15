'use client';

import { useState, useEffect } from 'react';

interface ProgressStage {
  id: number;
  label: string;
  duration: number; // in minutes
  completed: boolean;
}

const TOTAL_DURATION = 72; // 1 hour and 12 minutes in minutes
const STAGES: ProgressStage[] = [
  { id: 1, label: '(mantle) claim send', duration: 0, completed: false },
  { id: 2, label: '(sepolia) AI agent received claim', duration: 36, completed: false },
  { id: 3, label: '(sepolia) AI agent send claim', duration: 5, completed: false },
  { id: 4, label: '(mantle) role assignment processed', duration: 36, completed: false },
];

interface TrackProgressProps {
  showCountdown?: boolean;
}

export default function TrackProgress({ showCountdown = false }: TrackProgressProps) {
  const [timeLeft, setTimeLeft] = useState(TOTAL_DURATION);
  const [stages, setStages] = useState(STAGES);
  const [startTime, setStartTime] = useState<number | null>(null);

  useEffect(() => {
    // Load start time from localStorage or set new one
    const savedStartTime = localStorage.getItem('trackProgressStartTime');
    const currentTime = Date.now();
    
    if (!savedStartTime) {
      // First time starting the timer
      localStorage.setItem('trackProgressStartTime', currentTime.toString());
      setStartTime(currentTime);
    } else {
      // Resume from saved time
      const start = parseInt(savedStartTime);
      setStartTime(start);
      
      // Calculate elapsed time and remaining time
      const elapsedMinutes = Math.floor((currentTime - start) / (1000 * 60));
      const remaining = Math.max(0, TOTAL_DURATION - elapsedMinutes);
      setTimeLeft(remaining);
    }
  }, []);

  useEffect(() => {
    if (startTime === null) return;

    const interval = setInterval(() => {
      const currentTime = Date.now();
      const elapsedMinutes = Math.floor((currentTime - startTime) / (1000 * 60));
      const remaining = Math.max(0, TOTAL_DURATION - elapsedMinutes);
      
      setTimeLeft(remaining);

      // Update stages based on elapsed time
      let cumulativeTime = 0;
      const updatedStages = stages.map((stage, index) => {
        if (index === 0) {
          // First stage is completed immediately
          return { ...stage, completed: true };
        }
        
        cumulativeTime += stages[index].duration;
        const completed = elapsedMinutes >= cumulativeTime;
        return { ...stage, completed };
      });
      
      setStages(updatedStages);

      // Clear interval when timer reaches 0
      if (remaining <= 0) {
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [startTime, stages]);

  const formatTime = (minutes: number): string => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    
    if (hours > 0) {
      return `${hours} hour${hours > 1 ? 's' : ''} ${mins} minute${mins !== 1 ? 's' : ''} left`;
    }
    return `${mins} minute${mins !== 1 ? 's' : ''} left`;
  };

  const getProgressPercentage = (stageIndex: number): number => {
    if (startTime === null) return 0;
    
    const currentTime = Date.now();
    const elapsedMinutes = Math.floor((currentTime - startTime) / (1000 * 60));
    
    let cumulativeTime = 0;
    for (let i = 0; i < stageIndex; i++) {
      cumulativeTime += stages[i].duration;
    }
    
    const stageStart = cumulativeTime;
    const stageEnd = cumulativeTime + stages[stageIndex].duration;
    
    if (elapsedMinutes <= stageStart) return 0;
    if (elapsedMinutes >= stageEnd) return 100;
    
    return ((elapsedMinutes - stageStart) / stages[stageIndex].duration) * 100;
  };

  return (
    <div className="w-full mt-12">
      {/* Large Countdown */}
      <div className="text-center mb-12">
        <div className="text-5xl text-primary mb-4 min-h-24">
          {showCountdown ? formatTime(timeLeft) : " "}
        </div>
      </div>

              {/* Progress Bar */}
        <div className="flex flex-row items-center justify-center">
          {stages.map((stage, index) => (
            <div key={stage.id} className="flex items-center">
            {/* Circle with label */}
            <div className="flex flex-col items-center flex-shrink-0">
              <div className="relative mb-4">
                <div 
                  className={`w-10 h-10 rounded-full border-4 transition-all duration-500 bg-black ${
                    stage.completed 
                      ? 'border-primary' 
                      : 'border-gray-600'
                  }`}
                />
                
                {/* Stage Label */}
                <div className="absolute -top-12 left-1/2 transform -translate-x-1/2 w-24">
                  <span className="text-xs text-gray-400 text-center block leading-tight">
                    {stage.label}
                  </span>
                </div>
              </div>
            </div>

            {/* Connecting line (except for last stage) */}
            {index < stages.length - 1 && (
              <div className="flex flex-col items-center mx-8 pt-4">
                <div className="w-60 h-2 bg-gray-600 rounded-full relative overflow-hidden">
                  <div 
                    className={`h-full transition-all duration-500 bg-primary`}
                    style={{ 
                      width: `${getProgressPercentage(index + 1)}%` 
                    }}
                  />
                </div>
                
                {/* Duration Label */}
                <div className="mt-2">
                  <span className="text-xs text-gray-400">
                    {stages[index + 1].duration} minute{stages[index + 1].duration !== 1 ? 's' : ''}
                  </span>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
