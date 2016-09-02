classdef FuelCell_c < handle %goofy matlab class inheritance
    %% Class Constaining Model of FuelCell %%
    
    properties
        OutputFolder = '';

        %Constants
        CellNumber = 0;
        CellArea = 0;
        CellResistance = 0;
        Alpha = 0;
        ExchangeCurrentDensity = 0;
        CellOCVoltage = 0;
        DiodeVoltageDrop = 0;
        TheoreticalCellVoltage = 1.48;

        Faraday = 96485; %Faraday C/mol
        RealGas = 8.314462; %J/molK

        AuxCurrent = 0;
        StackTemperature = 300;

        %Variable Arrays
        StackVoltage = '';
        StackCurrent = '';
        StackEfficiency = '';
        StackPowerOut = '';
        StackEnergyProduced = '';
        StackEnergyConsumed = '';

        CurveI = [];
        CurveV = [];

        DataPoints = '';
        SimulationTime = '';
        TimeInterval = '';
        TimeEllapsed = '';
    end
    
    methods
        function obj = FuelCell_c(SimulationTime,TimeInterval,OutputFolder)
            %class constructor
            obj.OutputFolder = OutputFolder;        

            obj.SimulationTime = SimulationTime;
            obj.TimeInterval = TimeInterval;

            obj.DataPoints = floor(SimulationTime/TimeInterval);
            obj.TimeEllapsed = (1:obj.DataPoints)*TimeInterval';

            obj.StackVoltage = zeros(obj.DataPoints,1);
            obj.StackCurrent = zeros(obj.DataPoints,1);
            obj.StackEfficiency = zeros(obj.DataPoints,1);
            obj.StackPowerOut = zeros(obj.DataPoints,1);     
            obj.StackEnergyProduced = zeros(obj.DataPoints,1);
            obj.StackEnergyConsumed = zeros(obj.DataPoints,1);

            obj.CurveI = (0:0.1:120)';
            obj.CurveV = zeros(size(obj.CurveI));
        end

        function obj = build_VoltageCurrentCurve(obj)
            A = obj.RealGas * obj.StackTemperature / 2 / obj.Alpha / obj.Faraday;

            for i = 1:size(obj.CurveV,1)
                current = obj.CurveI(i);
                b = current / ( obj.CellArea * obj.ExchangeCurrentDensity / 1000);
                if b > 0
                    c = A*log(b);
                    if c > 0
                        obj.CurveV(i) = obj.CellNumber * (obj.CellOCVoltage - current*obj.CellResistance/obj.CellArea - A*log(b));
                    else
                        obj.CurveV(i) = obj.CellNumber * (obj.CellOCVoltage - current*obj.CellResistance/obj.CellArea - 0 );
                    end
                else
                    obj.CurveV(i) = obj.CellNumber * (obj.CellOCVoltage - current*obj.CellResistance/obj.CellArea - 0);
                end
            end
        end

        function Current = calc_StackCurrent(obj,Voltage)
            %calculate available current at specified voltage
            index = find(obj.CurveV < Voltage,1);
            %interpolation
            V1 = obj.CurveV(index);
            V2 = obj.CurveV(index+1);

            I1 = obj.CurveI(index);
            I2 = obj.CurveI(index+1);

            Current = I1 + (I2-I1)/(V2-V1)*(Voltage-V1);

            if Current < 0
                Current = 0;
            end
            if Current > 120
                disp('Warning: FuelCell Current Outside of Interpolation Range')
            end       
        end


        function [Voltage] = calc_StackVoltage(obj,Current)
            %calculates stack voltage based off of current draw

            A = obj.RealGas * obj.StackTemperature / 2 / obj.Alpha / obj.Faraday;

            b = Current / ( obj.CellArea * obj.ExchangeCurrentDensity / 1000);
            if b > 0
                Voltage = obj.CellNumber * (obj.CellOCVoltage - Current*obj.CellResistance/obj.CellArea - A*log(b));
            else
                Voltage = obj.CellNumber * (obj.CellOCVoltage - Current*obj.CellResistance/obj.CellArea);   
            end
        end    

        function obj = calc_StackEfficiency(obj)
            obj.StackEfficiency = obj.StackVoltage / obj.CellNumber / obj.TheoreticalCellVoltage;
        end        

        function obj = calc_StackPowerOut(obj)
            obj.StackPowerOut = obj.StackVoltage .* obj.StackCurrent;
        end    

        function [StackEnergyProduced] = calc_StackEnergyProduced(~,Voltage,Current,Time)
            StackEnergyProduced = Voltage*Current*Time;
        end

        function [StackEnergyConsumed] = calc_StackEnergyConsumed(obj,Current,Time)
            StackEnergyConsumed = obj.TheoreticalCellVoltage*obj.CellNumber*Current*Time;
        end

        %Plotting
        function plot_FCCurve(obj,savef)
            figure()
            plot( obj.CurveI, obj.CurveV )
            xlabel('Stack Current')
            ylabel('Stack Voltage')
            title('Fuel Cell curve')
            if savef
                savefig([obj.OutputFolder '\\' 'FuelcellVoltageCurrentCurve.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'FuelcellVoltageCurrentCurve.png'])
            close
        end

        function plot_StackVoltageCurrent(obj,savef)
            figure()
            plot( obj.StackCurrent, obj.StackVoltage )
            xlabel('Stack Current (A)')
            ylabel('Stack Voltage (V)')
            title('FuelCell')
            if savef
                savefig([obj.OutputFolder '\\' 'FuelcellVoltageCurrent.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'FuelcellVoltageCurrent.png'])
            close
        end

        function plot_StackEfficiency(obj,savef)
            figure()
            plot( obj.TimeEllapsed , obj.StackEfficiency )    
            xlabel('Time (s)')
            ylabel('Stack Efficiency')
            title('FuelCell')
            if savef
                savefig([obj.OutputFolder '\\' 'FuelcellEfficiency.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'FuelcellEfficiency.png'])
            close
        end

        function plot_StackCurrentTime(obj,savef)
            figure()
            plot(obj.TimeEllapsed,obj.StackCurrent)
            xlabel('Time')
            ylabel('Stack Current')
            title('Fuel Cell')
            if savef
                savefig([obj.OutputFolder '\\' 'FuelcellStackCurrentTime.fig'])
            end
            saveas(gcf,[obj.OutputFolder '\\' 'FuelcellStackCurrentTime.png'])
            close
        end
    end
end