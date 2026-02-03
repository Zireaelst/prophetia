"use client"

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Home Page with ASCII Dither Effect & Aceternity UI
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { Header } from '@/components/Header';
import { ASCIIBackground } from '@/components/ASCIIEffect';
import Link from 'next/link';
import { 
  Lock as LockIcon, 
  Brain as BrainCircuitIcon, 
  CheckCircle as CheckCircleIcon, 
  Wallet as CoinsIcon, 
  TrendingUp as TrendingUpIcon, 
  Trophy as AwardIcon 
} from 'lucide-react';

// Feature Card Component to ensure consistent sizing/alignment
function FeatureCard({ icon: Icon, title, description }: { icon: any, title: string, description: string }) {
  return (
    <div className="group relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 p-8 transition-all duration-300 hover:border-purple-500/50 hover:bg-white/10">
      <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-lg bg-purple-500/10 text-purple-400 group-hover:text-purple-300">
        <Icon className="h-6 w-6" />
      </div>
      <h3 className="mb-3 text-xl font-semibold text-white">{title}</h3>
      <p className="text-gray-400 leading-relaxed">{description}</p>
      
      {/* Hover Gradient Effect */}
      <div className="absolute -right-4 -top-4 h-24 w-24 rounded-full bg-purple-500/20 blur-2xl transition-all duration-500 group-hover:bg-purple-500/30" />
    </div>
  );
}

// Stat Card Component
function StatCard({ label, value, subtext, positive }: { label: string, value: string, subtext: string, positive: boolean }) {
  return (
    <div className="flex flex-col rounded-2xl border border-white/5 bg-white/[0.02] p-6 backdrop-blur-sm">
      <dt className="text-sm font-medium text-gray-500">{label}</dt>
      <dd className="mt-2 text-3xl font-bold tracking-tight text-white">{value}</dd>
      <dd className={`mt-1 text-sm font-medium ${positive ? 'text-emerald-400' : 'text-rose-400'}`}>
        {subtext}
      </dd>
    </div>
  );
}

