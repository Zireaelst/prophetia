import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Target, TrendingUp, Award, BarChart2, ChevronDown } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { StatCardProps } from '../types';

const Predictions: React.FC = () => {
  const [filter, setFilter] = useState<'all' | 'won' | 'lost'>('all');

  const stats: StatCardProps[] = [
    { label: "Total Earnings", value: "2,847 ALEO", isPositive: true, icon: TrendingUp },
    { label: "Total Predictions", value: "342", isPositive: true, icon: Target },
    { label: "Win Rate", value: "73%", change: "+2.4%", isPositive: true, icon: BarChart2 },
    { label: "Reputation", value: "105%", change: "+4.1%", isPositive: true, icon: Award },
  ];

  const predictionData = [
    {
      id: 1,
      model: 'Stock Price Predictor v2',
      input: 'AAPL Q4 Earnings Report',
      predicted: '180.50',
      actual: '182.30',
      confidence: 87,
      status: 'won',
      profit: { data: 180, model: 180, pool: 90 },
      time: '2 hours ago'
    },
    {
      id: 2,
      model: 'BTC Volatility Model',
      input: 'Hashrate Variance Delta',
      predicted: 'High (0.85)',
      actual: 'High (0.91)',
      confidence: 94,
      status: 'won',
      profit: { data: 210, model: 210, pool: 105 },
      time: '5 hours ago'
    },
    {
      id: 3,
      model: 'Weather Classification',
      input: 'Sensor Array #42 Data',
      predicted: 'Heavy Rain',
      actual: 'Overcast',
      confidence: 65,
      status: 'lost',
      time: '1 day ago'
    },
    {
      id: 4,
      model: 'Commodity Future AI',
      input: 'Wheat Supply Chain Log',
      predicted: '$450/ton',
      actual: '$452/ton',
      confidence: 81,
      status: 'won',
      profit: { data: 120, model: 120, pool: 60 },
      time: '1 day ago'
    }
  ];

  const filteredData = filter === 'all' 
    ? predictionData 
    : predictionData.filter(p => p.status === filter);

  return (
    <div className="min-h-screen pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-3">
      
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-white mb-1">Prediction Oracle</h1>
        <p className="text-gray-400 font-mono text-sm">Real-time feed of ZK-ML outcomes. Verify the accuracy and profit distribution of the network.</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2">
        {stats.map((stat, idx) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: idx * 0.1 }}
          >
            <Card className="p-2.5 relative overflow-hidden">
               <div className="relative z-10">
                <div className="flex justify-between items-start">
                    <p className="text-xs font-mono text-gray-400">{stat.label}</p>
                    {stat.icon && <stat.icon className="text-primary w-3.5 h-3.5" />}
                </div>
                <div className="mt-0.5 flex items-baseline gap-2">
                    <span className="text-xl font-bold text-white">{stat.value}</span>
                </div>
                {stat.change && (
                    <p className={`text-[10px] font-mono mt-0.5 ${stat.isPositive ? 'text-success' : 'text-error'}`}>
                        {stat.change}
                    </p>
                )}
               </div>
            </Card>
          </motion.div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
        
        {/* Main Feed */}
        <div className="lg:col-span-2 space-y-2">
            
            {/* Filter Bar */}
            <div className="flex gap-2">
              <Button 
                variant={filter === 'all' ? 'primary' : 'outline'} 
                onClick={() => setFilter('all')}
                size="sm"
                className="py-1 px-3 text-[10px] h-7"
              >
                All
              </Button>
              <Button 
                variant={filter === 'won' ? 'primary' : 'outline'} 
                onClick={() => setFilter('won')}
                size="sm"
                className={`py-1 px-3 text-[10px] h-7 ${filter === 'won' ? 'bg-success border-success' : ''}`}
              >
                Won
              </Button>
              <Button 
                variant={filter === 'lost' ? 'primary' : 'outline'} 
                onClick={() => setFilter('lost')}
                size="sm"
                className={`py-1 px-3 text-[10px] h-7 ${filter === 'lost' ? 'bg-error border-error' : ''}`}
              >
                Lost
              </Button>
            </div>

            {/* Feed Cards */}
            <AnimatePresence mode='popLayout'>
                {filteredData.map((item) => (
                    <motion.div
                        key={item.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.98 }}
                        transition={{ duration: 0.2 }}
                    >
                        <Card className="p-0 overflow-hidden group hover:border-primary/50 transition-colors">
                            {/* Card Header */}
                            <div className="px-3 py-2 flex justify-between items-start">
                                <div>
                                    <h3 className="text-sm font-bold text-white group-hover:text-primary-glow transition-colors leading-tight">{item.model}</h3>
                                    <p className="text-[10px] text-gray-400 font-mono leading-tight mt-0.5">Input: {item.input}</p>
                                </div>
                                <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide border ${item.status === 'won' ? 'bg-success/10 text-success border-success/20' : 'bg-error/10 text-error border-error/20'}`}>
                                    {item.status}
                                </span>
                            </div>

                            {/* Data Grid */}
                            <div className="px-3 pb-2 grid grid-cols-2 md:grid-cols-4 gap-2">
                                <div>
                                    <p className="text-[10px] text-gray-500 font-mono leading-none mb-0.5">Predicted</p>
                                    <p className="text-white font-medium text-xs leading-tight">{item.predicted}</p>
                                </div>
                                <div>
                                    <p className="text-[10px] text-gray-500 font-mono leading-none mb-0.5">Actual</p>
                                    <p className="text-white font-medium text-xs leading-tight">{item.actual}</p>
                                </div>
                                <div className="col-span-2">
                                    <p className="text-[10px] text-gray-500 font-mono leading-none mb-0.5 flex justify-between">
                                        <span>Confidence</span>
                                        <span>{item.confidence}%</span>
                                    </p>
                                    <div className="w-full bg-white/10 h-1 rounded-full overflow-hidden">
                                        <div className="bg-primary h-full rounded-full" style={{ width: `${item.confidence}%` }}></div>
                                    </div>
                                </div>
                            </div>

                            {/* Profit Breakdown (Only if Won) */}
                            {item.status === 'won' && item.profit && (
                                <div className="bg-white/5 px-3 py-1.5 border-t border-glass-border">
                                    <div className="flex flex-wrap gap-x-3 gap-y-0.5 text-[10px] font-mono">
                                        <div className="flex items-center gap-1.5">
                                            <div className="w-1.5 h-1.5 rounded-full bg-purple-500"></div>
                                            <span className="text-gray-400">Data:</span>
                                            <span className="text-white">{item.profit.data}</span>
                                        </div>
                                        <div className="flex items-center gap-1.5">
                                            <div className="w-1.5 h-1.5 rounded-full bg-pink-500"></div>
                                            <span className="text-gray-400">Creator:</span>
                                            <span className="text-white">{item.profit.model}</span>
                                        </div>
                                        <div className="flex items-center gap-1.5">
                                            <div className="w-1.5 h-1.5 rounded-full bg-blue-500"></div>
                                            <span className="text-gray-400">Pool:</span>
                                            <span className="text-white">{item.profit.pool}</span>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {/* Footer */}
                            <div className="px-3 py-1 bg-black/20 text-[10px] text-gray-500 font-mono flex justify-between items-center border-t border-white/5">
                                <span>{item.time}</span>
                                <button className="hover:text-white flex items-center gap-1 transition-colors">
                                    View Proof <ChevronDown size={10} />
                                </button>
                            </div>
                        </Card>
                    </motion.div>
                ))}
            </AnimatePresence>
        </div>

        {/* Sidebar */}
        <div className="space-y-2">
            <Card className="p-2.5">
                <h3 className="font-bold text-white mb-2 text-xs uppercase tracking-wider">Profit Formula</h3>
                <div className="space-y-1">
                    <div className="flex justify-between items-center">
                        <span className="text-[10px] text-gray-300">Data Provider</span>
                        <span className="text-[10px] font-bold text-purple-400">40%</span>
                    </div>
                    <div className="w-full bg-white/10 h-0.5 rounded-full"><div className="w-[40%] bg-purple-500 h-full rounded-full"></div></div>
                    
                    <div className="flex justify-between items-center mt-1">
                        <span className="text-[10px] text-gray-300">Model Creator</span>
                        <span className="text-[10px] font-bold text-pink-400">40%</span>
                    </div>
                    <div className="w-full bg-white/10 h-0.5 rounded-full"><div className="w-[40%] bg-pink-500 h-full rounded-full"></div></div>

                    <div className="flex justify-between items-center mt-1">
                        <span className="text-[10px] text-gray-300">Liquidity Pool</span>
                        <span className="text-[10px] font-bold text-blue-400">20%</span>
                    </div>
                    <div className="w-full bg-white/10 h-0.5 rounded-full"><div className="w-[20%] bg-blue-500 h-full rounded-full"></div></div>
                </div>
            </Card>

            <Card className="p-2.5 border-success/20 bg-success/5">
                <h3 className="font-bold text-success mb-1 text-xs uppercase tracking-wider">Network Status</h3>
                <div className="grid grid-cols-2 gap-2 mt-1 text-center">
                    <div>
                        <p className="text-[10px] text-gray-400 uppercase">Avg Conf.</p>
                        <p className="text-sm font-bold text-white">82%</p>
                    </div>
                    <div>
                        <p className="text-[10px] text-gray-400 uppercase">Latency</p>
                        <p className="text-sm font-bold text-white">1.2s</p>
                    </div>
                </div>
            </Card>
        </div>

      </div>
    </div>
  );
};

export default Predictions;