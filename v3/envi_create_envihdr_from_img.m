function [hdr] = envi_create_envihdr_from_img(img,varargin)
% [hdr] = envi_create_envihdr_from_img(img,varargin)
%  Create ENVI header struct of the given image
% INPUTS
%   img: image array
% Optional Parameters
%   SAMPLES
%   LINES
%   BANDS
%   DATA_TYPE
%   FILE_TYPE  char, (default) 'ENVI Standard'
%   BYTE_ORDER {0,1},(default) 0
%   INTERLEAVE {'bsq','bil','bip'} (default) 'bsq'
%   HEADER_OFFSET nonnegative integer, (default) 0
%   DATA_IGNORE_VALUE
%   DESCRIPTION
%   SENSOR_TYPE
%   BAND_NAMES
% OUTPUTS
%   hdr: ENVI header struct. By default, following fields are given
%     samples
%     lines
%     bands
%     data_type
%     file_type
%     byte_order
%     interleave
%     header_offset
%  
%    * optional fields *
%     data_ignore_value, description, sensor_type, band_names

[L,S,B]=size(img);
[data_type] = envihdr_get_data_type_from_precision(class(img));
hdr = envi_create_envihdr('SAMPLES',S,'LINES',L,'BANDS',B,'DATA_TYPE',data_type,varargin{:});

end
