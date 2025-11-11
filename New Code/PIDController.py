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
        self.antiwindup = 1024  # max output limit (equals 5 V = 1024)

        # PID constants:
        self.kp = 20
        self.ki = 0.05
        self.kd = 0.005

    def reset(self):
        """
        Restore controller with initial values.
        """
        self.errorLinear = self.refposition
        self.errorIntegral = 0

    def calculateTargetValue(self, actualValue):
        # Save old linear error for derivative term
        errorLinearold = self.errorLinear

        # P term
        self.errorLinear = round(self.refposition - actualValue)
        p_part = self.kp * self.errorLinear

        # I term (integral with anti-windup)
        self.errorIntegral += self.errorLinear * 0.01
        if abs(self.errorIntegral * self.ki) > self.antiwindup:
            self.errorIntegral = (
                self.antiwindup / self.ki
                if self.errorIntegral > 0
                else -self.antiwindup / self.ki
            )
        i_part = self.ki * self.errorIntegral

        # D term
        errorDerivative = (self.errorLinear - errorLinearold) / 0.01
        d_part = self.kd * errorDerivative

        # Combine
        PIDactions = [p_part, i_part, d_part]
        targetValue = sum(PIDactions)

        return int(targetValue), PIDactions
