import React from 'react';
import { motion } from 'framer-motion';
import { Cpu, Zap, Activity, Box, Terminal } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { StatCardProps } from '../types';

const Models: React.FC = () => {
  const stats: StatCardProps[] = [
    { label: "Deployed Models", value: "5", isPositive: true, icon: Box },
    { label: "Total Predictions", value: "1,247", isPositive: true, icon: Zap },
    { label: "Reputation", value: "92%", isPositive: true, icon: Activity },
    { label: "Total Earnings", value: "8,234 ALEO", isPositive: true, icon: Cpu },
  ];

  const models = [
    { name: 'Stock Price Predictor v2', algo: 'Linear Regression', accuracy: '87.3%', predictions: 342, earnings: '2,847' },
    { name: 'BTC Volatility Model', algo: 'Logistic Regression', accuracy: '91.2%', predictions: 521, earnings: '4,123' },
    { name: 'Weather Classification', algo: 'Decision Tree', accuracy: '84.1%', predictions: 189, earnings: '1,264' },
  ];

  return (
    <div className="min-h-screen pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-4">
      
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-white mb-1">Model Foundry</h1>
        <p className="text-gray-400 font-mono text-sm">Deploy ZK-ML models to the network. Smart contracts automatically route prediction requests to the highest performing models.</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2">
        {stats.map((stat, idx) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: idx * 0.1 }}
          >
            <Card className="p-4">
              <div className="flex justify-between items-start">
                 <p className="text-xs font-mono text-gray-400">{stat.label}</p>
                 {stat.icon && <stat.icon className="text-secondary w-4 h-4" />}
              </div>
              <div className="mt-1">
                <span className="text-2xl font-bold text-white">{stat.value}</span>
              </div>
            </Card>
          </motion.div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        
        {/* Main Deployment Form */}
        <div className="lg:col-span-2 space-y-4">
          <Card className="p-6">
             <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-primary/10 rounded-lg border border-primary/20">
                   <Terminal size={18} className="text-primary" />
                </div>
                <h3 className="text-lg font-bold text-white">Deploy New Model</h3>
             </div>

             <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="col-span-1 md:col-span-2 space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Model Name</label>
                   <input type="text" placeholder="e.g. ETH Price Predictor v1" className="w-full bg-black/40 border border-glass-border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm" />
                </div>
                
                <div className="space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Algorithm</label>
                   <select className="w-full bg-black/40 border border-glass-border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm">
                      <option>Linear Regression</option>
                      <option>Logistic Regression</option>
                      <option>Decision Tree</option>
                      <option>Neural Network (Simple)</option>
                   </select>
                </div>

                <div className="space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Input Features Count</label>
                   <input type="number" placeholder="Number of inputs" className="w-full bg-black/40 border border-glass-border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm" />
                </div>

                <div className="col-span-1 md:col-span-2 space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Weights (Comma Separated)</label>
                   <input type="text" placeholder="0.23, -0.5, 1.2, ..." className="w-full bg-black/40 border border-glass-border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm" />
                   <p className="text-[10px] text-gray-500">Provide initial weights for the model initialization.</p>
                </div>

                <div className="space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Bias</label>
                   <input type="number" placeholder="0.00" className="w-full bg-black/40 border border-glass-border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm" />
                </div>
             </div>

             <div className="mt-6 flex gap-3">
               <Button variant="primary" className="flex-1">Deploy Model</Button>
               <Button variant="outline">Reset</Button>
             </div>
          </Card>

          {/* Active Models Table */}
          <Card className="p-0 overflow-hidden">
             <div className="p-4 border-b border-glass-border">
                <h3 className="font-bold text-white text-sm">Active Deployments</h3>
             </div>
             <div className="overflow-x-auto">
               <table className="w-full text-sm">
                 <thead className="bg-white/5 font-mono text-gray-400">
                   <tr>
                     <th className="px-4 py-2 text-left text-xs">Model Name</th>
                     <th className="px-4 py-2 text-left text-xs">Algorithm</th>
                     <th className="px-4 py-2 text-left text-xs">Accuracy</th>
                     <th className="px-4 py-2 text-left text-xs">Predictions</th>
                     <th className="px-4 py-2 text-left text-xs">Earnings</th>
                   </tr>
                 </thead>
                 <tbody className="divide-y divide-glass-border">
                   {models.map((m, i) => (
                     <tr key={i} className="group hover:bg-white/5 transition-colors">
                       <td className="px-4 py-3 font-medium text-white text-xs">{m.name}</td>
                       <td className="px-4 py-3 text-gray-400 text-xs">{m.algo}</td>
                       <td className="px-4 py-3 font-mono text-success text-xs">{m.accuracy}</td>
                       <td className="px-4 py-3 font-mono text-white text-xs">{m.predictions}</td>
                       <td className="px-4 py-3 font-mono text-primary-glow text-xs">{m.earnings} ALEO</td>
                     </tr>
                   ))}
                 </tbody>
               </table>
             </div>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-4">
           <Card className="p-4 bg-gradient-to-b from-primary/10 to-transparent border-primary/20">
              <h3 className="font-bold text-white mb-3 text-sm">Why ZK-ML?</h3>
              <ul className="space-y-2">
                {[
                  "Privacy-Preserving Inference", 
                  "Verifiable Computation", 
                  "Decentralized Execution", 
                  "Model Ownership via NFTs"
                ].map((item, i) => (
                  <li key={i} className="flex gap-2 items-center text-xs text-gray-300">
                    <CheckCircle size={14} className="text-primary" />
                    {item}
                  </li>
                ))}
              </ul>
           </Card>

           <Card className="p-4">
              <h3 className="font-bold text-white mb-3 text-sm">Supported Algorithms</h3>
              <div className="flex flex-wrap gap-2">
                 {['Linear Reg', 'Logistic Reg', 'Decision Tree', 'SVM', 'Naive Bayes', 'K-Means'].map(tag => (
                   <span key={tag} className="px-2 py-0.5 rounded-full bg-white/5 text-[10px] text-gray-400 border border-white/10">
                     {tag}
                   </span>
                 ))}
              </div>
           </Card>
        </div>

      </div>
    </div>
  );
};

// Helper component for list items
const CheckCircle = ({ size, className }: { size: number, className: string }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    className={className}
  >
    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
    <polyline points="22 4 12 14.01 9 11.01" />
  </svg>
);

export default Models;