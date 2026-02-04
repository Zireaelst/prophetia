import React from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { 
  Activity, 
  Zap, 
  Database, 
  TrendingUp, 
  Bell, 
  ArrowRight, 
  Cpu, 
  Wallet, 
  Clock,
  ShieldCheck
} from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';

const Dashboard: React.FC = () => {
  const containerVariants = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0 }
  };

  const recentActivity = [
    { type: 'reward', message: 'Received payout for Model v2 prediction', time: '10 mins ago', amount: '+45 ALEO' },
    { type: 'system', message: 'Dataset "Weather_Global_24" verification complete', time: '2 hours ago', status: 'Verified' },
    { type: 'alert', message: 'Model accuracy dropped below 80% threshold', time: '5 hours ago', status: 'Warning' },
    { type: 'tx', message: 'Liquidity provided to ETH-USDC pool', time: '1 day ago', amount: '500 LP' },
  ];

  return (
    <div className="min-h-screen pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-4">
      
      {/* Welcome Section */}
      <div className="flex flex-col md:flex-row justify-between items-end md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white mb-1">Command Center</h1>
          <p className="text-gray-400 font-mono text-sm flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-success animate-pulse"></span>
            System Online • Agent 0x71...8A3
          </p>
        </div>
        <Button variant="outline" size="sm" leftIcon={<Clock size={14} />}>
          Sync Network
        </Button>
      </div>

      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="show"
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2"
      >
        {/* Main Stat Cards */}
        <motion.div variants={itemVariants} className="lg:col-span-2">
           <Card className="p-6 h-full bg-gradient-to-br from-primary/10 to-transparent border-primary/20">
              <div className="flex justify-between items-start mb-8">
                 <div>
                    <p className="text-gray-400 font-mono text-sm mb-1">Total Net Earnings</p>
                    <h2 className="text-4xl font-bold text-white">12,847 ALEO</h2>
                 </div>
                 <div className="p-3 bg-primary/20 rounded-lg">
                    <Wallet className="text-primary w-6 h-6" />
                 </div>
              </div>
              <div className="w-full bg-white/5 h-24 rounded-lg flex items-end justify-between px-2 pb-2 gap-1">
                  {[30, 45, 35, 60, 50, 75, 65, 80, 70, 90, 85, 100].map((h, i) => (
                      <div 
                        key={i} 
                        className="w-full bg-primary/40 hover:bg-primary transition-colors rounded-t-sm" 
                        style={{ height: `${h}%` }} 
                      />
                  ))}
              </div>
           </Card>
        </motion.div>

        <motion.div variants={itemVariants}>
           <Card className="p-6 h-full flex flex-col justify-between">
              <div className="flex justify-between items-start">
                 <p className="text-gray-400 font-mono text-sm">Reputation</p>
                 <ShieldCheck className="text-success w-5 h-5" />
              </div>
              <div className="mt-4 text-center">
                 <div className="relative inline-flex items-center justify-center">
                    <svg className="w-24 h-24 transform -rotate-90">
                       <circle className="text-white/10" strokeWidth="8" stroke="currentColor" fill="transparent" r="40" cx="48" cy="48" />
                       <circle className="text-success" strokeWidth="8" strokeDasharray={251.2} strokeDashoffset={251.2 * (1 - 0.98)} strokeLinecap="round" stroke="currentColor" fill="transparent" r="40" cx="48" cy="48" />
                    </svg>
                    <span className="absolute text-2xl font-bold text-white">98</span>
                 </div>
                 <p className="text-xs text-gray-500 mt-2 font-mono">Top 2% of Agents</p>
              </div>
           </Card>
        </motion.div>

        <motion.div variants={itemVariants} className="grid grid-rows-2 gap-2">
           <Card className="p-4 flex items-center justify-between">
              <div>
                 <p className="text-gray-400 text-xs font-mono uppercase">Active Models</p>
                 <p className="text-xl font-bold text-white">3 Running</p>
              </div>
              <Cpu className="text-secondary w-5 h-5" />
           </Card>
           <Card className="p-4 flex items-center justify-between">
              <div>
                 <p className="text-gray-400 text-xs font-mono uppercase">Pool Share</p>
                 <p className="text-xl font-bold text-white">3.2%</p>
              </div>
              <Activity className="text-blue-500 w-5 h-5" />
           </Card>
        </motion.div>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
         
         {/* Notifications / Activity Feed */}
         <motion.div 
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 }}
            className="lg:col-span-2 space-y-4"
         >
            <div className="flex items-center justify-between">
               <h3 className="text-lg font-bold text-white flex items-center gap-2">
                  <Bell size={18} />
                  System Activity
               </h3>
               <Button variant="ghost" size="sm" className="text-xs">View All</Button>
            </div>

            <div className="space-y-2">
               {recentActivity.map((activity, idx) => (
                  <Card 
                    key={idx} 
                    className={`p-3 flex items-center gap-4 transition-all duration-300 ${
                        activity.type === 'reward' ? 'bg-success/10 border-success/20 hover:bg-success/15' :
                        activity.type === 'alert' ? 'bg-error/10 border-error/20 hover:bg-error/15' :
                        activity.type === 'tx' ? 'bg-blue-500/10 border-blue-500/20 hover:bg-blue-500/15' :
                        'bg-white/5 border-white/10 hover:bg-white/10'
                    }`}
                  >
                     <div className={`p-2 rounded-full ${
                        activity.type === 'reward' ? 'bg-success/20 text-success' :
                        activity.type === 'alert' ? 'bg-error/20 text-error' :
                        activity.type === 'tx' ? 'bg-blue-500/20 text-blue-500' :
                        'bg-white/10 text-gray-400'
                     }`}>
                        {activity.type === 'reward' ? <Zap size={16} /> :
                         activity.type === 'alert' ? <Activity size={16} /> :
                         activity.type === 'tx' ? <Wallet size={16} /> :
                         <Database size={16} />}
                     </div>
                     <div className="flex-1">
                        <p className="text-white text-sm font-medium">{activity.message}</p>
                        <p className="text-gray-500 text-xs font-mono mt-0.5">{activity.time}</p>
                     </div>
                     {(activity.amount || activity.status) && (
                        <div className="text-right">
                           {activity.amount && (
                               <p className={`font-mono text-sm ${
                                   activity.type === 'reward' ? 'text-primary-glow' : 
                                   activity.type === 'tx' ? 'text-primary-glow' : 'text-white'
                               }`}>
                                   {activity.amount}
                               </p>
                           )}
                           {activity.status && (
                              <span className={`text-[10px] px-2 py-0.5 rounded border ${
                                 activity.status === 'Warning' ? 'border-error/30 text-error bg-error/10' : 'border-success/30 text-success bg-success/10'
                              }`}>
                                 {activity.status}
                              </span>
                           )}
                        </div>
                     )}
                  </Card>
               ))}
            </div>
         </motion.div>

         {/* Quick Actions */}
         <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.5 }}
            className="space-y-2"
         >
            <h3 className="text-lg font-bold text-white mb-2">Quick Actions</h3>
            
            <Link to="/data">
               <Card className="p-3 group hover:bg-white/5 transition-all cursor-pointer border-l-4 border-l-transparent hover:border-l-primary mb-2">
                  <div className="flex justify-between items-center mb-1">
                     <Database className="text-gray-400 group-hover:text-primary transition-colors" size={18} />
                     <ArrowRight size={14} className="text-gray-600 group-hover:text-white -translate-x-2 opacity-0 group-hover:opacity-100 group-hover:translate-x-0 transition-all" />
                  </div>
                  <h4 className="font-bold text-white text-sm">Upload Dataset</h4>
                  <p className="text-xs text-gray-500 mt-0.5">Monetize your private data.</p>
               </Card>
            </Link>

            <Link to="/models">
               <Card className="p-3 group hover:bg-white/5 transition-all cursor-pointer border-l-4 border-l-transparent hover:border-l-secondary mb-2">
                  <div className="flex justify-between items-center mb-1">
                     <Cpu className="text-gray-400 group-hover:text-secondary transition-colors" size={18} />
                     <ArrowRight size={14} className="text-gray-600 group-hover:text-white -translate-x-2 opacity-0 group-hover:opacity-100 group-hover:translate-x-0 transition-all" />
                  </div>
                  <h4 className="font-bold text-white text-sm">Deploy Model</h4>
                  <p className="text-xs text-gray-500 mt-0.5">Launch ZK-ML inference agents.</p>
               </Card>
            </Link>

            <Link to="/invest">
               <Card className="p-3 group hover:bg-white/5 transition-all cursor-pointer border-l-4 border-l-transparent hover:border-l-blue-500">
                  <div className="flex justify-between items-center mb-1">
                     <TrendingUp className="text-gray-400 group-hover:text-blue-500 transition-colors" size={18} />
                     <ArrowRight size={14} className="text-gray-600 group-hover:text-white -translate-x-2 opacity-0 group-hover:opacity-100 group-hover:translate-x-0 transition-all" />
                  </div>
                  <h4 className="font-bold text-white text-sm">Manage Liquidity</h4>
                  <p className="text-xs text-gray-500 mt-0.5">Check APY and withdraw yields.</p>
               </Card>
            </Link>
         </motion.div>

      </div>
    </div>
  );
};

export default Dashboard;