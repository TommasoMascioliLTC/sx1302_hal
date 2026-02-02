#!/bin/bash
# Wrapper script that performs proper WM1302 reset and runs packet forwarder
# NOTE: GPIO17 and GPIO18 are configured as active-low in the kernel,
#       so logic is inverted: write 0 for "high", write 1 for "low"

cd /opt/sx1302_hal/packet_forwarder

echo "WM1302 Reset sequence (proper timing with inverted GPIO logic)..."

# Kill any old GPIO processes first
killall gpioset 2>/dev/null || true
sleep 0.3

# Power enable (GPIO18: write 0 = HIGH = enabled)
echo "  → Power enable (GPIO18=0, reads as 1)"
sudo gpioset gpiochip0 18=0
sleep 0.1

# Reset pulse SX1302: 200ms LOW pulse (GPIO17 active-low reset)
# GPIO17: write 0 = HIGH = not reset, write 1 = LOW = reset active
echo "  → Reset pulse SX1302 (GPIO17: 200ms reset active)"
sudo gpioset gpiochip0 17=0    # HIGH = not reset
sleep 0.05
sudo gpioset gpiochip0 17=1    # LOW = reset active
sleep 0.2
sudo gpioset gpiochip0 17=0    # HIGH = reset release
sleep 0.1

# Reset pulse SX1261: 50ms LOW pulse (GPIO5 active-low)
echo "  → Reset pulse SX1261 (GPIO5: 50ms reset active)"
sudo gpioset gpiochip0 5=1     # LOW = reset active
sleep 0.05
sudo gpioset gpiochip0 5=0     # HIGH = reset release
sleep 0.1

# Verify GPIO state (should show: 0 0 0 which means 1 1 1 logically)
echo "  → Final GPIO state (inverted, 0=high, 1=low):"
GPIO_STATE=$(sudo gpioget gpiochip0 17 18 5 2>/dev/null)
echo "     GPIO17 GPIO18 GPIO5 = $GPIO_STATE (expected: 0 0 0)"

# Allow chip to stabilize
sleep 1.0

# Run the actual packet forwarder
echo "Starting packet forwarder..."
exec ./lora_pkt_fwd
