# Copyright 2020 Hochschule Luzern - Informatik
# Author: Peter Sollberger <peter.sollberger@hslu.ch>
# Modified for Raspberry Pi 5 compatibility

from time import sleep, time
from gpiozero import DigitalInputDevice, Button
from Encoder import Encoder
from Motor import Motor
from PIDController import PIDController
from Logger import Logger


# Predefine constants:
running = False          # Controller state
count = 0                # Interrupt counter
waitingtime = 1          # Waiting time in seconds for output

# Objects - using BCM GPIO numbering (plain integers)
pidcontroller = PIDController()
logger = Logger(pidcontroller.kp, pidcontroller.ki, pidcontroller.kd, pidcontroller.refposition)
encoder = Encoder(23, 24)
motor = Motor(16, 17, 18)  # Changed from 'GPIO16' to 16, etc.


def timerPinIRQ():
    """
    100 Hz timer for the regulator
    Method is activated with timer IRQ and should contain all actions necessary:
    1. Get current position
    2. Get current speed from PID controller
    3. Send current speed to Motor
    4. Save significant data for visualization.
    """
    global count

    count += 1          # Increase count
    
    if running:
        # Get current position from encoder
        current_pos = encoder.getPosition()
        
        # Calculate speed from PID controller
        speed, PIDactions = pidcontroller.calculateTargetValue(current_pos)
        
        # Send speed to motor
        motor.setSpeed(speed)
        
        # Log data
        logger.log(current_pos, speed, PIDactions)


def startPressed():
    """
    Start button pressed
    Clean data in Instances
    Turn on Motor
    set running=True
    """
    global running

    if not running:
        # Reset encoder position
        encoder.resetPosition()
        
        # Reset PID controller
        pidcontroller.reset()
        
        # Clear logger data
        logger.clean()
        
        # Turn on motor (release brake)
        motor.on()
        
        print("Starting")
        running = True


def stopPressed():
    """
    Stop button pressed
    when running was True:
    set running=False
    stop Motor
    create figures
    """
    global running

    if running:  # Only the first time
        running = False
        
        # Stop motor
        motor.stop()
        
        # Create/save figures (Feedback=True shows PID actions, save=True saves files)
        logger.showLoggings(Feedback=True, save=True)
        
        print("Stopping")


def cleanup():
    """
    Clean up all resources
    """
    global timerPin, startButton, stopButton, motor, encoder
    
    print("Cleaning up...")
    motor.cleanup()
    encoder.cleanup()
    timerPin.close()
    startButton.close()
    stopButton.close()


if __name__ == '__main__':
    """
    Main loop outputs actual position, speed and IRQ count every second.
    """
    print("Starting main")

    # Define pins - using BCM GPIO numbering (plain integers)
    timerPin = DigitalInputDevice(25)
    startButton = Button(5)
    stopButton = Button(6)

    # Register ISR on input signals
    timerPin.when_activated = timerPinIRQ
    startButton.when_activated = startPressed
    stopButton.when_activated = stopPressed

    try:
        while True:
            """ 
            Endlessly do:
            get time, position and speed
            print position and speed
            wait until exactly one second has passed
            """
            now = time()
            pos = encoder.getPosition()
            v = motor.getSpeed()
            print(f"Position: {pos} mm, Speed: {v}, IRQ Count: {count}")
            count = 0
            elapsed = time() - now
            if elapsed < waitingtime:
                sleep(waitingtime - elapsed)

    except KeyboardInterrupt:
        print("\nKeyboard interrupt detected")
        stopPressed()
        cleanup()