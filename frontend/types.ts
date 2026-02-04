export interface NavItem {
  label: string;
  path: string;
}

export interface StatCardProps {
  label: string;
  value: string;
  change?: string;
  isPositive?: boolean;
  icon?: React.ComponentType<{ className?: string }>;
}

export interface Prediction {
  id: string;
  model: string;
  amount: number;
  confidence: number;
  potentialWin: number;
  date: string;
}

export type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger' | 'shimmer';
