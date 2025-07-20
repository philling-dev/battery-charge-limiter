"""Graphical user interface for battery charge limiter."""

import sys
import os
import math
from typing import Optional
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, QWidget,
    QLabel, QSlider, QPushButton, QGroupBox, QGridLayout,
    QMessageBox, QSystemTrayIcon, QMenu, QProgressBar, QFrame
)
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QIcon, QAction, QPixmap, QPainter, QPen, QBrush, QFont

from .core import BatteryController, BatteryControlError


class BatteryLimiterGUI(QMainWindow):
    """Main application window for battery charge limiter."""
    
    def __init__(self):
        super().__init__()
        self.controller = BatteryController()
        self.current_limit = None
        self.init_ui()
        self.create_system_tray()
        self.check_battery_support()
        self.update_timer = QTimer()
        self.update_timer.timeout.connect(self.update_display)
        self.update_timer.start(5000)  # Update every 5 seconds
    
    def init_ui(self):
        """Initialize the user interface."""
        self.setWindowTitle("Battery Charge Limiter")
        self.setMinimumSize(400, 300)
        
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        layout = QVBoxLayout()
        
        # Title
        title_label = QLabel("🔋 Battery Charge Limiter")
        title_font = QFont()
        title_font.setPointSize(16)
        title_font.setBold(True)
        title_label.setFont(title_font)
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)
        
        # Subtitle
        subtitle_label = QLabel("Extend battery lifespan by limiting charge")
        subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle_label.setStyleSheet("color: #666; margin-bottom: 20px;")
        layout.addWidget(subtitle_label)
        
        # Status frame
        self.status_frame = QFrame()
        self.status_frame.setFrameStyle(QFrame.Shape.StyledPanel)
        status_layout = QVBoxLayout()
        
        self.status_label = QLabel("Checking battery support...")
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.status_label.setStyleSheet("padding: 10px; font-weight: bold;")
        status_layout.addWidget(self.status_label)
        
        self.status_frame.setLayout(status_layout)
        layout.addWidget(self.status_frame)
        
        # Control group
        self.control_group = QGroupBox("Charge Limit Control")
        control_layout = QGridLayout()
        
        # Current limit display
        control_layout.addWidget(QLabel("Current Limit:"), 0, 0)
        self.current_limit_label = QLabel("Unknown")
        self.current_limit_label.setStyleSheet("font-weight: bold; color: #2e7d32;")
        control_layout.addWidget(self.current_limit_label, 0, 1)
        
        # Limit slider
        control_layout.addWidget(QLabel("Set New Limit:"), 1, 0)
        
        slider_layout = QHBoxLayout()
        self.limit_slider = QSlider(Qt.Orientation.Horizontal)
        self.limit_slider.setMinimum(20)
        self.limit_slider.setMaximum(100)
        self.limit_slider.setValue(80)
        self.limit_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.limit_slider.setTickInterval(10)
        self.limit_slider.valueChanged.connect(self.on_slider_changed)
        
        self.limit_value_label = QLabel("80%")
        self.limit_value_label.setStyleSheet("font-weight: bold; min-width: 40px;")
        
        slider_layout.addWidget(self.limit_slider)
        slider_layout.addWidget(self.limit_value_label)
        
        control_layout.addLayout(slider_layout, 1, 1)
        
        # Preset buttons
        preset_layout = QHBoxLayout()
        
        presets = [("Conservative", 60), ("Balanced", 80), ("Extended", 90)]
        for name, value in presets:
            btn = QPushButton(f"{name}\n({value}%)")
            btn.clicked.connect(lambda checked, v=value: self.set_preset(v))
            preset_layout.addWidget(btn)
        
        control_layout.addWidget(QLabel("Quick Presets:"), 2, 0)
        control_layout.addLayout(preset_layout, 2, 1)
        
        # Apply button
        self.apply_button = QPushButton("Apply Limit")
        self.apply_button.setStyleSheet("""
            QPushButton {
                background-color: #4caf50;
                color: white;
                border: none;
                padding: 10px;
                font-weight: bold;
                border-radius: 5px;
            }
            QPushButton:hover {
                background-color: #45a049;
            }
            QPushButton:disabled {
                background-color: #cccccc;
            }
        """)
        self.apply_button.clicked.connect(self.apply_limit)
        control_layout.addWidget(self.apply_button, 3, 0, 1, 2)
        
        self.control_group.setLayout(control_layout)
        layout.addWidget(self.control_group)
        
        # Info section
        info_group = QGroupBox("Battery Information")
        info_layout = QGridLayout()
        
        self.battery_model_label = QLabel("Unknown")
        self.battery_manufacturer_label = QLabel("Unknown")
        self.control_file_label = QLabel("Unknown")
        
        info_layout.addWidget(QLabel("Model:"), 0, 0)
        info_layout.addWidget(self.battery_model_label, 0, 1)
        info_layout.addWidget(QLabel("Manufacturer:"), 1, 0)
        info_layout.addWidget(self.battery_manufacturer_label, 1, 1)
        info_layout.addWidget(QLabel("Control File:"), 2, 0)
        info_layout.addWidget(self.control_file_label, 2, 1)
        
        info_group.setLayout(info_layout)
        layout.addWidget(info_group)
        
        layout.addStretch()
        central_widget.setLayout(layout)
    
    def create_system_tray(self):
        """Create system tray icon with menu."""
        if not QSystemTrayIcon.isSystemTrayAvailable():
            return
        
        # Try to create custom icon, fallback to system icon
        try:
            icon = self.create_battery_icon()
            if icon.isNull():
                icon = QIcon.fromTheme("battery")
        except Exception:
            icon = QIcon.fromTheme("battery")
        
        self.tray_icon = QSystemTrayIcon(icon, self)
        self.setWindowIcon(icon)
        
        # Create menu
        tray_menu = QMenu()
        
        show_action = QAction("Show", self)
        show_action.triggered.connect(self.show)
        tray_menu.addAction(show_action)
        
        tray_menu.addSeparator()
        
        # Quick preset actions
        preset_menu = QMenu("Quick Set", self)
        for name, value in [("60%", 60), ("80%", 80), ("90%", 90)]:
            action = QAction(name, self)
            action.triggered.connect(lambda checked, v=value: self.apply_limit_direct(v))
            preset_menu.addAction(action)
        tray_menu.addMenu(preset_menu)
        
        tray_menu.addSeparator()
        
        quit_action = QAction("Quit", self)
        quit_action.triggered.connect(QApplication.quit)
        tray_menu.addAction(quit_action)
        
        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.activated.connect(self.on_tray_activated)
        self.tray_icon.show()
    
    def create_battery_icon(self) -> QIcon:
        """Create a simple battery icon for the system tray."""
        pixmap = QPixmap(64, 64)
        pixmap.fill(Qt.GlobalColor.transparent)
        
        painter = QPainter(pixmap)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Draw battery outline
        pen = QPen(Qt.GlobalColor.black, 3)
        painter.setPen(pen)
        painter.setBrush(QBrush(Qt.GlobalColor.lightGray))
        
        # Battery body
        painter.drawRoundedRect(12, 20, 32, 20, 3, 3)
        
        # Battery terminal
        painter.drawRect(44, 26, 4, 8)
        
        # Battery level indicator (green for limited)
        pen = QPen(Qt.GlobalColor.green, 2)
        painter.setPen(pen)
        painter.setBrush(QBrush(Qt.GlobalColor.green))
        
        # Fill level (80% example)
        painter.drawRect(16, 24, 20, 12)
        
        # Limit indicator (small line)
        pen = QPen(Qt.GlobalColor.red, 3)
        painter.setPen(pen)
        painter.drawLine(36, 20, 36, 40)
        
        painter.end()
        return QIcon(pixmap)
    
    def on_tray_activated(self, reason):
        """Handle system tray icon activation."""
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            if self.isVisible():
                self.hide()
            else:
                self.show()
                self.raise_()
                self.activateWindow()
    
    def check_battery_support(self):
        """Check if battery charge limiting is supported."""
        if not self.controller.is_supported():
            self.status_label.setText("❌ Battery charge limiting not supported on this system")
            self.status_label.setStyleSheet("padding: 10px; font-weight: bold; color: #d32f2f;")
            self.control_group.setEnabled(False)
            
            QMessageBox.warning(
                self,
                "Not Supported",
                "Battery charge limiting is not supported on this system.\n\n"
                "Your laptop may not expose this functionality via sysfs, "
                "or you may need to install appropriate drivers."
            )
        else:
            self.status_label.setText("✅ Battery charge limiting is supported")
            self.status_label.setStyleSheet("padding: 10px; font-weight: bold; color: #2e7d32;")
            self.control_group.setEnabled(True)
            self.update_display()
    
    def update_display(self):
        """Update the display with current battery information."""
        if not self.controller.is_supported():
            return
        
        # Update current limit
        current_limit = self.controller.get_current_limit()
        if current_limit is not None:
            self.current_limit = current_limit
            self.current_limit_label.setText(f"{current_limit}%")
        else:
            self.current_limit_label.setText("Unknown")
        
        # Update battery info
        model, manufacturer = self.controller.get_battery_info()
        self.battery_model_label.setText(model or "Unknown")
        self.battery_manufacturer_label.setText(manufacturer or "Unknown")
        
        control_file = self.controller.get_control_file_path()
        if control_file:
            self.control_file_label.setText(os.path.basename(control_file))
        
        # Update tray tooltip
        if hasattr(self, 'tray_icon') and self.tray_icon:
            tooltip = f"Battery Charge Limiter\nCurrent limit: {current_limit or 'Unknown'}%"
            self.tray_icon.setToolTip(tooltip)
    
    def on_slider_changed(self, value):
        """Handle slider value change."""
        self.limit_value_label.setText(f"{value}%")
    
    def set_preset(self, value):
        """Set a preset value."""
        self.limit_slider.setValue(value)
    
    def apply_limit(self):
        """Apply the selected charge limit."""
        limit = self.limit_slider.value()
        self.apply_limit_direct(limit)
    
    def apply_limit_direct(self, limit):
        """Apply charge limit directly."""
        try:
            self.controller.set_charge_limit(limit)
            self.update_display()
            
            # Show notification
            if hasattr(self, 'tray_icon') and self.tray_icon:
                self.tray_icon.showMessage(
                    "Battery Charge Limiter",
                    f"Charge limit set to {limit}%",
                    QSystemTrayIcon.MessageIcon.Information,
                    3000
                )
            else:
                QMessageBox.information(
                    self,
                    "Success",
                    f"Battery charge limit set to {limit}%"
                )
        
        except BatteryControlError as e:
            QMessageBox.critical(
                self,
                "Error",
                f"Failed to set charge limit: {e}\n\n"
                "Make sure you have the necessary permissions."
            )
        except Exception as e:
            QMessageBox.critical(
                self,
                "Error", 
                f"An unexpected error occurred: {e}"
            )


def main():
    """Main entry point for the GUI application."""
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)  # Keep running in system tray
    
    # Set application metadata
    app.setApplicationName("Battery Charge Limiter")
    app.setApplicationDisplayName("Battery Charge Limiter")
    app.setApplicationVersion("1.0.0")
    
    window = BatteryLimiterGUI()
    window.show()
    
    sys.exit(app.exec())


if __name__ == "__main__":
    main()