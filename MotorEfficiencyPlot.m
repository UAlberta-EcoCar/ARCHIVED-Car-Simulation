%this script calculates the efficiency of a motor over it's entire torque speed domain
%it does this by calculating the linear torque speed curve of the motor at an interval of different voltages

clear;

%%** define motor parameters **%%

%MaxVoltage: Either max rated voltage or the highest voltage you expect to use. Unit: Volts
MaxVoltage = 24; 

%Torque Constant: Numerical constant relating motor torque to motor current. Units: Nm/A
TorqueConstant = 38.5/1000;

%TorqueLoss: This term accounts for the frictional loses in the motor. Units: Nm
%It can be calculated from the formula: TorqueLoss = NoLoadCurrent * TorqueConstant
TorqueLoss = 0.236 * TorqueConstant;

%TerminalResistance: The resistance of the wire windings in the motor. Units: ohms
%Can be calculated with formula: TerminalResistance = MaxVoltage / StallTorque;
TerminalResistance = 0.103;

%%** Reassign Vars for doing math **%%
Vmax = MaxVoltage;
kt = TorqueConstant;
kb = kt; %back emf constant
kv = 1/kb; %rad/(V*s)
Tl = TorqueLoss;
R = TerminalResistance;
SpeedMax = kv*Vmax;
Tmax = Vmax/R*kt - Tl;

%%** Settings for calculation **%%
VoltagePoints = 100;
TorquePoints = 100;
%make torque vector with uneven spacing
out = logspace(0, 3, 100);
out = ( (out-min(out(:)))*(Tmax) ) / ( max(out(:))-min(out(:)) );

%%** Main Calculation **%%

c = 1;
Vstart = Tl*R/kt;
for V = linspace(Vstart,Vmax,VoltagePoints)
	for T = out%linspace(0,Tmax,TorquePoints)
		w = (T+Tl-kt/R*V)/(kt*kb)*(-1*R); %angular velocity
		i = (T+Tl)/kt; %current
		Pi = V*i; %power in
		Po = (T-Tl)*w; %power out
        if w>0 %filter values caused by invalid domain (at low voltage/torque motor thinks friction is causing it to go backwards..)
            Efficiency(c,1) = Po/Pi;
            Speed(c,1) = w;
            Torque(c,1) = T;
            Voltage(c,1) = V;
            if Efficiency(c,1) > 0 %filter values caused by invalid domain
                c = c+1;
            end
        end
	end
end

figure
xi = linspace(0,max(Speed),TorquePoints);
yi = out;
[X,Y] = meshgrid(xi,yi);
zi = griddata(Speed,Torque,Efficiency,X,Y);
%zi(zi==max(zi))=1;
h=surf(X,Y,zi);
set(h,'LineStyle','none')
colormap(winter)

% figure
% scatter3(Speed,Torque,Efficiency,20,floor(Efficiency/0.05),'.')
% axis tight;
% xlabel('Speed')
% ylabel('Torque')
% zlabel('Efficiency');

xi = linspace(0,max(Speed),TorquePoints);
yi = out;%linspace(0,Tmax,TorquePoints);
[X,Y] = meshgrid(xi,yi);
zi = griddata(Speed,Torque,Efficiency,X,Y);

%find most efficient torque at each speed
zi(isnan(zi)) = 0;
for i = 1:100
    m =max(zi(:,i)); %x and y for z have switched?
    if ~isnan(m)
        n=find(zi(:,i)==m);
        n = max(n);
        a(i) = yi(n);
    end
end

figure
for i = 1:100
    plot((yi+Tl)/kt,zi(:,i))
    title([ 'Speed = ' num2str(xi(i))])
    xlabel('Current')
    ylabel('Efficiency')
    pause(0.1)
end

s =xi(1:length(a));
i=(a+Tl)/kt;
plot(s*60/2/3.14159,i,'*')
title('Most Efficient Current')
ylabel('Current')
xlabel('Speed')

v = R*i+kb*s;
figure
plot(s*60/2/3.14159,v)
title('Voltage vs Speed')
ylabel('Voltage')
xlabel('Speed')
hold on
v = R*Tl/kt+kb*s;
plot(s*60/2/3.14159,v)
legend('Most Efficient','zero torque','Location','northwest')