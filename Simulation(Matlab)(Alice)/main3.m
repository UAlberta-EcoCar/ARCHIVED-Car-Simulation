clear
close

Folder = 'output';
if ~exist(Folder,'dir')
    mkdir(Folder)
end

OutputFolder = [ Folder ];

SimulationTime = 1000; %seconds
TimeInterval = 0.005; %time step/integration interval %make a lot smaller than total inertia to decrease motor speed integration error

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

%% CAR %%
%create car object
car = Car_c(SimulationTime,TimeInterval,OutputFolder);

%% set car parameters %%
% NumberOfTeethDriven / NumberOfTeethDriving
car.GearRatio = 17; %unitless
% efficency of gears (based off friction etc)
car.GearEfficiency = 0.9; % spur gears usually over 90%
% total mass of everything
car.Mass = 170; %kg 
car.WheelDiameter = 0.558; % m
% Bearing resistance friction coefficient
car.BearingDragCoefficient = 0.0015; %unitless Standard value for oiled bearings
%diameter of bearings
car.BearingBoreDiameter = 0.03; %m's
car.BearingDrag = car.calc_BearingDrag(car.BearingDragCoefficient,car.Mass,car.BearingBoreDiameter,car.WheelDiameter);
%https://en.wikipedia.org/wiki/Rolling_resistance
car.RollingResistanceCoefficient = 0.0025; %Unitless get from tire manufacturer
car.TireDrag = car.calc_TireDrag(car.RollingResistanceCoefficient,car.Mass);
% http://physics.info/drag/
car.AreodynamicDragCoefficient = 0.4; % standard value for a car
car.FrontalArea = 1.1; %m^2

car.plot_DragvsSpeed(track.AirDensity,1,0)
car.plot_DragPowervsSpeed(track.AirDensity,1,0)
car.plot_DragTorqueatWheelsvsSpeed(track.AirDensity,1,0)

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
fuelcell.AuxCurrent = 1.2; %current consumed by controllers, fans etc (everything except motor)
fuelcell.AuxCurrentLow = 0.5; %current consumed with fans off
fuelcell.AuxCurrentHigh = 1.5; %current with fans on
fuelcell.build_VoltageCurrentCurve(); %builds a lookup table for solving inverse of tafal equation

fuelcell.plot_VoltagevsPower(1,0)