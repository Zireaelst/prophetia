"use client"

import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

export function Meteors({ number = 20 }: { number?: number }) {
  const [meteorStyles, setMeteorStyles] = useState<Array<React.CSSProperties>>([])

  useEffect(() => {
    const styles = [...new Array(number)].map(() => ({
      top: -5,
      left: Math.floor(Math.random() * (typeof window !== 'undefined' ? window.innerWidth : 1920)) + 'px',
      animationDelay: Math.random() * 1 + 0.2 + 's',
      animationDuration: Math.floor(Math.random() * 8 + 2) + 's',
    }))
    setMeteorStyles(styles)
  }, [number])

  return (
    <>
      {meteorStyles.map((style, idx) => (
        <span
          key={idx}
          className={cn(
            'pointer-events-none absolute left-1/2 top-1/2 h-0.5 w-0.5 rotate-[215deg] animate-meteor rounded-full bg-purple-500 shadow-[0_0_0_1px_#ffffff10]'
          )}
          style={style}
        >
          <div className="pointer-events-none absolute top-1/2 -z-10 h-px w-[50px] -translate-y-1/2 bg-linear-to-r from-purple-500 to-transparent" />
        </span>
      ))}
    </>
  )
}
