"""Data processor for normalization, quality scoring, and feature extraction."""

import logging
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler

from core.config import Config


class DataProcessor:
    """Processes and validates collected data."""
    
    def __init__(self, config: Config):
        """Initialize data processor."""
        self.config = config
        self.processing_config = config.data_processing
        self.logger = logging.getLogger(__name__)
        
        # Setup processed data directory
        self.data_dir = Path(config.storage.processed_data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize scaler for normalization
        self.scaler = MinMaxScaler(
            feature_range=(
                self.processing_config.normalization.scale_min,
                self.processing_config.normalization.scale_max
            )
        )
        
        self.logger.info("✅ Data processor initialized")
    
    def process(self, raw_data: Dict) -> Optional[Dict]:
        """Process a single data item."""
        try:
            # Validate raw data
            if not self._validate_raw_data(raw_data):
                return None
            
            # Extract and normalize prices
            normalized_prices = self._normalize_prices(raw_data['prices'])
            
            # Calculate quality score
            quality_score = self._calculate_quality_score(raw_data)
            
            # Detect outliers
            is_outlier = self._detect_outlier(raw_data['prices'])
            
            # Extract features
            features = self._extract_features(raw_data)
            
            # Build processed data structure
            processed = {
                'symbol': raw_data['symbol'],
                'source': raw_data['source'],
                'timestamp': raw_data['timestamp'],
                'collected_at': raw_data['collected_at'],
                'processed_at': datetime.now().isoformat(),
                'original_prices': raw_data['prices'],
                'normalized_prices': normalized_prices,
                'quality_score': quality_score,
                'is_outlier': is_outlier,
                'features': features,
                'metadata': raw_data.get('metadata', {}),
                'stats': raw_data.get('stats', {})
            }
            
            # Save processed data
            self._save_processed_data(processed)
            
            return processed
            
        except Exception as e:
            self.logger.error(f"Failed to process data: {e}")
            return None
    
    def _validate_raw_data(self, data: Dict) -> bool:
        """Validate raw data structure."""
        required_fields = ['symbol', 'timestamp', 'prices']
        
        for field in required_fields:
            if field not in data:
                self.logger.warning(f"Missing required field: {field}")
                return False
        
        return True
    
    def _normalize_prices(self, prices: Dict) -> Dict:
        """Normalize prices using configured method."""
        if self.processing_config.normalization.method == "minmax":
            return self._normalize_minmax(prices)
        elif self.processing_config.normalization.method == "standard":
            return self._normalize_standard(prices)
        else:
            self.logger.warning(f"Unknown normalization method, using minmax")
            return self._normalize_minmax(prices)
    
    def _normalize_minmax(self, prices: Dict) -> Dict:
        """Normalize prices using min-max scaling."""
        # Extract price values (excluding volume)
        price_values = [
            prices['open'],
            prices['high'],
            prices['low'],
            prices['close']
        ]
        
        # Find min and max
        min_price = min(price_values)
        max_price = max(price_values)
        
        # Avoid division by zero
        if max_price == min_price:
            scale_min = self.processing_config.normalization.scale_min
            normalized = {
                'open': scale_min,
                'high': scale_min,
                'low': scale_min,
                'close': scale_min,
                'volume': prices['volume']  # Keep volume as-is
            }
        else:
            # Normalize to configured scale
            scale_min = self.processing_config.normalization.scale_min
            scale_max = self.processing_config.normalization.scale_max
            scale_range = scale_max - scale_min
            
            def normalize(value):
                return int(scale_min + ((value - min_price) / (max_price - min_price)) * scale_range)
            
            normalized = {
                'open': normalize(prices['open']),
                'high': normalize(prices['high']),
                'low': normalize(prices['low']),
                'close': normalize(prices['close']),
                'volume': prices['volume']
            }
        
        # Add normalization metadata
        normalized['_normalization'] = {
            'method': 'minmax',
            'min_price': min_price,
            'max_price': max_price,
            'scale_min': self.processing_config.normalization.scale_min,
            'scale_max': self.processing_config.normalization.scale_max
        }
        
        return normalized
    
    def _normalize_standard(self, prices: Dict) -> Dict:
        """Normalize prices using standardization (z-score)."""
        price_values = [
            prices['open'],
            prices['high'],
            prices['low'],
            prices['close']
        ]
        
        mean = np.mean(price_values)
        std = np.std(price_values)
        
        if std == 0:
            normalized = {
                'open': 0.0,
                'high': 0.0,
                'low': 0.0,
                'close': 0.0,
                'volume': prices['volume']
            }
        else:
            def standardize(value):
                return (value - mean) / std
            
            normalized = {
                'open': standardize(prices['open']),
                'high': standardize(prices['high']),
                'low': standardize(prices['low']),
                'close': standardize(prices['close']),
                'volume': prices['volume']
            }
        
        normalized['_normalization'] = {
            'method': 'standard',
            'mean': mean,
            'std': std
        }
        
        return normalized
    
    def _calculate_quality_score(self, data: Dict) -> float:
        """Calculate data quality score."""
        weights = self.processing_config.quality_scoring.weights
        
        # 1. Completeness score (40%)
        completeness = self._calculate_completeness(data)
        
        # 2. Freshness score (30%)
        freshness = self._calculate_freshness(data)
        
        # 3. Consistency score (30%)
        consistency = self._calculate_consistency(data)
        
        # Weighted average
        quality = (
            completeness * weights['completeness'] +
            freshness * weights['freshness'] +
            consistency * weights['consistency']
        )
        
        # Clamp to configured range
        min_score = self.processing_config.quality_scoring.min_score
        max_score = self.processing_config.quality_scoring.max_score
        
        return max(min_score, min(quality, max_score))
    
    def _calculate_completeness(self, data: Dict) -> float:
        """Calculate data completeness score."""
        required_fields = [
            'symbol', 'timestamp', 'prices',
            'prices.open', 'prices.high', 'prices.low', 'prices.close', 'prices.volume'
        ]
        
        present = 0
        for field in required_fields:
            if '.' in field:
                parts = field.split('.')
                value = data
                for part in parts:
                    value = value.get(part, {})
                if value:
                    present += 1
            else:
                if field in data:
                    present += 1
        
        return present / len(required_fields)
    
    def _calculate_freshness(self, data: Dict) -> float:
        """Calculate data freshness score."""
        try:
            timestamp = datetime.fromisoformat(data['timestamp'].replace('Z', '+00:00'))
            age = (datetime.now() - timestamp.replace(tzinfo=None)).total_seconds()
            
            # Fresh data: < 1 hour = 1.0
            # Old data: > 24 hours = 0.0
            # Linear decay between
            if age < 3600:  # < 1 hour
                return 1.0
            elif age > 86400:  # > 24 hours
                return 0.0
            else:
                return 1.0 - ((age - 3600) / (86400 - 3600))
                
        except Exception:
            return 0.5  # Default if timestamp parsing fails
    
    def _calculate_consistency(self, data: Dict) -> float:
        """Calculate data consistency score."""
        try:
            prices = data['prices']
            
            # Check OHLC relationships
            checks = [
                prices['low'] <= prices['open'] <= prices['high'],
                prices['low'] <= prices['close'] <= prices['high'],
                prices['high'] >= prices['low'],
                prices['volume'] >= 0
            ]
            
            return sum(checks) / len(checks)
            
        except Exception:
            return 0.0
    
    def _detect_outlier(self, prices: Dict) -> bool:
        """Detect if prices contain outliers."""
        if not self.processing_config.outlier_detection.enabled:
            return False
        
        method = self.processing_config.outlier_detection.method
        
        if method == "iqr":
            return self._detect_outlier_iqr(prices)
        elif method == "zscore":
            return self._detect_outlier_zscore(prices)
        else:
            return False
    
    def _detect_outlier_iqr(self, prices: Dict) -> bool:
        """Detect outliers using IQR method."""
        price_values = [
            prices['open'],
            prices['high'],
            prices['low'],
            prices['close']
        ]
        
        q1 = np.percentile(price_values, 25)
        q3 = np.percentile(price_values, 75)
        iqr = q3 - q1
        
        threshold = self.processing_config.outlier_detection.threshold
        lower_bound = q1 - threshold * iqr
        upper_bound = q3 + threshold * iqr
        
        # Check if any price is outside bounds
        for value in price_values:
            if value < lower_bound or value > upper_bound:
                return True
        
        return False
    
    def _detect_outlier_zscore(self, prices: Dict) -> bool:
        """Detect outliers using z-score method."""
        price_values = [
            prices['open'],
            prices['high'],
            prices['low'],
            prices['close']
        ]
        
        mean = np.mean(price_values)
        std = np.std(price_values)
        
        if std == 0:
            return False
        
        threshold = self.processing_config.outlier_detection.threshold
        
        for value in price_values:
            z_score = abs((value - mean) / std)
            if z_score > threshold:
                return True
        
        return False
    
    def _extract_features(self, data: Dict) -> Dict:
        """Extract additional features from data."""
        prices = data['prices']
        
        features = {
            # Price range
            'daily_range': prices['high'] - prices['low'],
            'daily_range_pct': ((prices['high'] - prices['low']) / prices['close']) * 100,
            
            # Price change
            'change': prices['close'] - prices['open'],
            'change_pct': ((prices['close'] - prices['open']) / prices['open']) * 100,
            
            # Position in range
            'close_position': (prices['close'] - prices['low']) / (prices['high'] - prices['low']) if prices['high'] != prices['low'] else 0.5,
            
            # Volume indicators
            'volume': prices['volume'],
            
            # Volatility estimate
            'volatility_estimate': abs(prices['high'] - prices['low']) / prices['close']
        }
        
        return features
    
    def _save_processed_data(self, data: Dict):
        """Save processed data to disk."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        symbol = data['symbol'].replace('-', '_')
        filename = self.data_dir / f"processed_{symbol}_{timestamp}.json"
        
        try:
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
            
            self.logger.debug(f"💾 Saved processed data to {filename}")
            
        except Exception as e:
            self.logger.error(f"Failed to save processed data: {e}")
    
    def process_batch(self, raw_data_list: List[Dict]) -> List[Dict]:
        """Process multiple data items."""
        processed = []
        
        for raw_data in raw_data_list:
            result = self.process(raw_data)
            if result:
                processed.append(result)
        
        return processed
