/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Button Component
 * ═══════════════════════════════════════════════════════════════════════════
 * Reusable button with multiple variants and sizes
 */

import React from 'react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  children: React.ReactNode;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      isLoading = false,
      leftIcon,
      rightIcon,
      children,
      className = '',
      disabled,
      ...props
    },
    ref
  ) => {
    const baseStyles =
      'inline-flex items-center justify-center font-semibold rounded-lg transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed';

    const variantStyles = {
      primary:
        'bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-secondary)] text-white hover:shadow-[var(--shadow-glow)] hover:scale-[1.02] active:scale-[0.98]',
      secondary:
        'bg-[var(--background-card)] text-[var(--foreground)] border border-[var(--border)] hover:bg-[var(--background-hover)] hover:border-[var(--color-primary)]',
      outline:
        'bg-transparent text-[var(--foreground)] border border-[var(--border)] hover:bg-[var(--background-hover)] hover:border-[var(--color-primary)]',
      ghost:
        'bg-transparent text-[var(--foreground-muted)] hover:bg-[var(--background-hover)] hover:text-[var(--foreground)]',
      danger:
        'bg-gradient-to-r from-[var(--color-error)] to-red-700 text-white hover:shadow-[0_0_20px_rgba(239,68,68,0.5)] hover:scale-[1.02] active:scale-[0.98]',
    };

    const sizeStyles = {
      sm: 'px-3 py-1.5 text-sm gap-1.5',
      md: 'px-6 py-2.5 text-base gap-2',
      lg: 'px-8 py-3.5 text-lg gap-2.5',
    };

    const combinedClassName = `${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]} ${className}`;

    return (
      <button
        ref={ref}
        className={combinedClassName}
        disabled={disabled || isLoading}
        {...props}
      >
        {isLoading ? (
          <>
            <svg
              className="animate-spin h-5 w-5"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              ></circle>
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              ></path>
            </svg>
            <span>Loading...</span>
          </>
        ) : (
          <>
            {leftIcon && <span className="inline-flex">{leftIcon}</span>}
            {children}
            {rightIcon && <span className="inline-flex">{rightIcon}</span>}
          </>
        )}
      </button>
    );
  }
);

Button.displayName = 'Button';
