# Copyright 2020 Hochschule Luzern - Informatik
# Author: Simon van Hemert <simon.vanhemert@hslu.ch>
# Author: Peter Sollberger <peter.sollberger@hslu.ch>

class PIDController:
    """
    Implements a PID controller.
    """
    def __init__(self):
        """
        Save relevant constants to self
        """
        # Predefine constants:
        self.refposition = 415               # Reference position in mm
        self.errorLinear = self.refposition  # Initial error
        self.errorIntegral = 0

        # PID constants:
        self.kp = 0.5
        self.ki = 0.05
        self.kd = 0.005

    def reset(self):
        """
        Restore controller with initial values.
        """
        self.errorLinear = self.refposition
        self.errorIntegral = 0

    def calculateTargetValue(self, actualValue):
        """
        Calculate next target values with the help of a PID controller.
        """
        # ToDo
        # ...

        # Save the three parts of the controler in a vector
        PIDactions = [p_part, i_part, d_part]
        # The output speed is the sum of the parts
        targetValue = sum(PIDactions)

        return int(targetValue), PIDactions
