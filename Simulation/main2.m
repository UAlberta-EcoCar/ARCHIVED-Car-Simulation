close all
clear all

Folder = 'output';
if ~exist(Folder,'dir')
    mkdir(Folder)
end
%% Simulation Details %%
savef = 1; %change to 1 to save .fig as well as .png
SimulationTime = 1000; %seconds
TimeInterval = 0.005; %time step/integration interval %make a lot smaller than total inertia to decrease motor speed integration error

DataPoints = floor(SimulationTime/TimeInterval);

GearRatio = 17;


Folder2 = [ Folder Delimiter() 'Maxon 370354' ];
Folder3 = [ Folder2 Delimiter() '28 cell Ballard' ]; 
OutputFolder = [ Folder3 Delimiter() 'GearRatio' int2str(GearRatio) ];
            
%% %% MOTOR %% %%
%create motor object
motor = Motor_c(SimulationTime,TimeInterval,OutputFolder);

%% Set Motor Constants %%
%Velocity constant, Torque constant, BackEMFConstant are all related only need one https://en.wikipedia.org/wiki/Motor_constants
motor.TorqueConstant = 0.0385; % Nm/A
motor.WindingResistance = 0.103;
motor.VelocityConstant = motor.rpm_per_V_2_rad_per_Vs(248);

motor.MaxSpeed = motor.rpm_2_rad_per_s(5952);%5680);
motor.StallTorque = 8.92;

motor.MaxVoltage = 24;

%calculate other motor parameters
motor.calc_MissingMotorConstants();

motor.set_BoostModes(0,0.25,0.405*3);
motor.ThermalTimeConstantWinding = 68.5; %seconds


%% BuckConvert / Motor Controller %%
buckconverter = BuckConverter_c(SimulationTime,TimeInterval,OutputFolder);
buckconverter.Efficiency = 0.9;

%% FUELCELL %%
%create fuelcell object
fuelcell = FuelCell_c(SimulationTime,TimeInterval,OutputFolder);
%Set FuelCell parameters
fuelcell.CellNumber = 28;
fuelcell.CellArea = 145; %cm2
fuelcell.CellResistance = 0.36;
fuelcell.Alpha = 0.45;
fuelcell.ExchangeCurrentDensity = 0.04;
fuelcell.CellOCVoltage = 1.02; %open circuit voltage
fuelcell.DiodeVoltageDrop = 0.5;
fuelcell.AuxCurrent = 1.2; %current consumed by controllers, fans etc (everything except motor)
fuelcell.AuxCurrentLow = 0.5; %current consumed with fans off
fuelcell.AuxCurrentHigh = 1.5; %current with fans on
fuelcell.build_VoltageCurrentCurve();


%% TRACK %%
%create track object
TrackLength = 950;
track = Track_c(SimulationTime,TimeInterval,OutputFolder);
%set track parameters
distance = [ 0	16.0934	32.1868	48.2802	64.3736	80.467	96.5604	112.6538	128.7472	144.8406	160.934	177.0274	193.1208	209.2142	225.3076	241.401	257.4944	273.5878	289.6812	292.89988	296.11856	299.33724	302.55592	305.7746	313.8213	321.868	337.9614	354.0548	370.1482	386.2416	402.335	418.4284	434.5218	450.6152	466.7086	482.802	498.8954	514.9888	531.0822	547.1756	563.269	579.3624	595.4558	611.5492	627.6426	643.736	659.8294	675.9228	692.0162	708.1096	724.203	740.2964	756.3898	772.4832	788.5766	804.67	820.7634	836.8568	852.9502	869.0436	877.0903	885.137	893.1837	901.2304	909.2771	917.3238	925.3705	933.4172	941.4639	949.5106 ];
track.LapDistance=max(distance);
incline = [ 0.5	0.4	0.7	0.5	0.7	0.9	0.7	0.6	0.6	0.8	0.3	-0.7	-1.1	-0.4	0.3	0.1	-0.8	-0.6	-0.5	-0.5	-1.4	-2.4	-3.3	-2.3	-1.5	-1.8	-1.7	-1.6	-0.9	-0.6	-0.9	-1.2	-1.9	-0.9	0.2	-0.5	-0.5	-0.5	-0.5	0.2	1	1.1	1	0.9	0.3	-1	0.2	0	-0.1	-0.2	-0.2	0	0.2	-0.8	-0.5	0	-0.5	-0.8	-0.6	-1.7	-1.5	3.2	1	5.5	4.2	3.9	4.2	4.2	3.2	1.2 ];
%calc track length
track.Incline = pchip(distance,incline,1:track.LapDistance)'; %pchip interpolation to smooth curve and calculate points over even 1m intervals
%convert %slope to degrees
track.Incline = atand(track.Incline / 100);

