function [precision,sizeA,iscx] = envihdr_get_precision_sizeA_from_data_type(data_type)
% [precision,sizeA,iscx] = envihdr_get_precision_sizeA_from_data_type(data_type_id)
%  get precision and sizeA (inputs for fread in MATLAB) from data type in
%  the ENVI heaer file
%  A new number 0 is added for supporting int8 type data (this is not 
%  originally supported in ENVI)

iscx = false;
switch data_type
    case {0}
        sizeA = 1;
        precision= 'int8';
    case {1}
        sizeA = 1;
        precision = 'uint8';
    case {2}
        sizeA = 2;
        precision= 'int16';
    case{3}
        sizeA = 4;
        precision= 'int32';
    case {4}
        sizeA = 4;
        precision= 'single';
    case {5}
        sizeA = 8;
        precision= 'double';
    case {6}
        iscx=true;
        precision= 'single';
    case {9}
        iscx=true;
        precision= 'double';
    case {12}
        sizeA = 2;
        precision= 'uint16';
    case {13}
        sizeA = 4;
        precision= 'uint32';
    case {14}
        sizeA = 8;
        precision= 'int64';
    case {15}
        sizeA = 8;
        precision= 'uint64';
    otherwise
        error('Undefined data_type "%d".',data_type);
end

end