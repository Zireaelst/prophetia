/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Predictions Page
 * ═══════════════════════════════════════════════════════════════════════════
 * View live ZK-ML predictions and profit distributions
 */

'use client';

import React, { useState } from 'react';
import { Header } from '@/components/Header';
import { Button } from '@/components/ui/Button';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useToast } from '@/components/ui/Toast';
import { SpotlightCard, Meteors, ShimmerButton } from '@/components/aceternity';
import { ASCIIBackground } from '@/components/ASCIIEffect';
import { motion } from 'framer-motion';
import { TrendingUp, Activity, Award, DollarSign, Brain, CheckCircle2, XCircle, Clock } from 'lucide-react';

interface Prediction {
  id: string;
  model_name: string;
  model_creator: string;
  data_provider: string;
  prediction_value: number;
  confidence: number;
  timestamp: string;
  status: 'pending' | 'won' | 'lost';
  pool_bet_amount: number;
  profit_distributed?: {
    data_provider_share: number;
    model_creator_share: number;
    pool_share: number;
    total_profit: number;
  };
}

interface ProfitStats {
  total_earnings: number;
  predictions_contributed: number;
  win_rate: number;
  reputation: number;
  role: 'data_provider' | 'model_creator' | 'investor' | 'all';
}

export default function PredictionsPage() {
  const { showToast } = useToast();
  
  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'won' | 'lost'>('all');
  const [selectedPrediction, setSelectedPrediction] = useState<Prediction | null>(null);
  
  // Mock profit stats
  const [profitStats] = useState<ProfitStats>({
    total_earnings: 12847,
    predictions_contributed: 247,
    win_rate: 78.3,
    reputation: 87,
    role: 'all',
  });
  
  // Mock predictions feed
  const [predictions] = useState<Prediction[]>([
    {
      id: 'pred_742',
      model_name: 'Stock Price Predictor v2',
      model_creator: 'aleo1creator...7x8y',
      data_provider: 'aleo1provider...3a4b',
      prediction_value: 187.42,
      confidence: 87,
      timestamp: '2024-02-03 10:23',
      status: 'pending',
      pool_bet_amount: 245,
    },
    {
      id: 'pred_739',
      model_name: 'BTC Volatility Model',
      model_creator: 'aleo1creator...9z1w',
      data_provider: 'aleo1provider...5c6d',
      prediction_value: 1,
      confidence: 92,
      timestamp: '2024-02-03 09:15',
      status: 'won',
      pool_bet_amount: 412,
      profit_distributed: {
        data_provider_share: 184.8,
        model_creator_share: 184.8,
        pool_share: 92.4,
        total_profit: 462,
      },
    },
    {
      id: 'pred_735',
      model_name: 'Weather Classification',
      model_creator: 'aleo1creator...2h3j',
      data_provider: 'aleo1provider...8k9l',
      prediction_value: 0,
      confidence: 78,
      timestamp: '2024-02-02 18:42',
      status: 'won',
      pool_bet_amount: 189,
      profit_distributed: {
        data_provider_share: 84.6,
        model_creator_share: 84.6,
        pool_share: 42.3,
        total_profit: 211.5,
      },
    },
    {
      id: 'pred_728',
      model_name: 'Stock Price Predictor v2',
      model_creator: 'aleo1creator...7x8y',
      data_provider: 'aleo1provider...3a4b',
      prediction_value: 142.18,
      confidence: 65,
      timestamp: '2024-02-02 14:10',
      status: 'lost',
      pool_bet_amount: 87,
    },
    {
      id: 'pred_724',
      model_name: 'Commodity Forecaster',
      model_creator: 'aleo1creator...4m5n',
      data_provider: 'aleo1provider...6p7q',
      prediction_value: 89.32,
      confidence: 91,
      timestamp: '2024-02-02 11:05',
      status: 'won',
      pool_bet_amount: 324,
      profit_distributed: {
        data_provider_share: 153.7,
        model_creator_share: 153.7,
        pool_share: 76.9,
        total_profit: 384.3,
      },
    },
  ]);

  const filteredPredictions = predictions.filter(
    (pred) => filterStatus === 'all' || pred.status === filterStatus
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'won':
        return 'success';
      case 'lost':
        return 'error';
      case 'pending':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 85) return 'text-[var(--color-success)]';
    if (confidence >= 70) return 'text-[var(--color-primary)]';
    return 'text-yellow-500';
  };

  return (
    <div className="min-h-screen">
      <Header />
      
      <main className="px-6 py-12 lg:px-8">
        <div className="mx-auto max-w-7xl">
          {/* Page Header */}
          <div className="mb-8">
            <h1 className="text-4xl font-bold gradient-text mb-2">
              Live Predictions
            </h1>
            <p className="text-lg text-[var(--foreground-muted)]">
              Zero-knowledge ML predictions with verifiable accuracy and transparent profit distribution.
            </p>
          </div>
          
          {/* Profit Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Total Earnings</div>
                <div className="text-2xl font-bold text-[var(--color-success)]">
                  {profitStats.total_earnings.toLocaleString()} ALEO
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Predictions</div>
                <div className="text-2xl font-bold text-[var(--foreground)]">
                  {profitStats.predictions_contributed}
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Win Rate</div>
                <div className="flex items-center gap-2">
                  <div className="text-2xl font-bold text-[var(--foreground)]">{profitStats.win_rate}%</div>
                  <Badge variant="success" size="sm">+4.1%</Badge>
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Reputation</div>
                <div className="text-2xl font-bold text-[var(--color-primary)]">
                  {profitStats.reputation}%
                </div>
              </CardContent>
            </Card>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Predictions Feed */}
            <div className="lg:col-span-2 space-y-6">
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Prediction Feed</CardTitle>
                      <CardDescription>
                        Real-time ZK-ML inference results
                      </CardDescription>
                    </div>
                    
                    {/* Filter Buttons */}
                    <div className="flex gap-2">
                      {(['all', 'pending', 'won', 'lost'] as const).map((status) => (
                        <Button
                          key={status}
                          variant={filterStatus === status ? 'primary' : 'ghost'}
                          size="sm"
                          onClick={() => setFilterStatus(status)}
                        >
                          {status.charAt(0).toUpperCase() + status.slice(1)}
                        </Button>
                      ))}
                    </div>
                  </div>
                </CardHeader>
                
                <CardContent>
                  <div className="space-y-4">
                    {filteredPredictions.map((prediction) => (
                      <div
                        key={prediction.id}
                        className="p-4 rounded-lg border border-[var(--border)] hover:border-[var(--color-primary)] transition-all cursor-pointer"
                        onClick={() => setSelectedPrediction(prediction)}
                      >
                        {/* Header */}
                        <div className="flex items-start justify-between mb-3">
                          <div>
                            <div className="font-semibold text-[var(--foreground)] mb-1">
                              {prediction.model_name}
                            </div>
                            <div className="text-xs text-[var(--foreground-muted)]">
                              {prediction.id} • {prediction.timestamp}
                            </div>
                          </div>
                          <Badge variant={getStatusColor(prediction.status)}>
                            {prediction.status}
                          </Badge>
                        </div>
                        
                        {/* Prediction Value & Confidence */}
                        <div className="grid grid-cols-2 gap-4 mb-3">
                          <div>
                            <div className="text-xs text-[var(--foreground-muted)] mb-1">Prediction</div>
                            <div className="text-lg font-bold text-[var(--foreground)]">
                              {prediction.prediction_value}
                            </div>
                          </div>
                          <div>
                            <div className="text-xs text-[var(--foreground-muted)] mb-1">Confidence</div>
                            <div className={`text-lg font-bold ${getConfidenceColor(prediction.confidence)}`}>
                              {prediction.confidence}%
                            </div>
                          </div>
                        </div>
                        
                        {/* Contributors */}
                        <div className="grid grid-cols-2 gap-4 text-xs mb-3">
                          <div>
                            <div className="text-[var(--foreground-muted)]">Data Provider</div>
                            <div className="font-mono text-[var(--foreground)]">
                              {prediction.data_provider.slice(0, 15)}...
                            </div>
                          </div>
                          <div>
                            <div className="text-[var(--foreground-muted)]">Model Creator</div>
                            <div className="font-mono text-[var(--foreground)]">
                              {prediction.model_creator.slice(0, 15)}...
                            </div>
                          </div>
                        </div>
                        
                        {/* Pool Bet */}
                        <div className="flex items-center justify-between pt-3 border-t border-[var(--border)]">
                          <span className="text-sm text-[var(--foreground-muted)]">Pool Bet Amount</span>
                          <span className="font-semibold text-[var(--foreground)]">
                            {prediction.pool_bet_amount} ALEO
                          </span>
                        </div>
                        
                        {/* Profit Distribution (if won) */}
                        {prediction.profit_distributed && (
                          <div className="mt-3 p-3 rounded-lg bg-[var(--color-success)]/10 border border-[var(--color-success)]/20">
                            <div className="text-xs font-semibold text-[var(--color-success)] mb-2">
                              💰 Profit Distributed: {prediction.profit_distributed.total_profit} ALEO
                            </div>
                            <div className="grid grid-cols-3 gap-2 text-xs">
                              <div>
                                <div className="text-[var(--foreground-muted)]">Data (40%)</div>
                                <div className="font-semibold text-[var(--foreground)]">
                                  {prediction.profit_distributed.data_provider_share} ALEO
                                </div>
                              </div>
                              <div>
                                <div className="text-[var(--foreground-muted)]">Model (40%)</div>
                                <div className="font-semibold text-[var(--foreground)]">
                                  {prediction.profit_distributed.model_creator_share} ALEO
                                </div>
                              </div>
                              <div>
                                <div className="text-[var(--foreground-muted)]">Pool (20%)</div>
                                <div className="font-semibold text-[var(--foreground)]">
                                  {prediction.profit_distributed.pool_share} ALEO
                                </div>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
            
            {/* Info Sidebar */}
            <div className="space-y-6">
              {/* Selected Prediction Details */}
              {selectedPrediction ? (
                <Card variant="glow">
                  <CardHeader>
                    <CardTitle>Prediction Details</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <div className="text-sm text-[var(--foreground-muted)] mb-1">Prediction ID</div>
                      <div className="font-mono text-xs text-[var(--foreground)]">
                        {selectedPrediction.id}
                      </div>
                    </div>
                    
                    <div>
                      <div className="text-sm text-[var(--foreground-muted)] mb-1">Model</div>
                      <div className="font-medium text-[var(--foreground)]">
                        {selectedPrediction.model_name}
                      </div>
                    </div>
                    
                    <div>
                      <div className="text-sm text-[var(--foreground-muted)] mb-1">Status</div>
                      <Badge variant={getStatusColor(selectedPrediction.status)} size="lg">
                        {selectedPrediction.status.toUpperCase()}
                      </Badge>
                    </div>
                    
                    <div>
                      <div className="text-sm text-[var(--foreground-muted)] mb-1">Confidence Score</div>
                      <div className={`text-2xl font-bold ${getConfidenceColor(selectedPrediction.confidence)}`}>
                        {selectedPrediction.confidence}%
                      </div>
                      <div className="mt-2 h-2 bg-[var(--background-card)] rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-secondary)]"
                          style={{ width: `${selectedPrediction.confidence}%` }}
                        ></div>
                      </div>
                    </div>
                    
                    {selectedPrediction.profit_distributed && (
                      <div className="pt-4 border-t border-[var(--border)]">
                        <div className="text-sm font-semibold text-[var(--foreground)] mb-3">
                          Profit Distribution
                        </div>
                        <div className="space-y-2 text-sm">
                          <div className="flex justify-between">
                            <span className="text-[var(--foreground-muted)]">Total Profit:</span>
                            <span className="font-bold text-[var(--color-success)]">
                              {selectedPrediction.profit_distributed.total_profit} ALEO
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-[var(--foreground-muted)]">Data Provider:</span>
                            <span className="font-semibold text-[var(--foreground)]">
                              {selectedPrediction.profit_distributed.data_provider_share} ALEO
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-[var(--foreground-muted)]">Model Creator:</span>
                            <span className="font-semibold text-[var(--foreground)]">
                              {selectedPrediction.profit_distributed.model_creator_share} ALEO
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-[var(--foreground-muted)]">Pool Investors:</span>
                            <span className="font-semibold text-[var(--foreground)]">
                              {selectedPrediction.profit_distributed.pool_share} ALEO
                            </span>
                          </div>
                        </div>
                      </div>
                    )}
                    
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full mt-4"
                      onClick={() => setSelectedPrediction(null)}
                    >
                      Close Details
                    </Button>
                  </CardContent>
                </Card>
              ) : (
                <>
                  <Card variant="hover">
                    <CardHeader>
                      <CardTitle>🎯 How It Works</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <ol className="space-y-3 text-sm text-[var(--foreground-muted)]">
                        <li className="flex items-start gap-2">
                          <span className="font-bold text-[var(--color-primary)]">1.</span>
                          <span>Model runs ZK inference on private data</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <span className="font-bold text-[var(--color-primary)]">2.</span>
                          <span>Confidence score determines bet size (max 10% pool)</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <span className="font-bold text-[var(--color-primary)]">3.</span>
                          <span>Prediction resolved on-chain with ZK proof</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <span className="font-bold text-[var(--color-primary)]">4.</span>
                          <span>Profits split 40-40-20 (data-model-pool)</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <span className="font-bold text-[var(--color-primary)]">5.</span>
                          <span>Reputation bonuses for winners (+5%)</span>
                        </li>
                      </ol>
                    </CardContent>
                  </Card>
                  
                  <Card variant="hover">
                    <CardHeader>
                      <CardTitle>💡 Profit Formula</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-3 text-sm">
                        <div>
                          <div className="text-[var(--foreground-muted)] mb-2">Base Split (40-40-20)</div>
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <div className="w-16 h-2 bg-[var(--color-primary)] rounded"></div>
                              <span className="text-xs text-[var(--foreground-muted)]">Data 40%</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <div className="w-16 h-2 bg-[var(--color-secondary)] rounded"></div>
                              <span className="text-xs text-[var(--foreground-muted)]">Model 40%</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <div className="w-8 h-2 bg-[var(--color-success)] rounded"></div>
                              <span className="text-xs text-[var(--foreground-muted)]">Pool 20%</span>
                            </div>
                          </div>
                        </div>
                        
                        <div className="pt-3 border-t border-[var(--border)]">
                          <div className="text-[var(--foreground-muted)] mb-1">Reputation Bonus</div>
                          <div className="text-xs text-[var(--foreground-muted)]">
                            Your {profitStats.reputation}% reputation adds <strong className="text-[var(--color-success)]">+{(profitStats.reputation * 0.2).toFixed(1)}%</strong> to your earnings per prediction.
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                  
                  <Card variant="hover">
                    <CardHeader>
                      <CardTitle>📊 Statistics</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-3 text-sm">
                        <div className="flex justify-between">
                          <span className="text-[var(--foreground-muted)]">Total Predictions:</span>
                          <span className="font-semibold text-[var(--foreground)]">1,247</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[var(--foreground-muted)]">Active Models:</span>
                          <span className="font-semibold text-[var(--foreground)]">89</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[var(--foreground-muted)]">Avg Confidence:</span>
                          <span className="font-semibold text-[var(--color-primary)]">81.4%</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[var(--foreground-muted)]">Network Win Rate:</span>
                          <span className="font-semibold text-[var(--color-success)]">73.2%</span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
