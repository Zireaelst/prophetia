"""Metrics tracking utility."""

import logging
from datetime import datetime
from typing import Dict, List
from collections import defaultdict


class MetricsTracker:
    """Tracks agent performance metrics."""
    
    def __init__(self):
        """Initialize metrics tracker."""
        self.logger = logging.getLogger(__name__)
        
        # Metrics storage
        self.cycles = []
        self.errors = []
        
        # Aggregated stats
        self.total_collected = 0
        self.total_processed = 0
        self.total_uploaded = 0
        self.total_errors = 0
        
        self.start_time = datetime.now()
        
        self.logger.info("✅ Metrics tracker initialized")
    
    def record_cycle(self, collected: int, processed: int, uploaded: int, elapsed: float):
        """Record a complete cycle."""
        cycle = {
            'timestamp': datetime.now().isoformat(),
            'collected': collected,
            'processed': processed,
            'uploaded': uploaded,
            'elapsed': elapsed,
            'success_rate': (uploaded / collected * 100) if collected > 0 else 0
        }
        
        self.cycles.append(cycle)
        
        # Update totals
        self.total_collected += collected
        self.total_processed += processed
        self.total_uploaded += uploaded
        
        self.logger.debug(f"📊 Cycle recorded: {collected}→{processed}→{uploaded} in {elapsed:.2f}s")
    
    def record_error(self, error: str):
        """Record an error."""
        error_record = {
            'timestamp': datetime.now().isoformat(),
            'error': error
        }
        
        self.errors.append(error_record)
        self.total_errors += 1
        
        self.logger.debug(f"❌ Error recorded: {error}")
    
    def get_stats(self) -> Dict:
        """Get aggregated statistics."""
        uptime = (datetime.now() - self.start_time).total_seconds()
        
        # Calculate averages
        if self.cycles:
            avg_collected = self.total_collected / len(self.cycles)
            avg_processed = self.total_processed / len(self.cycles)
            avg_uploaded = self.total_uploaded / len(self.cycles)
            avg_elapsed = sum(c['elapsed'] for c in self.cycles) / len(self.cycles)
            success_rate = (self.total_uploaded / self.total_collected * 100) if self.total_collected > 0 else 0
        else:
            avg_collected = 0
            avg_processed = 0
            avg_uploaded = 0
            avg_elapsed = 0
            success_rate = 0
        
        return {
            'uptime_seconds': uptime,
            'cycles': len(self.cycles),
            'total': {
                'collected': self.total_collected,
                'processed': self.total_processed,
                'uploaded': self.total_uploaded,
                'errors': self.total_errors
            },
            'averages': {
                'collected_per_cycle': round(avg_collected, 2),
                'processed_per_cycle': round(avg_processed, 2),
                'uploaded_per_cycle': round(avg_uploaded, 2),
                'elapsed_per_cycle': round(avg_elapsed, 2)
            },
            'success_rate': round(success_rate, 2),
            'recent_cycles': self.cycles[-10:] if self.cycles else []
        }
    
    def print_summary(self):
        """Print metrics summary."""
        stats = self.get_stats()
        
        print("\n" + "=" * 80)
        print("📊 SEEKER AGENT METRICS")
        print("=" * 80)
        print(f"Uptime: {stats['uptime_seconds']:.0f}s ({stats['uptime_seconds'] / 3600:.2f}h)")
        print(f"Cycles: {stats['cycles']}")
        print()
        print("Total:")
        print(f"  Collected: {stats['total']['collected']}")
        print(f"  Processed: {stats['total']['processed']}")
        print(f"  Uploaded:  {stats['total']['uploaded']}")
        print(f"  Errors:    {stats['total']['errors']}")
        print()
        print("Averages per cycle:")
        print(f"  Collected: {stats['averages']['collected_per_cycle']}")
        print(f"  Processed: {stats['averages']['processed_per_cycle']}")
        print(f"  Uploaded:  {stats['averages']['uploaded_per_cycle']}")
        print(f"  Duration:  {stats['averages']['elapsed_per_cycle']:.2f}s")
        print()
        print(f"Success Rate: {stats['success_rate']}%")
        print("=" * 80 + "\n")
