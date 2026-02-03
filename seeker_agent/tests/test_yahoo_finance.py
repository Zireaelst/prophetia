"""Test Yahoo Finance collector."""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import pandas as pd

from collectors.yahoo_finance import YahooFinanceCollector
from core.config import Config


@pytest.fixture
def mock_config():
    """Create mock configuration."""
    config = Mock(spec=Config)
    config.data_sources.yahoo_finance = Mock(
        enabled=True,
        stocks=['AAPL', 'GOOGL'],
        period='1mo',
        interval='1d',
        max_retries=3,
        retry_delay=1
    )
    config.storage.raw_data_dir = 'data/raw'
    config.features.cache_enabled = True
    config.performance.rate_limit_delay = 0
    return config


@pytest.fixture
def sample_ticker_data():
    """Sample ticker historical data."""
    dates = pd.date_range('2024-01-01', periods=30, freq='D')
    return pd.DataFrame({
        'Open': [150.0 + i for i in range(30)],
        'High': [155.0 + i for i in range(30)],
        'Low': [148.0 + i for i in range(30)],
        'Close': [152.0 + i for i in range(30)],
        'Volume': [1000000 + i * 10000 for i in range(30)]
    }, index=dates)


@pytest.fixture
def sample_ticker_info():
    """Sample ticker info."""
    return {
        'longName': 'Apple Inc.',
        'sector': 'Technology',
        'industry': 'Consumer Electronics',
        'marketCap': 3000000000000,
        'currency': 'USD',
        'fiftyTwoWeekHigh': 200.0,
        'fiftyTwoWeekLow': 120.0,
        'averageVolume': 50000000,
        'trailingPE': 28.5
    }


class TestYahooFinanceCollector:
    """Test Yahoo Finance collector."""
    
    def test_initialization(self, mock_config):
        """Test collector initialization."""
        collector = YahooFinanceCollector(mock_config)
        
        assert collector.config == mock_config
        assert collector.yahoo_config == mock_config.data_sources.yahoo_finance
        assert collector.cache is not None
    
    @patch('collectors.yahoo_finance.yf.Ticker')
    def test_fetch_stock_data_success(self, mock_ticker, mock_config, sample_ticker_data, sample_ticker_info):
        """Test successful stock data fetch."""
        # Setup mock
        mock_instance = MagicMock()
        mock_instance.history.return_value = sample_ticker_data
        mock_instance.info = sample_ticker_info
        mock_ticker.return_value = mock_instance
        
        collector = YahooFinanceCollector(mock_config)
        data = collector._fetch_stock_data('AAPL')
        
        # Verify data structure
        assert data is not None
        assert data['symbol'] == 'AAPL'
        assert data['source'] == 'yahoo_finance'
        assert 'prices' in data
        assert 'metadata' in data
        assert 'stats' in data
        
        # Verify prices
        assert 'open' in data['prices']
        assert 'high' in data['prices']
        assert 'low' in data['prices']
        assert 'close' in data['prices']
        assert 'volume' in data['prices']
        
        # Verify metadata
        assert data['metadata']['company_name'] == 'Apple Inc.'
        assert data['metadata']['sector'] == 'Technology'
    
    @patch('collectors.yahoo_finance.yf.Ticker')
    def test_fetch_stock_data_empty_response(self, mock_ticker, mock_config):
        """Test handling of empty response."""
        # Setup mock to return empty dataframe
        mock_instance = MagicMock()
        mock_instance.history.return_value = pd.DataFrame()
        mock_ticker.return_value = mock_instance
        
        collector = YahooFinanceCollector(mock_config)
        data = collector._fetch_stock_data('INVALID')
        
        assert data is None
    
    @patch('collectors.yahoo_finance.yf.Ticker')
    def test_fetch_with_retry(self, mock_ticker, mock_config, sample_ticker_data, sample_ticker_info):
        """Test retry logic on failure."""
        # First call fails, second succeeds
        mock_instance = MagicMock()
        mock_instance.history.side_effect = [
            Exception("Network error"),
            sample_ticker_data
        ]
        mock_instance.info = sample_ticker_info
        mock_ticker.return_value = mock_instance
        
        collector = YahooFinanceCollector(mock_config)
        data = collector._fetch_stock_data('AAPL')
        
        # Should succeed after retry
        assert data is not None
        assert data['symbol'] == 'AAPL'
    
    @patch('collectors.yahoo_finance.yf.Ticker')
    def test_collect_multiple_stocks(self, mock_ticker, mock_config, sample_ticker_data, sample_ticker_info):
        """Test collecting multiple stocks."""
        # Setup mock
        mock_instance = MagicMock()
        mock_instance.history.return_value = sample_ticker_data
        mock_instance.info = sample_ticker_info
        mock_ticker.return_value = mock_instance
        
        collector = YahooFinanceCollector(mock_config)
        data_list = collector.collect()
        
        # Should collect data for 2 stocks
        assert len(data_list) == 2
        assert data_list[0]['symbol'] in ['AAPL', 'GOOGL']
        assert data_list[1]['symbol'] in ['AAPL', 'GOOGL']
    
    def test_cache_functionality(self, mock_config):
        """Test data caching."""
        collector = YahooFinanceCollector(mock_config)
        
        # Add to cache
        sample_data = {'symbol': 'AAPL', 'prices': {}}
        collector._add_to_cache('AAPL', sample_data)
        
        # Retrieve from cache
        cached = collector._get_from_cache('AAPL')
        assert cached is not None
        assert cached['symbol'] == 'AAPL'
    
    def test_validate_data_success(self, mock_config):
        """Test data validation success."""
        collector = YahooFinanceCollector(mock_config)
        
        valid_data = {
            'symbol': 'AAPL',
            'timestamp': datetime.now().isoformat(),
            'prices': {
                'open': 150.0,
                'high': 155.0,
                'low': 148.0,
                'close': 152.0,
                'volume': 1000000
            }
        }
        
        assert collector.validate_data(valid_data) is True
    
    def test_validate_data_missing_field(self, mock_config):
        """Test validation fails on missing field."""
        collector = YahooFinanceCollector(mock_config)
        
        invalid_data = {
            'symbol': 'AAPL',
            'timestamp': datetime.now().isoformat()
            # Missing 'prices' field
        }
        
        assert collector.validate_data(invalid_data) is False
    
    def test_validate_data_invalid_ohlc(self, mock_config):
        """Test validation fails on invalid OHLC relationship."""
        collector = YahooFinanceCollector(mock_config)
        
        invalid_data = {
            'symbol': 'AAPL',
            'timestamp': datetime.now().isoformat(),
            'prices': {
                'open': 150.0,
                'high': 145.0,  # High < Open (invalid)
                'low': 148.0,
                'close': 152.0,
                'volume': 1000000
            }
        }
        
        assert collector.validate_data(invalid_data) is False
    
    def test_get_stats(self, mock_config):
        """Test collector statistics."""
        collector = YahooFinanceCollector(mock_config)
        stats = collector.get_stats()
        
        assert 'collector' in stats
        assert stats['collector'] == 'yahoo_finance'
        assert 'symbols' in stats
        assert 'symbol_count' in stats
        assert stats['symbol_count'] == 2
