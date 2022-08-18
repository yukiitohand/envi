function [data_type] = envihdr_get_data_type_from_precision(precision,varargin)
% [data_type] = envihdr_get_data_type_from_precision(precision)
% [data_type] = envihdr_get_data_type_from_precision(precision,iscx)
%  get data type for the ENVI heaer file from the input precision
%  A new number 0 is added for supporting int8 type data (this is not 
%  originally supported in ENVI)
%  Usage
%  >> [data_type] = envihdr_get_data_type_from_precision(precision)
%    
%  >> [data_type] = envihdr_get_data_type_from_precision(precision,iscx)


p = inputParser;
p.FunctionName = 'envihdr_get_data_type_from_precision';
addRequired(p,'precision', ...
    @(x) any(validatestring(x, ...
        {'int8','int16','int32','int64','uint8', ...
         'uint16','uint32','uint64','single','double'} ...
         )) );
addOptional(p,'iscx',false,@(x) islogical(x)); % is_complex
parse(p,precision,varargin{:});

precision = p.Results.precision;
iscx = p.Results.iscx;

switch lower(precision)
    case {'int8'}
        data_type = 0;
    case {'uint8'}
        data_type = 1;
    case {'int16'}
        data_type = 2;
    case{'int32'}
        data_type = 3;
    case {'single'}
        if iscx
            data_type = 6;
        else
            data_type = 4;
        end
    case {'double'}
        if iscx
            data_type = 9;
        else
            data_type = 5;
        end
    case {'uint16'}
        data_type = 12;
    case {'uint32'}
        data_type = 13;
    case {'int64'}
        data_type = 14;
    case {'uint64'}
        data_type = 15;
    otherwise
        error('Undefined precision "%s".',precision);
end

end