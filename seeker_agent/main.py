"""
═══════════════════════════════════════════════════════════════════════════
PROPHETIA Seeker Agent - Main Entry Point
═══════════════════════════════════════════════════════════════════════════
Automated data collection and blockchain upload system for PROPHETIA oracle.
"""

import sys
import signal
import logging
from pathlib import Path
from typing import Optional
import click
from dotenv import load_dotenv

from core.agent import SeekerAgent
from core.config import Config
from utils.logger import setup_logger

# Load environment variables
load_dotenv()

# Global agent instance
agent: Optional[SeekerAgent] = None


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    logger = logging.getLogger(__name__)
    logger.info(f"Received signal {signum}. Shutting down gracefully...")
    
    if agent:
        agent.stop()
    
    sys.exit(0)


@click.group()
def cli():
    """PROPHETIA Seeker Agent - Automated data collection and blockchain upload."""
    pass


@cli.command()
@click.option('--config', '-c', default='config.yaml', help='Path to config file')
@click.option('--dry-run', is_flag=True, help='Run without uploading to blockchain')
@click.option('--once', is_flag=True, help='Run once and exit (no scheduling)')
def start(config: str, dry_run: bool, once: bool):
    """Start the Seeker Agent."""
    global agent
    
    # Setup logging
    logger = setup_logger()
    logger.info("=" * 80)
    logger.info("PROPHETIA Seeker Agent Starting...")
    logger.info("=" * 80)
    
    try:
        # Load configuration
        config_path = Path(config)
        if not config_path.exists():
            logger.error(f"Config file not found: {config}")
            sys.exit(1)
        
        cfg = Config.from_file(config_path)
        
        # Override with CLI flags
        if dry_run:
            cfg.features.dry_run = True
            logger.warning("🔴 DRY RUN MODE - No blockchain uploads will occur")
        
        # Initialize agent
        agent = SeekerAgent(cfg)
        
        # Register signal handlers
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        # Start agent
        if once:
            logger.info("Running in ONCE mode - will execute one cycle and exit")
            agent.run_once()
            logger.info("✅ Single execution complete. Exiting.")
        else:
            logger.info("Starting in SCHEDULED mode - will run continuously")
            agent.start()
        
    except KeyboardInterrupt:
        logger.info("Interrupted by user. Shutting down...")
        if agent:
            agent.stop()
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}", exc_info=True)
        sys.exit(1)


@cli.command()
@click.option('--config', '-c', default='config.yaml', help='Path to config file')
def test(config: str):
    """Test data collection without uploading."""
    logger = setup_logger()
    logger.info("=" * 80)
    logger.info("PROPHETIA Seeker Agent - Test Mode")
    logger.info("=" * 80)
    
    try:
        config_path = Path(config)
        cfg = Config.from_file(config_path)
        cfg.features.dry_run = True
        
        agent = SeekerAgent(cfg)
        
        logger.info("Testing data collection...")
        agent.run_once()
        
        logger.info("✅ Test complete. Check logs for details.")
        
    except Exception as e:
        logger.error(f"❌ Test failed: {e}", exc_info=True)
        sys.exit(1)


@cli.command()
@click.option('--config', '-c', default='config.yaml', help='Path to config file')
def validate(config: str):
    """Validate configuration file."""
    logger = setup_logger()
    
    try:
        config_path = Path(config)
        if not config_path.exists():
            logger.error(f"Config file not found: {config}")
            sys.exit(1)
        
        cfg = Config.from_file(config_path)
        
        logger.info("✅ Configuration is valid!")
        logger.info(f"   Network: {cfg.blockchain.network}")
        logger.info(f"   Data sources: {len(cfg.data_sources.yahoo_finance.stocks)} stocks")
        logger.info(f"   Scheduling: {cfg.scheduling.mode}")
        logger.info(f"   Dry run: {cfg.features.dry_run}")
        
    except Exception as e:
        logger.error(f"❌ Configuration validation failed: {e}")
        sys.exit(1)


@cli.command()
def status():
    """Check agent status and recent activity."""
    logger = setup_logger()
    
    # Check if agent is running (TODO: implement PID file)
    logger.info("Checking agent status...")
    
    # Display recent logs
    log_file = Path("logs/seeker_agent.log")
    if log_file.exists():
        logger.info(f"\nRecent log entries from {log_file}:")
        with open(log_file, 'r') as f:
            lines = f.readlines()
            for line in lines[-20:]:  # Last 20 lines
                print(line.strip())
    else:
        logger.warning("No log file found.")


@cli.command()
@click.option('--days', default=30, help='Number of days to keep')
def cleanup(days: int):
    """Clean up old data files."""
    logger = setup_logger()
    logger.info(f"Cleaning up data older than {days} days...")
    
    from datetime import datetime, timedelta
    import shutil
    
    cutoff = datetime.now() - timedelta(days=days)
    data_dir = Path("data")
    
    if not data_dir.exists():
        logger.warning("Data directory not found.")
        return
    
    removed_count = 0
    for item in data_dir.rglob("*"):
        if item.is_file():
            mtime = datetime.fromtimestamp(item.stat().st_mtime)
            if mtime < cutoff:
                logger.info(f"Removing: {item}")
                item.unlink()
                removed_count += 1
    
    logger.info(f"✅ Removed {removed_count} old files.")


if __name__ == '__main__':
    cli()
