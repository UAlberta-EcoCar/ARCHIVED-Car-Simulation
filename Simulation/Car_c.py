# -*- coding: utf-8 -*-

import numpy as np
import math
from numba import jit
import matplotlib.pyplot as plt

class Car_c:
    """ Class containing model of Car """
    
    OutputFolder = ''
    
    #Constants
    Mass = 0  #kg
    
    WheelDiameter = 0  #m
    WhellInertia = 0 #kgm^2
    
    GearRatio = 0
    GearEfficiency = 0 #fraction
    GearInertia = 0
    
    RollingResistanceCoefficient = 0
    TireDrag = 0
    
    BearingDragCoefficient = 0 #N
    BearingBoreDiameter = 0
    BearingDrag = 0    
    
    AreodynamicDragCoefficient = 0
    AirDrag = 0
    
    FrontalArea = 0 #m^2
    
    DataPoints = ''
    SimulationTime = ''
    TimeInterval = ''
    
    #Variable arrays
    Acceleration = ''
    Speed = ''
    DistanceTravelled = ''
    AirDrag = ''    
    Milage = ''    
    
    #equations
    
        
    def __init__(self,SimulationTime,TimeInterval,OutputFolder):
        #class constructor
        print('Car Object Created')
        
        self.OutputFolder = OutputFolder
        
        self.SimulationTime = SimulationTime
        self.Timeinterval = TimeInterval
        self.DataPoints = math.floor(SimulationTime/TimeInterval)         
        
        #make time array for plotting
        self.TimeEllapsed = np.arange(self.DataPoints)*TimeInterval
        
        #Allocate RAM
        self.Acceleration = np.zeros(self.DataPoints)
        self.Speed = np.zeros(self.DataPoints)
        self.DistanceTravelled = np.zeros( self.DataPoints )
        self.AirDrag = np.zeros( self.DataPoints )

    @jit
    def calc_AirDrag(self,AirDensity,Speed):
        AirDrag = 0.5*self.AreodynamicDragCoefficient*self.FrontalArea*AirDensity*math.pow(Speed,2)
        return(AirDrag)
    
    @jit
    def calc_BearingDrag(self,BearingDragCoefficient,Mass,BearingBore,WheelDiameter):
        BearingDrag = BearingDragCoefficient*Mass*9.81*BearingBore/WheelDiameter
        return(BearingDrag)
    
    @jit
    def calc_TireDrag(self,RollingResistanceCoefficient,Mass):
        TireDrag = RollingResistanceCoefficient*Mass*9.81
        return(TireDrag)
  
    ## Plotting ##
    def plot_DistanceTime(self):
        plt.figure()
        plt.plot(self.TimeEllapsed, self.DistanceTravelled)
        plt.xlabel('Time')
        plt.ylabel('Distance (m)')
        plt.title('Car')
        plt.show()
        plt.savefig(self.OutputFolder + '\\' + 'CarDistanceTime.png')
        
    def plot_SpeedTime(self):
        plt.figure()
        plt.plot(self.TimeEllapsed, self.Speed*3.6)
        plt.xlabel('Time')
        plt.ylabel('Speed (km.h)')
        plt.title('Car')
        plt.show()
        plt.savefig(self.OutputFolder + '\\' + 'CarSpeedTime.png')
        
    def plot_AccelerationTime(self):
        plt.figure()
        plt.plot(self.TimeEllapsed, self.Acceleration)
        plt.xlabel('Time')
        plt.ylabel('Acceleration (m/s2)')
        plt.title('Car')
        plt.show()
        plt.savefig(self.OutputFolder + '\\' + 'CarAccelerationTime.png')
        
    def plot_Milage(self):
        plt.figure()
        plt.plot(self.TimeEllapsed, self.InstantaneousMilage)
        plt.xlabel('Time')
        plt.ylabel('Milage km/kwh')
        plt.title('Instantaneous Milage')
        plt.show()
        plt.plot(self.TimeEllapsed, self.AverageMilage)
        plt.xlabel('Time')
        plt.ylabel('Milage km/kwh')
        plt.title('Average Milage')
        plt.show()
        plt.savefig(self.OutputFolder + '\\' + 'CarMilage.png')
        
    def plot_Drag(self):
        plt.figure()
        plt.plot(self.TimeEllapsed,self.AirDrag)
        plt.xlabel('Time (S)')
        plt.ylabel('Drag (N)')
        plt.title('Air Drag')
        plt.show()
        plt.savefig(self.OutputFolder + '\\' + 'CarDrag.png')