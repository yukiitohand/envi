function [ iml ] = lazyEnviReadl( datafile,hdr_info,line)
% [ iml ] = lazyEnviReadl( datafile,info,line )
% read one line of hyperspectral data.
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       line: line to be read
%   Outputs:
%       iml: the line image of the hyperspectral data at bth band 
%                [bands x samples]

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

iml = zeros([bands,samples],typeName);
if strcmp(interleave,'bil') % BIL type: sample -> band -> line
    offset = s*(samples*bands*(line-1))+header_offset;
    fseek(fid, offset, -1);
    iml = fread(fid,samples*bands,typeName,0,machine);
    iml = reshape(iml,[samples,bands])';
    if data_type==12
        iml = uint16(iml);
    elseif data_type==2
        iml = int16(iml);
    end
elseif strcmp(interleave,'bsq') % sample -> line -> band
    offset = s*(samples*(line-1));
    skips = s*samples*(line-1);
    fseek(fid, offset, -1);
    for b=1:bands
        iml(b,:) = fread(fid,samples,typeName,0,machine);
        fseek(fid,skips,0);
    end
end

fclose(fid);

end
    


