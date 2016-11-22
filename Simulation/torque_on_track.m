function torque_on_track()
%This script finds the torque necessary for EcoCar at different parts of a
%track. Hopefully, in the future, it can be used to help determine optimal
%motor and gear values.

% 2016-11-26 Jason R. Wang
clf;

% Set parameters
global C_d A rho m r
C_d = 0.41; % Drag coefficient [*]
A = 1.08343; % Frontal area [m^2]
rho = 1.225; % Density of air at 101.325 kPa and 15ºC [kg/m^3]
m = 170; % Mass of car [kg]
r = 0.2792; % Radius of car tyres [m]

v = 0:31; % Velocity of vehicle in km/h
grade = (0:5)/100; % Grade of the track

Torque = torque(grade, v);
%plot(v,Torque(:,grade(find(grade == 5))));

figure(1)
hold on
for i = 1:length(grade)
    plot(v,Torque(i,:))
end
xlabel('{\itv}, Speed [km/h]')
ylabel('{\itT}, Torque [Nm]')

end

function T = torque(grade, v)
    
    global C_d A rho m r
    
    % Find the air friction drag and the drag from the hill
    F_D = C_d * A * rho/2 .* (v/3.6).^2;
    F_g_parallel = m * 9.81 * sin(atan(grade));
    
    % From a free body diagram, it can be seen that to maintain velocity,
    % the force of friction moving the car up the hill must be equal to the
    % sum of the forces resisting that motion.
    F_f = zeros(length(grade),length(v));
    for i = 1:length(grade)
        for j = 1:length(v)
            F_f(i,j) = F_D(j) + F_g_parallel(i);
        end
    end
    
    % The torque required for that motion is then easily captured as the
    % required force multiplied by the radius of the wheel.
    T = F_f .* r;
    
end