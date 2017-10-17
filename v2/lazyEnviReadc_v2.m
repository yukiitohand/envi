function [ imc ] = lazyEnviReadc_v2( datafile,hdr_info,c)
% [ imc ] = lazyEnviReadc( datafile,hdr_info,c )
% read an image of hyperspectral data at a specific column.
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       c: column to be read
%   Outputs:
%       imc: the image of the hyperspectral data at c-th column
%                [lines x bands]

interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;
byte_order = hdr_info.byte_order;

if c > samples
    error('The input "c" is out of range.');
end

switch byte_order
    case {0}
        byteorder = 'ieee-le';
    case {1}
        byteorder = 'ieee-be';
    otherwise
        byteorder = 'n';
end

iscx = false;
switch data_type
    case {1}
        precision = 'uint8';
    case {2}
        precision= 'int16';
    case{3}
        precision= 'int32';
    case {4}
        precision= 'single';
    case {5}
        precision= 'double';
    case {6}
        iscx=true;
        precision= 'single';
    case {9}
        iscx=true;
        precision= 'double';
    case {12}
        precision= 'uint16';
    case {13}
        precision= 'uint32';
    case {14}
        precision= 'int64';
    case {15}
        precision= 'uint64';
    otherwise
        error('Undefined data_type "%d".',data_type);
end


imc = multibandread(datafile, [lines,samples,bands],...
                    precision, header_offset, interleave, byteorder,...
                    {'Column','Direct',c});
                
imc = squeeze(imc);

end
    


