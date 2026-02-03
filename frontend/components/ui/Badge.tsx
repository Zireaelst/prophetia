/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Badge Component
 * ═══════════════════════════════════════════════════════════════════════════
 * Reusable badge for status indicators
 */

import React from 'react';

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info' | 'primary';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

export const Badge: React.FC<BadgeProps> = ({
  variant = 'default',
  size = 'md',
  children,
  className = '',
  ...props
}) => {
  const variantStyles = {
    default:
      'bg-[var(--background-card)] text-[var(--foreground-muted)] border border-[var(--border)]',
    success:
      'bg-[var(--color-success)]/10 text-[var(--color-success)] border border-[var(--color-success)]/20',
    warning:
      'bg-yellow-500/10 text-yellow-500 border border-yellow-500/20',
    error:
      'bg-[var(--color-error)]/10 text-[var(--color-error)] border border-[var(--color-error)]/20',
    info:
      'bg-[var(--color-secondary)]/10 text-[var(--color-secondary)] border border-[var(--color-secondary)]/20',
    primary:
      'bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-secondary)] text-white border-0',
  };

  const sizeStyles = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-sm',
    lg: 'px-3 py-1.5 text-base',
  };

  const combinedClassName = `inline-flex items-center gap-1 rounded-full font-medium ${variantStyles[variant]} ${sizeStyles[size]} ${className}`;

  return (
    <span className={combinedClassName} {...props}>
      {children}
    </span>
  );
};
