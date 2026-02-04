import React from 'react';
import { motion } from 'framer-motion';
import { 
  Activity, 
  Brain, 
  Lock, 
  TrendingUp, 
  ShieldCheck, 
  Database,
  ArrowRight
} from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Meteors from '../components/ui/Meteors';
import { StatCardProps } from '../types';

const features = [
  { icon: Lock, title: "Private Data", desc: "Encrypt datasets locally. Only ZK proofs are submitted on-chain." },
  { icon: Brain, title: "ZK-ML Models", desc: "Run inference off-chain with verifiable computation proofs." },
  { icon: ShieldCheck, title: "Verifiable Proofs", desc: "Cryptographic guarantees that model execution is honest." },
  { icon: Database, title: "Liquidity Pool", desc: "Provide liquidity to prediction markets and earn yield." },
  { icon: TrendingUp, title: "Automated Betting", desc: "Smart agents execute trades based on model confidence." },
  { icon: Activity, title: "Reputation System", desc: "On-chain track record for data scientists and providers." },
];

const stats: StatCardProps[] = [
  { label: "Total Predictions", value: "1,247", change: "+12.5%", isPositive: true },
  { label: "Pool Liquidity", value: "45,891 ALEO", change: "+8.3%", isPositive: true },
  { label: "Model Accuracy", value: "73.2%", change: "+2.1%", isPositive: true },
  { label: "Active Neurons", value: "89", change: "ZK-ML Agents", isPositive: true },
];

const Home: React.FC = () => {
  return (
    <div className="relative min-h-screen pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-8">
      
      {/* Hero Section */}
      <section className="relative text-center space-y-6 z-10 overflow-hidden rounded-3xl bg-white/[0.02] border border-white/[0.05] p-8 md:p-12">
        <div className="absolute inset-0 h-full w-full overflow-hidden">
            <Meteors number={30} />
        </div>

        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-primary/30 bg-primary/10 backdrop-blur-sm relative z-20"
        >
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-success"></span>
          </span>
          <span className="text-xs font-mono text-primary-glow font-semibold tracking-wide uppercase">Week 7 Complete - System Live</span>
        </motion.div>

        <motion.div
           initial={{ opacity: 0, scale: 0.95 }}
           animate={{ opacity: 1, scale: 1 }}
           transition={{ duration: 0.8, delay: 0.2 }}
           className="relative z-20"
        >
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight text-transparent bg-clip-text bg-gradient-to-b from-white via-white to-white/40 leading-tight">
              Divine the Future. <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-secondary">Reveal Nothing.</span>
            </h1>
            <p className="mt-4 max-w-2xl mx-auto text-base md:text-lg text-gray-400 font-mono leading-relaxed">
              The first Zero-Knowledge Prediction Market powered by decentralized Machine Learning. Train models on private data. Earn yields on accurate prophecies.
            </p>
        </motion.div>

        <motion.div 
           initial={{ opacity: 0 }}
           animate={{ opacity: 1 }}
           transition={{ duration: 0.5, delay: 0.5 }}
           className="flex flex-col sm:flex-row justify-center gap-4 relative z-20"
        >
          <Button variant="primary" size="lg" rightIcon={<ArrowRight size={18} />}>
            Explore Predictions
          </Button>
          <Button variant="outline" size="lg">
            Liquidity Mining
          </Button>
        </motion.div>
      </section>

      {/* Stats Grid */}
      <section>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2">
          {stats.map((stat, idx) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: idx * 0.1 }}
            >
              <Card className="p-4">
                <p className="text-xs font-mono text-gray-400">{stat.label}</p>
                <div className="mt-1 flex items-baseline gap-2">
                  <span className="text-2xl font-bold text-white">{stat.value}</span>
                </div>
                {stat.change && (
                   <p className={`text-xs font-mono mt-1 ${stat.isPositive ? 'text-success' : 'text-error'}`}>
                     {stat.change}
                   </p>
                )}
              </Card>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Features Grid */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
           <h2 className="text-xl font-bold text-white flex items-center gap-2">
             <span className="w-1 h-6 bg-secondary rounded-full block"></span>
             System Architecture
           </h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
          {features.map((feature, idx) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: idx * 0.1 }}
            >
              <Card className="p-4 h-full hover:bg-white/5 transition-colors group">
                <div className="w-10 h-10 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center mb-3 group-hover:bg-primary/20 group-hover:border-primary/50 transition-colors">
                  <feature.icon className="w-5 h-5 text-white group-hover:text-primary-glow" />
                </div>
                <h3 className="text-base font-semibold text-white mb-1">{feature.title}</h3>
                <p className="text-xs text-gray-400 leading-relaxed">
                  {feature.desc}
                </p>
              </Card>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Bottom CTA */}
      <section className="py-8">
         <Card className="p-8 text-center relative overflow-hidden group">
             {/* Gradient Background Animation */}
             <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary to-secondary" />
             <div className="absolute -left-10 -top-10 w-40 h-40 bg-primary/20 rounded-full blur-3xl group-hover:bg-primary/30 transition-all duration-700" />
             <div className="absolute -right-10 -bottom-10 w-40 h-40 bg-secondary/20 rounded-full blur-3xl group-hover:bg-secondary/30 transition-all duration-700" />
             
             <h2 className="text-2xl font-bold mb-4 relative z-10">Ready to Join the Network?</h2>
             <p className="text-gray-400 max-w-lg mx-auto mb-6 text-sm relative z-10">
               Start uploading data, training ZK-ML models, or providing liquidity to the prediction pool today.
             </p>
             <div className="flex justify-center gap-4 relative z-10">
               <Button variant="primary">Launch App</Button>
               <Button variant="outline">Read Docs</Button>
             </div>
         </Card>
      </section>
    </div>
  );
};

export default Home;