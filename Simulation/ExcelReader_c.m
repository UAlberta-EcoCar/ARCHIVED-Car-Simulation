classdef ExcelReader_c < handle
    
    properties
        MotorFile = ''
        FuelCellFile = ''
        
        motor = ''
        NumberMotors = 0;
    end
    
    methods
        function obj = ExcelReader_c()
            %empty class constructor
        end
        
        function obj = ParseMotorFile(obj,MotorFile)
            obj.MotorFile = MotorFile;
            [ ~, ~, M ] = xlsread(MotorFile);
            for n = 2:size(M,1)
                %name
                if ~strcmp(obj.read_entry(M,n,1),'')
                    obj.motor(n-1).name = obj.read_entry(M,n,1) ;
                else
                    obj.NumberMotors = n-2;
                    break;
                end
                %manufacturer
                if ~strcmp(obj.read_entry(M,n,2),'')
                    obj.motor(n-1).name = [ obj.read_entry(M,n,2) obj.motor(n-1).name ] ;
                end
                %max voltage
                obj.motor(n-1).MaxVoltage = obj.read_entry(M,n,5);
                %max speed
                obj.motor(n-1).MaxSpeed = obj.read_entry(M,n,6);
                %resistance
                obj.motor(n-1).WindingResistance = obj.read_entry(M,n,10);
                %torque constant
                obj.motor(n-1).TorqueConstant = obj.read_entry(M,n,11);
                %speed constant
                obj.motor(n-1).SpeedConstant = obj.read_entry(M,n,12);
                obj.NumberMotors = n-1;
            end
        end
        
        function v = read_entry(~,A,r,c)
            switch(c)
                %motor num/name
                case 1
                    if ischar(A{r,c})
                        v = A{r,c};
                    elseif isnan(A{r,c})
                        v = '';
                    else
                        v = num2str(A{r,c});
                    end
                    
                %motor manufacturor
                case 2
                    if ischar(A{r,c})
                        v = A{r,c};
                    elseif isnan(A{r,c})
                        v = '';
                    end
                    
                case {5 , 6, 7, 8, 9, 10, 11, 12, 13}
                    if ~ischar(A{r,c}) && ~isnan(A{r,c})
                        v = A{r,c};
                    elseif isnan(A{r,c})
                        v = 0;
                    else
                        v = 0;
                    end
            end
        end
    end
end

