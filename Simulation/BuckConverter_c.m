classdef BuckConverter_c < handle %goofy matlab class inheritance
    %Class definition for Motor Controller/Buck Converter
    %math made very simple I hope it is accurate
    
    properties

        OutputFolder = '';

        DataPoints = 0;
        TimeInterval = 0;
        SimulationTime = 0;
        TimeEllapsed = [];

        
        %efficiency of converter
        Efficiency = 0;
        
        % Variable Arrays
        VoltageIn = [];
        VoltageOut = [];
        CurrentIn = [];
        CurrentOut = [];
        
    end
    
    methods
        function obj = BuckConverter_c(SimulationTime,TimeInterval,OutputFolder)
            %class constructor
            
            obj.OutputFolder = OutputFolder;

            obj.SimulationTime = SimulationTime;
            obj.TimeInterval = TimeInterval;
            obj.DataPoints = floor(SimulationTime/TimeInterval);      
            %make time array for plotting
            obj.TimeEllapsed = (0:(obj.DataPoints-1))*TimeInterval';
            
            obj.VoltageIn = zeros(obj.DataPoints,1);
            obj.VoltageOut = zeros(obj.DataPoints,1);
            obj.CurrentIn = zeros(obj.DataPoints,1);
            obj.CurrentOut = zeros(obj.DataPoints,1);

        end
        
        function VoltageOut = calc_VoltageOut(obj,VoltageIn,Throttle)
            VoltageOut = VoltageIn / 100 * Throttle;
        end
        
        function CurrentIn = calc_CurrentIn(obj,CurrentOut,Throttle)
            CurrentIn = CurrentOut*Throttle/100/obj.Efficiency;
        end
        
        function plot_VoltageCurrentTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.VoltageIn)
            hold on
            plot(obj.TimeEllapsed,obj.VoltageOut)
            plot(obj.TimeEllapsed,obj.CurrentIn)
            plot(obj.TimeEllapsed,obj.CurrentOut)
            xlabel('Time (s)')
            ylabel('Voltage (V) or Current(Amps)')
            title('BuckConverter')
            legend('VoltageIn','VoltageOut','CurrentIn','CurrentOut')
            if savef
                savefig([obj.OutputFolder Delimiter() 'BuckConverter.fig'])
            end
            saveas(gcf,[obj.OutputFolder Delimiter() 'BuckConverter.png'])
            close
        end
    end
end