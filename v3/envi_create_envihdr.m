function [hdr] = envi_create_envihdr(varargin)
% [hdr] = envi_create_envihdr(varargin)
%  Create ENVI header struct
% Parameters
%   SAMPLES, positive integer, (default) -1
%   LINES,   positive integer, (default) -1
%   BANDS,   positive integer, (default) -1
%   DATA_TYPE, {0,1,2,3,4,5,6,9,12,13,14,15}, (default) -1
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

samples   = -1;
lines     = -1;
bands     = -1;
data_type = -1;

file_type     = 'ENVI Standard';
byte_order    = 0;
interleave    = 'bsq';
header_offset = 0;

data_ignore_value = [];
desc        = [];
sensor_type = [];
band_names  = [];

output_warning = true;

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            % Required Parameters for ENVI header, can be implicitly
            % defined,
            case 'SAMPLES'
                samples = varargin{i+1};
            case 'LINES'
                lines   = varargin{i+1};
            case 'BANDS'
                bands   = varargin{i+1};
            case 'DATA_TYPE'
                data_type = varargin{i+1};
            case 'INTERLEAVE'
                interleave = varargin{i+1};
            case 'BYTE_ORDER'
                byte_order = varargin{i+1};
            case 'HEADER_OFFSET'
                header_offset = varargin{i+1};
            case 'FILE_TYPE'
                file_type = varargin{i+1};
                
            % OPTIONAL Parameters
            case 'DATA_IGNORE_VALUE'
                data_ignore_value = varargin{i+1};
            case 'DESCRIPTION'
                desc = varargin{i+1};
            case 'SENSOR_TYPE'
                sensor_type = varargin{i+1};
            case 'BAND_NAMES'
                band_names = varargin{i+1};
                
            case 'OUTPUT_WARNING'
                output_warning = varargin{i+1};
                validateattributes(output_warning,{'numeric'},{'binary'},mfilename,'OUTPUT_WARNING');
            otherwise
                error('Unrecognized option: %s',varargin{i});
        end
    end
end



%% Validate Inputs
if samples==-1
    if output_warning
        warning('Required parameter SAMPLES is missing');
    end
else
    validateattributes(samples,{'numeric'},{'integer','nonnegative'},mfilename,'SAMPLES');
end
if lines==-1
    if output_warning
        warning('Required parameter LINES is missing');
    end
else
    validateattributes(lines,{'numeric'},{'integer','nonnegative'},mfilename,'LINES');
end
if bands==-1
    if output_warning
        warning('Required parameter BANDS is missing');
    end
else
    validateattributes(bands,{'numeric'},{'integer','nonnegative'},mfilename,'BANDS');
end

if data_type==-1
    if output_warning
        warning('Required parameter DATA_TYPE is missing');
    end
else
    envihdr_get_precision_sizeA_from_data_type(data_type);
end

interleave = validatestring(interleave,{'bsq','bil','bip'},mfilename,'INTERLEAVE');

if byte_order~=0 && byte_order~=1
    error('Parameter BYTE_ORDER needs to be either 0 or 1');
end
validateattributes(header_offset,{'numeric'},{'integer','nonnegative'},mfilename,'HEADER_OFFSET');
if ~isnumeric(data_ignore_value) && ~isempty(data_ignore_value)
    error('Parameter DATA_IGNORE_VALUE needs to be numeric or empty');
end
if ~ischar(desc) && ~isempty(desc)
    error('Parameter DESCRIPTION needs to be char or empty');
end
validateattributes(file_type,{'char','string'},{},mfilename,'FILE_TYPE');
if ~ischar(sensor_type) && ~isempty(sensor_type)
    error('Parameter SENSOR_TYPE needs to be char or empty');
end

if ~(iscell(band_names) && length(band_names)==bands) && ~isempty(band_names)
    error('Parameter BAND_NAMES needs to be a cell array with the length of BANDS or empty');
end



%%
hdr = [];
% Required Parameters
hdr.samples = samples;
hdr.lines   = lines;
hdr.bands   = bands;
hdr.data_type  = data_type;
hdr.interleave = interleave;
hdr.byte_order = byte_order;
hdr.header_offset = header_offset;
hdr.file_type     = file_type;

% OPTIONAL Parameters
if ~isempty(data_ignore_value)
    hdr.data_ignore_value = data_ignore_value;
end
if ~isempty(band_names)
    hdr.band_names = band_names;
end
if ~isempty(desc)
    hdr.description = desc;
end
if ~isempty(sensor_type)
    hdr.sensor_type = sensor_type;
end

end