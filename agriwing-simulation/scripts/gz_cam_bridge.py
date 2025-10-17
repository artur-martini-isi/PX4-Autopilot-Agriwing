#!/usr/bin/env python3

import time
import typing
import threading
import sys

from gz.msgs10.image_pb2 import Image
from gz.transport13 import SubscribeOptions
from gz.transport13 import Node

import cv2
import numpy as np
import PIL 
from PIL import Image as PIL_Image

# ROS2 imports
import rclpy
from rclpy.node import Node as ROSNode
from sensor_msgs.msg import Image as ROSImage
from sensor_msgs.msg import CameraInfo
from std_msgs.msg import Header
from cv_bridge import CvBridge
from builtin_interfaces.msg import Time


class GzCamROS2Bridge:
    def __init__(self, gz_topic_name, ros2_topic_name, resolution, camera_info_topic=None):
        self._res = resolution
        
        # Initialize Gazebo node
        self._gz_node = Node()  # gz node
        self._gz_node.subscribe(Image, gz_topic_name, self._gz_cb)
        
        # Initialize ROS2 node
        rclpy.init()
        self._ros_node = ROSNode('gz_camera_bridge')
        
        # Create ROS2 publishers
        self._image_pub = self._ros_node.create_publisher(
            ROSImage, 
            ros2_topic_name, 
            10
        )
        
        # Optional: publish camera info
        self._camera_info_pub = None
        if camera_info_topic:
            self._camera_info_pub = self._ros_node.create_publisher(
                CameraInfo, 
                camera_info_topic, 
                10
            )
            self._camera_info_msg = self._create_camera_info()
        
        # CV Bridge for image conversion
        self._bridge = CvBridge()
        
        # Thread synchronization
        self._img = None
        self._condition = threading.Condition()
        
        # Frame counter for headers
        self._frame_id = 0
        
        # Log initialization
        self._ros_node.get_logger().info(f'Gazebo Camera Bridge initialized')
        self._ros_node.get_logger().info(f'Subscribing to Gazebo topic: {gz_topic_name}')
        self._ros_node.get_logger().info(f'Publishing to ROS2 topic: {ros2_topic_name}')
    
    def _create_camera_info(self):
        """Create a basic CameraInfo message"""
        camera_info = CameraInfo()
        
        # Set basic parameters
        camera_info.height = self._res[1]
        camera_info.width = self._res[0]
        
        # Camera matrix (fx, 0, cx, 0, fy, cy, 0, 0, 1)
        # These are example values - adjust based on your actual camera
        fx = fy = self._res[0] / 2.0  # Focal length
        cx = self._res[0] / 2.0  # Principal point x
        cy = self._res[1] / 2.0  # Principal point y
        
        camera_info.k = [
            fx, 0.0, cx,
            0.0, fy, cy,
            0.0, 0.0, 1.0
        ]
        
        # Distortion parameters (assuming no distortion)
        camera_info.d = [0.0, 0.0, 0.0, 0.0, 0.0]
        
        # Rectification matrix (identity for monocular camera)
        camera_info.r = [
            1.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            0.0, 0.0, 1.0
        ]
        
        # Projection matrix
        camera_info.p = [
            fx, 0.0, cx, 0.0,
            0.0, fy, cy, 0.0,
            0.0, 0.0, 1.0, 0.0
        ]
        
        camera_info.distortion_model = "plumb_bob"
        
        return camera_info
    
    def _gz_cb(self, image: Image) -> None:
        """Gazebo image callback"""
        # Convert Gazebo image to OpenCV format
        raw_image_data = image.data
        np_image = np.frombuffer(raw_image_data, dtype=np.uint8).reshape((self._res[1], self._res[0], 3))
        cv2_image = cv2.cvtColor(np_image, cv2.COLOR_RGB2BGR)
        
        # Store image for display thread
        with self._condition:
            self._img = cv2_image
            self._condition.notify_all()
        
        # Publish to ROS2
        self._publish_ros2_image(cv2_image)
    
    def _publish_ros2_image(self, cv2_image):
        """Convert and publish OpenCV image to ROS2"""
        try:
            # Convert OpenCV image to ROS2 Image message
            ros_image = self._bridge.cv2_to_imgmsg(cv2_image, encoding="bgr8")
            
            # Set header
            ros_image.header.stamp = self._ros_node.get_clock().now().to_msg()
            ros_image.header.frame_id = f"camera_link_{self._frame_id}"
            self._frame_id += 1
            
            # Publish image
            self._image_pub.publish(ros_image)
            
            # Publish camera info if configured
            if self._camera_info_pub:
                self._camera_info_msg.header = ros_image.header
                self._camera_info_pub.publish(self._camera_info_msg)
            
            # Log periodically (every 30 frames)
            if self._frame_id % 30 == 0:
                self._ros_node.get_logger().debug(f'Published frame {self._frame_id}')
                
        except Exception as e:
            self._ros_node.get_logger().error(f'Error publishing image: {e}')
    
    def get_next_image(self, timeout=None):
        """Get the next image for display"""
        with self._condition:
            if self._img is None:
                self._condition.wait_for(lambda: self._img is not None, timeout=timeout)
            ret_img = self._img
            self._img = None
            return ret_img
    
    def spin_once(self):
        """Process ROS2 callbacks"""
        rclpy.spin_once(self._ros_node, timeout_sec=0)
    
    def destroy(self):
        """Clean up resources"""
        self._ros_node.destroy_node()
        rclpy.shutdown()


def main():
    # Configuration
    GZ_TOPIC = "/world/agriwing/model/x500_mono_cam_down_0/link/camera_link/sensor/imager/image"
    ROS2_IMAGE_TOPIC = "/camera/image_raw"
    ROS2_INFO_TOPIC = "/camera/camera_info"
    RESOLUTION = (1280, 960)
    DISPLAY_ENABLED = False
    
    # Create bridge
    bridge = GzCamROS2Bridge(
        gz_topic_name=GZ_TOPIC,
        ros2_topic_name=ROS2_IMAGE_TOPIC,
        resolution=RESOLUTION,
        camera_info_topic=ROS2_INFO_TOPIC
    )
    
    print(f"Gazebo to ROS2 Camera Bridge Started")
    print(f"Gazebo Topic: {GZ_TOPIC}")
    print(f"ROS2 Topics: {ROS2_IMAGE_TOPIC}, {ROS2_INFO_TOPIC}")
    print(f"Resolution: {RESOLUTION}")
    print(f"Display: {'Enabled' if DISPLAY_ENABLED else 'Disabled'}")
    print("\nPress 'q' in the display window or Ctrl+C to quit")
    
    try:
        while True:
            # Process ROS2 callbacks
            bridge.spin_once()
            
            # Display image if enabled
            if DISPLAY_ENABLED:
                img = bridge.get_next_image(timeout=0.1)
                if img is not None:
                    cv2.imshow('Gazebo Camera Feed', img)
                    key = cv2.waitKey(1)
                    if key == ord('q'):
                        print("Quit requested")
                        break
            else:
                # If display is disabled, just sleep briefly
                time.sleep(0.01)
                
    except KeyboardInterrupt:
        print("\nShutdown requested")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        cv2.destroyAllWindows()
        bridge.destroy()
        print("Bridge shutdown complete")


if __name__ == "__main__":
    main()