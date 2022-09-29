function [ imc ] = lazyEnviReadc_multBandRaster( imgpath,hdr,c,varargin)
% [ imc ] = lazyEnviReadc_multBandRaster( imgpath,hdr,c,varargin)
% read data from the specific column.
%  [ imc ] = lazyEnviReadc_multBandRaster(imgpath,hdr,c,...);
%  [ imc ] = lazyEnviReadc_multBandRaster(imgpath,hdr,c,idx_mode,...);
%  *INPUTS*
%    imgpath: file path to the image file
%    hdr: ENVI header struct
%    c: column(s) to be read
%    idx_mode: {'Direct','Range'} (default) 'Direct'
%  *OUTPUTS*
%    imc: column image(s) [lines x  x bands]
%  OPTIONAL Parameters
%    same as in lazyenvireadRect_multBandRaster_mexw
%   "PRECISION": char, string; data type of the output image.
%       'raw','double', 'single', 'uint8', 'int16', 'int32','int64'
%       'uint8','uint16','uint32','uint64'
%      if 'raw', the data is returned with the original data type of the
%      image.
%      (default) 'double'
%  "Replace_data_ignore_value": boolean, 
%      whether or not to replace data_ignore_value with NaNs or not.
%      (default) true (for single and double data types)
%                false (for integer types)
%  "RepVal_data_ignore_value": 
%      replaced values for the pixels with data_ignore_value.
%      (default) nan (for double and single precisions). Need to specify 
%                for integer precisions.
% 
% Copyright (C) 2021 Yuki Itoh <yukiitohand@gmail.com>
%

%%
idx_mode = 'Direct';

if (rem(length(varargin),2)==1)
    idx_mode = varargin{1};
    varargin = varargin(2:end);
end

switch upper(idx_mode)
    case 'RANGE'
        if length(c)~=2
            error('Input c needs to be a two length vector with "Range" mode');
        end
        if c(1)>c(2)
            error('c(1) needs to be smaller than c(2)');
        end
        imc = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
            c,[1 hdr.lines],[1 hdr.bands],varargin{:});
    case 'DIRECT'
        if issorted(c)
            crange = ind2rangelist(c);
            imc = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
                crange,[1,hdr.lines], [1 hdr.bands], varargin{:});
        else
            [c_sortd,~] = sort(c);
            crange = ind2rangelist(c_sortd);
            imc = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
                crange,[1,hdr.lines], [1 hdr.bands], varargin{:});
            indx_out = rangelist2ind(crange);
            [~,rindx_mapper] = ismember(c,indx_out); % this is to deal with duplications.
            imc = imc(:,rindx_mapper,:);
        end
        
    otherwise
        error('Undefined INDEX_MODE %s',idx_mode);
end
         
% imc = squeeze(imc);

end