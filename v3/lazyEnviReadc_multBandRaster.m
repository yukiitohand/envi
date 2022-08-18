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
        sample_offset = c(1)-1; samplesc = c(2)-c(1)+1;
        imc = lazyenvireadRect_multBandRaster_mexw(imgpath,hdr,...
            sample_offset,0,0,samplesc,hdr.lines,hdr.bands,varargin{:});
    case 'DIRECT'
        lc = length(c);
        imc = [];
        for ci = 1:lc
            imci = lazyenvireadRect_multBandRaster_mexw(imgpath,hdr,...
                c(ci)-1,0,0,1,hdr.lines,hdr.bands,varargin{:});
            imc = cat(2,imc,imci);
        end
    otherwise
        error('Undefined INDEX_MODE %s',idx_mode);
end
         
% imc = squeeze(imc);

end