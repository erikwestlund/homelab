#!/usr/bin/env python3
"""
NUT (Network UPS Tools) to InfluxDB Line Protocol converter
Fetches UPS metrics and outputs them in InfluxDB line protocol format
"""

import subprocess
import sys
import re
from datetime import datetime

def get_ups_list():
    """Get list of UPS devices from NUT server"""
    try:
        result = subprocess.run(['upsc', '-l'], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            return [ups.strip() for ups in result.stdout.strip().split('\n') if ups.strip()]
    except Exception as e:
        print(f"# Error getting UPS list: {e}", file=sys.stderr)
    return []

def get_ups_data(ups_name):
    """Get all variables for a specific UPS"""
    try:
        result = subprocess.run(['upsc', ups_name], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            return result.stdout
    except Exception as e:
        print(f"# Error getting data for {ups_name}: {e}", file=sys.stderr)
    return ""

def parse_value(value):
    """Parse value to appropriate type"""
    # Try to convert to float
    try:
        return float(value)
    except ValueError:
        # Return string value with quotes escaped
        return f'"{value.replace('"', '\\"')}"'

def convert_to_influx(ups_name, data):
    """Convert UPS data to InfluxDB line protocol"""
    lines = []
    timestamp = int(datetime.now().timestamp() * 1e9)
    
    # Key metrics we want to track as fields
    important_metrics = {
        'battery.charge': 'battery_charge',
        'battery.charge.low': 'battery_charge_low',
        'battery.runtime': 'battery_runtime',
        'battery.voltage': 'battery_voltage',
        'input.voltage': 'input_voltage',
        'output.voltage': 'output_voltage',
        'ups.load': 'ups_load',
        'ups.power': 'ups_power',
        'ups.realpower': 'ups_realpower',
        'ups.temperature': 'ups_temperature',
        'input.frequency': 'input_frequency',
        'output.frequency': 'output_frequency',
        'battery.runtime.low': 'battery_runtime_low',
        'ups.efficiency': 'ups_efficiency'
    }
    
    # Parse data
    fields = []
    tags = [f'ups={ups_name}']
    
    for line in data.strip().split('\n'):
        if ': ' in line:
            key, value = line.split(': ', 1)
            
            # Add model and status as tags
            if key == 'ups.model':
                tags.append(f'model={value.replace(" ", "_")}')
            elif key == 'ups.status':
                tags.append(f'status={value}')
            
            # Add important metrics as fields
            if key in important_metrics:
                try:
                    # Special handling for runtime (convert seconds to minutes)
                    if key == 'battery.runtime' or key == 'battery.runtime.low':
                        value_float = float(value)
                        fields.append(f'{important_metrics[key]}={value_float}')
                        fields.append(f'{important_metrics[key]}_minutes={value_float/60:.1f}')
                    else:
                        parsed_value = parse_value(value)
                        if isinstance(parsed_value, (int, float)):
                            fields.append(f'{important_metrics[key]}={parsed_value}')
                except ValueError:
                    pass
    
    # Create InfluxDB line protocol
    if fields:
        tag_string = ','.join(tags)
        field_string = ','.join(fields)
        lines.append(f'nut_ups,{tag_string} {field_string} {timestamp}')
    
    return lines

def main():
    """Main function"""
    all_lines = []
    
    # Get list of UPS devices
    ups_list = get_ups_list()
    
    for ups in ups_list:
        # Get UPS data
        data = get_ups_data(ups)
        if data:
            # Convert to InfluxDB format
            lines = convert_to_influx(ups, data)
            all_lines.extend(lines)
    
    # Output all lines
    for line in all_lines:
        print(line)

if __name__ == '__main__':
    main()