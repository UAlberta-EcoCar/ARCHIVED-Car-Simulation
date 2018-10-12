classdef Motor_c < handle %goofy matlab class inheritance
    %% Class containing model of Motor %%

    properties
        OutputFolder = '';

        DataPoints = 0;
        TimeInterval = 0;
        SimulationTime = 0;
        TimeEllapsed = [];

        % Motor Constants
        % https://en.wikipedia.org/wiki/Motor_constants
        % http://learningrc.com/motor-kv/
        VelocityConstant = 0; %rad/Vs
        TorqueConstant = 0; %Nm/A
        BackEMFConstant = 0; %Vs/rad
        MotorConstant = 0; %Nm/sqrt(W)   (W == Watts)

        %winding resistence ohms 
        WindingResistance = 0;   

        %% These Parameters are used to calculate motor torque loss
        %max nominal voltage reported by manufacturer
        MaxVoltage = 0; % V
        %max no load speed at that voltage
        MaxSpeed = 0; % rad/s
        %motor current at full speed with no load
        NoLoadCurrent = 0;
        %torque losses from motor (Nm) "iddle torque"
        TorqueLoss = 0;
        
        StallTorque = 0;
        
        %Thermal time constant (how long does it take to melt motor when
        %runing above torque rating)
        ThermalTimeConstantWinding = 0;
        
        %Torque Modes
        Torque0 = 0;
        Torque1 = 0;
        Torque2 = 0;
        
        BoostTorque = 0;
        RegularTorque = 0;
        
        %Some controllers limit motor current set that here
        MaxCurrent = 1000;


        %inertia of motor armature
        MotorInertia = 0; % kg m^2

        %Variable arrays
        Torque = '';
        PowerIn = '';
        PowerOut = '';
        Efficiency = '';
        Voltage = '';
        Current = '';
        Acceleration = '';
        Speed = '';    
    end
    
    methods
        function obj = Motor_c(SimulationTime,TimeInterval,OutputFolder)
            %class constructor
            
            obj.OutputFolder = OutputFolder;

            obj.SimulationTime = SimulationTime;
            obj.TimeInterval = TimeInterval;
            obj.DataPoints = floor(SimulationTime/TimeInterval);      
            %make time array for plotting
            obj.TimeEllapsed = (0:(obj.DataPoints-1))*TimeInterval';

            %Allocate RAM
            obj.Torque = zeros(obj.DataPoints,1);
            obj.PowerIn = zeros(obj.DataPoints,1);
            obj.PowerOut = zeros(obj.DataPoints,1);
            obj.Voltage = zeros(obj.DataPoints,1);
            obj.Current = zeros(obj.DataPoints,1);
            obj.Acceleration = zeros(obj.DataPoints,1);
            obj.Speed = zeros(obj.DataPoints,1);
            obj.Efficiency = zeros(obj.DataPoints,1);
        end

        %Motor Equations
        function calc_MissingMotorConstants(obj)
            % TorqueConstant = BackEMFConstant = 1/Kv = MotorContant * sqrt(WindingResistance)
            if obj.VelocityConstant == 0
                if obj.BackEMFConstant ~= 0
                    obj.VelocityConstant = 1 / obj.BackEMFConstant;
                elseif obj.TorqueConstant ~= 0
                    obj.VelocityConstant = 1 / obj.TorqueConstant;
                elseif obj.MotorConstant ~= 0
                    if obj.WindingResistance ~= 0
                        obj.VelocityConstant = 1 / obj.MotorConstant / math.sqrt(obj.WindingResistance);
                    else
                        disp('Unable to Calculate Motor Constants')
                    end
                else
                    disp('Unable to Calculate Motor Constants')
                end
            end

            if obj.BackEMFConstant == 0
                obj.BackEMFConstant = 1/obj.VelocityConstant;
            end

            if obj.TorqueConstant == 0
                obj.TorqueConstant = obj.BackEMFConstant;
            end

            if obj.MotorConstant == 0
                if obj.WindingResistance ~= 0
                    obj.MotorConstant = obj.VelocityConstant / sqrt(obj.WindingResistance);
                else
                    disp('Unable to Calculate Motor Constants');
                end
            end
            if obj.WindingResistance == 0
                if obj.MotorConstant ~= 0
                    obj.WindingResistance = math.pow((obj.VelocityConstant / obj.MotorConstant),2);
                    %possible to measure aswell if torque loss is know or no load current
                    %will add later
                else
                    disp('Unable to Calculate Motor Constants')
                end
            end
            %torque loss equals position on torque speed curve at no load idle speed
            if obj.TorqueLoss == 0
                if (obj.MaxSpeed ~= 0) && (obj.MaxVoltage ~= 0)
                    obj.TorqueLoss = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*obj.MaxSpeed + obj.MaxVoltage*obj.TorqueConstant/obj.WindingResistance;
                elseif obj.NoLoadCurrent ~= 0
                    obj.TorqueLoss = obj.TorqueConstant * obj.NoLoadCurrent;
                else
                    disp('Unable to Calculate Motor Losses')
                end
            end
            if obj.TorqueLoss < 0
                disp('Warning: Torque Loss Term Less Than Zero. Check motor Parameters!')
            end
        end
        
        function [MotorVoltage, MotorCurrent] = calc_VoltCurr(obj,MotorSpeed,MotorTorque)
            MotorCurrent = (MotorTorque+obj.TorqueLoss) / obj.TorqueConstant;
            MotorVoltage = (MotorSpeed+obj.MaxSpeed/obj.StallTorque*(MotorTorque+obj.TorqueLoss))/obj.VelocityConstant;
            %Torque = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*Speed+Voltage*obj.TorqueConstant/obj.WindingResistance-obj.TorqueLoss;
        end
        
        function [Torque, Current, Voltage ] = calc_MotorTorqueCurrentwLimit(obj,VoltageIn,Speed,TorqueLimit)
            Torque = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*Speed+VoltageIn*obj.TorqueConstant/obj.WindingResistance-obj.TorqueLoss;
            Voltage = VoltageIn;
            
            if Torque > TorqueLimit
                Torque = TorqueLimit;
                Voltage = ((Torque+obj.TorqueLoss)+obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*Speed)*obj.WindingResistance/obj.TorqueConstant;
            end
            
            Current = (Torque+obj.TorqueLoss)/obj.TorqueConstant;
        end
        
        function [Torque, Current] = calc_MotorTorqueCurrent(obj,Voltage,Speed)
            %motor Torque Speed Curve
            %Torque = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*Speed+Voltage*obj.TorqueConstant/obj.WindingResistance-obj.TorqueLoss;
            Torque = (Voltage*obj.VelocityConstant-Speed)*obj.StallTorque/obj.MaxSpeed-obj.TorqueLoss;
            %MotorVoltage = (MotorSpeed+obj.MaxSpeed/obj.StallTorque*(MotorTorque+obj.TorqueLoss))/obj.VelocityConstant;
            
            %motor torque constant
            Current = (Torque+obj.TorqueLoss)/obj.TorqueConstant;
            %limit motor current to max current
            if Current > obj.MaxCurrent
                Current = obj.MaxCurrent;
                %need to recalculate torque based off of current limit
                Torque = Current*obj.TorqueConstant-obj.TorqueLoss;
            end
            if Current < 0
                Current = 0;
                Torque = -obj.TorqueLoss;
            end
        end

        function obj = calc_Efficiency(obj)
            %% Efficiency %%
            %electrical power in
            obj.PowerIn = obj.Voltage .* obj.Current;
            %mechanical power out
            obj.PowerOut = obj.Torque .* obj.Speed;
            % power out / power in
            obj.Efficiency = obj.PowerOut ./ obj.PowerIn;
            obj.Efficiency(obj.PowerIn == 0) = 0;
        end
        
        %Torque Control
        function obj = set_BoostModes(obj,Torque0,Torque1,Torque2)
            obj.Torque0 = Torque0;
            obj.Torque1 = Torque1;
            obj.Torque2 = Torque2;
        end
        
        function [MotorTorque, MotorVoltage, MotorCurrent ] = calc_TorqueControlledMotor(obj,MotorSpeed,Mode)
            switch(Mode)
                case 0
                    %motor off
                    MotorTorque = obj.Torque0;
                    MotorCurrent = 0;
                    MotorVoltage= 0;
                case 1
                    %optimal boost mode
                    MotorTorque = obj.Torque1;
                    MotorCurrent = MotorTorque / obj.TorqueConstant;
                    MotorVoltage = (MotorSpeed+obj.MaxSpeed/obj.StallTorque*MotorTorque)/obj.VelocityConstant;
                case 2
                    %max boost mode
                    MotorTorque = obj.Torque2;
                    MotorCurrent = MotorTorque / obj.TorqueConstant;
                    MotorVoltage = (MotorSpeed+obj.MaxSpeed/obj.StallTorque*MotorTorque)/obj.VelocityConstant;
            end
        end
        
        %Unit Conversions
        function rad_per_Vs = rpm_per_V_2_rad_per_Vs(~,rpm_per_V)
            rad_per_Vs = rpm_per_V / 60 * 2 * pi;
        end

        function rad_per_s = rpm_2_rad_per_s(~,rpm)
            rad_per_s = rpm / 60 * 2 * pi;
        end

        function kgm2 = gcm2_2_kgm2(~,gcm2)
            kgm2 = gcm2 / 10000000;
        end

        %Plotting
        function plot_TorqueSpeedCurve(obj,savef)
            ms = (-24*obj.TorqueConstant/obj.WindingResistance)/(-1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance);
            speed = 0:ms;
            Torque1 = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*speed+24*obj.TorqueConstant/obj.WindingResistance;
            Torque2 = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*speed+24*obj.TorqueConstant/obj.WindingResistance-obj.TorqueLoss;
            figure()
            plot(speed,Torque1)
            hold on
            plot(speed,Torque2)
            title('Motor Curve at 24 V')
            xlabel('Speed (rad/s)')
            ylabel('Torque (Nm)')
            legend('Theoretical','With Losses')
            if savef
                savefig([obj.OutputFolder Delimiter() 'TorqueSpeedCurve.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'TorqueSpeedCurve.png'])
            close
        end

        function plot_TorqueSpeed(obj,savef)
            figure()
            plot( obj.Speed, obj.Torque )
            xlabel('Speed (rad/s)')
            ylabel('Torque (Nm')
            title('Motor')
            if savef
                savefig([obj.OutputFolder  Delimiter()  'MotorTorqueSpeed.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorTorqueSpeed.png'])
            close
        end

        function plot_EfficiencySpeed(obj,savef)
            figure()
            plot( obj.Speed, obj.Efficiency )
            xlabel('Speed (rad/s)')
            ylabel('Efficiency')
            title('Motor')
            if savef
                savefig([obj.OutputFolder Delimiter() 'MotorEfficiencySpeed.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorEfficiencySpeed.png'])
            close
        end
        
        function plot_EfficiencyTime(obj,savef)
            figure()
            plot( obj.TimeEllapsed, obj.Efficiency )
            xlabel('Time (s)')
            ylabel('Efficiency')
            title('Motor')
            if savef
                savefig([obj.OutputFolder Delimiter() 'MotorEfficiency.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorEfficiency.png'])
            close
        end

        function plot_PowerSpeed(obj,savef)
            figure()
            plot( obj.Speed, obj.PowerIn , obj.Speed , obj.PowerOut )
            xlabel('Speed (rad/s)')
            ylabel('Power (W)')
            title('Motor')
            if savef
                savefig([obj.OutputFolder Delimiter() 'MotorPowerSpeed.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorPowerSpeed.png'])
            close
        end

        function plot_SpeedTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Speed)
            xlabel('Time (s)')
            ylabel('Speed (rad/s)')
            title('Motor')
            if savef
               savefig([obj.OutputFolder Delimiter() 'MotorSpeedTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorSpeedTime.png'])
            close
        end

        function plot_TorqueTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.Torque)
            xlabel('Time (s)')
            ylabel('Torque (Nm)')
            title('Motor')
            if savef
                savefig([obj.OutputFolder Delimiter() 'MotorTorqueTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorTorqueTime.png'])
            close
        end

        function plot_CurrentTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Current)
            xlabel('Time (s)')
            ylabel('Current (A)')
            title('Motor')
            if savef
                savefig([obj.OutputFolder Delimiter() 'MotorCurrentTime.fig'])  
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorCurrentTime.png'])  
            close
        end

        function plot_VoltageTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Voltage)
            xlabel('Time (s)')
            ylabel('Voltage (V)')
            title('Motor')
            hold on
            plot(obj.TimeEllapsed, ones(size(obj.TimeEllapsed))*obj.MaxVoltage)
            if savef
                savefig([obj.OutputFolder Delimiter() 'MotorVoltageTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'MotorVoltageTime.png'])
            close
        end
    end
end