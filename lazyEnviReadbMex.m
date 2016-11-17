function [ imb ] = lazyEnviReadbMex( datafile,hdr_info,band)
% [ spc ] = lazyEnviReadbMex( datafile,info,band )
% read a band image of hyperspectral data.
% wrapper to mex functions
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

if ~exist(datafile,'file')
    error('Wrong path, the file does not exist:%s',data_file);
end

if band>bands
    error('The specified band exceed the number of channels.');
end

if data_type==12
    % unsigned int16
    s = 2;
    f = dir(datafile);
    fsize = f.bytes;
    if fsize ~= s*samples*lines*bands;
        error('The combination of the data and header is wrong.');
    end
    imb = lazyEnviReadbMex12Uint16(datafile,hdr_info,band);
elseif data_type==4
    % single
    s = 4;
    f = dir(datafile);
    fsize = f.bytes;
    if fsize ~= s*samples*lines*bands;
        error('The combination of the data and header is wrong.');
    end
    imb = lazyEnviReadbMex04Float(datafile,hdr_info,band);
elseif data_type==5
    % double precision
    s = 8;
    f = dir(datafile);
    fsize = f.bytes;
    if fsize ~= s*samples*lines*bands;
        error('The combination of the data and header is wrong.');
    end
    error('Sorry, double type is not supported yet');
end

% transpose the image
imb = imb.';

end
    


