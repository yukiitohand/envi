function [subimg] = lazyenvireadRectxv2_multBandRaster_mexw(imgpath,hdr,...
   sample_rangelist,line_rangelist,band_rangelist,varargin)
% [subimg] = lazyenvireadRectx_multBandRaster_mexw(imgpath,hdr,...
%    sample_rangelist,line_rangelist,band_rangelist,varargin)
%   read a rectangular part of multi-band raster image. Image needs to
%   be stored non-compressiond binary format. 
% INPUTS
%   imgpath: path to the image file
%   hdr : ENVI header struct
%   sample_rangelist,line_rangelist,band_rangelist: 
%      2-column array, representing the selected ranges of sample, line,
%      band.
% OUTPUTS
%   subimg: array [ x x ]
% 
% OPTIONAL PARAMETERS
%   "PRECISION": char, string; data type of the output image.
%       'raw','double', 'single','int8','int16', 'int32','int64'
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
% Copyright (C) 2022 Yuki Itoh <yukiitohand@gmail.com>
% 



precision  = 'double';
rep_div    = [];
repval_div = [];
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'PRECISION'
                precision = varargin{i+1};
            case 'REPLACE_DATA_IGNORE_VALUE'
                rep_div = varargin{i+1};
            case 'REPVAL_DATA_IGNORE_VALUE'
                repval_div = varargin{i+1};
            otherwise
                error('Unrecognized option: %s',varargin{i});
        end
    end
end

[precision_raw,sz,iscx] = envihdr_get_precision_sizeA_from_data_type(...
    hdr.data_type);

if iscx
    error('Complex numbers are currently not supported.');
end

if strcmpi(precision,'raw')
    precision = precision_raw;
end

switch lower(precision)
    case {'single','double'}
        if isempty(rep_div), rep_div = true; end
        if rep_div && isempty(repval_div), repval_div = nan; end
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
        if isempty(rep_div), rep_div = false; end
        if rep_div && isempty(repval_div)
            fprintf(...
                ['With integer precision, explicitly specify '
                 '"REPVAL_DATA_IGNORE_VALUE"\n']...
              );
            rep_div = false;
        end
    otherwise
        error('Not implemented yet for data_type %s.',precision);
end

dir_info = dir(imgpath);
imgfullpath = fullfile(dir_info.folder,dir_info.name);

%%
[sample_skipszlist,sample_readszlist] = rangelist2skipreadsizelist(sample_rangelist);
[line_skipszlist,line_readszlist] = rangelist2skipreadsizelist(line_rangelist);
[band_skipszlist,band_readszlist] = rangelist2skipreadsizelist(band_rangelist);

%%
if ispc()
else
    if verLessThan('matlab','9.4')
        need_permute = true;
        switch hdr.data_type
            case {1 2 4 12 16} % uint8 int16 single (float 32bit) uint16 int8
                [subimg] = lazyenvireadRectxv2_multBandRaster_mex(...
                    imgfullpath,hdr,sample_skipszlist,sample_readszlist, ...
                    line_skipszlist,line_readszlist, ...
                    band_skipszlist,band_readszlist);
            otherwise
                fprintf('Mex not implemented yet for data_type %d.\n',hdr.data_type);
                % sindxes = 
                % lindxes = ;
                % bindxes = ;
    %             switch hdr.byte_order
    %                 case {0}
    %                     byte_order = 'ieee-le';
    %                 case {1}
    %                     byte_order = 'ieee-be';
    %                 otherwise
    %                     byte_order = 'n';
    %             end
    %             subimg = multibandread(imgfullpath, ...
    %                 [hdr.lines,hdr.samples,hdr.bands],...
    %                 [precision_raw '=>' precision_raw],...
    %                 hdr.header_offset,hdr.interleave, byte_order,...
    %                 {'Row','Direct',lrange},{'Column','Direct',srange},...
    %                 {'Band','Direct',brange});
    %             need_permute = false;
        end
    else
        need_permute = true;
        switch hdr.data_type
            case {1 2 4 12 16} % uint8 int16 single (float 32bit) uint16 int8
                [subimg] = lazyenvireadRectxv2_multBandRaster_mex(...
                    imgfullpath,hdr,sample_skipszlist,sample_readszlist, ...
                    line_skipszlist,line_readszlist, ...
                    band_skipszlist,band_readszlist);
            otherwise
                fprintf('Mex not implemented yet for data_type %d.\n',hdr.data_type);
                % sindxes = 
                % lindxes = ;
                % bindxes = ;
    %             switch hdr.byte_order
    %                 case {0}
    %                     byte_order = 'ieee-le';
    %                 case {1}
    %                     byte_order = 'ieee-be';
    %                 otherwise
    %                     byte_order = 'n';
    %             end
    %             subimg = multibandread(imgfullpath, ...
    %                 [hdr.lines,hdr.samples,hdr.bands],...
    %                 [precision_raw '=>' precision_raw],...
    %                 hdr.header_offset,hdr.interleave, byte_order,...
    %                 {'Row','Direct',lrange},{'Column','Direct',srange},...
    %                 {'Band','Direct',brange});
    %             need_permute = false;
        end
    
    end
    
    % permute the image based on interleave option.
    if need_permute
        switch lower(hdr.interleave)
            case {'bsq'}
                % subimg = reshape(subimg,[samplesc,linesc,bandsc]);
                subimg = permute(subimg,[2,1,3]);
            case {'bil'}
                % subimg = reshape(subimg,[samplesc,bandsc,linesc]);
                subimg = permute(subimg,[3,1,2]);
            case {'bip'}
                % subimg = reshape(subimg,[bandsc,samplesc,linesc]);
                subimg = permute(subimg,[3,2,1]);
        end
    end
end

switch lower(precision)
    case 'double'
        subimg = double(subimg);
    case 'single'
        subimg = single(subimg);
    case 'int8'
        subimg = int8(subimg);
    case 'int16'
        subimg = int16(subimg);
    case 'int32'
        subimg = int32(subimg);
    case 'int64'
        subimg = int64(subimg);
    case 'uint8'
        subimg = uint8(subimg);
    case 'uint16'
        subimg = uint16(subimg);
    case 'uint32'
        subimg = uint32(subimg);
    case 'uint64'
        subimg = uint64(subimg);
    case 'raw'
        % not changing data_type
    otherwise
        error('Undefined precision %d',precision);
end

if rep_div && isfield(hdr,'data_ignore_value')
    div = cast(hdr.data_ignore_value,class(subimg));
    repval_div = cast(repval_div,class(subimg));
    subimg(subimg==div) = repval_div;
end


end