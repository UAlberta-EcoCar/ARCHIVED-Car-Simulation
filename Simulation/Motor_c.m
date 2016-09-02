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
            if obj.TorqueLoss <= 0
                disp('Warning: Torque Loss Term Less Than Zero. Check motor Parameters!')
            end
        end

        function [Torque, Current] = calc_MotorTorqueCurrent(obj,Voltage,Speed,Throttle)
            if Throttle
                %motor Torque Speed Curve
                Torque = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*Speed+Voltage*obj.TorqueConstant/obj.WindingResistance-obj.TorqueLoss;

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
                    Torque = 0;
                end
            else
                Torque = 0;
                Current = 0;
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
            ms = (-36*obj.TorqueConstant/obj.WindingResistance)/(-1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance);
            speed = 0:ms;
            Torque1 = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*speed+36*obj.TorqueConstant/obj.WindingResistance;
            Torque2 = -1*obj.BackEMFConstant*obj.TorqueConstant/obj.WindingResistance*speed+36*obj.TorqueConstant/obj.WindingResistance-obj.TorqueLoss;
            figure()
            plot(speed,Torque1)
            hold on
            plot(speed,Torque2)
            title('Motor Curve at 36 V')
            xlabel('Speed (rad/s)')
            ylabel('Torque (Nm)')
            legend('Theoretical','With Losses')
            if savef
                savefig([obj.OutputFolder '\\' 'TorqueSpeedCurve.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'TorqueSpeedCurve.png'])
            close
        end

        function plot_TorqueSpeed(obj,savef)
            figure()
            plot( obj.Speed, obj.Torque )
            xlabel('Speed (rad/s)')
            ylabel('Torque (Nm')
            title('Motor')
            if savef
                savefig([obj.OutputFolder  '\\'  'MotorTorqueSpeed.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'TorqueSpeedCurve.png'])
            close
        end

        function plot_EfficiencySpeed(obj,savef)
            figure()
            plot( obj.Speed, obj.Efficiency )
            xlabel('Speed (rad/s)')
            ylabel('Efficiency')
            title('Motor')
            if savef
                savefig([obj.OutputFolder '\\' 'MotorEfficiencySpeed.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'MotorEfficiencySpeed.png'])
            close
        end

        function plot_PowerSpeed(obj,savef)
            figure()
            plot( obj.Speed, obj.PowerIn , obj.Speed , obj.PowerOut )
            xlabel('Speed (rad/s)')
            ylabel('Power (W)')
            title('Motor')
            if savef
                savefig([obj.OutputFolder '\\' 'MotorPowerSpeed.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'MotorPowerSpeed.png'])
            close
        end

        function plot_SpeedTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Speed)
            xlabel('Time (s)')
            ylabel('Speed (rad/s)')
            title('Motor')
            if savef
               savefig([obj.OutputFolder '\\' 'MotorSpeedTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'MotorSpeedTime.png'])
            close
        end

        function plot_TorqueTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.Torque)
            xlabel('Time (s)')
            ylabel('Torque (Nm)')
            title('Motor')
            if savef
                savefig([obj.OutputFolder '\\' 'MotorTorqueTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'MotorTorqueTime.png'])
            close
        end

        function plot_CurrentTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Current)
            xlabel('Time (s)')
            ylabel('Current (A)')
            title('Motor')
            if savef
                savefig([obj.OutputFolder '\\' 'MotorCurrentTime.fig'])  
            end
            saveas(gcf,[obj.OutputFolder '\\' 'MotorCurrentTime.png'])  
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
                savefig([obj.OutputFolder '\\' 'MotorVoltageTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'MotorVoltageTime.png'])
            close
        end
    end
end