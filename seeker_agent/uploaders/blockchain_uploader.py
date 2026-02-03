"""Blockchain uploader for Aleo network."""

import logging
import time
import json
import hashlib
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path

from web3 import Web3

from core.config import Config


class BlockchainUploader:
    """Uploads processed data to Aleo blockchain."""
    
    def __init__(self, config: Config):
        """Initialize blockchain uploader."""
        self.config = config
        self.blockchain_config = config.blockchain
        self.logger = logging.getLogger(__name__)
        
        # Setup upload tracking directory
        self.upload_dir = Path(config.storage.processed_data_dir) / "uploads"
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize connection (mock for now, real Aleo integration later)
        self.connected = False
        self._setup_connection()
        
        self.logger.info("✅ Blockchain uploader initialized")
        self.logger.info(f"   Network: {self.blockchain_config.network}")
        self.logger.info(f"   Contract: {self.blockchain_config.contract_address}")
    
    def _setup_connection(self):
        """Setup blockchain connection."""
        try:
            # TODO: Replace with real Aleo SDK
            # For now, we'll simulate the connection
            self.logger.info("🔗 Connecting to Aleo network...")
            
            # Validate configuration
            if not self.blockchain_config.private_key:
                self.logger.warning("⚠️  No private key configured - running in simulation mode")
                self.connected = False
                return
            
            # Simulate connection
            time.sleep(0.5)
            self.connected = True
            self.logger.info("   ✓ Connected successfully")
            
        except Exception as e:
            self.logger.error(f"   ✗ Connection failed: {e}")
            self.connected = False
    
    def upload_batch(self, data_list: List[Dict]) -> int:
        """Upload batch of processed data to blockchain."""
        if not data_list:
            self.logger.warning("No data to upload")
            return 0
        
        self.logger.info(f"📤 Uploading {len(data_list)} records in batches...")
        
        uploaded = 0
        batch_size = self.blockchain_config.upload_config['batch_size']
        batch_delay = self.blockchain_config.upload_config['batch_delay']
        
        # Split into batches
        for i in range(0, len(data_list), batch_size):
            batch = data_list[i:i + batch_size]
            
            try:
                # Upload batch
                success = self._upload_single_batch(batch, i // batch_size + 1)
                
                if success:
                    uploaded += len(batch)
                    self.logger.info(f"   ✓ Batch {i // batch_size + 1}: {len(batch)} records uploaded")
                else:
                    self.logger.warning(f"   ✗ Batch {i // batch_size + 1}: Upload failed")
                
                # Delay between batches
                if i + batch_size < len(data_list):
                    time.sleep(batch_delay)
                    
            except Exception as e:
                self.logger.error(f"   ✗ Batch {i // batch_size + 1}: {e}")
        
        self.logger.info(f"   📊 Upload summary: {uploaded}/{len(data_list)} successful")
        return uploaded
    
    def _upload_single_batch(self, batch: List[Dict], batch_num: int) -> bool:
        """Upload a single batch to blockchain."""
        max_retries = self.blockchain_config.upload_config['max_retries']
        retry_delay = self.blockchain_config.upload_config['retry_delay']
        
        for attempt in range(max_retries):
            try:
                # Prepare batch data
                batch_data = self._prepare_batch_data(batch)
                
                # Generate file hash
                file_hash = self._generate_file_hash(batch_data)
                
                # Create transaction
                tx = self._create_transaction(file_hash, batch_data)
                
                # Sign transaction
                signed_tx = self._sign_transaction(tx)
                
                # Submit transaction
                tx_id = self._submit_transaction(signed_tx)
                
                # Track upload
                self._track_upload(batch, tx_id, file_hash)
                
                return True
                
            except Exception as e:
                if attempt < max_retries - 1:
                    self.logger.warning(f"      Retry {attempt + 1}/{max_retries}: {e}")
                    time.sleep(retry_delay)
                else:
                    self.logger.error(f"      Failed after {max_retries} attempts: {e}")
                    return False
        
        return False
    
    def _prepare_batch_data(self, batch: List[Dict]) -> Dict:
        """Prepare batch data for upload."""
        return {
            'version': '1.0',
            'timestamp': datetime.now().isoformat(),
            'batch_size': len(batch),
            'records': [
                {
                    'symbol': item['symbol'],
                    'source': item['source'],
                    'timestamp': item['timestamp'],
                    'normalized_prices': item['normalized_prices'],
                    'quality_score': item['quality_score'],
                    'is_outlier': item['is_outlier'],
                    'features': item['features']
                }
                for item in batch
            ]
        }
    
    def _generate_file_hash(self, data: Dict) -> str:
        """Generate SHA256 hash of data."""
        data_str = json.dumps(data, sort_keys=True)
        return hashlib.sha256(data_str.encode()).hexdigest()
    
    def _create_transaction(self, file_hash: str, data: Dict) -> Dict:
        """Create blockchain transaction."""
        # Extract metadata
        symbols = [r['symbol'] for r in data['records']]
        avg_quality = sum(r['quality_score'] for r in data['records']) / len(data['records'])
        
        # Determine category based on symbols
        category = self._determine_category(symbols)
        
        # Build transaction
        tx = {
            'contract': self.blockchain_config.contract_address,
            'function': 'submit_data_record',
            'parameters': {
                'file_hash': file_hash,
                'category': category,
                'quality_score': int(avg_quality * 100),  # Convert to integer
                'timestamp': int(datetime.now().timestamp()),
                'batch_size': len(data['records']),
                'symbols': ','.join(symbols[:10])  # Limit to 10 symbols
            },
            'gas_limit': self.blockchain_config.gas_limit,
            'fee': self.blockchain_config.fee
        }
        
        return tx
    
    def _determine_category(self, symbols: List[str]) -> str:
        """Determine data category from symbols."""
        # Check for crypto
        crypto_symbols = ['BTC-USD', 'ETH-USD', 'BNB-USD']
        if any(symbol in crypto_symbols for symbol in symbols):
            return 'crypto'
        
        # Check for major tech stocks
        tech_symbols = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'META', 'NVDA', 'TSLA']
        if any(symbol in tech_symbols for symbol in symbols):
            return 'tech_stocks'
        
        return 'general'
    
    def _sign_transaction(self, tx: Dict) -> Dict:
        """Sign transaction with private key."""
        # TODO: Replace with real Aleo signing
        # For now, simulate signing
        
        if self.config.features.dry_run:
            self.logger.debug("      [DRY RUN] Simulating transaction signing")
            tx['signature'] = 'dry_run_signature'
            return tx
        
        # Simulate signing
        tx_str = json.dumps(tx, sort_keys=True)
        signature = hashlib.sha256(
            (tx_str + self.blockchain_config.private_key).encode()
        ).hexdigest()
        
        tx['signature'] = signature
        return tx
    
    def _submit_transaction(self, signed_tx: Dict) -> str:
        """Submit signed transaction to blockchain."""
        # TODO: Replace with real Aleo submission
        # For now, simulate submission
        
        if self.config.features.dry_run:
            tx_id = f"dry_run_{hashlib.sha256(str(datetime.now()).encode()).hexdigest()[:16]}"
            self.logger.debug(f"      [DRY RUN] Simulated TX ID: {tx_id}")
            return tx_id
        
        # Simulate network delay
        time.sleep(0.5)
        
        # Generate transaction ID
        tx_id = f"tx_{hashlib.sha256(json.dumps(signed_tx).encode()).hexdigest()[:16]}"
        
        self.logger.debug(f"      Submitted TX: {tx_id}")
        return tx_id
    
    def _track_upload(self, batch: List[Dict], tx_id: str, file_hash: str):
        """Track upload for auditing."""
        tracking = {
            'tx_id': tx_id,
            'file_hash': file_hash,
            'uploaded_at': datetime.now().isoformat(),
            'batch_size': len(batch),
            'symbols': [item['symbol'] for item in batch],
            'network': self.blockchain_config.network,
            'contract': self.blockchain_config.contract_address
        }
        
        # Save tracking info
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = self.upload_dir / f"upload_{timestamp}.json"
        
        try:
            with open(filename, 'w') as f:
                json.dump(tracking, f, indent=2)
            
            self.logger.debug(f"      💾 Upload tracked: {filename}")
            
        except Exception as e:
            self.logger.error(f"      Failed to track upload: {e}")
    
    def verify_upload(self, tx_id: str) -> Dict:
        """Verify transaction status on blockchain."""
        # TODO: Replace with real Aleo verification
        
        self.logger.info(f"🔍 Verifying transaction: {tx_id}")
        
        # Simulate verification
        time.sleep(0.3)
        
        return {
            'tx_id': tx_id,
            'status': 'confirmed',
            'confirmations': 6,
            'block_height': 12345,
            'timestamp': datetime.now().isoformat()
        }
    
    def get_upload_stats(self) -> Dict:
        """Get upload statistics."""
        # Count upload files
        upload_files = list(self.upload_dir.glob("upload_*.json"))
        
        total_uploads = len(upload_files)
        total_records = 0
        
        for file in upload_files:
            try:
                with open(file) as f:
                    data = json.load(f)
                    total_records += data.get('batch_size', 0)
            except Exception:
                pass
        
        return {
            'total_uploads': total_uploads,
            'total_records': total_records,
            'network': self.blockchain_config.network,
            'contract': self.blockchain_config.contract_address,
            'connected': self.connected
        }
