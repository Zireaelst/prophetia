import React from 'react';
import { ButtonVariant } from '../../types';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Button: React.FC<ButtonProps> = ({ 
  children, 
  variant = 'primary', 
  size = 'md',
  className = '', 
  isLoading, 
  leftIcon, 
  rightIcon, 
  disabled,
  ...props 
}) => {
  
  const baseStyles = "relative inline-flex items-center justify-center gap-2 font-mono font-medium transition-all duration-300 rounded-md focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed group overflow-hidden";
  
  const sizeStyles = {
    sm: "px-3 py-1.5 text-xs",
    md: "px-6 py-3 text-sm",
    lg: "px-8 py-4 text-base",
  };

  const variants = {
    primary: "bg-primary text-white shadow-[0_0_15px_rgba(147,51,234,0.3)] hover:shadow-[0_0_25px_rgba(147,51,234,0.6)] hover:bg-primary-glow border border-transparent",
    secondary: "bg-secondary/10 text-secondary border border-secondary/20 hover:bg-secondary/20",
    outline: "bg-transparent text-white border border-white/20 hover:bg-white/5",
    ghost: "bg-transparent text-white/70 hover:text-white hover:bg-white/5",
    danger: "bg-error/10 text-error border border-error/20 hover:bg-error/20",
    shimmer: "bg-slate-900 text-white border border-slate-800", // Shimmer logic handled below
  };

  const shimmerEffect = variant === 'shimmer' ? (
    <span className="absolute inset-0 -translate-x-full group-hover:animate-[shimmer_2s_infinite] bg-gradient-to-r from-transparent via-white/10 to-transparent z-10" />
  ) : null;

  return (
    <button 
      className={`${baseStyles} ${sizeStyles[size]} ${variants[variant]} ${className}`}
      disabled={isLoading || disabled}
      {...props}
    >
      {shimmerEffect}
      {isLoading && (
        <svg className="w-4 h-4 animate-spin mr-2" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
      )}
      {!isLoading && leftIcon && <span className="z-20">{leftIcon}</span>}
      <span className="z-20">{children}</span>
      {!isLoading && rightIcon && <span className="z-20">{rightIcon}</span>}
    </button>
  );
};

export default Button;