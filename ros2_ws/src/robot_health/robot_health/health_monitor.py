#!/usr/bin/env python3
"""
Subscribes to /robot_health and monitors for threshold violations.
Logs warnings when battery is low, temperature is high, or sensors report issues.
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import json


class HealthMonitor(Node):
    def __init__(self):
        super().__init__('health_monitor')

        self.subscription = self.create_subscription(
            String,
            'robot_health',
            self.health_callback,
            10,
        )

        self.BATTERY_LOW_THRESHOLD = 30.0
        self.CPU_TEMP_HIGH_THRESHOLD = 60.0

        self.get_logger().info('Health monitor started - listening for robot health data')

    def health_callback(self, msg):
        try:
            health_data = json.loads(msg.data)

            robot_id = health_data.get('robot_id', 'unknown')
            battery = health_data.get('battery_percent', 0)
            temp = health_data.get('cpu_temp_celsius', 0)
            camera = health_data.get('camera_status', 'UNKNOWN')
            lidar = health_data.get('lidar_status', 'UNKNOWN')

            issues = []

            if battery < self.BATTERY_LOW_THRESHOLD:
                issues.append(f'LOW BATTERY: {battery}%')
            if temp > self.CPU_TEMP_HIGH_THRESHOLD:
                issues.append(f'HIGH TEMP: {temp}°C')
            if camera != 'OK':
                issues.append(f'CAMERA {camera}')
            if lidar != 'OK':
                issues.append(f'LIDAR {lidar}')

            if issues:
                self.get_logger().warn(f'[{robot_id}] ISSUES: {", ".join(issues)}')

        except json.JSONDecodeError:
            self.get_logger().error('Failed to parse health data JSON')
        except Exception as e:
            self.get_logger().error(f'Error processing health data: {str(e)}')


def main(args=None):
    rclpy.init(args=args)
    health_monitor = HealthMonitor()
    try:
        rclpy.spin(health_monitor)
    except KeyboardInterrupt:
        pass
    finally:
        health_monitor.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
