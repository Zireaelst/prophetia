"""Test data processor."""

import pytest
from unittest.mock import Mock
from datetime import datetime, timedelta

from processors.data_processor import DataProcessor
from core.config import Config


@pytest.fixture
def mock_config():
    """Create mock configuration."""
    config = Mock(spec=Config)
    
    # Normalization config
    config.data_processing.normalization = Mock(
        method='minmax',
        scale_min=0,
        scale_max=1000000
    )
    
    # Quality scoring config
    config.data_processing.quality_scoring = Mock(
        weights={'completeness': 0.4, 'freshness': 0.3, 'consistency': 0.3},
        min_score=0.0,
        max_score=1.0
    )
    
    # Outlier detection config
    config.data_processing.outlier_detection = Mock(
        enabled=True,
        method='iqr',
        threshold=3.0
    )
    
    config.storage.processed_data_dir = 'data/processed'
    
    return config


@pytest.fixture
def sample_raw_data():
    """Sample raw data for processing."""
    return {
        'symbol': 'AAPL',
        'source': 'yahoo_finance',
        'timestamp': datetime.now().isoformat(),
        'collected_at': datetime.now().isoformat(),
        'prices': {
            'open': 150.0,
            'high': 155.0,
            'low': 148.0,
            'close': 152.0,
            'volume': 1000000
        },
        'metadata': {
            'company_name': 'Apple Inc.',
            'sector': 'Technology'
        },
        'stats': {
            'week_high_52': 200.0,
            'week_low_52': 120.0
        }
    }


