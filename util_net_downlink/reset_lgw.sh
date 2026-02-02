#!/bin/bash
# WM1302 HAT Reset Script with GPIO inversion
SX1261_RESET_PIN=5
SX1302_RESET_PIN=17
SX1302_POWER_EN_PIN=18
GPIOCHIP="gpiochip0"

reset_start() {
    echo "WM1302 Reset (GPIO inverted: 0=HIGH, 1=LOW)..."
    sudo gpioset $GPIOCHIP $SX1302_POWER_EN_PIN=0
    sleep 0.1
    sudo gpioset $GPIOCHIP $SX1302_RESET_PIN=0; sleep 0.05
    sudo gpioset $GPIOCHIP $SX1302_RESET_PIN=1; sleep 0.2
    sudo gpioset $GPIOCHIP $SX1302_RESET_PIN=0; sleep 0.1
    sudo gpioset $GPIOCHIP $SX1261_RESET_PIN=1; sleep 0.05
    sudo gpioset $GPIOCHIP $SX1261_RESET_PIN=0; sleep 0.1
    echo "✓ Reset done"
    return 0
}

reset_stop() {
    echo "WM1302 Shutdown..."
    sudo gpioset $GPIOCHIP $SX1302_RESET_PIN=1; sleep 0.1
    sudo gpioset $GPIOCHIP $SX1261_RESET_PIN=1; sleep 0.1
    sudo gpioset $GPIOCHIP $SX1302_POWER_EN_PIN=1
}

case "$1" in
    start) reset_start; exit $? ;;
    stop) reset_stop ;;
    *) echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
exit 0
