classdef ExcelWriter < handle
    %ExcelWriter creates a summary excel report containing results of
    %simulation
    properties
        ExcelFile = '';
        
        %row number
        r = 1;
        
        %data cell array
        D = {};
        
        %column descriptions
        cd = {'Motor' , ...
              'FuelCell' , ...
              'Gear Ratio', ...
              'Top Speed km/h', ...
              'Average Speed km/h', ...
              '0 to 25km/hr time', ...
              'Max Efficiency km/kwh', ...
              'Average Efficiency km/kwh', ...
              'Distance Travelled', ...
              };
    end
    
    methods
        function obj = ExcelWriter(ExcelFile)
            obj.ExcelFile = ExcelFile;
            obj.WriteLine(obj.cd);
        end
        
        %write a cell array vector as the next line in excel file
        function obj = WriteLine(obj,columnvalues)
            %make into a row vector if it isn'r already
            if size(columnvalues,1) > size(columnvalues,2)
                columnvalues = columnvalues';
            end
            %make sure its a vector not a matrix
            if size(columnvalues,1) ~= 1
                disp('Error: Input is not a vector')
            else
                %update data matrix
                obj.D(obj.r,:) = columnvalues;
                obj.r = obj.r+1;
            end
        end
        
        %write cell array matrix to actual excel file
        function obj = SaveToFile(obj)
            xlswrite(obj.ExcelFile,obj.D);
        end
    end
end

