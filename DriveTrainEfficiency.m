function E = DriveTrainEfficiency(Voltage,Speed,GearRatio)
%calculates efficiency of drive train for given inputs

%motor parameters
Vmax = 24;
kt = 38.5/1000;
kb = kt;
kv=1/kb;
Tl = 0.236*kt;
R=0.103;

%car parameters
GearEfficiency = 0.9;
m = 115;
WheelDiameter = 0.478;
Cb = 0.0015; %wheel bearing drag
BearingBore = 0.03;
BearingDrag = Cb*Mass*9.81*BearingBore/WheelDiameter;

Crr = 0.09; %rolling resistance coefficient
TireDrag =  = Crr*Mass*9.81;