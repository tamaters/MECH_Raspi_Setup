# Copyright 2020 Hochschule Luzern - Informatik
# Author: Peter Sollberger <peter.sollberger@hslu.ch>
# Modified for Raspberry Pi 5 compatibility

import lgpio


class Encoder:
    """
    Maintains position from encoder signals A and B.
    """
    
    def __init__(self, inpA, inpB, chip=4):
        """
        Initialize encoder
        :param inpA: Input pin for encoder signal A (BCM numbering)
        :param inpB: Input pin for encoder signal B (BCM numbering)
        :param chip: GPIO chip number (default 4 for Pi 5)
        """
        self.pos = 0
        self.last = 0
        self.delta = 0
        self.bits = 0
        self.lastToggle = -1
        
        self.inpA = inpA
        self.inpB = inpB
        
        # Open GPIO chip
        self.chip_handle = lgpio.gpiochip_open(chip)
        
        # Configure pins as inputs with pull-down
        lgpio.gpio_claim_input(self.chip_handle, self.inpA, lgpio.SET_PULL_DOWN)
        lgpio.gpio_claim_input(self.chip_handle, self.inpB, lgpio.SET_PULL_DOWN)
        
        # Set up edge detection callbacks for both rising and falling edges
        lgpio.gpio_claim_alert(self.chip_handle, self.inpA, lgpio.BOTH_EDGES)
        lgpio.gpio_claim_alert(self.chip_handle, self.inpB, lgpio.BOTH_EDGES)
        
        # Start callback thread
        self.callback_a = lgpio.callback(self.chip_handle, self.inpA, lgpio.BOTH_EDGES, self.__input_callback)
        self.callback_b = lgpio.callback(self.chip_handle, self.inpB, lgpio.BOTH_EDGES, self.__input_callback)

    def __del__(self):
        """
        Stop and clean up.
        """
        self.cleanup()

    def cleanup(self):
        """
        Clean up GPIO resources.
        """
        try:
            # Cancel callbacks
            if hasattr(self, 'callback_a'):
                self.callback_a.cancel()
            if hasattr(self, 'callback_b'):
                self.callback_b.cancel()
            
            # Free GPIO pins
            if hasattr(self, 'chip_handle'):
                lgpio.gpio_free(self.chip_handle, self.inpA)
                lgpio.gpio_free(self.chip_handle, self.inpB)
                lgpio.gpiochip_close(self.chip_handle)
        except:
            pass

    def __input_callback(self, chip, gpio, level, tick):
        """
        ISR on both input signals.
        :param chip: GPIO chip handle
        :param gpio: GPIO pin that triggered
        :param level: New level (0 or 1)
        :param tick: Timestamp in microseconds
        """
        b = self.bits
        m = 1 << gpio
        if level:
            b |= m
        else:
            b &= ~m
        t = b ^ self.bits
        self.bits = b
        if t == self.lastToggle:
            return
        self.lastToggle = t

        x = 0
        if self.bits & (1 << self.inpA):
            x = 3
        if self.bits & (1 << self.inpB):
            x ^= 1
        diff = self.last - x  # difference last - new
        if diff & 1:  # bit 0 = value (1)
            self.last = x  # store new as next last
            self.delta += (diff & 2) - 1  # bit 1 = direction (+/-)

            val = self.delta
            self.delta = val % 1
            val //= 1
            if val:
                self.pos += val

    def getPosition(self):
        """
        Get current position in millimeters.
        :return: Current position (mm)
        """
        # 1024 tics/rotation, 4 edge-detects per tic, pi * 58 mm/rotation
        return int(self.pos / 1024 / 4 * 3.142 * 58)

    def getPositionRaw(self):
        """
        Get raw position count.
        :return: Current raw position
        """
        return self.pos

    def resetPosition(self):
        """
        Reset position to zero.
        """
        self.pos = 0