track.RelativeHumidity = 50; %%
track.Temperature = 30; %Celcius
track.AirPressure = 101; %kPa
track.AirDensity = track.calc_AirDensity();


%% SUPERCAPS %%
%create super capacitor object
supercaps = SuperCapacitor_c(SimulationTime,TimeInterval,OutputFolder);
%set super capacitor parameters
supercaps.Capacitance = 58/2;


%% CAR %%
%create car object
car = Car_c(SimulationTime,TimeInterval,OutputFolder);

%% set car parameters %%
% NumberOfTeethDriven / NumberOfTeethDriving
car.GearRatio = GearRatio; %unitless
% efficency of gears (based off friction etc)
car.GearEfficiency = 0.9; % spur gears usually over 90%
% total mass of everything
car.Mass = 115; %kg 
car.WheelDiameter = 0.478; % m
% Bearing resistance friction coefficient
car.BearingDragCoefficient = 0.0015; %unitless Standard value for oiled bearings
%diameter of bearings
car.BearingBoreDiameter = 0.03; %m's
car.BearingDrag = car.calc_BearingDrag(car.BearingDragCoefficient,car.Mass,car.BearingBoreDiameter,car.WheelDiameter);
%https://en.wikipedia.org/wiki/Rolling_resistance
car.RollingResistanceCoefficient = 0.00081; %Unitless get from tire manufacturer
car.TireDrag = car.calc_TireDrag(car.RollingResistanceCoefficient,car.Mass);
% http://physics.info/drag/
car.AreodynamicDragCoefficient = 0.09; % standard value for a car
car.FrontalArea = 0.45; %m^2

%make new instance of Simulation class
Simulation = Simulation2_c();
Simulation.run_Simulation(motor,buckconverter,fuelcell,car,track,supercaps,DataPoints,TimeInterval);

if 1
    if ~exist(Folder2,'dir')
        mkdir(Folder2)
    end
    if ~exist(Folder3,'dir')
        mkdir(Folder3)
    end
    if ~exist(OutputFolder,'dir')
        mkdir(OutputFolder)
    end
    
    %% Make Plots %%
    track.plot_Profile(savef)
    
    motor.plot_TorqueSpeedCurve(savef)
    motor.plot_TorqueSpeed(savef)
    motor.plot_PowerSpeed(savef)
    motor.plot_EfficiencySpeed(savef)
    motor.plot_EfficiencyTime(savef)
    motor.plot_SpeedTime(savef)
    motor.plot_TorqueTime(savef)
    motor.plot_CurrentTime(savef)
    motor.plot_VoltageTime(savef)
    
    fuelcell.plot_FCCurve(savef)
    fuelcell.plot_StackVoltageCurrent(savef)
    fuelcell.plot_StackEfficiency(savef)
    fuelcell.plot_StackCurrentTime(savef)
    fuelcell.plot_PowerCurves(savef)
    
    car.plot_DistanceTime(savef)
    car.plot_SpeedTime(savef)
    car.plot_AccelerationTime(savef)
    car.plot_Milage(savef)
    car.plot_Drag(savef)
    
    supercaps.plot_VoltageCharge(savef)
    supercaps.plot_ChargeTime(savef)
    supercaps.plot_CurrentTime(savef)
    supercaps.plot_VoltageTime(savef)
    buckconverter.plot_VoltageCurrentTime(savef)
    buckconverter.plot_PowerTime(savef)
    
    Simulation.plot_PowerCurves(fuelcell,motor,supercaps,OutputFolder,savef)
    Simulation.plot_Driving(fuelcell,motor,supercaps,track,car,OutputFolder,savef)
    
    
    %Save data to .mat
    save([OutputFolder Delimiter() 'Motor1' '_' 'FC1' '_' 'GearRatio' int2str(GearRatio) ])

end