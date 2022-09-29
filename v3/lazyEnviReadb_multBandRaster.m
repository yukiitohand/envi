function [ imb ] = lazyEnviReadb_multBandRaster( imgpath,hdr,b,varargin)
% [ imb ] = lazyEnviReadb_multBandRaster( imgpath,hdr,b,varargin)
% read a band image of hyperspectral data.
%  [ imb ] = lazyEnviReadb_multBandRaster(imgpath,hdr,b,...);
%  [ imb ] = lazyEnviReadb_multBandRaster(imgpath,hdr,b,idx_mode,...);
%  *INPUTS*
%    imgpath: file path to the image file
%    hdr: ENVI header struct
%    b: band(s) to be read
%    idx_mode: {'Direct','Range'} (default) 'Direct'
%  *OUTPUTS*
%    imb: band image(s) [lines x samples x ]
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
        imb = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
            [1 hdr.samples],[1,hdr.lines], b, varargin{:});
    case 'DIRECT'
        brange = ind2rangelist(b);
        imb = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
            [1 hdr.samples],[1,hdr.lines], brange, varargin{:});
%         
%         lb = length(b);
%         imb = [];
%         for bi = 1:lb
%             imbi = lazyenvireadRect_multBandRaster_mexw(...
%                 imgpath,hdr,...
%                 0,0,b(bi)-1,hdr.samples,hdr.lines,1,varargin{:});
%             imb = cat(3,imb,imbi);
%         end
    otherwise
        error('Undefined INDEX_MODE %s',idx_mode);
end
         
imb = squeeze(imb);

end
    


