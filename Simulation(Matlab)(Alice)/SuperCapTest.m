


%define a constant current draw
draw = 2;

%define integration time
dt = 0.001;

%define total time
t = 30;

%calculate datapoints
dp = t/dt;

supercap = SuperCapacitor_c(t,dt,'.');
supercap.Capacitance = 20;

%start at 35V
supercap.Voltage(1) = 35;
supercap.Charge(1) = supercap.calc_Charge(supercap.Voltage(1));

for n = 2:dp
    supercap.Current(n) = draw;
    supercap.Charge(n) = supercap.DrainCaps(supercap.Charge(n-1),supercap.Current(n),dt);
    supercap.Voltage(n) = supercap.calc_Voltage(supercap.Charge(n));
end

supercap.plot_VoltageTime(0);