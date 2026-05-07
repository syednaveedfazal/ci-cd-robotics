#!/usr/bin/env python3
"""
Publishes robot health status to /robot_health topic every 2 seconds.
Reports battery level, CPU temperature, network signal, and sensor status.
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import json
import random
import socket


class HealthPublisher(Node):
    def __init__(self):
        super().__init__('health_publisher')

        self.publisher_ = self.create_publisher(String, 'robot_health', 10)

        try:
            self.robot_id = socket.gethostname()
        except Exception:
            self.robot_id = 'robot_unknown'

        self.timer = self.create_timer(2.0, self.publish_health)
        self.battery_level = 100.0
        self.mission_count = 0

        self.get_logger().info(f'Health publisher started for {self.robot_id}')

    def publish_health(self):
        self.battery_level = max(20.0, self.battery_level - random.uniform(0.1, 0.5))

        if self.battery_level < 30.0:
            self.battery_level = 100.0
            self.get_logger().info('Battery recharged')

        health_data = {
            'robot_id': self.robot_id,
            'timestamp': self.get_clock().now().to_msg().sec,
            'battery_percent': round(self.battery_level, 2),
            'cpu_temp_celsius': round(random.uniform(45.0, 65.0), 2),
            'network_signal_dbm': round(random.uniform(-70, -40), 2),
            'camera_status': 'OK' if random.random() > 0.05 else 'WARNING',
            'lidar_status': 'OK' if random.random() > 0.05 else 'WARNING',
            'mission_state': 'IDLE' if self.mission_count == 0 else 'ACTIVE',
            'missions_completed': self.mission_count,
        }

        msg = String()
        msg.data = json.dumps(health_data)
        self.publisher_.publish(msg)

        if random.random() < 0.1:
            self.get_logger().info(
                f'Health: Battery {health_data["battery_percent"]}%, '
                f'Temp {health_data["cpu_temp_celsius"]}°C'
            )


def main(args=None):
    rclpy.init(args=args)
    health_publisher = HealthPublisher()
    try:
        rclpy.spin(health_publisher)
    except KeyboardInterrupt:
        pass
    finally:
        health_publisher.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
