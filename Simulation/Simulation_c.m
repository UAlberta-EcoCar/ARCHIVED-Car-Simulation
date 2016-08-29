classdef Simulation_c < handle %goofy matlab class inheritance
    %%%% SIMULATION %%%%
    methods
        function obj = Simulation_c()
            %empty class constructor
            disp('Simulation Object Created')
        end
        function run_Simulation(~,motor,fuelcell,car,track,supercap,DataPoints,TimeInterval)
            %Starting Simulation

            %% initial conditions %%

            fuelcell.StackCurrent(1) = fuelcell.AuxCurrent;
            fuelcell.StackVoltage(1) = fuelcell.calc_StackVoltage(fuelcell.StackCurrent(1));

            supercap.Charge(1) = supercap.calc_Charge(fuelcell.StackVoltage(1)-fuelcell.DiodeVoltageDrop);
            supercap.Voltage(1) = supercap.calc_Voltage(supercap.Charge(1));

            Throttle = 100;

            %% Solve Differential Equations Numerically in for Loop %%
            for n = 2:DataPoints
                car.Speed(n) = car.Speed(n-1) + car.Acceleration(n-1)*TimeInterval;
                motor.Speed(n) = car.Speed(n) / car.WheelDiameter * 2 * car.GearRatio;

                [motor.Torque(n),motor.Current(n)] = motor.calc_MotorTorqueCurrent(motor.Voltage(n-1),motor.Speed(n-1),Throttle);

                %motor and Aux  drains caps
                supercap.Charge(n) = supercap.DrainCaps(supercap.Charge(n-1),motor.Current(n)+fuelcell.AuxCurrent,TimeInterval);

                %fuel cell supplies caps
                fuelcell.StackCurrent(n) = fuelcell.calc_StackCurrent(fuelcell.StackVoltage(n-1));
                supercap.Charge(n) = supercap.DrainCaps(supercap.Charge(n),-1*fuelcell.StackCurrent(n),TimeInterval);

                %super cap voltage changes based on charge
                supercap.Voltage(n) = supercap.calc_Voltage(supercap.Charge(n));
                %fuelcell voltage from cap voltage
                fuelcell.StackVoltage(n) = supercap.Voltage(n) + fuelcell.DiodeVoltageDrop;

                motor.Voltage(n) = supercap.Voltage(n);

                car.AirDrag(n) = car.calc_AirDrag(track.AirDensity,car.Speed(n));

                car.Acceleration(n) = (motor.Torque(n)/car.WheelDiameter*2*car.GearRatio*car.GearEfficiency-car.Mass*sin(track.calc_Incline(car.DistanceTravelled(n-1))/180*pi)*9.81-car.AirDrag(n)-car.TireDrag-car.BearingDrag) / car.Mass;

                %stop car from moving backwards if oposing forces are too high
                if car.Acceleration(n) < 0
                    if car.Speed(n) <= 0
                        car.Acceleration(n) = 0;
                        car.Speed(n) = 0;
                    end
                end
                car.DistanceTravelled(n) = car.DistanceTravelled(n-1) + car.Speed(n-1)*TimeInterval;

                fuelcell.StackEnergyProduced(n) = fuelcell.StackEnergyProduced(n-1) + fuelcell.calc_StackEnergyProduced(fuelcell.StackVoltage(n),fuelcell.StackCurrent(n),TimeInterval);
                fuelcell.StackEnergyConsumed(n) = fuelcell.StackEnergyConsumed(n-1) + fuelcell.calc_StackEnergyConsumed(fuelcell.StackCurrent(n),TimeInterval);
            end

            %% These calculations can be vectorized instead of being in for loop %%

            %calculate motor efficiency curve
            motor.calc_Efficiency();

            %fuelcell power output
            fuelcell.calc_StackPowerOut();
            %calculate fuelcell efficiency curve
            fuelcell.calc_StackEfficiency();

            %super capacitor current
            supercap.calc_Current();  
            supercap.calc_PowerOut();

            %instantaneous driving efficiency -> power into motor vs speed
            car.InstantaneousMilage = car.Speed * 3.6  ./ (fuelcell.CellNumber*fuelcell.TheoreticalCellVoltage*fuelcell.StackCurrent / 1000); %km / kWh
            car.AverageMilage = car.DistanceTravelled / 1000 ./ (fuelcell.StackEnergyConsumed / 1000 / 1000 / 3.6); %km / kWh
        end

        %% Car Performance Plots %%
        function plot_PowerCurves(~,fuelcell,motor,supercaps,OutputFolder,savef)
            figure()
            plot(fuelcell.TimeEllapsed,fuelcell.StackPowerOut)
            hold on
            plot(motor.TimeEllapsed,motor.PowerIn)
            plot(motor.TimeEllapsed,motor.PowerOut)
            plot(supercaps.TimeEllapsed,supercaps.PowerOut)
            xlabel('Time (s)')
            ylabel('Power (W)')
            title('Power Time Series Comparison')
            legend('FuelCell','MotorIn','MotorOut','SuperCaps')            
            if savef
                savefig([OutputFolder '\\' 'PowerOutputs.fig'])
            end
            saveas(gcf,[OutputFolder '\\' 'PowerOutputs.png'])
            close
        end
    end
end
