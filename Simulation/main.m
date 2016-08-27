close all
clear all
OutputFolder = 'output';

SimulationTime = 600; %seconds
TimeInterval = 0.005; %time step/integration interval %make a lot smaller than total inertia to decrease motor speed integration error
TrackLength = 4500; % meters

DataPoints = floor(SimulationTime/TimeInterval);


%%%% MOTOR %%%%

%create motor object
motor = Motor_c(SimulationTime,TimeInterval,OutputFolder);

%% Set Motor Constants %%
%Velocity constant, Torque constant, BackEMFConstant are all related only need one https://en.wikipedia.org/wiki/Motor_constants
motor.VelocityConstant = motor.rpm_per_V_2_rad_per_Vs(250); % rad/Vs
motor.WindingResistance = 0.5;
motor.NoLoadCurrent = 2;
%set to limit motor current (ie some controllers limit current)  default is 1000 Amps
motor.MaxCurrent = 60; %Amp
%calculate other motor parameters
motor.calc_MissingMotorConstants();
motor.plot_TorqueSpeedCurve();


%% FUELCELL %%

%create fuelcell object
fuelcell = FuelCell_c(SimulationTime,TimeInterval,OutputFolder);
%Set FuelCell parameters
fuelcell.CellNumber = 46;
fuelcell.CellArea = 145; %cm2
fuelcell.CellResistance = 0.36;
fuelcell.Alpha = 0.45;
fuelcell.ExchangeCurrentDensity = 0.04;
fuelcell.CellOCVoltage = 1.02; %open circuit voltage
fuelcell.DiodeVoltageDrop = 0.5;
fuelcell.AuxCurrent = 2; %current consumed by controllers, fans etc (everything except motor)
fuelcell.build_VoltageCurrentCurve();
fuelcell.plot_FCCurve();


%% TRACK %%

%create track object
track = Track_c(SimulationTime,TimeInterval,TrackLength,OutputFolder);
%set track parameters
track.smoothtrack(5);
track.plot_Profile();
track.RelativeHumidity = 50; %%
track.Temperature = 30; %Celcius
track.AirPressure = 101; %kPa
track.AirDensity = track.calc_AirDensity();


%% SUPERCAPS %%

%create super capacitor object
supercaps = SuperCapacitor_c(SimulationTime,TimeInterval,OutputFolder);
%set super capacitor parameters
supercaps.Capacitance = 19.3;


%% CAR %%
%create car object
car = Car_c(SimulationTime,TimeInterval,OutputFolder);

%% set car parameters %%
% NumberOfTeethDriven / NumberOfTeethDriving
car.GearRatio = 29; %unitless
% efficency of gears (based off friction etc)
car.GearEfficiency = 0.9; % spur gears usually over 90%
% total mass of everything
car.Mass = 170+75; %kg 
car.WheelDiameter = 0.56; % m
% Bearing resistance friction coefficient
car.BearingDragCoefficient = 0.0015; %unitless Standard value for oiled bearings
%diameter of bearings
car.BearingBoreDiameter = 0.05; %m's
car.BearingDrag = car.calc_BearingDrag(car.BearingDragCoefficient,car.Mass,car.BearingBoreDiameter,car.WheelDiameter);
%https://en.wikipedia.org/wiki/Rolling_resistance
car.RollingResistanceCoefficient = 0.007; %Unitless get from Michelin (lowest from michelin is 0.0065)
car.TireDrag = car.calc_TireDrag(car.RollingResistanceCoefficient,car.Mass);
% http://physics.info/drag/
car.AreodynamicDragCoefficient = 0.3; % standard value for a car
car.FrontalArea = 1.2*1.67; %m^2

%make new instance of Simulation class
Simulation = Simulation_c();
Simulation.run_Simulation(motor,fuelcell,car,track,supercaps,DataPoints,TimeInterval);


%% Make Plots %%
motor.plot_TorqueSpeed()
motor.plot_PowerSpeed()
motor.plot_EfficiencySpeed()
motor.plot_SpeedTime()
motor.plot_TorqueTime()
motor.plot_CurrentTime()
motor.plot_VoltageTime()

fuelcell.plot_StackVoltageCurrent()
fuelcell.plot_StackEfficiency()
fuelcell.plot_StackCurrentTime()

car.plot_DistanceTime()
car.plot_SpeedTime()
car.plot_AccelerationTime()
car.plot_Milage()
car.plot_Drag()

supercaps.plot_VoltageCharge()
supercaps.plot_ChargeTime()
supercaps.plot_CurrentTime()

Simulation.plot_PowerCurves(fuelcell,motor,supercaps,OutputFolder)

%Save data to .mat
save([OutputFolder '\\' 'Data'])