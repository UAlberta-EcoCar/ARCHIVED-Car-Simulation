close all
clear all

Folder = 'output';
if ~exist(Folder,'dir')
    mkdir(Folder)
end
%% Simulation Details %%
savef = 0; %change to 1 to save .fig as well as .png
SimulationTime = 80; %seconds
TimeInterval = 0.01; %time step/integration interval %make a lot smaller than total inertia to decrease motor speed integration error
TrackLength = 4500; % meters
DataPoints = floor(SimulationTime/TimeInterval);

%% Excel Files Information %%
NumberFuelCells = 1;

ef = ExcelReader_c();
ef.ParseMotorFile('Motor List.xlsx');

GearRatios = [ 4 6 8 9 10 11 12 14 16 18 20 22 24 26 ];

%% Nested For Loops %%
for m = 1:(ef.NumberMotors)
    Folder2 = [ Folder '\\' ef.motor(m).name ];

    for f = 2:(NumberFuelCells+1)
        Folder3 = [ Folder2 '\\' 'FC1' ]; 
        
        for GearRatio = GearRatios
            OutputFolder = [ Folder3 '\\' 'GearRatio' int2str(GearRatio) ];
            
            disp('')
            disp([ef.motor(m).name ' ' 'FC1' ' ' int2str(GearRatio) ]) 
            
            %% %% MOTOR %% %%
            %create motor object
            motor = Motor_c(SimulationTime,TimeInterval,OutputFolder);

            %% Set Motor Constants %%
            %Velocity constant, Torque constant, BackEMFConstant are all related only need one https://en.wikipedia.org/wiki/Motor_constants
            motor.VelocityConstant = motor.rpm_per_V_2_rad_per_Vs(ef.motor(m).SpeedConstant); % rad/Vs
            motor.WindingResistance = ef.motor(m).WindingResistance;
            motor.MaxSpeed = motor.rpm_2_rad_per_s(ef.motor(m).MaxSpeed);
            motor.MaxVoltage = ef.motor(m).MaxVoltage;
            %set to limit motor current (ie some controllers limit current)  default is 1000 Amps
            motor.MaxCurrent = 60; %Amp
            %calculate other motor parameters
            motor.calc_MissingMotorConstants();

            
            %% FUELCELL %%

            %create fuelcell object
            fuelcell = FuelCell_c(SimulationTime,TimeInterval,OutputFolder);
            %Set FuelCell parameters
            fuelcell.CellNumber = 23;
            fuelcell.CellArea = 145; %cm2
            fuelcell.CellResistance = 0.36;
            fuelcell.Alpha = 0.45;
            fuelcell.ExchangeCurrentDensity = 0.04;
            fuelcell.CellOCVoltage = 1.02; %open circuit voltage
            fuelcell.DiodeVoltageDrop = 0.5;
            fuelcell.AuxCurrent = 2; %current consumed by controllers, fans etc (everything except motor)
            fuelcell.build_VoltageCurrentCurve();

            %% TRACK %%

            %create track object
            track = Track_c(SimulationTime,TimeInterval,TrackLength,OutputFolder);
            %set track parameters
            track.smoothtrack(5);
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
            car.GearRatio = GearRatio; %unitless
            % efficency of gears (based off friction etc)
            car.GearEfficiency = 0.9; % spur gears usually over 90%
            % total mass of everything
            car.Mass = 40+75; %kg 
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
            car.AreodynamicDragCoefficient = 0.15; % standard value for a car
            car.FrontalArea = 0.5*0.5;% 1.2*1.67; %m^2

            %make new instance of Simulation class
            Simulation = Simulation_c();
            Simulation.run_Simulation(motor,fuelcell,car,track,supercaps,DataPoints,TimeInterval);
            
            if Simulation.check_Viability(fuelcell,motor,supercaps,car,TimeInterval)
                disp('Car runs successfully')
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
                track.plot_Profile(savef);
                
                motor.plot_TorqueSpeedCurve(savef);
                motor.plot_TorqueSpeed(savef)
                motor.plot_PowerSpeed(savef)
                motor.plot_EfficiencySpeed(savef)
                motor.plot_SpeedTime(savef)
                motor.plot_TorqueTime(savef)
                motor.plot_CurrentTime(savef)
                motor.plot_VoltageTime(savef)

                fuelcell.plot_FCCurve(savef);
                fuelcell.plot_StackVoltageCurrent(savef)
                fuelcell.plot_StackEfficiency(savef)
                fuelcell.plot_StackCurrentTime(savef)

                car.plot_DistanceTime(savef)
                car.plot_SpeedTime(savef)
                car.plot_AccelerationTime(savef)
                car.plot_Milage(savef)
                car.plot_Drag(savef)

                supercaps.plot_VoltageCharge(savef)
                supercaps.plot_ChargeTime(savef)
                supercaps.plot_CurrentTime(savef)

                Simulation.plot_PowerCurves(fuelcell,motor,supercaps,OutputFolder,savef)

                %Save data to .mat
                save([OutputFolder '\\' 'Motor1' '_' 'FC1' '_' 'GearRatio' int2str(GearRatio) ])
            end
        end
    end
end