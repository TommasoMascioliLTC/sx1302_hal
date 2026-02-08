#!/bin/bash

# This script is intended to be used on SX1302 CoreCell platform (WM1302)
# It performs the following actions:
#       - Reset the SX1302 chip using GPIO (power enable and reset)
#       - Reset the optional SX1261 radio used for LBT/Spectral Scan
#       - Reset the AD5338R ADC (full-duplex CN490 reference design)
#
# Usage examples:
#       ./reset_lgw.sh start
#       ./reset_lgw.sh stop
#
# NOTE: Uses gpioset/gpioget from libgpiod (modern GPIO interface)
#       GPIO pins are configured as active-low in kernel:
#       0 = HIGH (active), 1 = LOW (inactive/reset)

# GPIO mapping verified with: cat /sys/kernel/debug/gpio
# BCM GPIO numbers for WM1302 HAT (gpiochip0 base)
SX1302_RESET_PIN=17      # SX1302 reset (gpio-529) 17
SX1302_POWER_EN_PIN=22   # SX1302 power enable (gpio-534) 22 oppure 18
SX1261_RESET_PIN=5      # SX1261 reset for LBT/Spectral Scan (gpio-537) 25
AD5338R_RESET_PIN=13     # AD5338R ADC reset (gpio-525) 13
GPIOCHIP="gpiochip0"

reset_start() {
    echo "WM1302 Reset sequence (GPIO active-low: 0=HIGH, 1=LOW)..."
    
    # Kill any old GPIO processes
    killall gpioset 2>/dev/null || true
    sleep 0.1
    
    # Power enable (write 0 = HIGH = enabled)
    echo "  → Power enable GPIO$SX1302_POWER_EN_PIN"
    gpioset $GPIOCHIP $SX1302_POWER_EN_PIN=0
    sleep 0.1
    
    # Reset pulse SX1302: 200ms LOW pulse
    echo "  → Reset SX1302 GPIO$SX1302_RESET_PIN"
    gpioset $GPIOCHIP $SX1302_RESET_PIN=0  # HIGH = not reset
    sleep 0.05
    gpioset $GPIOCHIP $SX1302_RESET_PIN=1  # LOW = reset active
    sleep 0.2
    gpioset $GPIOCHIP $SX1302_RESET_PIN=0  # HIGH = reset release
    sleep 0.1
    
    # Reset pulse SX1261: 50ms LOW pulse
    echo "  → Reset SX1261 GPIO$SX1261_RESET_PIN"
    gpioset $GPIOCHIP $SX1261_RESET_PIN=1  # LOW = reset active
    sleep 0.05
    gpioset $GPIOCHIP $SX1261_RESET_PIN=0  # HIGH = reset release
    sleep 0.1
    
    # Reset pulse AD5338R: 50ms LOW pulse
    echo "  → Reset AD5338R GPIO$AD5338R_RESET_PIN"
    gpioset $GPIOCHIP $AD5338R_RESET_PIN=1  # LOW = reset active
    sleep 0.05
    gpioset $GPIOCHIP $AD5338R_RESET_PIN=0  # HIGH = reset release
    sleep 0.1
    
    # Verify GPIO state
    GPIO_STATE=$(gpioget $GPIOCHIP $SX1302_RESET_PIN $SX1302_POWER_EN_PIN $SX1261_RESET_PIN $AD5338R_RESET_PIN 2>/dev/null)
    echo "  → GPIO state: $GPIO_STATE (0=HIGH/active)"
    echo "✓ Reset complete"
    return 0
}

reset_stop() {
    echo "WM1302 Shutdown..."
    
    # Put chips in reset (write 1 = LOW = reset)
    gpioset $GPIOCHIP $SX1302_RESET_PIN=1 2>/dev/null
    sleep 0.1
    gpioset $GPIOCHIP $SX1261_RESET_PIN=1 2>/dev/null
    sleep 0.1
    gpioset $GPIOCHIP $AD5338R_RESET_PIN=1 2>/dev/null
    sleep 0.1
    
    # Power disable (write 1 = LOW = disabled)
    gpioset $GPIOCHIP $SX1302_POWER_EN_PIN=1 2>/dev/null
    
    echo "✓ Shutdown complete"
}

case "$1" in
    start)
        reset_start
        exit $?
        ;;
    stop)
        reset_stop
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
