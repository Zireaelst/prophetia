'use client';

import { Header } from '@/components/Header';

export default function ModelsPage() {
  return (
    <div className="min-h-screen">
      <Header />
      <div className="pt-24 pb-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-white mb-4">ZK-ML Models</h1>
        <p className="text-gray-400">Deploy and manage your zero-knowledge machine learning models.</p>
        <div className="glass-card p-8 mt-8">
          <p className="text-center text-gray-500">Model deployment interface coming soon...</p>
        </div>
      </div>
    </div>
  );
}
