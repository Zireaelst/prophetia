/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Models Deployment Page
 * ═══════════════════════════════════════════════════════════════════════════
 * Deploy ZK-ML models for private inference
 */

'use client';

import React, { useState } from 'react';
import { Header } from '@/components/Header';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { TextArea } from '@/components/ui/Input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useToast } from '@/components/ui/Toast';
import { SpotlightCard, Meteors, ShimmerButton } from '@/components/aceternity';
import { ASCIIBackground } from '@/components/ASCIIEffect';
import { motion } from 'framer-motion';

interface Model {
  id: string;
  name: string;
  algorithm: string;
  accuracy: number;
  predictions: number;
  deployed_at: string;
  status: 'active' | 'paused' | 'training';
  earnings: number;
}

const ALGORITHMS = [
  { value: '', label: 'Select Algorithm' },
  { value: 'linear', label: '📈 Linear Regression' },
  { value: 'logistic', label: '🎯 Logistic Regression' },
  { value: 'decision_tree', label: '🌳 Decision Tree' },
];

export default function ModelsPage() {
  const { showToast } = useToast();
  
  const [isDeploying, setIsDeploying] = useState(false);
  const [showWeightsInput, setShowWeightsInput] = useState(false);
  
  const [formData, setFormData] = useState({
    name: '',
    algorithm: '',
    description: '',
    weights: '',
    bias: '0',
    input_features: '4',
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  // Mock user stats
  const [userStats] = useState({
    deployed_models: 5,
    total_predictions: 1247,
    reputation: 92,
    total_earnings: 8234,
  });
  
  // Mock deployed models
  const [deployedModels] = useState<Model[]>([
    {
      id: '1',
      name: 'Stock Price Predictor v2',
      algorithm: 'Linear Regression',
      accuracy: 87.3,
      predictions: 342,
      deployed_at: '2024-01-15',
      status: 'active',
      earnings: 2847,
    },
    {
      id: '2',
      name: 'BTC Volatility Model',
      algorithm: 'Logistic Regression',
      accuracy: 91.2,
      predictions: 521,
      deployed_at: '2024-01-08',
      status: 'active',
      earnings: 4123,
    },
    {
      id: '3',
      name: 'Weather Classification',
      algorithm: 'Decision Tree',
      accuracy: 84.1,
      predictions: 189,
      deployed_at: '2024-01-22',
      status: 'active',
      earnings: 1264,
    },
  ]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.name.trim()) {
      newErrors.name = 'Model name is required';
    }
    
    if (!formData.algorithm) {
      newErrors.algorithm = 'Please select an algorithm';
    }
    
    const inputFeatures = parseInt(formData.input_features);
    if (isNaN(inputFeatures) || inputFeatures < 1 || inputFeatures > 100) {
      newErrors.input_features = 'Input features must be between 1 and 100';
    }
    
    if (showWeightsInput && formData.weights.trim()) {
      const weights = formData.weights.split(',').map(w => w.trim());
      if (weights.some(w => isNaN(parseFloat(w)))) {
        newErrors.weights = 'All weights must be valid numbers';
      }
      if (weights.length !== inputFeatures) {
        newErrors.weights = `Must provide exactly ${inputFeatures} weights`;
      }
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      showToast('error', 'Please fix the errors before deploying');
      return;
    }
    
    setIsDeploying(true);
    
    try {
      // Simulate model deployment
      await new Promise(resolve => setTimeout(resolve, 2500));
      
      // Reset form
      setFormData({
        name: '',
        algorithm: '',
        description: '',
        weights: '',
        bias: '0',
        input_features: '4',
      });
      setShowWeightsInput(false);
      
      showToast('success', 'Model deployed successfully! Training on blockchain...');
      
      // Simulate training complete
      setTimeout(() => {
        showToast('success', 'Model training complete! Ready for predictions.');
      }, 3000);
      
    } catch (error) {
      showToast('error', 'Deployment failed. Please try again.');
      console.error('Deployment error:', error);
    } finally {
      setIsDeploying(false);
    }
  };

  return (
    <div className="min-h-screen">
      <Header />
      
      <main className="px-6 py-12 lg:px-8">
        <div className="mx-auto max-w-7xl">
          {/* Page Header */}
          <div className="mb-8">
            <h1 className="text-4xl font-bold gradient-text mb-2">
              Deploy ZK-ML Models
            </h1>
            <p className="text-lg text-[var(--foreground-muted)]">
              Create private machine learning models that run inference in zero-knowledge.
            </p>
          </div>
          
          {/* User Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Deployed Models</div>
                <div className="text-2xl font-bold text-[var(--foreground)]">{userStats.deployed_models}</div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Total Predictions</div>
                <div className="text-2xl font-bold text-[var(--color-primary)]">
                  {userStats.total_predictions.toLocaleString()}
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Reputation Score</div>
                <div className="flex items-center gap-2">
                  <div className="text-2xl font-bold text-[var(--foreground)]">{userStats.reputation}%</div>
                  <Badge variant="success" size="sm">+7%</Badge>
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Total Earnings</div>
                <div className="text-2xl font-bold text-[var(--color-success)]">
                  {userStats.total_earnings.toLocaleString()} ALEO
                </div>
              </CardContent>
            </Card>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Deployment Form */}
            <div className="lg:col-span-2">
              <Card>
                <CardHeader>
                  <CardTitle>Deploy New Model</CardTitle>
                  <CardDescription>
                    Configure and deploy your ZK-ML model. All model architecture remains private through zero-knowledge proofs.
                  </CardDescription>
                </CardHeader>
                
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-6">
                    {/* Model Name */}
                    <Input
                      label="Model Name"
                      placeholder="e.g., Stock Price Predictor"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      error={errors.name}
                      required
                    />
                    
                    {/* Algorithm Selection */}
                    <Select
                      label="Algorithm Type"
                      options={ALGORITHMS}
                      value={formData.algorithm}
                      onChange={(e) => setFormData({ ...formData, algorithm: e.target.value })}
                      error={errors.algorithm}
                      required
                    />
                    
                    {/* Algorithm Info */}
                    {formData.algorithm && (
                      <div className="p-4 rounded-lg bg-[var(--color-secondary)]/10 border border-[var(--color-secondary)]/20">
                        <p className="text-sm text-[var(--foreground-muted)]">
                          {formData.algorithm === 'linear' && '📈 Best for continuous value predictions (e.g., prices, temperatures)'}
                          {formData.algorithm === 'logistic' && '🎯 Best for binary classification (e.g., up/down, yes/no)'}
                          {formData.algorithm === 'decision_tree' && '🌳 Best for multi-class classification and feature importance'}
                        </p>
                      </div>
                    )}
                    
                    {/* Input Features */}
                    <Input
                      type="number"
                      label="Number of Input Features"
                      placeholder="4"
                      min="1"
                      max="100"
                      value={formData.input_features}
                      onChange={(e) => setFormData({ ...formData, input_features: e.target.value })}
                      error={errors.input_features}
                      helperText="How many features (variables) does your model take as input?"
                      required
                    />
                    
                    {/* Model Description */}
                    <TextArea
                      label="Description"
                      placeholder="Describe what your model predicts and how it works..."
                      rows={4}
                      value={formData.description}
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      helperText="Optional: Help others understand your model's purpose"
                    />
                    
                    {/* Advanced Options Toggle */}
                    <div>
                      <button
                        type="button"
                        onClick={() => setShowWeightsInput(!showWeightsInput)}
                        className="flex items-center gap-2 text-sm text-[var(--color-primary)] hover:text-[var(--color-secondary)] transition-colors"
                      >
                        <span>{showWeightsInput ? '▼' : '▶'}</span>
                        <span>Advanced: Set Custom Weights & Bias</span>
                      </button>
                    </div>
                    
                    {/* Weights Input (collapsed by default) */}
                    {showWeightsInput && (
                      <div className="space-y-4 p-4 rounded-lg border border-[var(--border)] bg-[var(--background-card)]">
                        <TextArea
                          label="Model Weights"
                          placeholder="e.g., 0.5, -0.3, 1.2, 0.8"
                          rows={3}
                          value={formData.weights}
                          onChange={(e) => setFormData({ ...formData, weights: e.target.value })}
                          error={errors.weights}
                          helperText={`Comma-separated list of ${formData.input_features} weight values. Leave empty for random initialization.`}
                        />
                        
                        <Input
                          type="number"
                          label="Model Bias"
                          placeholder="0"
                          step="0.01"
                          value={formData.bias}
                          onChange={(e) => setFormData({ ...formData, bias: e.target.value })}
                          helperText="Bias term for the model (default: 0)"
                        />
                      </div>
                    )}
                    
                    {/* Deploy Button */}
                    <div className="flex gap-4">
                      <Button
                        type="submit"
                        variant="primary"
                        size="lg"
                        className="flex-1"
                        isLoading={isDeploying}
                        disabled={isDeploying}
                      >
                        {isDeploying ? 'Deploying...' : 'Deploy to Blockchain'}
                      </Button>
                      
                      <Button
                        type="button"
                        variant="outline"
                        size="lg"
                        onClick={() => {
                          setFormData({
                            name: '',
                            algorithm: '',
                            description: '',
                            weights: '',
                            bias: '0',
                            input_features: '4',
                          });
                          setShowWeightsInput(false);
                          setErrors({});
                        }}
                        disabled={isDeploying}
                      >
                        Reset
                      </Button>
                    </div>
                  </form>
                </CardContent>
              </Card>
            </div>
            
            {/* Info Sidebar */}
            <div className="space-y-6">
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>🧠 ZK-ML Benefits</CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-3 text-sm text-[var(--foreground-muted)]">
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>Model architecture stays private</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>Verifiable inference on-chain</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>Tamper-proof predictions</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>No training data exposure</span>
                    </li>
                  </ul>
                </CardContent>
              </Card>
              
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>💰 Revenue Model</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3 text-sm">
                    <div>
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-[var(--foreground-muted)]">Base Share</span>
                        <span className="font-semibold text-[var(--foreground)]">40%</span>
                      </div>
                      <div className="h-2 bg-[var(--background-card)] rounded-full overflow-hidden">
                        <div className="h-full w-[40%] bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-secondary)]"></div>
                      </div>
                    </div>
                    
                    <div>
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-[var(--foreground-muted)]">Reputation Bonus</span>
                        <span className="font-semibold text-[var(--color-success)]">+{(userStats.reputation * 0.2).toFixed(1)}%</span>
                      </div>
                      <div className="h-2 bg-[var(--background-card)] rounded-full overflow-hidden">
                        <div className="h-full bg-[var(--color-success)]" style={{ width: `${userStats.reputation}%` }}></div>
                      </div>
                    </div>
                    
                    <p className="text-xs text-[var(--foreground-muted)] pt-2">
                      Earn 40% of profits per prediction + reputation bonus. Higher accuracy = more earnings.
                    </p>
                  </div>
                </CardContent>
              </Card>
              
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>📊 Supported Algorithms</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2 text-sm">
                    <div className="flex items-center gap-2">
                      <Badge variant="primary" size="sm">Linear</Badge>
                      <span className="text-[var(--foreground-muted)]">Regression</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="primary" size="sm">Logistic</Badge>
                      <span className="text-[var(--foreground-muted)]">Classification</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="primary" size="sm">Tree</Badge>
                      <span className="text-[var(--foreground-muted)]">Decision Tree</span>
                    </div>
                    <p className="text-xs text-[var(--foreground-muted)] pt-2">
                      More algorithms coming soon: Neural Networks, Random Forest, SVM
                    </p>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
          
          {/* Deployed Models Table */}
          <div className="mt-12">
            <Card>
              <CardHeader>
                <CardTitle>Your Deployed Models</CardTitle>
                <CardDescription>
                  Track your models' performance and earnings
                </CardDescription>
              </CardHeader>
              
              <CardContent>
                {deployedModels.length === 0 ? (
                  <div className="text-center py-12">
                    <div className="text-5xl mb-3">🧠</div>
                    <p className="text-[var(--foreground-muted)]">No models deployed yet. Deploy your first model!</p>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b border-[var(--border)]">
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Model</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Algorithm</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Accuracy</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Predictions</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Earnings</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {deployedModels.map((model) => (
                          <tr key={model.id} className="border-b border-[var(--border)] hover:bg-[var(--background-hover)] transition-colors">
                            <td className="py-3 px-4">
                              <div>
                                <div className="font-medium text-[var(--foreground)]">{model.name}</div>
                                <div className="text-xs text-[var(--foreground-muted)]">Deployed {model.deployed_at}</div>
                              </div>
                            </td>
                            <td className="py-3 px-4">
                              <Badge variant="default">{model.algorithm}</Badge>
                            </td>
                            <td className="py-3 px-4">
                              <Badge variant={model.accuracy >= 85 ? 'success' : model.accuracy >= 70 ? 'warning' : 'error'}>
                                {model.accuracy}%
                              </Badge>
                            </td>
                            <td className="py-3 px-4 text-sm text-[var(--foreground-muted)]">
                              {model.predictions.toLocaleString()}
                            </td>
                            <td className="py-3 px-4">
                              <span className="text-sm font-semibold text-[var(--color-success)]">
                                {model.earnings.toLocaleString()} ALEO
                              </span>
                            </td>
                            <td className="py-3 px-4">
                              <Badge variant={model.status === 'active' ? 'success' : 'warning'}>
                                {model.status}
                              </Badge>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
