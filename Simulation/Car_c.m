classdef Car_c < handle %goofy matlab class inheritance
    %% Class containing model of Car %%
    
    properties
        OutputFolder = '';

        %Constants
        Mass = 0;  %kg

        WheelDiameter = 0;  %m
        WhellInertia = 0; %kgm^2

        GearRatio = 0;
        GearEfficiency = 0; %fraction
        GearInertia = 0;

        RollingResistanceCoefficient = 0;
        TireDrag = 0;

        BearingDragCoefficient = 0; %N
        BearingBoreDiameter = 0;
        BearingDrag = 0;    

        AreodynamicDragCoefficient = 0;
        AirDrag = 0;

        FrontalArea = 0; %m^2

        DataPoints = '';
        SimulationTime = '';
        TimeInterval = '';
        TimeEllapsed = [];

        %Variable arrays
        Acceleration = '';
        Speed = '';
        DistanceTravelled = '';
        Milage = '';    
        
        AverageMilage = [];
        InstantaneousMilage = [];
    end

    methods
        function obj = Car_c(SimulationTime,TimeInterval,OutputFolder)
            %classfunction constructor
            disp('Car Object Created')

            obj.OutputFolder = OutputFolder;

            obj.SimulationTime = SimulationTime;
            obj.TimeInterval = TimeInterval;
            obj.DataPoints = floor(SimulationTime/TimeInterval);         

            %make time array for plotting
            obj.TimeEllapsed = (1:obj.DataPoints)*TimeInterval';

            %Allocate RAM
            obj.Acceleration = zeros(obj.DataPoints,1);
            obj.Speed = zeros(obj.DataPoints,1);
            obj.DistanceTravelled = zeros( obj.DataPoints,1);
            obj.AirDrag = zeros( obj.DataPoints,1);
        end

        
        function [AirDrag] = calc_AirDrag(obj,AirDensity,Speed)
            AirDrag = 0.5*obj.AreodynamicDragCoefficient*obj.FrontalArea*AirDensity*Speed^2;
        end

        
        function [BearingDrag] = calc_BearingDrag(~,BearingDragCoefficient,Mass,BearingBore,WheelDiameter)
            BearingDrag = BearingDragCoefficient*Mass*9.81*BearingBore/WheelDiameter;
        end

        
        function [TireDrag] = calc_TireDrag(~,RollingResistanceCoefficient,Mass)
            TireDrag = RollingResistanceCoefficient*Mass*9.81;
        end

        %% Plotting %%
        function plot_DistanceTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.DistanceTravelled)
            xlabel('Time')
            ylabel('Distance (m)')
            title('Car')            
            if savef
                savefig([obj.OutputFolder '\\' 'CarDistanceTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'CarDistanceTime.png'])
            close
        end

        function plot_SpeedTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Speed*3.6)
            xlabel('Time')
            ylabel('Speed (km.h)')
            title('Car')
            if savef
                savefig([obj.OutputFolder '\\' 'CarSpeedTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'CarSpeedTime.png'])
            close
        end

        function plot_AccelerationTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.Acceleration)
            xlabel('Time')
            ylabel('Acceleration (m/s2)')
            title('Car')
            if savef
                savefig([obj.OutputFolder '\\' 'CarAccelerationTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'CarAccelerationTime.png'])
            close
        end

        function plot_Milage(obj,savef)
            figure()
            plot(obj.TimeEllapsed, obj.InstantaneousMilage)
            xlabel('Time')
            ylabel('Milage km/kwh')
            title('Instantaneous Milage')
            hold on 
            plot(obj.TimeEllapsed, obj.AverageMilage)
            legend('InstantaneousMilage','Average Milage')
            if savef
                savefig([obj.OutputFolder '\\' 'CarMilage.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'CarMilage.png'])
            close
        end

        function plot_Drag(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.AirDrag)
            hold on
            plot(obj.TimeEllapsed,ones(size(obj.TimeEllapsed))*obj.BearingDrag)
            plot(obj.TimeEllapsed,ones(size(obj.TimeEllapsed))*obj.TireDrag)
            xlabel('Time (S)')
            ylabel('Drag (N)')
            title('Drag Forces')
            legend('AirDrag','BearingDrag','TireDrag')
            if savef
                savefig([obj.OutputFolder '\\' 'CarDrag.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'CarDrag.png'])
            close
        end
    end
end