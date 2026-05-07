# Multi-stage build: builder compiles and tests the ROS2 package,
# runtime stage copies only the install artifacts (no build tools).

# ---- Stage 1: Build ---------------------------------------------------------
FROM ros:humble-ros-base AS builder

RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-pytest \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ros2_ws

COPY ros2_ws/src ./src

RUN pip3 install pytest

RUN . /opt/ros/humble/setup.sh && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# Tests run at build time — a failing test prevents the image from being created.
RUN . /opt/ros/humble/setup.sh && \
    . install/setup.sh && \
    colcon test && \
    colcon test-result --verbose

# ---- Stage 2: Runtime -------------------------------------------------------
FROM ros:humble-ros-base

RUN apt-get update && apt-get install -y \
    python3-pip \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ros2_ws

COPY --from=builder /ros2_ws/install ./install

RUN printf '#!/bin/bash\nset -e\nsource /opt/ros/humble/setup.bash\nsource /ros2_ws/install/setup.bash\nexec "$@"\n' \
    > /entrypoint.sh && chmod +x /entrypoint.sh

ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "run", "robot_health", "health_publisher"]

LABEL maintainer="syednaveedfazal@gmail.com"
LABEL description="ROS2 Robot Health Monitoring System"
LABEL version="0.1.0"
LABEL ros.distro="humble"
