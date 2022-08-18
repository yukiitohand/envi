function [machinefmt] = envihdr_get_machinefmt_from_byte_order(byte_order)
% [machinefmt] = envihdr_get_machinefmt_from_byte_order(byte_order)
%  get machine format (an input for fread in MATLAB) from byter order in
%  the ENVI heaer file

switch byte_order
    case {0}
        machinefmt = 'ieee-le';
    case {1}
        machinefmt = 'ieee-be';
    otherwise
        machinefmt = 'n';
end

end