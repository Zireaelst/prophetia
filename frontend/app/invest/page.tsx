/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Investment/Liquidity Pool Page
 * ═══════════════════════════════════════════════════════════════════════════
 * Invest in prediction pool and earn passive income
 */

'use client';

import React, { useState } from 'react';
import { Header } from '@/components/Header';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useToast } from '@/components/ui/Toast';
import { SpotlightCard, Meteors, ShimmerButton } from '@/components/aceternity';
import { ASCIIBackground } from '@/components/ASCIIEffect';
import { motion } from 'framer-motion';

interface ActiveBet {
  id: string;
  prediction_id: string;
  model_name: string;
  amount: number;
  confidence: number;
  potential_return: number;
  placed_at: string;
  status: 'active' | 'won' | 'lost';
}

interface Transaction {
  id: string;
  type: 'deposit' | 'withdraw' | 'earnings';
  amount: number;
  timestamp: string;
  status: 'completed' | 'pending';
}

export default function InvestPage() {
  const { showToast } = useToast();
  
  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [amount, setAmount] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  
  // Mock pool stats
  const [poolStats] = useState({
    total_liquidity: 45891,
    your_share: 3.2,
    your_balance: 1468,
    share_value: 1.024,
    apy: 24.7,
    total_bets_active: 47,
    win_rate: 73.2,
  });
  
  // Mock active bets
  const [activeBets] = useState<ActiveBet[]>([
    {
      id: '1',
      prediction_id: 'pred_742',
      model_name: 'Stock Price Predictor v2',
      amount: 245,
      confidence: 87,
      potential_return: 294,
      placed_at: '2024-02-03 10:23',
      status: 'active',
    },
    {
      id: '2',
      prediction_id: 'pred_739',
      model_name: 'BTC Volatility Model',
      amount: 412,
      confidence: 92,
      potential_return: 494,
      placed_at: '2024-02-03 09:15',
      status: 'active',
    },
    {
      id: '3',
      prediction_id: 'pred_735',
      model_name: 'Weather Classification',
      amount: 189,
      confidence: 78,
      potential_return: 227,
      placed_at: '2024-02-02 18:42',
      status: 'won',
    },
  ]);
  
  // Mock recent transactions
  const [transactions] = useState<Transaction[]>([
    {
      id: '1',
      type: 'earnings',
      amount: 124.3,
      timestamp: '2024-02-03 08:00',
      status: 'completed',
    },
    {
      id: '2',
      type: 'deposit',
      amount: 500,
      timestamp: '2024-02-01 14:23',
      status: 'completed',
    },
    {
      id: '3',
      type: 'withdraw',
      amount: 200,
      timestamp: '2024-01-28 10:15',
      status: 'completed',
    },
  ]);

  const handleTransaction = async () => {
    const parsedAmount = parseFloat(amount);
    
    if (!amount || isNaN(parsedAmount) || parsedAmount <= 0) {
      showToast('error', 'Please enter a valid amount');
      return;
    }
    
    if (activeTab === 'withdraw' && parsedAmount > poolStats.your_balance) {
      showToast('error', 'Insufficient balance');
      return;
    }
    
    setIsProcessing(true);
    
    try {
      // Simulate blockchain transaction
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      setAmount('');
      
      if (activeTab === 'deposit') {
        showToast('success', `Successfully deposited ${parsedAmount} ALEO to the pool!`);
      } else {
        showToast('success', `Successfully withdrew ${parsedAmount} ALEO from the pool!`);
      }
      
    } catch (error) {
      showToast('error', 'Transaction failed. Please try again.');
      console.error('Transaction error:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const calculatePotentialShares = () => {
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) return 0;
    return parsedAmount / poolStats.share_value;
  };

  return (
    <div className="min-h-screen">
      <Header />
      
      <main className="px-6 py-12 lg:px-8">
        <div className="mx-auto max-w-7xl">
          {/* Page Header */}
          <div className="mb-8">
            <h1 className="text-4xl font-bold gradient-text mb-2">
              Liquidity Pool Investment
            </h1>
            <p className="text-lg text-[var(--foreground-muted)]">
              Invest in automated prediction bets and earn passive income from successful predictions.
            </p>
          </div>
          
          {/* Pool Overview Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Total Pool Liquidity</div>
                <div className="text-2xl font-bold text-[var(--foreground)]">
                  {poolStats.total_liquidity.toLocaleString()} ALEO
                </div>
                <div className="text-xs text-[var(--color-success)] mt-1">+8.3% this month</div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Your Pool Share</div>
                <div className="text-2xl font-bold text-[var(--color-primary)]">
                  {poolStats.your_share}%
                </div>
                <div className="text-xs text-[var(--foreground-muted)] mt-1">
                  {poolStats.your_balance.toLocaleString()} ALEO
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Current APY</div>
                <div className="flex items-center gap-2">
                  <div className="text-2xl font-bold text-[var(--color-success)]">{poolStats.apy}%</div>
                  <Badge variant="success" size="sm">High</Badge>
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Win Rate</div>
                <div className="text-2xl font-bold text-[var(--foreground)]">{poolStats.win_rate}%</div>
                <div className="text-xs text-[var(--foreground-muted)] mt-1">
                  {poolStats.total_bets_active} active bets
                </div>
              </CardContent>
            </Card>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Deposit/Withdraw Section */}
            <div className="lg:col-span-2 space-y-8">
              <Card>
                <CardHeader>
                  <CardTitle>Manage Your Investment</CardTitle>
                  <CardDescription>
                    Deposit or withdraw ALEO tokens from the liquidity pool
                  </CardDescription>
                </CardHeader>
                
                <CardContent>
                  {/* Tab Buttons */}
                  <div className="flex gap-2 mb-6">
                    <Button
                      variant={activeTab === 'deposit' ? 'primary' : 'outline'}
                      onClick={() => setActiveTab('deposit')}
                      className="flex-1"
                    >
                      💰 Deposit
                    </Button>
                    <Button
                      variant={activeTab === 'withdraw' ? 'primary' : 'outline'}
                      onClick={() => setActiveTab('withdraw')}
                      className="flex-1"
                    >
                      💸 Withdraw
                    </Button>
                  </div>
                  
                  {/* Amount Input */}
                  <div className="space-y-4">
                    <Input
                      type="number"
                      label={`Amount to ${activeTab}`}
                      placeholder="0.00"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      rightIcon={<span className="text-[var(--foreground)]">ALEO</span>}
                      min="0"
                      step="0.01"
                    />
                    
                    {/* Quick Amount Buttons */}
                    <div className="flex gap-2">
                      {[100, 500, 1000].map((quickAmount) => (
                        <Button
                          key={quickAmount}
                          variant="ghost"
                          size="sm"
                          onClick={() => setAmount(quickAmount.toString())}
                        >
                          {quickAmount}
                        </Button>
                      ))}
                      {activeTab === 'withdraw' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setAmount(poolStats.your_balance.toString())}
                        >
                          Max
                        </Button>
                      )}
                    </div>
                    
                    {/* Calculation Display */}
                    {amount && parseFloat(amount) > 0 && (
                      <div className="p-4 rounded-lg bg-[var(--background-card)] border border-[var(--border)] space-y-2">
                        <div className="flex justify-between text-sm">
                          <span className="text-[var(--foreground-muted)]">
                            {activeTab === 'deposit' ? 'You will receive' : 'You will burn'}
                          </span>
                          <span className="font-semibold text-[var(--foreground)]">
                            {calculatePotentialShares().toFixed(2)} LP tokens
                          </span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-[var(--foreground-muted)]">Share value</span>
                          <span className="font-semibold text-[var(--foreground)]">
                            {poolStats.share_value} ALEO
                          </span>
                        </div>
                        {activeTab === 'deposit' && (
                          <div className="flex justify-between text-sm">
                            <span className="text-[var(--foreground-muted)]">Estimated annual return</span>
                            <span className="font-semibold text-[var(--color-success)]">
                              {(parseFloat(amount) * poolStats.apy / 100).toFixed(2)} ALEO
                            </span>
                          </div>
                        )}
                      </div>
                    )}
                    
                    {/* Action Button */}
                    <Button
                      variant="primary"
                      size="lg"
                      className="w-full"
                      onClick={handleTransaction}
                      isLoading={isProcessing}
                      disabled={isProcessing || !amount || parseFloat(amount) <= 0}
                    >
                      {isProcessing 
                        ? 'Processing...' 
                        : activeTab === 'deposit' 
                          ? 'Deposit to Pool' 
                          : 'Withdraw from Pool'
                      }
                    </Button>
                  </div>
                </CardContent>
              </Card>
              
              {/* Active Bets */}
              <Card>
                <CardHeader>
                  <CardTitle>Active Pool Bets</CardTitle>
                  <CardDescription>
                    Automated bets placed by the liquidity pool
                  </CardDescription>
                </CardHeader>
                
                <CardContent>
                  <div className="space-y-3">
                    {activeBets.map((bet) => (
                      <div
                        key={bet.id}
                        className="p-4 rounded-lg border border-[var(--border)] hover:border-[var(--color-primary)] transition-colors"
                      >
                        <div className="flex items-start justify-between mb-2">
                          <div>
                            <div className="font-medium text-[var(--foreground)]">{bet.model_name}</div>
                            <div className="text-xs text-[var(--foreground-muted)]">
                              {bet.prediction_id} • {bet.placed_at}
                            </div>
                          </div>
                          <Badge 
                            variant={
                              bet.status === 'won' ? 'success' : 
                              bet.status === 'lost' ? 'error' : 
                              'warning'
                            }
                          >
                            {bet.status}
                          </Badge>
                        </div>
                        
                        <div className="grid grid-cols-3 gap-4 text-sm">
                          <div>
                            <div className="text-[var(--foreground-muted)] text-xs">Amount</div>
                            <div className="font-semibold text-[var(--foreground)]">{bet.amount} ALEO</div>
                          </div>
                          <div>
                            <div className="text-[var(--foreground-muted)] text-xs">Confidence</div>
                            <div className="font-semibold text-[var(--color-primary)]">{bet.confidence}%</div>
                          </div>
                          <div>
                            <div className="text-[var(--foreground-muted)] text-xs">Potential Return</div>
                            <div className="font-semibold text-[var(--color-success)]">
                              {bet.potential_return} ALEO
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
            
            {/* Info Sidebar */}
            <div className="space-y-6">
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>💡 How It Works</CardTitle>
                </CardHeader>
                <CardContent>
                  <ol className="space-y-3 text-sm text-[var(--foreground-muted)]">
                    <li className="flex items-start gap-2">
                      <span className="font-bold text-[var(--color-primary)]">1.</span>
                      <span>Deposit ALEO to the liquidity pool</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="font-bold text-[var(--color-primary)]">2.</span>
                      <span>Receive LP tokens representing your share</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="font-bold text-[var(--color-primary)]">3.</span>
                      <span>Pool automatically bets on high-confidence predictions</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="font-bold text-[var(--color-primary)]">4.</span>
                      <span>Earn 20% of profits from winning bets</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="font-bold text-[var(--color-primary)]">5.</span>
                      <span>Withdraw anytime by burning LP tokens</span>
                    </li>
                  </ol>
                </CardContent>
              </Card>
              
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>📊 Pool Performance</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm text-[var(--foreground-muted)]">7-Day Return</span>
                        <span className="font-semibold text-[var(--color-success)]">+4.2%</span>
                      </div>
                      <div className="h-2 bg-[var(--background-card)] rounded-full overflow-hidden">
                        <div className="h-full w-[42%] bg-[var(--color-success)]"></div>
                      </div>
                    </div>
                    
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm text-[var(--foreground-muted)]">30-Day Return</span>
                        <span className="font-semibold text-[var(--color-success)]">+18.7%</span>
                      </div>
                      <div className="h-2 bg-[var(--background-card)] rounded-full overflow-hidden">
                        <div className="h-full w-[187%]" style={{width: '93.5%'}} className="bg-gradient-to-r from-[var(--color-success)] to-[var(--color-primary)]"></div>
                      </div>
                    </div>
                    
                    <div className="pt-2 text-xs text-[var(--foreground-muted)]">
                      Historical performance is not indicative of future results.
                    </div>
                  </div>
                </CardContent>
              </Card>
              
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>⚠️ Risk Factors</CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-2 text-sm text-[var(--foreground-muted)]">
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-error)]">•</span>
                      <span>Impermanent loss risk</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-error)]">•</span>
                      <span>Prediction accuracy variability</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-error)]">•</span>
                      <span>Smart contract risks</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-error)]">•</span>
                      <span>No guaranteed returns</span>
                    </li>
                  </ul>
                </CardContent>
              </Card>
            </div>
          </div>
          
          {/* Recent Transactions */}
          <div className="mt-12">
            <Card>
              <CardHeader>
                <CardTitle>Recent Transactions</CardTitle>
                <CardDescription>
                  Your deposit, withdrawal, and earnings history
                </CardDescription>
              </CardHeader>
              
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-[var(--border)]">
                        <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Type</th>
                        <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Amount</th>
                        <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Time</th>
                        <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {transactions.map((tx) => (
                        <tr key={tx.id} className="border-b border-[var(--border)] hover:bg-[var(--background-hover)] transition-colors">
                          <td className="py-3 px-4">
                            <Badge 
                              variant={
                                tx.type === 'earnings' ? 'success' : 
                                tx.type === 'deposit' ? 'primary' : 
                                'default'
                              }
                            >
                              {tx.type === 'earnings' ? '💰' : tx.type === 'deposit' ? '⬇️' : '⬆️'} {tx.type}
                            </Badge>
                          </td>
                          <td className="py-3 px-4">
                            <span className={`font-semibold ${
                              tx.type === 'earnings' || tx.type === 'deposit' 
                                ? 'text-[var(--color-success)]' 
                                : 'text-[var(--foreground)]'
                            }`}>
                              {tx.type === 'withdraw' ? '-' : '+'}{tx.amount} ALEO
                            </span>
                          </td>
                          <td className="py-3 px-4 text-sm text-[var(--foreground-muted)]">{tx.timestamp}</td>
                          <td className="py-3 px-4">
                            <Badge variant={tx.status === 'completed' ? 'success' : 'warning'}>
                              {tx.status}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
