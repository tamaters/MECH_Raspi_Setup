# Copyright 2020 Hochschule Luzern - Informatik
# Author: Peter Sollberger <peter.sollberger@hslu.ch>
# Modified for Raspberry Pi 5 compatibility

from gpiozero import LED
from spidev import SpiDev


class Motor:
    """
    Conveyor belt motor controller.
    """
    def __init__(self, directionPinNbr, brakePinNbr, stopPinNbr):
        """
        Initialize motor.
        :param directionPinNbr: GPIO pin number for direction control
        :param brakePinNbr: GPIO pin number for brake control
        :param stopPinNbr: GPIO pin number for stop control
        """
        self.directionPin = LED(directionPinNbr)
        self.brakePin = LED(brakePinNbr)
        self.stopPin = LED(stopPinNbr)

        self.spi = SpiDev()
        self.spi.open(0, 0)  # SPI0, CE0
        self.spi.max_speed_hz = 4000000
        self.speed = 0.0

    def __analogOutput(self, value):
        """
        Send analog output value via SPI to DAC (MCP4921).
        :param value: 10-bit value (0-1023)
        """
        # lowbyte has 6 data bits
        # B7, B6, B5, B4, B3, B2, B1, B0
        # D5, D4, D3, D2, D1, D0,  X,  X
        lowByte = value << 2 & 0b11111100
        # highbyte has control and 4 data bits
        # control bits are:
        # B7, B6,   B5, B4,     B3,  B2,  B1,  B0
        # W  ,BUF, !GA, !SHDN,  D9,  D8,  D7,  D6
        # B7=0:write to DAC, B6=0:unbuffered, B5=1:Gain=1X, B4=1:Output is active
        highByte = ((value >> 6) & 0xff) | 0b0 << 7 | 0b0 << 6 | 0b1 << 5 | 0b1 << 4
        # by using spi.xfer2(), the CS is released after each block, transferring the
        # value to the output pin.
        self.spi.xfer2([highByte, lowByte])

    def setSpeed(self, value):
        """
        Set the motor speed in the range of -1023 to 1023. Higher values will be ignored.
        :param value: Speed (-1023 to 1023, negative for reverse)
        """
        if value >= 0:
            self.directionPin.on()
        else:
            self.directionPin.off()
            value = abs(value)
        if value > 1023:
            value = 1023
        self.speed = value
        self.__analogOutput(value)

    def getSpeed(self):
        """
        Return actual speed (negative values indicate reverse direction).
        :return: Current speed value
        """
        value = self.speed
        if self.directionPin.value == 0:
            value *= -1
        return value

    def on(self):
        """
        Release brake and stop signal, preparing motor for operation.
        """
        self.speed = 0
        self.__analogOutput(0)
        self.stopPin.on()
        self.brakePin.on()

    def stop(self):
        """
        Immediately stop the motor using the stop and brake signal.
        """
        self.__analogOutput(0)
        self.stopPin.off()
        self.brakePin.off()
        self.speed = 0

    def cleanup(self):
        """
        Clean up resources when done with motor.
        """
        self.stop()
        self.spi.close()
        self.directionPin.close()
        self.brakePin.close()
        self.stopPin.close()