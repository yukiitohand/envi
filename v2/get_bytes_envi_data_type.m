function nbytes = get_bytes_envi_data_type(data_typeid)

switch data_typeid
    case 1  % 8-bit unsigned integer
        nbytes = 1;
    case 2  % 16-bit signed integer
        nbytes = 2;
    case 3  % 32-bit signed integer
        nbytes = 4;
    case 4  % 32-bit single-precision
        nbytes = 4;
    case 5  % 64-bit double-precision floating-point
        nbytes = 8;
    case 6  % Real-imaginary pair of single-precision floating-point
        nbytes = 8;
    case 9  % Real-imaginary pair of double precision floating-point
        nbytes = 16;
    case 12 % Unsigned integer: 16-bit
        nbytes = 2;
    case 13 % Unsigned long integer: 32-bit
        nbytes = 4;
    case 14 % 64-bit long integer (signed)
        nbytes = 8;
    case 15 % 64-bit unsigned long integer (unsigned)
        nbytes = 8;
    otherwise
        error('Invalide data_type %d',data_typeid);
end

end