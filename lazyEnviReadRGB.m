function [ imrgb ] = lazyEnviReadRGB( datafile,hdr_info,rgb)
% [ spc ] = lazyEnviReadb( datafile,info,band )
% read a band image of hyperspectral data.
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       rgb: RGB bands to be read [R,G,B]
%   Outputs:
%       imrgb: the rgb image of the hyperspectral data at bth band 
%                [lines x samples x 3]

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
end

imrgb = zeros([lines,samples,3],typeName);

for bidx=1:3
    imrgb(:,:,bidx) = lazyEnviReadb(datafile,hdr_info,rgb(bidx));
end

end
    


