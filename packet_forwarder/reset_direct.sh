#!/bin/sh

# WM1302 HAT Reset Script using direct GPIO control (sysfs fallback)
# This version uses direct chip register writes via SPI tools
#
# GPIO mapping for Seeed Studio WM1302:
#       - GPIO17 (pin 11): SX1302 reset (main concentrator) - active LOW
#       - GPIO18 (pin 12): SX1302 power enable - active HIGH  
#       - GPIO5  (pin 29): SX1261 reset (LBT/Spectral Scan) - active LOW

SX1302_RESET_PIN=17
SX1302_POWER_EN_PIN=18
SX1261_RESET_PIN=5

reset_start() {
    echo "WM1302 Reset sequence (direct GPIO)..."
    
    # Kill any existing gpioset processes
    pkill -f "gpioset.*signal" 2>/dev/null || true
    sleep 0.2
    
    # Use gpioset with transient mode for pulse sequence
    echo "Power enable..."
    sudo gpioset -m exit gpiochip0 ${SX1302_POWER_EN_PIN}=1 2>/dev/null
    sleep 0.1
    
    echo "SX1302 reset pulse..."
    sudo gpioset -m exit gpiochip0 ${SX1302_RESET_PIN}=0 2>/dev/null
    sleep 0.15
    sudo gpioset -m exit gpiochip0 ${SX1302_RESET_PIN}=1 2>/dev/null
    sleep 0.15
    
    echo "SX1261 reset pulse..."
    sudo gpioset -m exit gpiochip0 ${SX1261_RESET_PIN}=0 2>/dev/null
    sleep 0.1
    sudo gpioset -m exit gpiochip0 ${SX1261_RESET_PIN}=1 2>/dev/null
    sleep 0.2
    
    echo "Reset complete - GPIO values active"
    return 0
}

reset_stop() {
    echo "WM1302 Shutdown..."
    sudo gpioset -m exit gpiochip0 ${SX1302_RESET_PIN}=0 2>/dev/null
    sleep 0.1
    sudo gpioset -m exit gpiochip0 ${SX1261_RESET_PIN}=0 2>/dev/null
    sleep 0.1
    sudo gpioset -m exit gpiochip0 ${SX1302_POWER_EN_PIN}=0 2>/dev/null
    echo "✓ WM1302 Shutdown completed"
}

ACTION="${1:-start}"

case "$ACTION" in
    start)
        reset_start
        exit $?
        ;;
    stop)
        reset_stop
        exit $?
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
