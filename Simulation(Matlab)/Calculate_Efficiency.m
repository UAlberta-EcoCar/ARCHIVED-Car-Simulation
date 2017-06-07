function mpge = Calculate_Efficiency( D , C )
%Calculate_Efficiency: takes in distance travelled (D) in meters and energy
%consumed (C) in units of columbs of electricity (Amp-seconds)
%Can also input in rate form ( m/s and Amps ) to get instantaneous
%efficiency

%energy density of hydrogen
DH2 = 33.3; %kwh/kg

%elementary charge
q = 1.6*10^-19; %C

%Avagadros number
NA = 6.02*10^23;

%energy density of gasoline
Dgas = 33.7; %kwh/gallon

%molar mass of hydrogen
MH2 = 2; %g/mol

mpkwh = D./C*q/DH2*NA*2/MH2/1.6;
mpge = mpkwh*Dgas;

end

