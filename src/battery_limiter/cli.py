"""Command-line interface for battery charge limiter."""

import argparse
import sys
from .core import BatteryController, BatteryControlError


def main():
    """Main entry point for the CLI application."""
    parser = argparse.ArgumentParser(
        description="Set battery charge limit for your laptop",
        epilog="Example: battery-limiter 80"
    )
    parser.add_argument(
        'limit',
        type=int,
        help="Charge limit percentage (1-100)"
    )
    parser.add_argument(
        '--mock',
        action='store_true',
        help="Use mock environment for testing"
    )
    parser.add_argument(
        '--info',
        action='store_true',
        help="Show battery information"
    )
    
    args = parser.parse_args()
    
    # Initialize controller
    controller = BatteryController(use_mock=args.mock)
    
    # Check if supported
    if not controller.is_supported():
        print("❌ Battery charge limiting is not supported on this system.")
        print("Your laptop may not expose this functionality via sysfs.")
        sys.exit(1)
    
    # Show info if requested
    if args.info:
        model, manufacturer = controller.get_battery_info()
        control_file = controller.get_control_file_path()
        current_limit = controller.get_current_limit()
        
        print("🔋 Battery Information:")
        print(f"   Manufacturer: {manufacturer or 'Unknown'}")
        print(f"   Model: {model or 'Unknown'}")
        print(f"   Control File: {control_file or 'Unknown'}")
        print(f"   Current Limit: {current_limit or 'Unknown'}%")
        print()
    
    # Set the limit
    try:
        controller.set_charge_limit(args.limit)
        print(f"✅ Battery charge limit set to {args.limit}%")
        
        if controller.get_control_file_path():
            print(f"   Using: {controller.get_control_file_path()}")
        
    except BatteryControlError as e:
        print(f"❌ Error: {e}")
        if "permission" in str(e).lower() or "operation not permitted" in str(e).lower():
            print("💡 Try running with sudo privileges")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()