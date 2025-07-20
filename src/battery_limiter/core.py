"""Core battery charge limiting functionality."""

import os
import glob
from typing import Optional, Tuple


class BatteryControlError(Exception):
    """Exception raised for battery control errors."""
    pass


class BatteryController:
    """Main controller for battery charge limiting."""
    
    # Paths for real and mock environments
    REAL_BASE_PATH = '/sys/class/power_supply/'
    MOCK_BASE_PATH = os.path.join(os.path.dirname(__file__), '../../mock_sys/class/power_supply/')
    
    # Control file names in order of preference
    CONTROL_FILES = ['charge_control_end_threshold', 'charge_stop_threshold']
    
    def __init__(self, use_mock: bool = False):
        """Initialize the battery controller.
        
        Args:
            use_mock: Whether to use mock data for testing
        """
        self.use_mock = use_mock
        self.base_path = self.MOCK_BASE_PATH if use_mock else self.REAL_BASE_PATH
        self.control_file = self._find_control_file()
    
    def _find_control_file(self) -> Optional[str]:
        """Find the first available battery control file."""
        battery_dirs = glob.glob(os.path.join(self.base_path, 'BAT*'))
        if not battery_dirs:
            return None
        
        for bat_dir in battery_dirs:
            for control_file in self.CONTROL_FILES:
                path = os.path.join(bat_dir, control_file)
                if os.path.exists(path):
                    return path
        return None
    
    def is_supported(self) -> bool:
        """Check if battery charge limiting is supported."""
        return self.control_file is not None
    
    def get_current_limit(self) -> Optional[int]:
        """Get the current charge limit."""
        if not self.control_file:
            return None
        
        try:
            with open(self.control_file, 'r') as f:
                return int(f.read().strip())
        except (IOError, ValueError):
            return None
    
    def set_charge_limit(self, limit: int) -> None:
        """Set the battery charge limit.
        
        Args:
            limit: Charge limit percentage (1-100)
            
        Raises:
            BatteryControlError: If the operation fails
        """
        if not 1 <= limit <= 100:
            raise BatteryControlError(f"Charge limit must be between 1 and 100, got {limit}")
        
        if not self.control_file:
            raise BatteryControlError("No compatible battery control file found")
        
        try:
            with open(self.control_file, 'w') as f:
                f.write(str(limit))
        except IOError as e:
            raise BatteryControlError(f"Failed to write to control file: {e}")
    
    def get_battery_info(self) -> Tuple[Optional[str], Optional[str]]:
        """Get battery information (model, manufacturer)."""
        if not self.control_file:
            return None, None
        
        battery_dir = os.path.dirname(self.control_file)
        
        try:
            model_file = os.path.join(battery_dir, 'model_name')
            manufacturer_file = os.path.join(battery_dir, 'manufacturer')
            
            model = None
            manufacturer = None
            
            if os.path.exists(model_file):
                with open(model_file, 'r') as f:
                    model = f.read().strip()
            
            if os.path.exists(manufacturer_file):
                with open(manufacturer_file, 'r') as f:
                    manufacturer = f.read().strip()
            
            return model, manufacturer
        except IOError:
            return None, None
    
    def get_control_file_path(self) -> Optional[str]:
        """Get the path to the control file being used."""
        return self.control_file