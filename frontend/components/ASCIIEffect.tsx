"use client"

import { useEffect, useRef } from 'react'

const ASCII_CHARS = ['@', '#', 'S', '%', '?', '*', '+', ';', ':', ',', '.', ' ']

export function ASCIIEffect() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const asciiRef = useRef<HTMLPreElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    const asciiContainer = asciiRef.current
    if (!canvas || !asciiContainer) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    // Create a simple pattern
    const width = 80
    const height = 40
    canvas.width = width
    canvas.height = height

    let animationFrame: number

    const animate = () => {
      // Clear
      ctx.fillStyle = '#000000'
      ctx.fillRect(0, 0, width, height)

      // Draw animated pattern (crystal ball / oracle effect)
      const time = Date.now() / 1000
      const centerX = width / 2
      const centerY = height / 2

      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const dx = x - centerX
          const dy = y - centerY
          const distance = Math.sqrt(dx * dx + dy * dy)
          const angle = Math.atan2(dy, dx)
          
          // Create wave effect
          const wave = Math.sin(distance * 0.5 - time * 2) * Math.cos(angle * 3 + time)
          const brightness = (wave + 1) / 2
          
          ctx.fillStyle = `rgb(${brightness * 100}, ${brightness * 80}, ${brightness * 255})`
          ctx.fillRect(x, y, 1, 1)
        }
      }

      // Convert to ASCII
      const imageData = ctx.getImageData(0, 0, width, height)
      let ascii = ''
      
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const i = (y * width + x) * 4
          const brightness = (imageData.data[i] + imageData.data[i + 1] + imageData.data[i + 2]) / 3
          const charIndex = Math.floor((brightness / 255) * (ASCII_CHARS.length - 1))
          ascii += ASCII_CHARS[charIndex]
        }
        ascii += '\n'
      }

      asciiContainer.textContent = ascii

      animationFrame = requestAnimationFrame(animate)
    }

    animate()

    return () => {
      cancelAnimationFrame(animationFrame)
    }
  }, [])

  return (
    <div className="fixed inset-0 pointer-events-none z-0 opacity-20">
      <canvas ref={canvasRef} className="hidden" />
      <pre
        ref={asciiRef}
        className="text-[4px] leading-[4px] text-purple-500/30 font-mono whitespace-pre overflow-hidden"
        style={{ letterSpacing: '0px' }}
      />
    </div>
  )
}

export function ASCIIBackground() {
  return (
    <div className="fixed inset-0 pointer-events-none z-0">
      <div className="absolute inset-0 bg-linear-to-b from-black via-purple-950/20 to-black" />
      <ASCIIEffect />
    </div>
  )
}
