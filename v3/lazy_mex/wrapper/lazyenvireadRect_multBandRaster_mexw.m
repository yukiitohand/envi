function [subimg] = lazyenvireadRect_multBandRaster_mexw(imgpath,hdr,...
   sample_offset,line_offset,band_offset,samplesc,linesc,bandsc,varargin)
% [subimg] = lazyenvireadRect_multBandRaster_mexw(imgpath,hdr,...
%    sample_offset,line_offset,band_offset,samplesc,linesc,bands,varargin)
%   read a rectangular part of multi-band raster image. Image needs to
%   be stored non-compressiond binary format. 
% INPUTS
%   imgpath: path to the image file
%   hdr : ENVI header struct
%   sample_offset, line_offset,band_offset: samples, lines, and band
%           to be offset
%   samplesc, linesc, bandsc,: size of the rectangle
% OUTPUTS
%   subimg: array [linesc x samplesc x bandsc]
% 
% OPTIONAL PARAMETERS
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
    case {'uint8','uint16','uint32','uint64','int16','int32','int64'}
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

%%
if verLessThan('matlab','9.4') || ispc()
    % For the version older than , use multibandread always
    srange = [sample_offset+1 sample_offset+samplesc];
    lrange = [line_offset+1 line_offset+linesc];
    brange = [band_offset+1 band_offset+bandsc];
    switch hdr.byte_order
        case {0}
            byte_order = 'ieee-le';
        case {1}
            byte_order = 'ieee-be';
        otherwise
            byte_order = 'n';
    end
    subimg = multibandread(imgpath, ...
        [hdr.lines,hdr.samples,hdr.bands],...
        [precision_raw '=>' precision_raw],...
        hdr.header_offset,hdr.interleave, byte_order,...
        {'Row','Range',lrange},{'Column','Range',srange},...
        {'Band','Range',brange});
    need_permute = false;
else
    
    need_permute = true;
    switch hdr.data_type
        case 1 % uint8
            % there is no need for dealing with the endian for uint8
            [subimg] = lazyenvireadRect_multBandRasterUint8_mex(...
                imgpath,hdr,sample_offset,line_offset,band_offset,...
                samplesc,linesc,bandsc);
        case 2 % int16
            [subimg] = lazyenvireadRect_multBandRasterInt16_mex(...
                imgpath,hdr,sample_offset,line_offset,band_offset,...
                samplesc,linesc,bandsc);
        case 4 % single (float 32bit)
            [subimg] = lazyenvireadRect_multBandRasterSingle_mex(...
                imgpath,hdr,sample_offset,line_offset,band_offset,...
                samplesc,linesc,bandsc);
        case 12 % uint16
            [subimg] = lazyenvireadRect_multBandRasterUint16_mex(...
                imgpath,hdr,sample_offset,line_offset,band_offset,...
                samplesc,linesc,bandsc);
        otherwise
            % fprintf('Mex not implemented yet for data_type %d.\n',hdr.data_type);
            srange = [sample_offset+1 sample_offset+samplesc];
            lrange = [line_offset+1 line_offset+linesc];
            brange = [band_offset+1 band_offset+bandsc];
            switch hdr.byte_order
                case {0}
                    byte_order = 'ieee-le';
                case {1}
                    byte_order = 'ieee-be';
                otherwise
                    byte_order = 'n';
            end
            subimg = multibandread(imgpath, ...
                [hdr.lines,hdr.samples,hdr.bands],...
                [precision_raw '=>' precision_raw],...
                hdr.header_offset,hdr.interleave, byte_order,...
                {'Row','Range',lrange},{'Column','Range',srange},...
                {'Band','Range',brange});
            need_permute = false;
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

switch lower(precision)
    case 'double'
        subimg = double(subimg);
    case 'single'
        subimg = single(subimg);
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