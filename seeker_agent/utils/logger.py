"""Logging setup utility."""

import logging
import sys
from pathlib import Path
from logging.handlers import RotatingFileHandler

import colorlog


def setup_logger(config) -> logging.Logger:
    """Setup application logger with console and file handlers."""
    
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, config.logging.level))
    
    # Clear existing handlers
    logger.handlers = []
    
    # Console handler with colors
    if config.logging.console:
        console_handler = colorlog.StreamHandler(sys.stdout)
        console_handler.setLevel(getattr(logging, config.logging.level))
        
        console_formatter = colorlog.ColoredFormatter(
            '%(log_color)s%(levelname)-8s%(reset)s %(blue)s%(name)s%(reset)s %(message)s',
            log_colors={
                'DEBUG': 'cyan',
                'INFO': 'green',
                'WARNING': 'yellow',
                'ERROR': 'red',
                'CRITICAL': 'red,bg_white',
            }
        )
        console_handler.setFormatter(console_formatter)
        logger.addHandler(console_handler)
    
    # File handler with rotation
    if config.logging.file:
        log_file = Path(config.logging.file)
        log_file.parent.mkdir(parents=True, exist_ok=True)
        
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=config.logging.max_bytes,
            backupCount=config.logging.backup_count
        )
        file_handler.setLevel(getattr(logging, config.logging.level))
        
        file_formatter = logging.Formatter(config.logging.format)
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)
    
    return logger
