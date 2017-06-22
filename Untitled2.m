
dt = 0.05;
f = 55:257;
t=zeros(size(f));
for i = 1:length(f)
    Speed = 0;
    while(Speed < (50/3.6))
        fnet = f(i) - calc_drag(Speed);
        a = fnet/170;
        Speed = Speed + a*dt;
        t(i) = t(i) + dt;
        disp(Speed)
        if Speed < 0
            break
        end
    end
end
plot(f,t)
xlabel('Force')
ylabel('Time to 50 km/hr')