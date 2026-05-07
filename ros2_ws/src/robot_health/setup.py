from setuptools import setup

package_name = 'robot_health'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Syed Naveed Fazal',
    maintainer_email='syednaveedfazal123@gmail.com',
    description='Robot health monitoring package',
    license='Apache-2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'health_publisher = robot_health.health_publisher:main',
            'health_monitor = robot_health.health_monitor:main',
        ],
    },
)
