function [hdr] = envihdrnew(varargin)
% create a new header struct
%   options could be either a struct with values, or cell of arrays.


hdr = [];
hdr.description = '';
hdr.lines = -1;
hdr.samples = -1;
hdr.bands = 1;
hdr.data_type = 1;
hdr.byte_order = 0;
hdr.file_type = 'ENVI Standard';
hdr.header_offset = 0;
hdr.interleave = 'bil';

if length(varargin)==1 && isstruct(varargin{1})
    options = varargin{1};
    flds = fields(options);
    for i=1:length(flds)
        fld = flds{i};
        hdr.(fld) = options.(fld);
    end
elseif iscell(varargin)
    hdr = hdrupdate(hdr,varargin{:});
end