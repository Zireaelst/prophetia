"""Main Seeker Agent class."""

import logging
import time
from datetime import datetime
from typing import Optional
from pathlib import Path

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from apscheduler.triggers.cron import CronTrigger

from core.config import Config
from collectors.yahoo_finance import YahooFinanceCollector
from processors.data_processor import DataProcessor
from uploaders.blockchain_uploader import BlockchainUploader
from utils.metrics import MetricsTracker


class SeekerAgent:
    """Main Seeker Agent orchestrator."""
    
    def __init__(self, config: Config):
        """Initialize Seeker Agent."""
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.scheduler = BackgroundScheduler()
        self.running = False
        
        # Initialize components
        self.logger.info("Initializing Seeker Agent components...")
        
        self.collectors = {}
        if config.data_sources.yahoo_finance.enabled:
            self.collectors['yahoo_finance'] = YahooFinanceCollector(config)
        
        self.processor = DataProcessor(config)
        self.uploader = BlockchainUploader(config)
        
        if config.features.metrics_enabled:
            self.metrics = MetricsTracker()
        else:
            self.metrics = None
        
        self.logger.info(f"✅ Initialized {len(self.collectors)} data collectors")
    
    def run_once(self):
        """Execute one complete cycle."""
        self.logger.info("=" * 80)
        self.logger.info(f"⏰ Starting collection cycle at {datetime.now()}")
        self.logger.info("=" * 80)
        
        start_time = time.time()
        
        try:
            # 1. Collect data
            self.logger.info("📥 Step 1/3: Collecting data from sources...")
            raw_data = self._collect_data()
            self.logger.info(f"   Collected {len(raw_data)} raw data points")
            
            # 2. Process data
            self.logger.info("⚙️  Step 2/3: Processing and validating data...")
            processed_data = self._process_data(raw_data)
            self.logger.info(f"   Processed {len(processed_data)} valid records")
            
            # 3. Upload to blockchain
            self.logger.info("📤 Step 3/3: Uploading to blockchain...")
            uploaded_count = self._upload_data(processed_data)
            self.logger.info(f"   Uploaded {uploaded_count} records successfully")
            
            # Record metrics
            elapsed = time.time() - start_time
            if self.metrics:
                self.metrics.record_cycle(len(raw_data), len(processed_data), uploaded_count, elapsed)
            
            self.logger.info("=" * 80)
            self.logger.info(f"✅ Cycle complete in {elapsed:.2f}s")
            self.logger.info(f"   Collection: {len(raw_data)} → Processing: {len(processed_data)} → Upload: {uploaded_count}")
            self.logger.info("=" * 80)
            
        except Exception as e:
            self.logger.error(f"❌ Cycle failed: {e}", exc_info=True)
            if self.metrics:
                self.metrics.record_error(str(e))
    
    def _collect_data(self) -> list:
        """Collect data from all enabled sources."""
        all_data = []
        
        for name, collector in self.collectors.items():
            try:
                self.logger.info(f"   Collecting from {name}...")
                data = collector.collect()
                all_data.extend(data)
                self.logger.info(f"   ✓ {name}: {len(data)} records")
            except Exception as e:
                self.logger.error(f"   ✗ {name} failed: {e}")
        
        return all_data
    
    def _process_data(self, raw_data: list) -> list:
        """Process and validate raw data."""
        processed = []
        
        for item in raw_data:
            try:
                processed_item = self.processor.process(item)
                if processed_item:
                    processed.append(processed_item)
            except Exception as e:
                self.logger.warning(f"   Failed to process item: {e}")
        
        return processed
    
    def _upload_data(self, processed_data: list) -> int:
        """Upload processed data to blockchain."""
        if self.config.features.dry_run:
            self.logger.warning("   🔴 DRY RUN - Skipping blockchain upload")
            return len(processed_data)
        
        uploaded = 0
        
        try:
            uploaded = self.uploader.upload_batch(processed_data)
        except Exception as e:
            self.logger.error(f"   Upload failed: {e}")
        
        return uploaded
    
    def start(self):
        """Start the agent with scheduling."""
        self.logger.info("Starting Seeker Agent scheduler...")
        
        # Add jobs based on scheduling mode
        if self.config.scheduling.mode == "interval":
            self._setup_interval_jobs()
        elif self.config.scheduling.mode == "cron":
            self._setup_cron_jobs()
        else:
            self.logger.error(f"Unknown scheduling mode: {self.config.scheduling.mode}")
            return
        
        # Start scheduler
        self.scheduler.start()
        self.running = True
        
        self.logger.info("✅ Scheduler started. Press Ctrl+C to stop.")
        
        # Keep running
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()
    
    def _setup_interval_jobs(self):
        """Setup interval-based jobs."""
        stock_interval = self.config.scheduling.interval['stock_updates']
        historical_interval = self.config.scheduling.interval['historical_sync']
        
        self.scheduler.add_job(
            self.run_once,
            trigger=IntervalTrigger(seconds=stock_interval),
            id='stock_updates',
            name='Stock Data Updates',
            replace_existing=True
        )
        
        self.logger.info(f"   ✓ Stock updates: every {stock_interval}s ({stock_interval // 60} minutes)")
        self.logger.info(f"   ✓ Historical sync: every {historical_interval}s ({historical_interval // 3600} hours)")
    
    def _setup_cron_jobs(self):
        """Setup cron-based jobs."""
        stock_cron = self.config.scheduling.cron['stock_updates']
        historical_cron = self.config.scheduling.cron['historical_sync']
        
        self.scheduler.add_job(
            self.run_once,
            trigger=CronTrigger.from_crontab(stock_cron),
            id='stock_updates',
            name='Stock Data Updates',
            replace_existing=True
        )
        
        self.logger.info(f"   ✓ Stock updates: {stock_cron}")
        self.logger.info(f"   ✓ Historical sync: {historical_cron}")
    
    def stop(self):
        """Stop the agent."""
        self.logger.info("Stopping Seeker Agent...")
        self.running = False
        
        if self.scheduler.running:
            self.scheduler.shutdown(wait=False)
        
        self.logger.info("✅ Agent stopped")
    
    def get_status(self) -> dict:
        """Get agent status."""
        jobs = []
        if self.scheduler.running:
            for job in self.scheduler.get_jobs():
                jobs.append({
                    'id': job.id,
                    'name': job.name,
                    'next_run': job.next_run_time.isoformat() if job.next_run_time else None
                })
        
        return {
            'running': self.running,
            'scheduler_running': self.scheduler.running,
            'collectors': list(self.collectors.keys()),
            'jobs': jobs,
            'config': self.config.to_dict()
        }
