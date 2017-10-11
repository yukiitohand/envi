function [ spc ] = lazyEnviRead_v2( datafile,hdr_info,s,l)
% [ spc ] = lazyEnviRead( datafile,hdr_info,s,l )
% read one spectrum at specified location [sample, line]
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       s: coordinate in the cross-track direction, integer
%       l: coordinate in the along-track direction
%   Outputs:
%       spc: spectral signature at [sample, line], numerical array with
%       the size bands x 1. 

interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;

if l > lines
    error('The input "l" is out of range.');
end

if s > samples
    error('The input "s" is out of range.');
end

switch hdr_info.byte_order
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

spc = multibandread(datafile, [lines,samples,bands],...
                    precision, header_offset, interleave, byteorder,...
                    {'Row','Direct',l},{'Column','Direct',s});
spc = squeeze(spc);

end
    


