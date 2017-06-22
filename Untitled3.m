
d = 0;
v = 0;
a = 0;
t = 0;
f = 0;
dt=0.05;
drag = calc_drag(0);
P = 1300;

for i = 2:2000
    drag(i) = calc_drag(v(i-1));
    f(i) = min(1000/v(i-1),200);
    a(i) = f(i)/170 - drag(i-1)/170;
    v(i) = v(i-1) + a(i-1)*dt;
    d(i) = d(i-1) + v(i-1)*dt;
    t(i) = t(i-1)+dt;
end

figure
plot(t,v*3.6)
figure
plot(t,f)
figure
plot(v,a)
figure
plot(t,a)