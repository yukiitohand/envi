function [ img ] = enviRasterRead( imgpath,hdr,varargin)
% read the whole raster image cube stored in the binary format.
%  Inputs:
%     imgpath: char or string
%         file path to the image file
%     hdr: struct
%        ENVI header struct returned by envihdrread(hdrfile)
%  Outputs:
%     img: raster image cube [lines x samples x bands]
%  OPTIONAL Parameters
%   "PRECISION": char, string; data type of the output image.
%       'double', 'single', 'uint8', 'raw'
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
% Copyright(c) 2021 Yuki Itoh

%% 


% [img] = lazyenvireadRect_multBandRaster_mexw(imgpath,hdr,...
%    0,0,0,hdr.samples,hdr.lines,hdr.bands,varargin{:});


precision  = 'double';
rep_div    = []; % replace data ignore value
repval_div = []; % value replaced for data ignore value
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
        error('Not implemented yet for precision %s.',precision);
end

if ~exist(imgpath,'file')
    error('File does not exist. Check the file path\n %s',imgpath);
end

%% Main processing

interleave    = hdr.interleave;
samples       = hdr.samples;
lines         = hdr.lines;
header_offset = hdr.header_offset;
bands         = hdr.bands;

switch hdr.byte_order
    case {0}
        byteorder = 'ieee-le';
    case {1}
        byteorder = 'ieee-be';
    otherwise
        byteorder = 'n';
end


switch iscx % if complex value or not.
    case 0
        switch lower(precision_raw)
            case 'single'
                img = lazyenvireadRect_multBandRasterSingle_mex(...
                    imgpath,hdr,0,0,0,hdr.samples,hdr.lines,hdr.bands);
            otherwise
                fid = fopen(imgpath,'rb');
                n = samples*lines*bands;
                img = fread(fid, n, [precision_raw '=>' precision_raw], ...
                    header_offset, byteorder);
                fclose(fid);
                switch lower(interleave)
                    case {'bsq'}
                        img = reshape(img,[samples,lines,bands]);
                    case {'bil'}
                        img = reshape(img,[samples,bands,lines]);
                    case {'bip'}
                        img = reshape(img,[bands,samples,lines]);
                end
        end
    case 1
        % not tested well.
        fid = fopen(imgpath,'rb');
        n = samples*lines*bands;
        img = fread(fid, n*2, [precision_raw '=>' precision_raw],...
            header_offset, byteorder);
        img = complex(img(1:2:end),img(2:2:end));
        fclose(fid);
end


switch lower(interleave)
    case {'bsq'}
        img = permute(img,[2,1,3]);
    case {'bil'}
        img = permute(img,[3,1,2]);
    case {'bip'}
        img = permute(img,[3,2,1]);
end

%% Post processing
switch lower(precision)
    case 'double'
        img = double(img);
    case 'single'
        img = single(img);
    case 'int8'
        img = int8(img);
    case 'int16'
        img = int16(img);
    case 'int32'
        img = int32(img);
    case 'int64'
        img = int64(img);
    case 'uint8'
        img = uint8(img);
    case 'uint16'
        img = uint16(img);
    case 'uint32'
        img = uint32(img);
    case 'uint64'
        img = uint64(img);
    case 'raw'
        % not changing data_type
    otherwise
        error('Undefined precision %d',precision);
end

if rep_div && isfield(hdr,'data_ignore_value')
    div = cast(hdr.data_ignore_value,class(img));
    repval_div = cast(repval_div,class(img));
    img(img==div) = repval_div;
end


end