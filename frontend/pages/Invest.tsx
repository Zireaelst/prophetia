import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, DollarSign, PieChart, AlertTriangle, ArrowUpRight, ArrowDownLeft } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';

const Invest: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [amount, setAmount] = useState<string>('');
  
  // Mock calculation
  const shareValue = 1.024;
  const estimatedLP = amount ? (parseFloat(amount) / shareValue).toFixed(4) : '0.0000';

  const poolStats = [
    { label: "Total Liquidity", value: "45,891 ALEO", icon: DollarSign },
    { label: "APY", value: "24.7%", icon: TrendingUp, color: "text-success" },
    { label: "Active Bets", value: "47", icon: PieChart },
    { label: "Win Rate", value: "73.2%", icon: TrendingUp },
  ];

  const transactions = [
    { type: 'Deposit', amount: '+500 ALEO', time: '2 mins ago', hash: '0x123...abc', status: 'Confirmed' },
    { type: 'Earnings', amount: '+12.4 ALEO', time: '4 hours ago', hash: '0x456...def', status: 'Confirmed' },
    { type: 'Withdraw', amount: '-200 ALEO', time: '1 day ago', hash: '0x789...ghi', status: 'Confirmed' },
  ];

  return (
    <div className="min-h-screen pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        
        {/* Left Column: Main Pool Interface */}
        <div className="lg:col-span-2 space-y-4">
          
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold text-white mb-1">Liquidity Pool</h1>
            <p className="text-gray-400 font-mono text-sm">Provide liquidity to ZK-ML prediction markets and earn yield.</p>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {poolStats.map((stat) => (
              <Card key={stat.label} className="p-3 flex flex-col justify-between h-20">
                <div className="flex justify-between items-start">
                  <span className="text-[10px] text-gray-400 uppercase font-mono">{stat.label}</span>
                  <stat.icon size={12} className="text-gray-500" />
                </div>
                <span className={`text-lg font-bold ${stat.color || 'text-white'}`}>{stat.value}</span>
              </Card>
            ))}
          </div>

          {/* Main Action Card */}
          <Card className="p-0 overflow-hidden">
             {/* Tabs */}
             <div className="flex border-b border-glass-border">
               <button 
                 onClick={() => setActiveTab('deposit')}
                 className={`flex-1 py-3 text-sm font-mono font-medium transition-colors ${activeTab === 'deposit' ? 'bg-primary/10 text-primary border-b-2 border-primary' : 'text-gray-400 hover:text-white hover:bg-white/5'}`}
               >
                 Deposit Liquidity
               </button>
               <button 
                 onClick={() => setActiveTab('withdraw')}
                 className={`flex-1 py-3 text-sm font-mono font-medium transition-colors ${activeTab === 'withdraw' ? 'bg-primary/10 text-primary border-b-2 border-primary' : 'text-gray-400 hover:text-white hover:bg-white/5'}`}
               >
                 Withdraw Liquidity
               </button>
             </div>

             <div className="p-6 space-y-4">
                <div className="space-y-2">
                  <label className="text-sm text-gray-400 font-mono">Amount (ALEO)</label>
                  <div className="relative">
                    <input 
                      type="number" 
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      placeholder="0.00"
                      className="w-full bg-black/40 border border-glass-border rounded-lg p-3 text-xl text-white focus:outline-none focus:border-primary transition-colors font-mono placeholder:text-gray-600"
                    />
                    <button className="absolute right-3 top-1/2 -translate-y-1/2 text-xs bg-white/10 hover:bg-white/20 px-2 py-1 rounded text-primary-glow font-mono">
                      MAX
                    </button>
                  </div>
                </div>

                <div className="bg-white/5 rounded-lg p-3 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">Exchange Rate</span>
                    <span className="font-mono text-white">1 LP = {shareValue} ALEO</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">{activeTab === 'deposit' ? 'You Receive' : 'You Burn'}</span>
                    <span className="font-mono text-primary-glow">{estimatedLP} LP Tokens</span>
                  </div>
                </div>

                <Button variant="primary" className="w-full h-12 text-base">
                  {activeTab === 'deposit' ? 'Confirm Deposit' : 'Confirm Withdraw'}
                </Button>
             </div>
          </Card>

          {/* Transactions */}
          <Card className="p-4">
             <h3 className="text-base font-bold text-white mb-3">Recent Transactions</h3>
             <div className="overflow-x-auto">
               <table className="w-full">
                 <thead>
                   <tr className="text-left border-b border-glass-border">
                     <th className="pb-2 text-[10px] text-gray-500 font-mono uppercase">Type</th>
                     <th className="pb-2 text-[10px] text-gray-500 font-mono uppercase">Amount</th>
                     <th className="pb-2 text-[10px] text-gray-500 font-mono uppercase">Time</th>
                     <th className="pb-2 text-[10px] text-gray-500 font-mono uppercase">Status</th>
                   </tr>
                 </thead>
                 <tbody className="space-y-2">
                    {transactions.map((tx, idx) => (
                      <tr key={idx} className="group text-sm">
                        <td className="py-2">
                           <div className="flex items-center gap-2">
                             {tx.type === 'Deposit' ? <ArrowDownLeft size={14} className="text-success" /> : 
                              tx.type === 'Withdraw' ? <ArrowUpRight size={14} className="text-error" /> : 
                              <TrendingUp size={14} className="text-primary" />}
                             <span className="font-medium">{tx.type}</span>
                           </div>
                        </td>
                        <td className="py-2 font-mono">{tx.amount}</td>
                        <td className="py-2 text-gray-400">{tx.time}</td>
                        <td className="py-2">
                           <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-success/10 text-success">
                             {tx.status}
                           </span>
                        </td>
                      </tr>
                    ))}
                 </tbody>
               </table>
             </div>
          </Card>

        </div>

        {/* Right Column: Sidebar Stats */}
        <div className="space-y-4">
           {/* My Position */}
           <Card className="p-4 space-y-4 relative overflow-hidden">
              <div className="absolute top-0 right-0 p-3 opacity-10">
                <PieChart size={48} />
              </div>
              <div>
                <p className="text-xs text-gray-400 font-mono mb-1">Your Balance</p>
                <h2 className="text-2xl font-bold text-white">1,468 ALEO</h2>
                <p className="text-[10px] text-success mt-0.5">≈ $3,204.50</p>
              </div>
              
              <div className="space-y-2 pt-3 border-t border-glass-border">
                 <div className="flex justify-between items-center text-sm">
                   <span className="text-gray-400">Pool Share</span>
                   <span className="font-mono text-white">3.2%</span>
                 </div>
                 <div className="flex justify-between items-center text-sm">
                   <span className="text-gray-400">Unclaimed Yield</span>
                   <span className="font-mono text-primary-glow">124.5 ALEO</span>
                 </div>
              </div>
              <Button variant="outline" size="sm" className="w-full">Claim Yield</Button>
           </Card>

           {/* Risk Warning */}
           <Card className="p-4 border-warning/20 bg-warning/5">
              <div className="flex items-center gap-2 mb-2">
                 <AlertTriangle size={16} className="text-warning" />
                 <h3 className="font-bold text-warning text-sm">Risk Warning</h3>
              </div>
              <ul className="text-[10px] text-gray-300 space-y-1 list-disc pl-3">
                <li>Impermanent loss is possible if model accuracy drops significantly.</li>
                <li>Smart contract risk: Audit pending for v2.0 contracts.</li>
                <li>Liquidity lock-up period: 24 hours after deposit.</li>
              </ul>
           </Card>

           {/* Performance Graph Placeholder */}
           <Card className="p-4">
             <h3 className="text-sm font-bold text-white mb-3">Pool Performance</h3>
             <div className="h-32 flex items-end justify-between gap-1">
                {[40, 65, 50, 80, 75, 90, 85].map((h, i) => (
                  <div key={i} className="w-full bg-primary/20 hover:bg-primary/50 transition-colors rounded-t" style={{ height: `${h}%` }}></div>
                ))}
             </div>
             <div className="flex justify-between mt-2 text-[10px] text-gray-500 font-mono">
                <span>7 Days</span>
                <span className="text-success">+4.2%</span>
             </div>
           </Card>
        </div>

      </div>
    </div>
  );
};

export default Invest;