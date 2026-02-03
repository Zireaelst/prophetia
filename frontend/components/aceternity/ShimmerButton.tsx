"use client"

import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'

export function ShimmerButton({
  children,
  className,
  onClick,
}: {
  children: React.ReactNode
  className?: string
  onClick?: () => void
}) {
  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className={cn(
        'relative inline-flex overflow-hidden rounded-lg p-px focus:outline-none focus:ring-2 focus:ring-purple-400 focus:ring-offset-2 focus:ring-offset-black',
        className
      )}
      onClick={onClick}
    >
      <span className="absolute inset-[-1000%] animate-[spin_2s_linear_infinite] bg-[conic-gradient(from_90deg_at_50%_50%,#a855f7_0%,#6366f1_50%,#a855f7_100%)]" />
      <span className="inline-flex h-full w-full cursor-pointer items-center justify-center rounded-lg bg-black px-8 py-4 text-base font-semibold text-white backdrop-blur-3xl">
        {children}
      </span>
    </motion.button>
  )
}
