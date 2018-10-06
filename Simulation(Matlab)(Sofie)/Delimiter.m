function [ delimiter ] = Delimiter(  )
%Returns correct folder separation Delimiter for your OS
%returns '\\' for windows and '/' for mac/linux

if ispc()
    delimiter = '\\';
else
    delimiter ='/';
end

end