class TestDataProcessor:
    """Test data processor."""
    
    def test_initialization(self, mock_config):
        """Test processor initialization."""
        processor = DataProcessor(mock_config)
        
        assert processor.config == mock_config
        assert processor.processing_config == mock_config.data_processing
    
    def test_process_success(self, mock_config, sample_raw_data):
        """Test successful data processing."""
        processor = DataProcessor(mock_config)
        processed = processor.process(sample_raw_data)
        
        # Verify processed structure
        assert processed is not None
        assert processed['symbol'] == 'AAPL'
        assert 'normalized_prices' in processed
        assert 'quality_score' in processed
        assert 'is_outlier' in processed
        assert 'features' in processed
    
    def test_normalize_minmax(self, mock_config, sample_raw_data):
        """Test min-max normalization."""
        processor = DataProcessor(mock_config)
        normalized = processor._normalize_minmax(sample_raw_data['prices'])
        
        # Verify normalization
        assert 'open' in normalized
        assert 'high' in normalized
        assert 'low' in normalized
        assert 'close' in normalized
        
        # Verify values are in range [0, 1000000]
        assert 0 <= normalized['open'] <= 1000000
        assert 0 <= normalized['high'] <= 1000000
        assert 0 <= normalized['low'] <= 1000000
        assert 0 <= normalized['close'] <= 1000000
        
        # Verify high is maximum
        assert normalized['high'] == 1000000
        
        # Verify low is minimum
        assert normalized['low'] == 0
    
    def test_normalize_standard(self, mock_config, sample_raw_data):
        """Test standard normalization (z-score)."""
        processor = DataProcessor(mock_config)
        normalized = processor._normalize_standard(sample_raw_data['prices'])
        
        # Verify normalization
        assert 'open' in normalized
        assert '_normalization' in normalized
        assert normalized['_normalization']['method'] == 'standard'
    
    def test_calculate_quality_score(self, mock_config, sample_raw_data):
        """Test quality score calculation."""
        processor = DataProcessor(mock_config)
        score = processor._calculate_quality_score(sample_raw_data)
        
        # Verify score is in valid range
        assert 0.0 <= score <= 1.0
    
    def test_calculate_completeness_full(self, mock_config, sample_raw_data):
        """Test completeness calculation with complete data."""
        processor = DataProcessor(mock_config)
        completeness = processor._calculate_completeness(sample_raw_data)
        
        # Should be 1.0 for complete data
        assert completeness == 1.0
    
    def test_calculate_completeness_partial(self, mock_config):
        """Test completeness calculation with incomplete data."""
        processor = DataProcessor(mock_config)
        
        partial_data = {
            'symbol': 'AAPL',
            'timestamp': datetime.now().isoformat(),
            'prices': {
                'open': 150.0,
                'close': 152.0
                # Missing high, low, volume
            }
        }
        
        completeness = processor._calculate_completeness(partial_data)
        
        # Should be less than 1.0
        assert completeness < 1.0
    
    def test_calculate_freshness_recent(self, mock_config, sample_raw_data):
        """Test freshness calculation for recent data."""
        processor = DataProcessor(mock_config)
        freshness = processor._calculate_freshness(sample_raw_data)
        
        # Recent data should have high freshness
        assert freshness >= 0.8
    
    def test_calculate_freshness_old(self, mock_config):
        """Test freshness calculation for old data."""
        processor = DataProcessor(mock_config)
        
        old_data = {
            'timestamp': (datetime.now() - timedelta(days=2)).isoformat()
        }
        
        freshness = processor._calculate_freshness(old_data)
        
        # Old data should have low freshness
        assert freshness == 0.0
    
    def test_calculate_consistency_valid(self, mock_config, sample_raw_data):
        """Test consistency calculation with valid OHLC."""
        processor = DataProcessor(mock_config)
        consistency = processor._calculate_consistency(sample_raw_data)
        
        # Valid OHLC should have perfect consistency
        assert consistency == 1.0
    
    def test_calculate_consistency_invalid(self, mock_config):
        """Test consistency calculation with invalid OHLC."""
        processor = DataProcessor(mock_config)
        
        invalid_data = {
            'prices': {
                'open': 150.0,
                'high': 145.0,  # High < Open (invalid)
                'low': 148.0,
                'close': 152.0,
                'volume': 1000000
            }
        }
        
        consistency = processor._calculate_consistency(invalid_data)
        
        # Invalid OHLC should have lower consistency
        assert consistency < 1.0
    
    def test_detect_outlier_iqr_normal(self, mock_config, sample_raw_data):
        """Test outlier detection with normal data."""
        processor = DataProcessor(mock_config)
        is_outlier = processor._detect_outlier_iqr(sample_raw_data['prices'])
        
        # Normal data should not be outlier
        assert is_outlier is False
    
    def test_detect_outlier_iqr_extreme(self, mock_config):
        """Test outlier detection with extreme values."""
        processor = DataProcessor(mock_config)
        
        extreme_prices = {
            'open': 150.0,
            'high': 155.0,
            'low': 148.0,
            'close': 500.0,  # Extreme value
            'volume': 1000000
        }
        
        is_outlier = processor._detect_outlier_iqr(extreme_prices)
        
        # Extreme value should be detected as outlier
        assert is_outlier is True
    
    def test_extract_features(self, mock_config, sample_raw_data):
        """Test feature extraction."""
        processor = DataProcessor(mock_config)
        features = processor._extract_features(sample_raw_data)
        
        # Verify features
        assert 'daily_range' in features
        assert 'daily_range_pct' in features
        assert 'change' in features
        assert 'change_pct' in features
        assert 'close_position' in features
        assert 'volume' in features
        assert 'volatility_estimate' in features
        
        # Verify calculations
        assert features['daily_range'] == 7.0  # 155 - 148
        assert features['change'] == 2.0  # 152 - 150
    
    def test_process_batch(self, mock_config, sample_raw_data):
        """Test batch processing."""
        processor = DataProcessor(mock_config)
        
        # Create multiple data items
        batch = [sample_raw_data, sample_raw_data.copy()]
        
        processed_batch = processor.process_batch(batch)
        
        # Verify batch processing
        assert len(processed_batch) == 2
        assert all('quality_score' in item for item in processed_batch)
    
    def test_validate_raw_data_valid(self, mock_config, sample_raw_data):
        """Test raw data validation with valid data."""
        processor = DataProcessor(mock_config)
        is_valid = processor._validate_raw_data(sample_raw_data)
        
        assert is_valid is True
    
    def test_validate_raw_data_invalid(self, mock_config):
        """Test raw data validation with invalid data."""
        processor = DataProcessor(mock_config)
        
        invalid_data = {
            'symbol': 'AAPL'
            # Missing timestamp and prices
        }
        
        is_valid = processor._validate_raw_data(invalid_data)
        
        assert is_valid is False
