/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Loading Spinner Component
 * ═══════════════════════════════════════════════════════════════════════════
 * Reusable loading spinner for async operations
 */

import React from 'react';

export interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  text?: string;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'md',
  className = '',
  text,
}) => {
  const sizeStyles = {
    sm: 'w-4 h-4',
    md: 'w-8 h-8',
    lg: 'w-12 h-12',
    xl: 'w-16 h-16',
  };

  return (
    <div className={`flex flex-col items-center justify-center gap-3 ${className}`}>
      <div className="relative">
        <div
          className={`${sizeStyles[size]} rounded-full border-4 border-[var(--border)] border-t-[var(--color-primary)] animate-spin`}
        ></div>
        <div
          className={`${sizeStyles[size]} rounded-full border-4 border-transparent border-t-[var(--color-secondary)] animate-spin absolute top-0 left-0`}
          style={{ animationDuration: '1.5s', animationDirection: 'reverse' }}
        ></div>
      </div>
      {text && (
        <p className="text-sm text-[var(--foreground-muted)] animate-pulse">{text}</p>
      )}
    </div>
  );
};

export const FullPageLoader: React.FC<{ text?: string }> = ({ text }) => {
  return (
    <div className="fixed inset-0 bg-[var(--background)]/80 backdrop-blur-sm flex items-center justify-center z-50">
      <LoadingSpinner size="xl" text={text || 'Loading...'} />
    </div>
  );
};
