"""Test configuration module."""

import pytest
from pathlib import Path
import tempfile
import yaml

from core.config import Config, YahooFinanceConfig


@pytest.fixture
def temp_config_dir(tmp_path):
    """Create temporary config directory."""
    config_dir = tmp_path / "config"
    config_dir.mkdir()
    return config_dir


@pytest.fixture
def sample_config_dict():
    """Sample configuration dictionary."""
    return {
        'data_sources': {
            'yahoo_finance': {
                'enabled': True,
                'stocks': ['AAPL', 'GOOGL', 'MSFT'],
                'period': '1mo',
                'interval': '1d',
                'max_retries': 3,
                'retry_delay': 5
            }
        },
        'data_processing': {
            'normalization': {
                'method': 'minmax',
                'scale_min': 0,
                'scale_max': 1000000
            },
            'quality_scoring': {
                'weights': {
                    'completeness': 0.4,
                    'freshness': 0.3,
                    'consistency': 0.3
                },
                'min_score': 0.0,
                'max_score': 1.0
            },
            'outlier_detection': {
                'enabled': True,
                'method': 'iqr',
                'threshold': 3.0
            }
        },
        'blockchain': {
            'network': 'testnet',
            'contract_address': 'prophetia.aleo',
            'private_key': 'test_key_123',
            'endpoint': 'https://api.explorer.provable.com/v1',
            'gas_limit': 100000,
            'fee': 1000000,
            'upload_config': {
                'batch_size': 10,
                'batch_delay': 5,
                'max_retries': 3,
                'retry_delay': 10
            }
        },
        'scheduling': {
            'mode': 'interval',
            'interval': {
                'stock_updates': 3600,
                'historical_sync': 86400
            },
            'cron': {
                'stock_updates': '0 * * * *',
                'historical_sync': '0 0 * * *'
            }
        },
        'logging': {
            'level': 'INFO',
            'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            'file': 'logs/seeker_agent.log',
            'max_bytes': 10485760,
            'backup_count': 5,
            'console': True
        },
        'storage': {
            'raw_data_dir': 'data/raw',
            'processed_data_dir': 'data/processed',
            'cache_dir': 'data/cache',
            'retention_days': 30
        },
        'notifications': {
            'enabled': False,
            'email': {
                'smtp_server': 'smtp.gmail.com',
                'smtp_port': 587,
                'sender': 'seeker@prophetia.io',
                'recipients': [],
                'password': ''
            },
            'slack': {
                'webhook_url': '',
                'channel': '#prophetia-alerts'
            }
        },
        'performance': {
            'max_workers': 4,
            'request_timeout': 30,
            'rate_limit_delay': 1.0,
            'memory_limit_mb': 512
        },
        'features': {
            'auto_start': True,
            'dry_run': False,
            'cache_enabled': True,
            'metrics_enabled': True
        }
    }


@pytest.fixture
def sample_config_file(temp_config_dir, sample_config_dict):
    """Create sample config file."""
    config_file = temp_config_dir / "config.yaml"
    
    with open(config_file, 'w') as f:
        yaml.dump(sample_config_dict, f)
    
    return config_file


class TestYahooFinanceConfig:
    """Test Yahoo Finance configuration."""
    
    def test_default_values(self):
        """Test default configuration values."""
        config = YahooFinanceConfig(
            enabled=True,
            stocks=['AAPL'],
            period='1y',
            interval='1d'
        )
        
        assert config.enabled is True
        assert config.stocks == ['AAPL']
        assert config.period == '1y'
        assert config.interval == '1d'
        assert config.max_retries == 3
        assert config.retry_delay == 5


class TestConfig:
    """Test main Config class."""
    
    def test_from_dict(self, sample_config_dict):
        """Test loading config from dictionary."""
        config = Config.from_dict(sample_config_dict)
        
        assert config.data_sources.yahoo_finance.enabled is True
        assert len(config.data_sources.yahoo_finance.stocks) == 3
        assert config.blockchain.network == 'testnet'
        assert config.scheduling.mode == 'interval'
    
    def test_from_file(self, sample_config_file):
        """Test loading config from YAML file."""
        config = Config.from_file(sample_config_file)
        
        assert config.data_sources.yahoo_finance.enabled is True
        assert config.blockchain.contract_address == 'prophetia.aleo'
        assert config.features.cache_enabled is True
    
    def test_to_dict(self, sample_config_dict):
        """Test converting config to dictionary."""
        config = Config.from_dict(sample_config_dict)
        config_dict = config.to_dict()
        
        assert 'data_sources' in config_dict
        assert 'blockchain' in config_dict
        assert 'features' in config_dict
    
    def test_missing_required_field(self):
        """Test error on missing required field."""
        incomplete_config = {
            'data_sources': {
                'yahoo_finance': {
                    'enabled': True
                    # Missing 'stocks' field
                }
            }
        }
        
        with pytest.raises(Exception):
            Config.from_dict(incomplete_config)
    
    def test_normalization_config(self, sample_config_dict):
        """Test normalization configuration."""
        config = Config.from_dict(sample_config_dict)
        
        assert config.data_processing.normalization.method == 'minmax'
        assert config.data_processing.normalization.scale_min == 0
        assert config.data_processing.normalization.scale_max == 1000000
    
    def test_quality_scoring_weights(self, sample_config_dict):
        """Test quality scoring weights."""
        config = Config.from_dict(sample_config_dict)
        weights = config.data_processing.quality_scoring.weights
        
        assert weights['completeness'] == 0.4
        assert weights['freshness'] == 0.3
        assert weights['consistency'] == 0.3
        assert sum(weights.values()) == 1.0
    
    def test_blockchain_config(self, sample_config_dict):
        """Test blockchain configuration."""
        config = Config.from_dict(sample_config_dict)
        
        assert config.blockchain.network == 'testnet'
        assert config.blockchain.gas_limit == 100000
        assert config.blockchain.upload_config['batch_size'] == 10
