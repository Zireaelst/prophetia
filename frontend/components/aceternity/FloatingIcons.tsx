"use client"

import { motion } from 'framer-motion'
import { Brain, Lock, TrendingUp, Zap, Shield, Eye } from 'lucide-react'

const icons = [Brain, Lock, TrendingUp, Zap, Shield, Eye]

// Generate random positions that work on both server and client
const positions = Array.from({ length: 6 }, () => ({
  x: [
    Math.random() * 100,
    Math.random() * 100,
    Math.random() * 100,
  ],
  y: [
    Math.random() * 100,
    Math.random() * 100,
    Math.random() * 100,
  ],
}))

export function FloatingIcons() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {icons.map((Icon, i) => (
        <motion.div
          key={i}
          className="absolute"
          style={{
            left: `${positions[i].x[0]}%`,
            top: `${positions[i].y[0]}%`,
          }}
          animate={{
            x: positions[i].x.map(v => `${v}vw`),
            y: positions[i].y.map(v => `${v}vh`),
          }}
          transition={{
            duration: 20 + Math.random() * 10,
            repeat: Infinity,
            ease: 'linear',
          }}
        >
          <Icon className="w-8 h-8 text-purple-500/10" />
        </motion.div>
      ))}
    </div>
  )
}
