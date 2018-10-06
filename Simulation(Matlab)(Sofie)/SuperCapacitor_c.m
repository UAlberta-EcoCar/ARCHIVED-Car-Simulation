classdef SuperCapacitor_c < handle %goofy matlab class inheritance
    %% Class containing model of Super Capacitor %%
    
    properties
        OutputFolder = '';

        %Constants
        Capacitance = 0;

        SimulationTime = 0;
        TimeInterval = 0;
        DataPoints = 0;

        %Variable arrays
        TimeEllapsed = [];
        Charge = [];
        Voltage =[];
        Current = [];
        PowerOut = [];
    end

    methods
        function obj = SuperCapacitor_c(SimulationTime,TimeInterval,OutputFolder)
            %class constructor

            obj.OutputFolder = OutputFolder;

            obj.SimulationTime = SimulationTime;
            obj.TimeInterval = TimeInterval;
            obj.DataPoints = floor(SimulationTime/TimeInterval);         

            %make time array for plotting
            obj.TimeEllapsed = (0:(obj.DataPoints-1))*TimeInterval';

            obj.Charge = zeros(obj.DataPoints,1);
            obj.Voltage = zeros(obj.DataPoints,1);
            obj.Current = zeros(obj.DataPoints,1);
            obj.PowerOut = zeros(obj.DataPoints,1);
        end

        function Charge = DrainCaps(~,CurrentCharge,Current,TimeInterval)
            Charge = CurrentCharge - Current*TimeInterval;
        end

        function Voltage = calc_Voltage(obj,Charge)
            Voltage = Charge / obj.Capacitance;
        end    

        function Charge = calc_Charge(obj,Voltage)
            Charge = Voltage * obj.Capacitance;
        end

        function obj = calc_Current(obj)
            obj.Current(2:end) = -diff(obj.Voltage)*obj.Capacitance./obj.TimeInterval;
        end

        function obj = calc_PowerOut(obj)
            obj.PowerOut = obj.Voltage .* obj.Current;
        end

        %plotting
        function plot_VoltageCharge(obj,savef)
            figure()
            plot(obj.Charge,obj.Voltage)
            ylabel('Voltage')
            xlabel('Charge')
            title('SuperCaps')
            if savef
                savefig([obj.OutputFolder Delimiter() 'SuperCapVoltageCharge.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'SuperCapVoltageCharge.png'])
            close
        end

        function plot_ChargeTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.Charge)
            xlabel('Time')
            ylabel('Charge')
            title('SuperCaps')
            if savef
                savefig([obj.OutputFolder Delimiter() 'SuperCapChargeTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'SuperCapChargeTime.png'])
            close
        end

        function plot_CurrentTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.Current)
            xlabel('Times (S)')
            ylabel('Current (Amps)')
            title('SuperCaps')
            if savef
                savefig([obj.OutputFolder Delimiter() 'SuperCapCurrentTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'SuperCapCurrentTime.png'])
            close
        end
        
        function plot_VoltageTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.Voltage)
            xlabel('Times (S)')
            ylabel('Voltage')
            title('SuperCaps')
            if savef
                savefig([obj.OutputFolder Delimiter() 'SuperCapVoltageTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'SuperCapVoltageTime.png'])
            close
        end

    end
end