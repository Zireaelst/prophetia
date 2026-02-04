import React, { useState, useRef } from 'react';
import { motion } from 'framer-motion';
import { Upload, FileText, CheckCircle, Shield, Database, DollarSign, X, AlertCircle } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { StatCardProps } from '../types';

const Data: React.FC = () => {
  const [isDragging, setIsDragging] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [category, setCategory] = useState('');
  const [quality, setQuality] = useState('');
  const [description, setDescription] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<'idle' | 'success'>('idle');
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  const MAX_SIZE = 10 * 1024 * 1024; // 10MB
  const ALLOWED_EXTENSIONS = ['csv', 'json', 'txt'];

  const stats: StatCardProps[] = [
    { label: "Uploaded Datasets", value: "12", isPositive: true },
    { label: "Total Earnings", value: "3,847 ALEO", isPositive: true, icon: DollarSign },
    { label: "Reputation Score", value: "87%", change: "+5%", isPositive: true, icon: Shield },
    { label: "Success Rate", value: "91%", isPositive: true, icon: CheckCircle },
  ];

  const datasets = [
    { name: 'AAPL_stock_2024.csv', category: 'Stock Market', quality: 92, size: '2.4 MB', date: '2024-02-01', status: 'Active' },
    { name: 'Global_Temps_v2.json', category: 'Weather', quality: 88, size: '14.1 MB', date: '2024-01-28', status: 'Verifying' },
    { name: 'BTC_Orderbook_L2.csv', category: 'Crypto', quality: 95, size: '8.9 MB', date: '2024-01-15', status: 'Active' },
  ];

  const validateFile = (selectedFile: File): string | null => {
    if (!selectedFile) return "File is required.";
    
    const extension = selectedFile.name.split('.').pop()?.toLowerCase();
    if (!extension || !ALLOWED_EXTENSIONS.includes(extension)) {
      return "Invalid file type. Only .csv, .json, and .txt are allowed.";
    }

    if (selectedFile.size > MAX_SIZE) {
      return "File size exceeds 10MB limit.";
    }

    return null;
  };

  const handleFileSelect = (selectedFile: File | undefined) => {
    setErrors((prev) => ({ ...prev, file: '' }));
    setUploadStatus('idle');

    if (!selectedFile) return;

    const error = validateFile(selectedFile);
    if (error) {
      setErrors((prev) => ({ ...prev, file: error }));
      return;
    }

    setFile(selectedFile);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFileSelect(e.dataTransfer.files[0]);
    }
  };

  const removeFile = () => {
    setFile(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleSubmit = () => {
    const newErrors: Record<string, string> = {};
    let isValid = true;

    // File Validation
    if (!file) {
      newErrors.file = "Please upload a dataset.";
      isValid = false;
    }

    // Category Validation
    if (!category) {
      newErrors.category = "Please select a category.";
      isValid = false;
    }

    // Quality Score Validation
    const qualityNum = parseInt(quality);
    if (!quality || isNaN(qualityNum) || qualityNum < 0 || qualityNum > 100) {
      newErrors.quality = "Quality score must be between 0 and 100.";
      isValid = false;
    }

    setErrors(newErrors);

    if (isValid) {
      setIsSubmitting(true);
      // Simulate API call
      setTimeout(() => {
        setIsSubmitting(false);
        setUploadStatus('success');
        // Reset form
        setFile(null);
        setCategory('');
        setQuality('');
        setDescription('');
      }, 2000);
    }
  };

  return (
    <div className="min-h-screen pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-4">
      
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-white mb-1">Data Management</h1>
        <p className="text-gray-400 font-mono text-sm">Upload private datasets to train ZK-ML models. Data never leaves your local client without encryption.</p>
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
                 {stat.icon && <stat.icon className="text-primary w-4 h-4" />}
              </div>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        
        {/* Main Upload & Form Area */}
        <div className="lg:col-span-2 space-y-4">
          
          <Card className="p-6 space-y-4">
             {/* Hidden Input */}
             <input 
                type="file" 
                ref={fileInputRef}
                className="hidden"
                accept=".csv,.json,.txt"
                onChange={(e) => handleFileSelect(e.target.files?.[0])}
             />

             {/* Drag & Drop Zone */}
             <div 
               className={`relative border-2 border-dashed rounded-lg transition-all duration-300 ${
                 errors.file 
                   ? 'border-error/50 bg-error/5' 
                   : isDragging 
                     ? 'border-primary bg-primary/5' 
                     : 'border-white/10 hover:border-white/20 hover:bg-white/5'
               } ${file ? 'p-4' : 'p-8 text-center'}`}
               onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
               onDragLeave={() => setIsDragging(false)}
               onDrop={handleDrop}
             >
                {file ? (
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="p-2 bg-primary/20 rounded-lg">
                        <FileText className="text-primary w-6 h-6" />
                      </div>
                      <div>
                        <p className="text-white font-medium text-sm">{file.name}</p>
                        <p className="text-gray-400 text-xs font-mono">{(file.size / 1024 / 1024).toFixed(2)} MB</p>
                      </div>
                    </div>
                    <button 
                      onClick={removeFile}
                      className="p-1 hover:bg-white/10 rounded-full text-gray-400 hover:text-white transition-colors"
                    >
                      <X size={18} />
                    </button>
                  </div>
                ) : (
                  <>
                    <div className="w-12 h-12 rounded-full bg-white/5 mx-auto flex items-center justify-center mb-2">
                      <Upload className="text-primary w-6 h-6" />
                    </div>
                    <h3 className="text-base font-bold text-white">Drag & Drop Dataset</h3>
                    <p className="text-gray-400 text-xs mt-1 font-mono">
                      Supported: .CSV, .JSON, .TXT (Max 10MB)
                    </p>
                    <div className="mt-4">
                      <Button variant="outline" size="sm" onClick={() => fileInputRef.current?.click()}>Browse Files</Button>
                    </div>
                  </>
                )}
             </div>
             {errors.file && (
                <div className="flex items-center gap-2 text-error text-xs mt-1">
                   <AlertCircle size={12} />
                   <span>{errors.file}</span>
                </div>
             )}

             {/* Form Fields */}
             <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Category <span className="text-error">*</span></label>
                   <select 
                      value={category}
                      onChange={(e) => { setCategory(e.target.value); setErrors(prev => ({...prev, category: ''})) }}
                      className={`w-full bg-black/40 border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm transition-colors ${errors.category ? 'border-error' : 'border-glass-border'}`}
                   >
                      <option value="">Select Category</option>
                      <option value="Stock Market">Stock Market</option>
                      <option value="Weather Pattern">Weather Pattern</option>
                      <option value="Commodity Prices">Commodity Prices</option>
                      <option value="Cryptocurrency">Cryptocurrency</option>
                   </select>
                   {errors.category && <p className="text-error text-[10px]">{errors.category}</p>}
                </div>
                
                <div className="space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Quality Score (0-100) <span className="text-error">*</span></label>
                   <input 
                     type="number" 
                     min="0"
                     max="100"
                     value={quality}
                     onChange={(e) => { setQuality(e.target.value); setErrors(prev => ({...prev, quality: ''})) }}
                     placeholder="e.g. 85" 
                     className={`w-full bg-black/40 border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm transition-colors ${errors.quality ? 'border-error' : 'border-glass-border'}`} 
                   />
                   {errors.quality && <p className="text-error text-[10px]">{errors.quality}</p>}
                </div>
                
                <div className="col-span-1 md:col-span-2 space-y-1">
                   <label className="text-xs text-gray-400 font-mono">Description (Optional)</label>
                   <textarea 
                     rows={3} 
                     value={description}
                     onChange={(e) => setDescription(e.target.value)}
                     className="w-full bg-black/40 border border-glass-border rounded-md p-2.5 text-white focus:outline-none focus:border-primary font-mono text-sm" 
                     placeholder="Describe the data source and features..." 
                   />
                </div>
             </div>

             <Button 
                variant="primary" 
                className="w-full" 
                onClick={handleSubmit}
                isLoading={isSubmitting}
                disabled={isSubmitting}
             >
               {isSubmitting ? 'Encrypting & Uploading...' : 'Encrypt & Upload Dataset'}
             </Button>

             {/* Success Message */}
             {uploadStatus === 'success' && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="p-3 bg-success/10 border border-success/20 rounded-lg flex items-center gap-2"
                >
                   <CheckCircle className="text-success w-4 h-4" />
                   <div>
                      <p className="text-success font-bold text-xs">Upload Successful!</p>
                      <p className="text-success/80 text-[10px]">Your dataset has been encrypted and the ZK-proof is on-chain.</p>
                   </div>
                </motion.div>
             )}
          </Card>

          <Card className="p-0 overflow-hidden">
             <div className="p-4 border-b border-glass-border">
                <h3 className="font-bold text-white text-sm">Uploaded Datasets</h3>
             </div>
             <div className="overflow-x-auto">
               <table className="w-full text-sm">
                 <thead className="bg-white/5 font-mono text-gray-400">
                   <tr>
                     <th className="px-4 py-2 text-left text-xs">Name</th>
                     <th className="px-4 py-2 text-left text-xs">Category</th>
                     <th className="px-4 py-2 text-left text-xs">Quality</th>
                     <th className="px-4 py-2 text-left text-xs">Status</th>
                   </tr>
                 </thead>
                 <tbody className="divide-y divide-glass-border">
                   {datasets.map((d, i) => (
                     <tr key={i} className="group hover:bg-white/5 transition-colors">
                       <td className="px-4 py-3 flex items-center gap-2">
                         <FileText size={14} className="text-primary" />
                         <span className="text-white font-medium text-xs">{d.name}</span>
                       </td>
                       <td className="px-4 py-3 text-gray-300 text-xs">{d.category}</td>
                       <td className="px-4 py-3 font-mono text-primary-glow text-xs">{d.quality}/100</td>
                       <td className="px-4 py-3">
                         <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium ${d.status === 'Active' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'}`}>
                           {d.status}
                         </span>
                       </td>
                     </tr>
                   ))}
                 </tbody>
               </table>
             </div>
          </Card>

        </div>

        {/* Sidebar Info */}
        <div className="space-y-4">
           <Card className="p-4">
              <h3 className="font-bold text-white mb-3 flex items-center gap-2 text-sm">
                <Database size={16} className="text-secondary" />
                How It Works
              </h3>
              <ul className="space-y-3">
                {[1, 2, 3, 4, 5].map((step) => (
                  <li key={step} className="flex gap-2 text-xs text-gray-400">
                    <span className="flex-shrink-0 w-4 h-4 rounded-full bg-white/10 text-white flex items-center justify-center text-[10px] font-mono">{step}</span>
                    <span>
                      {step === 1 && "Upload your raw CSV/JSON data."}
                      {step === 2 && "Client-side ZK-encryption."}
                      {step === 3 && "Generate validity proof."}
                      {step === 4 && "Submit proof to chain."}
                      {step === 5 && "Earn fees when models use it."}
                    </span>
                  </li>
                ))}
              </ul>
           </Card>

           <Card className="p-4 border-primary/20 bg-primary/5">
              <h3 className="font-bold text-primary-glow mb-1 text-sm">Privacy Guaranteed</h3>
              <p className="text-[10px] text-gray-300 leading-relaxed mb-3">
                Your raw data never leaves your browser. Only Zero-Knowledge proofs validating the data structure and quality are submitted to the Prophetia network.
              </p>
              <Button variant="outline" size="sm" className="w-full text-xs py-1">View ZK-Proof Spec</Button>
           </Card>
        </div>

      </div>
    </div>
  );
};

export default Data;