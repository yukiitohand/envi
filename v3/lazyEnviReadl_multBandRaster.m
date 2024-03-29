function [ iml ] = lazyEnviReadl_multBandRaster( imgpath,hdr,l,varargin)
% [ iml ] = lazyEnviReadl_multBandRaster( imgpath,hdr,l,varargin)
% read data from the specific line(s).
%  [ iml ] = lazyEnviReadl_multBandRaster(imgpath,hdr,l,...);
%  [ iml ] = lazyEnviReadl_multBandRaster(imgpath,hdr,l,idx_mode,...);
%  *INPUTS*
%    imgpath: file path to the image file
%    hdr: ENVI header struct
%    l: line(s) to be read
%    idx_mode: {'Direct','Range'} (default) 'Direct'
%  *OUTPUTS*
%    iml: line image(s) [ x sample x bands]
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
        if length(l)~=2
            error('Input l needs to be a two length vector with "Range" mode');
        end
        if l(1)>l(2)
            error('l(1) needs to be smaller than l(2)');
        end
        iml = lazyenvireadRect_multBandRaster_mexw(imgpath,hdr,...
            [1,hdr.samples],l,[1,hdr.bands],varargin{:});
    case 'DIRECT'
        if issorted(l)
            lrange = ind2rangelist(l);
            iml = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
                [1 hdr.samples],lrange, [1,hdr.bands], varargin{:});
        else
            [l_sortd,~] = sort(l);
            lrange = ind2rangelist(l_sortd);
            iml = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
                [1 hdr.samples],lrange, [1,hdr.bands], varargin{:});
            indx_out = rangelist2ind(lrange);
            [~,rindx_mapper] = ismember(l,indx_out); % this is to deal with duplications.
            iml = iml(rindx_mapper,:,:);
        end
    otherwise
        error('Undefined INDEX_MODE %s',idx_mode);
end
         
% iml = squeeze(iml);

end