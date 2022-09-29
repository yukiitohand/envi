function [ imb ] = lazyEnviReadb( datafile,hdr_info,band)
% [ spc ] = lazyEnviReadb( datafile,info,band )
% read a band image of hyperspectral data.
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       band: band to be read
%   Outputs:
%       imb: the band image of the hyperspectral data at bth band 
%                [lines x samples]

interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;

switch hdr_info.byte_order
    case {0}
        machine = 'ieee-le';
    case {1}
        machine = 'ieee-be';
    otherwise
        machine = 'n';
end

if data_type==12
    % unsigned int16
    s=2;
    typeName = 'uint16';
elseif data_type==4
    s=4;
    typeName = 'single';
elseif data_type==5
    s=8;
    typeName = 'double';
elseif data_type==2
    s=2;
    typeName = 'int16';
elseif data_type==1
    s=1;
    typeName = 'uint8';
else
    error('Undefined data_type "%d".',data_type);
end

fid = fopen(datafile);

imb = zeros([lines,samples],typeName);
if strcmp(interleave,'bil') % BIL type: sample -> band -> line
    offset = s*(samples*(band-1));
    skips = s*samples*(bands-1);
    fseek(fid, offset, -1);
    for l=1:lines
        imb(l,:) = fread(fid,samples,typeName,0,machine);
        fseek(fid,skips,0);
    end
elseif strcmp(interleave,'bsq') % sample -> line -> band
    offset = s*(samples*lines*(band-1))+header_offset;
    fseek(fid, offset, -1);
    imb = fread(fid,samples*lines,typeName,0,machine);
    imb = reshape(imb,[samples,lines])';
end

fclose(fid);

end
    


