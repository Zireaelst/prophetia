"""Yahoo Finance data collector."""

import logging
import time
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from pathlib import Path
import json

import yfinance as yf
import pandas as pd

from core.config import Config


class YahooFinanceCollector:
    """Collects stock market data from Yahoo Finance."""
    
    def __init__(self, config: Config):
        """Initialize Yahoo Finance collector."""
        self.config = config
        self.yahoo_config = config.data_sources.yahoo_finance
        self.logger = logging.getLogger(__name__)
        
        # Setup data directory
        self.data_dir = Path(config.storage.raw_data_dir) / "yahoo_finance"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Cache for avoiding redundant API calls
        self.cache = {} if config.features.cache_enabled else None
        self.cache_ttl = 300  # 5 minutes
        
        self.logger.info(f"✅ Yahoo Finance collector initialized")
        self.logger.info(f"   Tracking {len(self.yahoo_config.stocks)} symbols: {', '.join(self.yahoo_config.stocks)}")
    
    def collect(self) -> List[Dict]:
        """Collect latest data from Yahoo Finance."""
        self.logger.info(f"📥 Collecting data for {len(self.yahoo_config.stocks)} stocks...")
        
        all_data = []
        
        for symbol in self.yahoo_config.stocks:
            try:
                data = self._fetch_stock_data(symbol)
                if data:
                    all_data.append(data)
                
                # Rate limiting
                if self.config.performance.rate_limit_delay > 0:
                    time.sleep(self.config.performance.rate_limit_delay)
                    
            except Exception as e:
                self.logger.error(f"   ✗ Failed to fetch {symbol}: {e}")
        
        # Save raw data
        self._save_raw_data(all_data)
        
        self.logger.info(f"   ✓ Collected {len(all_data)} stocks successfully")
        return all_data
    
    def _fetch_stock_data(self, symbol: str) -> Optional[Dict]:
        """Fetch data for a single stock symbol."""
        # Check cache
        if self.cache is not None:
            cached = self._get_from_cache(symbol)
            if cached:
                self.logger.debug(f"   ↻ Using cached data for {symbol}")
                return cached
        
        self.logger.debug(f"   Fetching {symbol}...")
        
        retries = 0
        max_retries = self.yahoo_config.max_retries
        retry_delay = self.yahoo_config.retry_delay
        
        while retries <= max_retries:
            try:
                # Fetch data using yfinance
                ticker = yf.Ticker(symbol)
                
                # Get historical data
                hist = ticker.history(
                    period=self.yahoo_config.period,
                    interval=self.yahoo_config.interval
                )
                
                if hist.empty:
                    self.logger.warning(f"   No data returned for {symbol}")
                    return None
                
                # Get latest data point
                latest = hist.iloc[-1]
                timestamp = hist.index[-1]
                
                # Get additional info
                info = ticker.info
                
                # Build data structure
                data = {
                    'source': 'yahoo_finance',
                    'symbol': symbol,
                    'timestamp': timestamp.isoformat(),
                    'collected_at': datetime.now().isoformat(),
                    'prices': {
                        'open': float(latest['Open']),
                        'high': float(latest['High']),
                        'low': float(latest['Low']),
                        'close': float(latest['Close']),
                        'volume': int(latest['Volume'])
                    },
                    'metadata': {
                        'company_name': info.get('longName', symbol),
                        'sector': info.get('sector', 'Unknown'),
                        'industry': info.get('industry', 'Unknown'),
                        'market_cap': info.get('marketCap', 0),
                        'currency': info.get('currency', 'USD')
                    },
                    'stats': {
                        'week_high_52': info.get('fiftyTwoWeekHigh', 0),
                        'week_low_52': info.get('fiftyTwoWeekLow', 0),
                        'avg_volume': info.get('averageVolume', 0),
                        'pe_ratio': info.get('trailingPE', 0)
                    }
                }
                
                # Add to cache
                if self.cache is not None:
                    self._add_to_cache(symbol, data)
                
                return data
                
            except Exception as e:
                retries += 1
                if retries <= max_retries:
                    self.logger.warning(f"   Retry {retries}/{max_retries} for {symbol}: {e}")
                    time.sleep(retry_delay)
                else:
                    self.logger.error(f"   Failed to fetch {symbol} after {max_retries} retries")
                    return None
        
        return None
    
    def fetch_historical_data(self, symbol: str, days: int = 365) -> Optional[pd.DataFrame]:
        """Fetch historical data for analysis."""
        self.logger.info(f"📊 Fetching {days} days of historical data for {symbol}...")
        
        try:
            ticker = yf.Ticker(symbol)
            
            # Calculate date range
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days)
            
            # Fetch historical data
            hist = ticker.history(
                start=start_date.strftime('%Y-%m-%d'),
                end=end_date.strftime('%Y-%m-%d'),
                interval='1d'
            )
            
            if hist.empty:
                self.logger.warning(f"   No historical data for {symbol}")
                return None
            
            self.logger.info(f"   ✓ Fetched {len(hist)} data points")
            return hist
            
        except Exception as e:
            self.logger.error(f"   Failed to fetch historical data: {e}")
            return None
    
    def _get_from_cache(self, symbol: str) -> Optional[Dict]:
        """Get data from cache if not expired."""
        if symbol in self.cache:
            cached_data, cached_time = self.cache[symbol]
            
            # Check if cache is still valid
            if (datetime.now() - cached_time).total_seconds() < self.cache_ttl:
                return cached_data
            else:
                # Cache expired
                del self.cache[symbol]
        
        return None
    
    def _add_to_cache(self, symbol: str, data: Dict):
        """Add data to cache."""
        self.cache[symbol] = (data, datetime.now())
    
    def _save_raw_data(self, data: List[Dict]):
        """Save raw data to disk."""
        if not data:
            return
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = self.data_dir / f"raw_{timestamp}.json"
        
        try:
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
            
            self.logger.debug(f"   💾 Saved raw data to {filename}")
            
        except Exception as e:
            self.logger.error(f"   Failed to save raw data: {e}")
    
    def validate_data(self, data: Dict) -> bool:
        """Validate data completeness and quality."""
        required_fields = ['symbol', 'timestamp', 'prices']
        
        # Check required fields
        for field in required_fields:
            if field not in data:
                self.logger.warning(f"   Missing required field: {field}")
                return False
        
        # Check prices
        prices = data['prices']
        required_prices = ['open', 'high', 'low', 'close', 'volume']
        
        for price_field in required_prices:
            if price_field not in prices:
                self.logger.warning(f"   Missing price field: {price_field}")
                return False
            
            # Check for valid values
            value = prices[price_field]
            if price_field == 'volume':
                if not isinstance(value, int) or value < 0:
                    self.logger.warning(f"   Invalid volume: {value}")
                    return False
            else:
                if not isinstance(value, (int, float)) or value <= 0:
                    self.logger.warning(f"   Invalid price {price_field}: {value}")
                    return False
        
        # Check OHLC logic
        if not (prices['low'] <= prices['open'] <= prices['high'] and
                prices['low'] <= prices['close'] <= prices['high']):
            self.logger.warning("   Invalid OHLC relationship")
            return False
        
        return True
    
    def get_stats(self) -> Dict:
        """Get collector statistics."""
        return {
            'collector': 'yahoo_finance',
            'symbols': self.yahoo_config.stocks,
            'symbol_count': len(self.yahoo_config.stocks),
            'cache_enabled': self.cache is not None,
            'cached_items': len(self.cache) if self.cache else 0
        }
