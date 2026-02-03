/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Data Upload Page
 * ═══════════════════════════════════════════════════════════════════════════
 * Upload private data for ZK-ML predictions
 */

'use client';

import React, { useState, useCallback } from 'react';
import { Header } from '@/components/Header';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useToast } from '@/components/ui/Toast';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { SpotlightCard, Meteors, ShimmerButton } from '@/components/aceternity';
import { ASCIIBackground } from '@/components/ASCIIEffect';
import { motion } from 'framer-motion';

interface DataRecord {
  id: string;
  name: string;
  category: string;
  quality_score: number;
  size: string;
  uploaded_at: string;
  status: 'processing' | 'active' | 'failed';
}

const CATEGORIES = [
  { value: '', label: 'Select Category' },
  { value: 'stock', label: '📈 Stock Market Data' },
  { value: 'weather', label: '🌤️ Weather Data' },
  { value: 'commodity', label: '🛢️ Commodity Prices' },
  { value: 'crypto', label: '₿ Cryptocurrency' },
];

export default function DataUploadPage() {
  const { showToast } = useToast();
  
  // Form state
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  
  const [formData, setFormData] = useState({
    category: '',
    quality_score: '85',
    description: '',
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  // Mock user data
  const [userStats] = useState({
    uploaded_count: 12,
    total_earnings: 3847,
    reputation: 87,
    success_rate: 91,
  });
  
  // Mock uploaded data records
  const [uploadedData, setUploadedData] = useState<DataRecord[]>([
    {
      id: '1',
      name: 'AAPL_stock_2024.csv',
      category: 'Stock Market',
      quality_score: 92,
      size: '2.4 MB',
      uploaded_at: '2024-02-01',
      status: 'active',
    },
    {
      id: '2',
      name: 'btc_prices_jan.json',
      category: 'Cryptocurrency',
      quality_score: 88,
      size: '1.1 MB',
      uploaded_at: '2024-01-28',
      status: 'active',
    },
  ]);

  // File upload handlers
  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      const file = files[0];
      validateAndSetFile(file);
    }
  }, []);

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      validateAndSetFile(files[0]);
    }
  }, []);

  const validateAndSetFile = (file: File) => {
    // Validate file type
    const allowedTypes = ['text/csv', 'application/json', 'text/plain'];
    const allowedExtensions = ['.csv', '.json', '.txt'];
    
    const isValidType = allowedTypes.includes(file.type) || 
      allowedExtensions.some(ext => file.name.toLowerCase().endsWith(ext));
    
    if (!isValidType) {
      showToast('error', 'Invalid file type. Please upload CSV, JSON, or TXT files.');
      return;
    }
    
    // Validate file size (max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      showToast('error', 'File too large. Maximum size is 10MB.');
      return;
    }
    
    setSelectedFile(file);
    setErrors({});
    showToast('success', `File "${file.name}" selected successfully!`);
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!selectedFile) {
      newErrors.file = 'Please select a file to upload';
    }
    
    if (!formData.category) {
      newErrors.category = 'Please select a data category';
    }
    
    const qualityScore = parseInt(formData.quality_score);
    if (isNaN(qualityScore) || qualityScore < 0 || qualityScore > 100) {
      newErrors.quality_score = 'Quality score must be between 0 and 100';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      showToast('error', 'Please fix the errors before submitting');
      return;
    }
    
    setIsUploading(true);
    
    try {
      // Simulate file upload and blockchain transaction
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Add to uploaded data list
      const newRecord: DataRecord = {
        id: Date.now().toString(),
        name: selectedFile!.name,
        category: CATEGORIES.find(c => c.value === formData.category)?.label || formData.category,
        quality_score: parseInt(formData.quality_score),
        size: `${(selectedFile!.size / (1024 * 1024)).toFixed(1)} MB`,
        uploaded_at: new Date().toISOString().split('T')[0],
        status: 'processing',
      };
      
      setUploadedData(prev => [newRecord, ...prev]);
      
      // Reset form
      setSelectedFile(null);
      setFormData({
        category: '',
        quality_score: '85',
        description: '',
      });
      
      showToast('success', 'Data uploaded successfully! Processing on blockchain...');
      
      // Simulate processing complete
      setTimeout(() => {
        setUploadedData(prev => 
          prev.map(record => 
            record.id === newRecord.id 
              ? { ...record, status: 'active' } 
              : record
          )
        );
        showToast('success', 'Data processing complete! Ready for predictions.');
      }, 3000);
      
    } catch (error) {
      showToast('error', 'Upload failed. Please try again.');
      console.error('Upload error:', error);
    } finally {
      setIsUploading(false);
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
              Upload Private Data
            </h1>
            <p className="text-lg text-[var(--foreground-muted)]">
              Contribute data to the oracle network while maintaining complete privacy through zero-knowledge proofs.
            </p>
          </div>
          
          {/* User Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Uploaded Datasets</div>
                <div className="text-2xl font-bold text-[var(--foreground)]">{userStats.uploaded_count}</div>
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
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Reputation Score</div>
                <div className="flex items-center gap-2">
                  <div className="text-2xl font-bold text-[var(--foreground)]">{userStats.reputation}%</div>
                  <Badge variant="success" size="sm">+5%</Badge>
                </div>
              </CardContent>
            </Card>
            
            <Card>
              <CardContent className="p-4">
                <div className="text-sm text-[var(--foreground-muted)] mb-1">Success Rate</div>
                <div className="text-2xl font-bold text-[var(--color-primary)]">{userStats.success_rate}%</div>
              </CardContent>
            </Card>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Upload Form */}
            <div className="lg:col-span-2">
              <Card>
                <CardHeader>
                  <CardTitle>Upload New Dataset</CardTitle>
                  <CardDescription>
                    Upload CSV, JSON, or TXT files (max 10MB). Your data remains private through ZK proofs.
                  </CardDescription>
                </CardHeader>
                
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-6">
                    {/* File Upload Dropzone */}
                    <div>
                      <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
                        Data File <span className="text-[var(--color-error)]">*</span>
                      </label>
                      
                      <div
                        onDragOver={handleDragOver}
                        onDragLeave={handleDragLeave}
                        onDrop={handleDrop}
                        className={`
                          relative border-2 border-dashed rounded-lg p-8 text-center transition-all duration-200
                          ${isDragging 
                            ? 'border-[var(--color-primary)] bg-[var(--color-primary)]/5' 
                            : 'border-[var(--border)] hover:border-[var(--color-primary)]/50'
                          }
                          ${errors.file ? 'border-[var(--color-error)]' : ''}
                        `}
                      >
                        <input
                          type="file"
                          id="file-upload"
                          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                          onChange={handleFileSelect}
                          accept=".csv,.json,.txt"
                        />
                        
                        <div className="pointer-events-none">
                          {selectedFile ? (
                            <>
                              <div className="text-5xl mb-3">📄</div>
                              <p className="text-lg font-medium text-[var(--foreground)] mb-1">
                                {selectedFile.name}
                              </p>
                              <p className="text-sm text-[var(--foreground-muted)]">
                                {(selectedFile.size / (1024 * 1024)).toFixed(2)} MB
                              </p>
                              <Button
                                type="button"
                                variant="ghost"
                                size="sm"
                                className="mt-3"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setSelectedFile(null);
                                }}
                              >
                                Remove File
                              </Button>
                            </>
                          ) : (
                            <>
                              <div className="text-5xl mb-3">📁</div>
                              <p className="text-lg font-medium text-[var(--foreground)] mb-1">
                                Drop your file here
                              </p>
                              <p className="text-sm text-[var(--foreground-muted)] mb-3">
                                or click to browse
                              </p>
                              <Badge variant="default">CSV, JSON, TXT (max 10MB)</Badge>
                            </>
                          )}
                        </div>
                      </div>
                      
                      {errors.file && (
                        <p className="mt-1.5 text-sm text-[var(--color-error)] flex items-center gap-1">
                          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                          </svg>
                          {errors.file}
                        </p>
                      )}
                    </div>
                    
                    {/* Category Selection */}
                    <Select
                      label="Data Category"
                      options={CATEGORIES}
                      value={formData.category}
                      onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                      error={errors.category}
                      required
                    />
                    
                    {/* Quality Score */}
                    <Input
                      type="number"
                      label="Quality Score"
                      placeholder="85"
                      min="0"
                      max="100"
                      value={formData.quality_score}
                      onChange={(e) => setFormData({ ...formData, quality_score: e.target.value })}
                      error={errors.quality_score}
                      helperText="Rate your data quality from 0-100. Higher scores earn more reputation bonuses."
                      required
                    />
                    
                    {/* Description */}
                    <div>
                      <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
                        Description (Optional)
                      </label>
                      <textarea
                        className="w-full px-4 py-2.5 rounded-lg bg-[var(--background-card)] border border-[var(--border)] text-[var(--foreground)] placeholder:text-[var(--foreground-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] focus:border-transparent transition-all duration-200 resize-vertical"
                        rows={3}
                        placeholder="Describe your dataset (e.g., source, time range, features)..."
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      />
                    </div>
                    
                    {/* Submit Button */}
                    <div className="flex gap-4">
                      <Button
                        type="submit"
                        variant="primary"
                        size="lg"
                        className="flex-1"
                        isLoading={isUploading}
                        disabled={isUploading}
                      >
                        {isUploading ? 'Uploading...' : 'Upload to Blockchain'}
                      </Button>
                      
                      <Button
                        type="button"
                        variant="outline"
                        size="lg"
                        onClick={() => {
                          setSelectedFile(null);
                          setFormData({ category: '', quality_score: '85', description: '' });
                          setErrors({});
                        }}
                        disabled={isUploading}
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
                  <CardTitle>🔐 Privacy Guaranteed</CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-3 text-sm text-[var(--foreground-muted)]">
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>Data encrypted before upload</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>ZK proofs protect sensitive info</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[var(--color-success)] mt-0.5">✓</span>
                      <span>Only you control access rights</span>
                    </li>
                  </ul>
                </CardContent>
              </Card>
              
              <Card variant="hover">
                <CardHeader>
                  <CardTitle>💰 Earnings Model</CardTitle>
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
                      Higher quality data and successful predictions increase your reputation and earnings.
                    </p>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
          
          {/* Uploaded Data Table */}
          <div className="mt-12">
            <Card>
              <CardHeader>
                <CardTitle>Your Uploaded Datasets</CardTitle>
                <CardDescription>
                  Track your data contributions and their performance
                </CardDescription>
              </CardHeader>
              
              <CardContent>
                {uploadedData.length === 0 ? (
                  <div className="text-center py-12">
                    <div className="text-5xl mb-3">📊</div>
                    <p className="text-[var(--foreground-muted)]">No data uploaded yet. Start contributing!</p>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b border-[var(--border)]">
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Dataset</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Category</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Quality</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Size</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Date</th>
                          <th className="text-left py-3 px-4 text-sm font-medium text-[var(--foreground-muted)]">Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {uploadedData.map((record) => (
                          <tr key={record.id} className="border-b border-[var(--border)] hover:bg-[var(--background-hover)] transition-colors">
                            <td className="py-3 px-4">
                              <div className="font-medium text-[var(--foreground)]">{record.name}</div>
                            </td>
                            <td className="py-3 px-4">
                              <span className="text-sm text-[var(--foreground-muted)]">{record.category}</span>
                            </td>
                            <td className="py-3 px-4">
                              <Badge variant={record.quality_score >= 80 ? 'success' : 'warning'}>
                                {record.quality_score}%
                              </Badge>
                            </td>
                            <td className="py-3 px-4 text-sm text-[var(--foreground-muted)]">{record.size}</td>
                            <td className="py-3 px-4 text-sm text-[var(--foreground-muted)]">{record.uploaded_at}</td>
                            <td className="py-3 px-4">
                              <Badge 
                                variant={
                                  record.status === 'active' ? 'success' : 
                                  record.status === 'processing' ? 'warning' : 
                                  'error'
                                }
                              >
                                {record.status === 'processing' && (
                                  <LoadingSpinner size="sm" className="mr-1" />
                                )}
                                {record.status}
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
