#!/usr/bin/env python3
import pytest
import json
from robot_health.health_publisher import HealthPublisher
from robot_health.health_monitor import HealthMonitor
import rclpy


class TestHealthPublisher:
    @classmethod
    def setup_class(cls):
        rclpy.init()

    @classmethod
    def teardown_class(cls):
        rclpy.shutdown()

    def test_node_creation(self):
        node = HealthPublisher()
        assert node is not None
        assert node.get_name() == 'health_publisher'
        node.destroy_node()

    def test_battery_level_initialization(self):
        node = HealthPublisher()
        assert node.battery_level == 100.0
        node.destroy_node()

    def test_robot_id_assignment(self):
        node = HealthPublisher()
        assert node.robot_id is not None
        assert len(node.robot_id) > 0
        node.destroy_node()


class TestHealthMonitor:
    @classmethod
    def setup_class(cls):
        if not rclpy.ok():
            rclpy.init()

    def test_monitor_creation(self):
        node = HealthMonitor()
        assert node is not None
        assert node.get_name() == 'health_monitor'
        node.destroy_node()

    def test_thresholds_set(self):
        node = HealthMonitor()
        assert hasattr(node, 'BATTERY_LOW_THRESHOLD')
        assert hasattr(node, 'CPU_TEMP_HIGH_THRESHOLD')
        assert node.BATTERY_LOW_THRESHOLD > 0
        assert node.CPU_TEMP_HIGH_THRESHOLD > 0
        node.destroy_node()


def test_health_data_format():
    health_data = {
        'robot_id': 'test_robot',
        'timestamp': 1234567890,
        'battery_percent': 85.5,
        'cpu_temp_celsius': 55.0,
        'network_signal_dbm': -60.0,
        'camera_status': 'OK',
        'lidar_status': 'OK',
        'mission_state': 'IDLE',
        'missions_completed': 0,
    }

    json_str = json.dumps(health_data)
    parsed = json.loads(json_str)

    assert parsed['robot_id'] == 'test_robot'
    assert parsed['battery_percent'] == 85.5
    assert parsed['camera_status'] == 'OK'


if __name__ == '__main__':
    pytest.main([__file__])
