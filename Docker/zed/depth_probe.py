#!/usr/bin/env python3
"""Print the depth the ZED SDK reports at a few pixels, to check the simulated cloud is metric.

Counterpart to ZedSimCamera's "Log ground truth depth" toggle in the Unity simulator (crane_sim):
that logs the true Z along the left eye's optical axis at the same pixels, this reads back what the
SDK computed from the streamed stereo pair. The two should agree to a few centimetres; a constant
ratio between them means the rendered baseline and the SDK's calibration disagree.

Usage (the zed-sim service must be running and Unity streaming):
    docker compose exec zed-sim python3 /root/depth_probe.py
"""
import sys

import numpy as np
import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data
from sensor_msgs.msg import CameraInfo, Image

TOPIC = "/zed/zed_node/depth/depth_registered"
INFO = "/zed/zed_node/left/color/rect/camera_info"
# Same fractions of the image as ZedSimCamera.ProbePixels.
PROBES = [(0.5, 0.5), (0.25, 0.5), (0.75, 0.5), (0.5, 0.25), (0.5, 0.75)]
FRAMES = 5


class DepthProbe(Node):
    def __init__(self):
        super().__init__("zed_depth_probe")
        self.seen = 0
        self.reported_calibration = False
        self.create_subscription(CameraInfo, INFO, self.on_info, qos_profile_sensor_data)
        self.create_subscription(Image, TOPIC, self.on_depth, qos_profile_sensor_data)
        self.get_logger().info(f"waiting for {TOPIC} ...")

    def on_info(self, msg):
        """The calibration the SDK turns disparity into metres with: it must match ZedCameraSpecs."""
        if self.reported_calibration:
            return
        self.reported_calibration = True
        fx, cx, cy = msg.k[0], msg.k[2], msg.k[5]
        self.get_logger().info(
            f"calibration: {msg.width}x{msg.height} fx={fx:.2f} cx={cx:.1f} cy={cy:.1f} "
            f"model={msg.distortion_model} d={'zero' if not any(msg.d) else list(msg.d)}"
        )

    def on_depth(self, msg):
        if msg.encoding != "32FC1":
            self.get_logger().error(f"expected 32FC1 depth in metres, got {msg.encoding}")
            raise SystemExit(1)

        depth = np.frombuffer(msg.data, dtype=np.float32).reshape(msg.height, msg.width)
        parts = []
        for fu, fv in PROBES:
            u, v = int(round(fu * msg.width)), int(round(fv * msg.height))
            # A single pixel is often NaN on a textureless surface; fall back to the window median.
            window = depth[max(v - 2, 0):v + 3, max(u - 2, 0):u + 3]
            window = window[np.isfinite(window)]
            value = depth[v, u]
            if not np.isfinite(value):
                value = np.median(window) if window.size else float("nan")
            parts.append(f"({u},{v})={value:.3f}" if np.isfinite(value) else f"({u},{v})=nan")

        valid = np.isfinite(depth).sum()
        self.get_logger().info(
            f"SDK depth (metres): {'  '.join(parts)}   [{valid * 100 // depth.size}% of pixels valid]"
        )

        self.seen += 1
        if self.seen >= FRAMES:
            raise SystemExit(0)


def main():
    rclpy.init()
    node = DepthProbe()
    code = 0
    try:
        rclpy.spin(node)
    except SystemExit as stop:  # raised once FRAMES samples are in
        code = stop.code
    except (KeyboardInterrupt, ExternalShutdownException):
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()
    return code


if __name__ == "__main__":
    sys.exit(main())
