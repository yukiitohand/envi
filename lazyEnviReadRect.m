function [ hsi_sub ] = lazyEnviReadRect( datafile,info,upperLeft,lowerRight,band_idxes)
% [ spc ] = lazyEnviReadRect( datafile,info,upperLeft,LowerRight,bands )
% read a subset of hyperspectral data. The spatial subset is defined by the
% samples and the lines and the spectral subset is defined by the bands. 
%   Inputs:
%       datafile: file path to the image file
%       info: info object returned by envihdrread(hdrfile)
%       upperLeft: the coordinate of the vertex at the upper Left of the
%                  rectangle [y_ul,x_ul] 
%                  (Note: y_ul<y_lr and x_ul<x_lr are required)
%       LowerRight: the coordinate of the vertex at the lower Right of the
%                  rectangle [y_lr,x_lr]
%       bands_idxes: list of indices in the spectral direction of the subset
%   Outputs:
%       hsi_sub: the subset of the hyperspectral data 
%                [lines x samples x bands]

%% variable checking
if length(upperLeft)~=2
    error('The size of "upperLeft" is incorrect.\n');
end
if length(lowerRight)~=2
    error('The size of "lowerRight" is incorrect.\n');
end
y_ul = upperLeft(1); x_ul = upperLeft(2);
y_lr = lowerRight(1); x_lr = lowerRight(2);
% [y_ul,x_ul] = reshape(upperLeft,[1,2]); [y_lr,x_lr] = reshape(lowerRight,[1,2]);

interleave = info.interleave;
samples = info.samples;
lines = info.lines;
header_offset = info.header_offset;
bands = info.bands;
data_type = info.data_type;
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
else 
    error('Sorry the specified type is not supproted\n');
end

if y_ul>y_lr
    error('Y region is invalid\n');
end
if x_ul>x_lr
    error('X region is invalid\n');
end

if y_ul<1 || y_ul>lines
    error('UpperLeft is outside of the image\n');
end
if y_lr<1 || y_lr>lines
    error('LowerLeft is outside of the image\n');
end

if x_ul<1 || x_ul>samples
    error('UpperLeft is outside of the image\n');
end
if x_lr<1 || x_lr>samples
    error('LowerLeft is outside of the image\n');
end


if any(band_idxes>bands) || any(band_idxes<1)
    error(' "band_idxes" is invalid\n');
end


nRectx = x_lr-x_ul+1;
nRecty = y_lr-y_ul+1;
nband_selected = length(band_idxes);
fid = fopen(datafile);
hsi_sub = zeros([nRecty,nRectx,bands],typeName);
if strcmp(interleave,'bil') % BIL type: sample -> band -> line
    hsi_sub = zeros([nRecty,nRectx,bands],typeName);
    offset = s*(samples*bands*(y_ul-1)...
                +(x_ul-1));
    skip_samples = s*(samples-nRectx);

    fseek(fid, offset, -1);
    for l=1:nRecty
        for b=1:bands
            hsi_sub(l,:,b) = fread(fid,nRectx,typeName,0);
            fseek(fid,skip_samples,0);
        end
    end
elseif strcmp(interleave,'bsq') % sample -> line -> band
    hsi_sub = zeros([nRecty,nRectx,bands],typeName);
    offset = s*(x_ul-1)+s*(y_ul-1)*samples;
    skip_samples = s*(samples-nRectx);
    skip_ls = s*(lines*samples-samples*nRecty);
    fseek(fid, offset, -1);
    for b = 1:bands
        for l=1:nRecty
            hsi_sub(l,:,b) = fread(fid,nRectx,typeName);
            fseek(fid,skip_samples,0);
        end
        fseek(fid, skip_ls, 0);
    end
end
% take spectral subset
hsi_sub = hsi_sub(:,:,band_idxes);
fclose(fid);
end
    


