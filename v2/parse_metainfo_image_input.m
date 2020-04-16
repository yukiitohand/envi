function [i_cdata,i_xdata,i_ydata,i_zdata,i_image_varargin] = parse_metainfo_image_input(metainfo_image_input)
% [i_cdata,i_xdata,i_ydata,i_zdata,i_image_varargin] = parse_metainfo_image_input(metainfo_image_input)
%  Evaluate 

numeric_types = {'single','double','int8','int16','int64','int32','uint8','uint16','uint32','uint64'};
Nin = length(metainfo_image_input);
if Nin == 1 && ... 
        any(strcmpi(metainfo_image_input(1).class,{numeric_types,'logcal'}))
    % input is just cdata, inside a cell
    i_cdata = 1; i_xdata = []; i_ydata = []; i_zdata = [];
    i_image_varargin = [];
elseif Nin > 1
    % when more than one variables are specified
    if any(strcmpi(metainfo_image_input(1).class,{numeric_types,'logcal'})) && ...
            strcmpi(metainfo_image_input(2).class,'char')
        % first input may be the cdata and rest are variable input
        % arguments.
        i_xdata = []; i_ydata = []; i_cdata = 1;
        i_zdata = [];
        i_image_varargin = 2:Nin;
    elseif (any(strcmpi(metainfo_image_input(1).class,numeric_types)) && any(metainfo_image_input(1).size==1)) ...
            && (any(strcmpi(metainfo_image_input(2).class,numeric_types)) && any(metainfo_image_input(2).size==1)) ...
            && any(strcmpi(metainfo_image_input(1).class,{numeric_types,'logcal'}))
        % if input is (x,y,C)
        i_xdata = 1; i_ydata = 2; i_cdata = 3; i_zdata = [];
        i_image_varargin = 4:Nin;
    else
        i_image_varargin = 1:Nin;
        i_xdata = []; i_ydata = []; i_cdata = [];
        for ii=1:2:length(metainfo_image_input)
            switch upper(metainfo_image_input{ii})
                case 'XDATA'
                    i_xdata =ii+1;
                case 'YDATA'
                    i_ydata = ii+1;
                case 'CDATA'
                    i_cdata = ii+1;
            end
        end
        if isempty(i_xdata) && isempty(i_ydata) && isempty(i_cdata)
            error('the input is something wrong');
        end
    end
end
    
end