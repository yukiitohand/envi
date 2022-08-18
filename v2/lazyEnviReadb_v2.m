function [ imb ] = lazyEnviReadb_v2( datafile,hdr_info,b)
% [ imb ] = lazyEnviReadb( datafile,hdr_info,b )
% read a band image of hyperspectral data.
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       b: band to be read
%   Outputs:
%       imb: the band image of the hyperspectral data at bth band 
%                [lines x samples]

interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;

if b > bands
    error('The input "b" is out of range.');
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

imb = multibandread(datafile, [lines,samples,bands],...
                    precision, header_offset, interleave, byteorder,...
                    {'Band','Direct',b});
imb = squeeze(imb);

end
    


