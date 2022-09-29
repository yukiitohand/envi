function [ spc ] = lazyEnviRead( datafile,hdr_info,sample,line )
% [ spc ] = lazyEnviRead( datafile,info,sample,line )
% read one spectrum at specified location [sample, line]
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       sample: coordinate in the cross-track direction, integer
%       line: coordinate in the along-track direction
%   Outputs:
%       spc: spectral signature at [sample, line], numerical array with
%       the size bands x 1. 

interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;
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

switch hdr_info.byte_order
    case {0}
        machine = 'ieee-le';
    case {1}
        machine = 'ieee-be';
    otherwise
        machine = 'n';
end

fid = fopen(datafile);

if strcmp(interleave,'bil')
    spc = zeros(bands,1);
    offset = s*(samples*(line-1)*bands+(sample-1));
    skip = s*(samples-1);
    fseek(fid, offset, -1);
    for b = 1:bands
        spctmp = fread(fid,1,typeName,skip,machine);
        spc(b) = spctmp;
    end
elseif strcmp(interleave,'bsq')
    spc = zeros(bands,1);
    skip = s*(lines*samples-1);
    offset = s*(sample-1)+s*(line-1)*samples;
    fseek(fid, offset, -1);
    for b = 1:bands
        spctmp = fread(fid,1,typeName,skip,machine);
        spc(b) = spctmp;
    end
end

fclose(fid);

end