export default function Home() {
  return (
    <div className="relative min-h-screen bg-black text-white selection:bg-purple-500/30">
      {/* Background Layer */}
      <ASCIIBackground />
      
      {/* Content Layer */}
      <div className="relative z-10 flex min-h-screen flex-col">
        <Header />

        <main className="flex-1">
          {/* HERO SECTION */}
          <section className="relative px-6 pt-24 pb-16 lg:px-8 lg:pt-32">
            <div className="mx-auto max-w-4xl text-center">
              {/* Status Pill */}
              <div className="mb-8 inline-flex items-center gap-2 rounded-full border border-purple-500/30 bg-purple-950/30 px-4 py-1.5 text-sm text-purple-200 backdrop-blur-md">
                <span className="relative flex h-2 w-2">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500"></span>
                </span>
                Week 7 Complete - System Live
              </div>

              {/* Main Heading */}
              <h1 className="mb-8 text-6xl font-black tracking-tight text-white sm:text-7xl lg:text-8xl">
                Divine the <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-600">Future.</span>
                <br />
                Reveal Nothing.
              </h1>

              {/* Subheading */}
              <p className="mx-auto mt-6 max-w-2xl text-lg text-gray-400 sm:text-xl leading-relaxed">
                Zero-knowledge machine learning oracle network on Aleo. 
                Generate verifiable predictions with complete privacy of data and models.
              </p>

              {/* CTA Buttons */}
              <div className="mt-10 flex items-center justify-center gap-4">
                <Link
                  href="/predictions"
                  className="group relative inline-flex items-center justify-center overflow-hidden rounded-lg bg-white px-8 py-3 font-bold text-black transition-all hover:bg-gray-200 hover:scale-105"
                >
                  <span className="mr-2">Explore Predictions</span>
                  <TrendingUpIcon className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                </Link>
                <Link
                  href="/invest"
                  className="inline-flex items-center justify-center rounded-lg border border-white/20 px-8 py-3 font-medium text-white transition-all hover:bg-white/10"
                >
                  Liquidity Mining
                </Link>
              </div>
            </div>
          </section>

          {/* METRICS SECTION */}
          <section className="border-y border-white/5 bg-black/50 backdrop-blur-sm">
            <div className="mx-auto max-w-7xl px-6 py-12 lg:px-8">
              <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
                <div className="flex flex-col rounded-2xl border border-white/5 bg-white/5 p-6 backdrop-blur-sm transition-colors hover:bg-white/10">
                  <dt className="text-sm font-medium text-gray-500">Total Predictions</dt>
                  <dd className="mt-2 text-3xl font-bold tracking-tight text-white">1,247</dd>
                  <dd className="mt-1 text-sm font-medium text-emerald-400">+12.5% this week</dd>
                </div>
                <div className="flex flex-col rounded-2xl border border-white/5 bg-white/5 p-6 backdrop-blur-sm transition-colors hover:bg-white/10">
                  <dt className="text-sm font-medium text-gray-500">Pool Liquidity</dt>
                  <dd className="mt-2 text-3xl font-bold tracking-tight text-white">45,891 ALEO</dd>
                  <dd className="mt-1 text-sm font-medium text-emerald-400">+8.3% TVL</dd>
                </div>
                <div className="flex flex-col rounded-2xl border border-white/5 bg-white/5 p-6 backdrop-blur-sm transition-colors hover:bg-white/10">
                  <dt className="text-sm font-medium text-gray-500">Model Accuracy</dt>
                  <dd className="mt-2 text-3xl font-bold tracking-tight text-white">73.2%</dd>
                  <dd className="mt-1 text-sm font-medium text-emerald-400">+2.1% performance</dd>
                </div>
                <div className="flex flex-col rounded-2xl border border-white/5 bg-white/5 p-6 backdrop-blur-sm transition-colors hover:bg-white/10">
                  <dt className="text-sm font-medium text-gray-500">Active Neurons</dt>
                  <dd className="mt-2 text-3xl font-bold tracking-tight text-white">89</dd>
                  <dd className="mt-1 text-sm font-medium text-emerald-400">ZK-ML Agents</dd>
                </div>
              </div>
            </div>
          </section>

          {/* FEATURES GRID */}
          <section className="py-24 sm:py-32">
            <div className="mx-auto max-w-7xl px-6 lg:px-8">
              <div className="mx-auto max-w-2xl text-center mb-16">
                <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
                  Decentralized Intelligence
                </h2>
                <p className="mt-4 text-lg text-gray-400">
                  Trustless infrastructure for the next generation of predictive AI.
                </p>
              </div>
              
              <div className="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
                {[
                  {
                    icon: LockIcon,
                    title: 'Private Data',
                    description: 'Upload data without revealing sensitive information. Zero-knowledge proofs ensure input privacy.',
                  },
                  {
                    icon: BrainCircuitIcon,
                    title: 'ZK-ML Models',
                    description: 'Deploy ML models on-chain. Inference runs in zero-knowledge, protecting model IP and parameters.',
                  },
                  {
                    icon: CheckCircleIcon,
                    title: 'Verifiable Proofs',
                    description: 'Cryptographic proofs guarantee computation correctness without revealing the underlying data.',
                  },
                  {
                    icon: CoinsIcon,
                    title: 'Liquidity Pool',
                    description: 'Invest in prediction markets. Share-based economics ensure fair profit distribution for stakers.',
                  },
                  {
                    icon: TrendingUpIcon,
                    title: 'Automated Betting',
                    description: 'Smart contracts execute trades based on inference confidence scores with risk management.',
                  },
                  {
                    icon: AwardIcon,
                    title: 'Reputation System',
                    description: 'Meritocratic profit sharing. High-quality model providers earn increased rewards.',
                  },
                ].map((feature) => (
                  <div key={feature.title} className="group relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 p-8 transition-all duration-300 hover:border-purple-500/50 hover:bg-white/10">
                    <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-lg bg-purple-500/10 text-purple-400 group-hover:text-purple-300">
                      <feature.icon className="h-6 w-6" />
                    </div>
                    <h3 className="mb-3 text-xl font-semibold text-white">{feature.title}</h3>
                    <p className="text-gray-400 leading-relaxed">{feature.description}</p>
                    <div className="absolute -right-4 -top-4 h-24 w-24 rounded-full bg-purple-500/20 blur-2xl transition-all duration-500 group-hover:bg-purple-500/30" />
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* BOTTOM CTA */}
          <section className="relative px-6 py-24 sm:py-32 lg:px-8">
            <div className="absolute inset-0 bg-gradient-to-t from-purple-900/10 to-transparent pointer-events-none" />
            <div className="mx-auto max-w-2xl text-center relative z-10">
              <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl mb-6">
                Ready to Join the Network?
              </h2>
              <p className="text-gray-400 mb-10 text-lg">
                Whether you're a data scientist, investor, or developer, Prophetia provides the tools for privacy-preserving AI.
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                <Link
                  href="/data"
                  className="w-full sm:w-auto rounded-lg bg-gradient-to-r from-purple-600 to-pink-600 px-8 py-3 font-semibold text-white shadow-lg hover:shadow-purple-500/25 transition-all outline-none focus:ring-2 focus:ring-purple-500 active:scale-95"
                >
                  Start Uploading
                </Link>
                <Link
                  href="/models"
                  className="w-full sm:w-auto rounded-lg border border-white/10 bg-white/5 px-8 py-3 font-semibold text-white hover:bg-white/10 transition-all"
                >
                  Deploy Model
                </Link>
              </div>
            </div>
          </section>
        </main>

        <footer className="border-t border-white/10 bg-black py-12">
          <div className="mx-auto max-w-7xl px-6 lg:px-8 flex flex-col items-center justify-between gap-6 sm:flex-row">
            <div className="flex items-center gap-2">
              <span className="text-xl">🔮</span>
              <span className="text-sm font-semibold text-white">PROPHETIA</span>
            </div>
            <p className="text-xs text-gray-500">
              © 2026 Prophetia. Built on Aleo.
            </p>
          </div>
        </footer>
      </div>
    </div>
  )
}
