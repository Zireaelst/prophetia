"""Configuration management for Seeker Agent."""

from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Any
import yaml


@dataclass
class YahooFinanceConfig:
    """Yahoo Finance data source configuration."""
    enabled: bool = True
    stocks: List[str] = field(default_factory=list)
    period: str = "1y"
    interval: str = "1d"
    retry_limit: int = 3
    retry_delay: int = 5


@dataclass
class DataSourcesConfig:
    """Data sources configuration."""
    yahoo_finance: YahooFinanceConfig = field(default_factory=YahooFinanceConfig)


@dataclass
class NormalizationConfig:
    """Data normalization configuration."""
    method: str = "minmax"
    scale_min: int = 0
    scale_max: int = 1000000


@dataclass
class QualityScoringConfig:
    """Quality scoring configuration."""
    weights: Dict[str, float] = field(default_factory=lambda: {
        "completeness": 0.4,
        "freshness": 0.3,
        "consistency": 0.3
    })
    min_score: int = 500000
    max_score: int = 1000000


@dataclass
class OutlierDetectionConfig:
    """Outlier detection configuration."""
    enabled: bool = True
    method: str = "iqr"
    threshold: float = 3.0


@dataclass
class DataProcessingConfig:
    """Data processing configuration."""
    normalization: NormalizationConfig = field(default_factory=NormalizationConfig)
    quality_scoring: QualityScoringConfig = field(default_factory=QualityScoringConfig)
    outlier_detection: OutlierDetectionConfig = field(default_factory=OutlierDetectionConfig)


@dataclass
class BlockchainConfig:
    """Blockchain configuration."""
    network: str = "testnet"
    contract_address: str = "prophetia.aleo"
    private_key: str = ""
    endpoint: str = "https://api.explorer.aleo.org/v1"
    gas_limit: int = 100000
    fee: int = 1000
    upload_config: Dict[str, int] = field(default_factory=lambda: {
        "batch_size": 10,
        "batch_delay": 5,
        "max_retries": 3,
        "retry_delay": 10
    })


@dataclass
class SchedulingConfig:
    """Scheduling configuration."""
    mode: str = "interval"
    interval: Dict[str, int] = field(default_factory=lambda: {
        "stock_updates": 3600,
        "historical_sync": 86400
    })
    cron: Dict[str, str] = field(default_factory=lambda: {
        "stock_updates": "0 * * * *",
        "historical_sync": "0 2 * * *",
        "cleanup_old_data": "0 3 * * 0"
    })


@dataclass
class LoggingConfig:
    """Logging configuration."""
    level: str = "INFO"
    format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    file: str = "logs/seeker_agent.log"
    max_bytes: int = 10485760
    backup_count: int = 5
    console: bool = True


@dataclass
class StorageConfig:
    """Storage configuration."""
    raw_data_dir: str = "data/raw"
    processed_data_dir: str = "data/processed"
    cache_dir: str = "data/cache"
    retention_days: int = 30


@dataclass
class EmailConfig:
    """Email notification configuration."""
    enabled: bool = False
    smtp_server: str = "smtp.gmail.com"
    smtp_port: int = 587
    sender: str = ""
    recipients: List[str] = field(default_factory=list)
    password: str = ""


@dataclass
class SlackConfig:
    """Slack notification configuration."""
    enabled: bool = False
    webhook_url: str = ""
    channel: str = "#prophetia-alerts"


@dataclass
class NotificationsConfig:
    """Notifications configuration."""
    enabled: bool = False
    email: EmailConfig = field(default_factory=EmailConfig)
    slack: SlackConfig = field(default_factory=SlackConfig)


@dataclass
class PerformanceConfig:
    """Performance configuration."""
    max_workers: int = 4
    request_timeout: int = 30
    rate_limit_delay: int = 1
    memory_limit_mb: int = 512


@dataclass
class FeaturesConfig:
    """Feature flags."""
    auto_start: bool = True
    dry_run: bool = False
    cache_enabled: bool = True
    metrics_enabled: bool = True


@dataclass
class Config:
    """Main configuration class."""
    data_sources: DataSourcesConfig = field(default_factory=DataSourcesConfig)
    data_processing: DataProcessingConfig = field(default_factory=DataProcessingConfig)
    blockchain: BlockchainConfig = field(default_factory=BlockchainConfig)
    scheduling: SchedulingConfig = field(default_factory=SchedulingConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)
    storage: StorageConfig = field(default_factory=StorageConfig)
    notifications: NotificationsConfig = field(default_factory=NotificationsConfig)
    performance: PerformanceConfig = field(default_factory=PerformanceConfig)
    features: FeaturesConfig = field(default_factory=FeaturesConfig)
    
    @classmethod
    def from_file(cls, path: Path) -> 'Config':
        """Load configuration from YAML file."""
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        
        return cls(
            data_sources=DataSourcesConfig(
                yahoo_finance=YahooFinanceConfig(**data.get('data_sources', {}).get('yahoo_finance', {}))
            ),
            data_processing=DataProcessingConfig(
                normalization=NormalizationConfig(**data.get('data_processing', {}).get('normalization', {})),
                quality_scoring=QualityScoringConfig(**data.get('data_processing', {}).get('quality_scoring', {})),
                outlier_detection=OutlierDetectionConfig(**data.get('data_processing', {}).get('outlier_detection', {}))
            ),
            blockchain=BlockchainConfig(**data.get('blockchain', {})),
            scheduling=SchedulingConfig(**data.get('scheduling', {})),
            logging=LoggingConfig(**data.get('logging', {})),
            storage=StorageConfig(**data.get('storage', {})),
            notifications=NotificationsConfig(
                enabled=data.get('notifications', {}).get('enabled', False),
                email=EmailConfig(**data.get('notifications', {}).get('email', {})),
                slack=SlackConfig(**data.get('notifications', {}).get('slack', {}))
            ),
            performance=PerformanceConfig(**data.get('performance', {})),
            features=FeaturesConfig(**data.get('features', {}))
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary."""
        return {
            'data_sources': {
                'yahoo_finance': {
                    'enabled': self.data_sources.yahoo_finance.enabled,
                    'stocks': self.data_sources.yahoo_finance.stocks,
                    'period': self.data_sources.yahoo_finance.period,
                    'interval': self.data_sources.yahoo_finance.interval
                }
            },
            'blockchain': {
                'network': self.blockchain.network,
                'contract_address': self.blockchain.contract_address
            },
            'scheduling': {
                'mode': self.scheduling.mode
            },
            'features': {
                'dry_run': self.features.dry_run,
                'cache_enabled': self.features.cache_enabled
            }
        }
