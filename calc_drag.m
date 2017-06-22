function Drag = calc_drag(Speed)

Mass = 170;
BearingDragCoefficient = 0.0015;
BearingBoreDiameter = 0.03;
WheelDiameter = 0.478;

BearingDrag = BearingDragCoefficient*Mass*9.81*BearingBoreDiameter/WheelDiameter;

RollingResistanceCoefficient = 0.00081;

TireDrag = RollingResistanceCoefficient*Mass*9.81;

FrontalArea = 1.1;

AreodynamicDragCoefficient = 0.4;
AirDensity = 1.2;

AirDrag = 0.5*AreodynamicDragCoefficient*FrontalArea*AirDensity*Speed.^2;

Drag = BearingDrag + TireDrag + AirDrag;