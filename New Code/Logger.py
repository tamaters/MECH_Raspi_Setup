# Copyright 2020 Hochschule Luzern - Informatik
# Author: Simon van Hemert <simon.vanhemert@hslu.ch>
# Author: Peter Sollberger <peter.sollberger@hslu.ch>

from matplotlib import pyplot as plt
from array import array
from multiprocessing import Process
import sys
import numpy as np


class Logger:
    """"
    Logs position and speed and on request visualizes collected values concurrently
    """

    def __init__(self, kp, ki, kd, refposition):
        """
        Create a logger and save parameters for displaying.
        """
        self.__title = "Kp = " + str(round(kp, 3)) + " Ki = " + str(round(ki, 3)) + " Kd = " + str(round(kd, 3)) \
                       + " Refpos = " + str(round(refposition, 0))
        self.__speeds = array('l')
        self.__positions = array('l')
        self.__Paction = array('f')
        self.__Iaction = array('f')
        self.__Daction = array('f')
        self.refpos = refposition

    def clean(self):
        """
        Remove all previously stored values.
        """
        del self.__positions
        del self.__speeds
        del self.__Paction
        del self.__Iaction
        del self.__Daction

        self.__speeds = array('l')
        self.__positions = array('l')
        self.__Paction = array('f')
        self.__Iaction = array('f')
        self.__Daction = array('f')

    def log(self, position, speed, PIDactions):
        """
        Add a data tupple to the log.
        """
        self.__positions.append(position)
        self.__speeds.append(speed)
        self.__Paction.append(PIDactions[0])
        self.__Iaction.append(PIDactions[1])
        self.__Daction.append(PIDactions[2])

    def showLoggings(self, Feedback=False, save=False):
        """
        Display a graph of the recorded values.
        """
        t = Process(target=self.displayPlot, args=(self.__positions.tolist(), self.__speeds.tolist(), self.__title,
                                                   [self.__Paction, self.__Iaction, self.__Daction],
                                                   Feedback, self.refpos, save))
        t.start()

    @staticmethod
    def displayPlot(positionsCopy, speedsCopy, titleCopy, PIDactionsCopy, Feedback, refpos, save):
        """
        Thread function to display values with the help of matplotlib.
        Plots Position and speed over time. Optionally the Feedback-actions can be plotted.
        figures and data are saved to png and .txt when save=True
        """
        try:
            time_ax = np.arange(len(positionsCopy)) * 0.01

            # Calculate constants
            # Overshoot
            if np.sign(refpos) == 1:
                overshoot = np.max(positionsCopy) - refpos
            elif np.sign(refpos) == -1:
                overshoot = np.min(positionsCopy) - refpos

            # Rise time --> time between 10% and 90%
            bandmin = 0.1 * refpos
            bandmax = 0.9 * refpos
            # Find times
            risetime = np.interp([bandmin, bandmax], positionsCopy, time_ax)
            risetime = np.round(risetime[1] - risetime[0], 3)
            for i in range(len(speedsCopy)):
                if abs(speedsCopy[i]) > 1024:
                    if speedsCopy[i] > 0:
                        speedsCopy[i] = 1024
                    else:
                        speedsCopy[i] = -1024

            # Settle time 5%
            bandmin = 0.95 * refpos
            bandmax = 1.05 * refpos
            # Find indices where outside band
            for i in range(len(positionsCopy)):
                if positionsCopy[i] > bandmax or positionsCopy[i] < bandmin:
                    settletime = time_ax[i]
            settletime = np.round(settletime, 3)

            # Create figure for Position and speed
            fig = plt.figure(figsize=(12, 5))
            ax1 = fig.add_subplot(121)
            color = 'tab:red'
            ax1.set_xlabel('Time (0.01s)')
            ax1.set_ylabel('Position [mm]', color=color)
            ax1.plot(positionsCopy, color=color)
            ax1.title.set_text('Position and Speed')
            plt.axhline(refpos, alpha=0.5, color="grey")
            plt.axhline(bandmin, alpha=0.5, color="grey", linestyle=":")
            plt.axhline(bandmax, alpha=0.5, color="grey", linestyle=":")
            ax1.tick_params(axis='y', labelcolor=color)

            ax12 = ax1.twinx()  # instantiate a second axes that shares the same x-axis

            color = 'tab:blue'
            ax12.set_ylabel('Speed', color=color)  # we already handled the x-label with ax1
            ax12.plot(speedsCopy, color=color)
            ax12.tick_params(axis='y', labelcolor=color)

            if Feedback:
                """ Plot the PID feedback in separate plot"""
                # fig2 = plt.figure(figsize=(6, 5))

                ax2 = fig.add_subplot(122)
                ax2.plot([0, len(PIDactionsCopy[0][:])], [0, 0], "k:")
                ax2.plot(PIDactionsCopy[0][:], label="P Action")
                ax2.plot(PIDactionsCopy[1][:], label="I Action")
                ax2.plot(PIDactionsCopy[2][:], label="D Action")
                ax2.title.set_text('PID actions over Time')

                plt.xlabel('Time [0.01s]')
                plt.ylabel('Feedback action [1024 = 5V = max]')
                plt.legend()
            figtitle = (str(titleCopy))
            plt.figtext(0.5, 0.01, ("overshoot=" + str(overshoot) + " [mm]" +
                                    "   risetime=" + str(risetime) + " [s]" +
                                    "   settletime=" + str(settletime) + " [s]"),
                        ha="center",
                        fontsize=12,
                        bbox={"facecolor": "salmon", "alpha": 0.3, "pad": 5})
            fig.suptitle(figtitle,
                         va='top',
                         ha="center",
                         fontsize=12,
                         bbox={"facecolor": "aquamarine", "alpha": 0.3, "pad": 5})
            plt.subplots_adjust(top=0.5)
            fig.tight_layout(pad=3)  # otherwise the right y-label is slightly clipped
            plt.show()

            if save:
                # Save the Data as .txt files and the figure as .png
                titleCopy = titleCopy.replace(" ", "")
                filename_png = titleCopy + ".png"
                fig.savefig(filename_png)

                filename_txt = "position_" + titleCopy + '.txt'

                with open(filename_txt, 'w') as f:
                    for item in positionsCopy:
                        f.write("%s\n" % item)

                filename_txt = "feedback_" + titleCopy + '.txt'
                with open(filename_txt, 'w') as f:
                    for item in speedsCopy:
                        f.write("%s\n" % item)

        except:
            print("Unexpected error:", sys.exc_info()[0])
            pass
