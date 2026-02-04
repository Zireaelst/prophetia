import React, { useEffect, useRef } from 'react';

const AsciiBackground: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = window.innerWidth;
    let height = window.innerHeight;
    
    // Config
    const fontSize = 14;
    const charSet = "010101XYZAJV@#$%&proph"; 
    
    // State
    let columns = Math.ceil(width / fontSize);
    // Drops stores the y-coordinate of the drop for each column
    let drops: number[] = [];
    // LightMap stores an intensity value (0-1) for each column to create "waves" or "dither"
    let lightMap: number[] = [];

    const init = () => {
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = width;
      canvas.height = height;
      columns = Math.ceil(width / fontSize);
      drops = new Array(columns).fill(1);
      lightMap = new Array(columns).fill(0);
    };

    init();

    // Mouse interaction
    let mouseX = 0;
    let mouseY = 0;

    const handleMouseMove = (e: MouseEvent) => {
      mouseX = e.clientX;
      mouseY = e.clientY;
      
      // Add light around mouse
      const col = Math.floor(mouseX / fontSize);
      const range = 4; // Affect 4 columns to left and right
      
      for(let i = -range; i <= range; i++) {
        const targetCol = col + i;
        if(targetCol >= 0 && targetCol < columns) {
           // Intensity based on distance
           lightMap[targetCol] = Math.min(lightMap[targetCol] + (0.5 - Math.abs(i) * 0.1), 1); 
        }
      }
    };

    window.addEventListener('resize', init);
    window.addEventListener('mousemove', handleMouseMove);

    const draw = () => {
      // Semi-transparent black to create trail effect
      ctx.fillStyle = 'rgba(10, 10, 10, 0.08)';
      ctx.fillRect(0, 0, width, height);

      ctx.font = `${fontSize}px "JetBrains Mono"`;

      for (let i = 0; i < drops.length; i++) {
        // Decay light
        lightMap[i] = Math.max(0, lightMap[i] - 0.02);

        // Determine color based on light intensity
        const isHighlighted = lightMap[i] > 0.3;
        const isMouseNear = Math.abs(i * fontSize - mouseX) < 100 && Math.abs(drops[i] * fontSize - mouseY) < 100;

        if (isMouseNear || isHighlighted) {
           ctx.fillStyle = '#ec4899'; // Cyber Pink
        } else {
           ctx.fillStyle = '#333333'; // Dark Grey for background noise
           if (Math.random() > 0.98) ctx.fillStyle = '#9333ea'; // Occasional Purple
        }

        const text = charSet[Math.floor(Math.random() * charSet.length)];
        
        // Randomly skip drawing to create "dither" noise look instead of solid lines
        if(Math.random() > 0.6 || isHighlighted) {
            ctx.fillText(text, i * fontSize, drops[i] * fontSize);
        }

        // Reset drop to top randomly or if it goes off screen
        if (drops[i] * fontSize > height && Math.random() > 0.975) {
          drops[i] = 0;
        }

        drops[i]++;
      }

      requestAnimationFrame(draw);
    };

    const animationId = requestAnimationFrame(draw);

    return () => {
      window.removeEventListener('resize', init);
      window.removeEventListener('mousemove', handleMouseMove);
      cancelAnimationFrame(animationId);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed top-0 left-0 w-full h-full pointer-events-none z-0 opacity-40 mix-blend-screen"
    />
  );
};

export default AsciiBackground;