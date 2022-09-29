function [ hsi_sub ] = lazyEnviReadRect_v2( datafile,hdr_info,varargin)
% [ spc ] = lazyEnviReadRect( datafile,info,upperLeft,LowerRight,bands )
% read a subset of hyperspectral data. The spatial subset is defined by the
% samples and the lines and the spectral subset is defined by the bands. 
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%   Optional parameters
%       'CRANGE': range of columns [cstart,cend] (default) 'all'
%       'LRANGE': range of lines [lstart, lend] (default) 'all'
%       'BRANGE': range of bands [bstart, bend] (default) 'all'
%   Outputs:
%       hsi_sub: the subset of the hyperspectral data 
%                [lines x samples x bands]

%% variable checking
interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;

crange = 'all'; lrange = 'all'; brange = 'all';

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'CRANGE'
                crange = varargin{i+1};
            case 'LRANGE'
                lrange = varargin{i+1};
            case 'BRANGE'
                brange = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end
    end
end

iscx = false;
switch data_type
    case {1}
        precision = 'uint8';
    case {2}
        precision= 'int16';
    case{3}
        precision= 'int32';
    case {4}
        precision= 'single';
    case {5}
        precision= 'double';
    case {6}
        iscx=true;
        precision= 'single';
    case {9}
        iscx=true;
        precision= 'double';
    case {12}
        precision= 'uint16';
    case {13}
        precision= 'uint32';
    case {14}
        precision= 'int64';
    case {15}
        precision= 'uint64';
    otherwise
        error('Undefined data_type "%d".',data_type);
end

switch hdr_info.byte_order
    case {0}
        byteorder = 'ieee-le';
    case {1}
        byteorder = 'ieee-be';
    otherwise
        byteorder = 'n';
end

if strcmpi(crange,'all')
    if strcmpi(lrange,'all')
        if strcmpi(brange,'all')
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder);
        else
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Band','Range',brange});
        end
    else
        if strcmpi(brange,'all')
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Row', 'Range', lrange});
        else
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Row', 'Range', lrange}, {'Band','Range',brange});
        end
    end
else
    if strcmpi(lrange,'all')
        if strcmpi(brange,'all')
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Column', 'Range', crange});
        else
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Column', 'Range', crange},{'Band','Range',brange});
        end
    else
        if strcmpi(brange,'all')
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Row', 'Range', lrange}, {'Column', 'Range', crange});
        else
            hsi_sub = multibandread(datafile,[lines,samples,bands],...
                                precision, header_offset, interleave, byteorder,...
                                {'Row', 'Range', lrange}, ...
                                {'Column', 'Range', crange},{'Band','Range',brange});
        end
    end
        
end
    


