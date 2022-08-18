function [size_cdata,xdata,ydata,zdata,image_varargin] = parse_image_input(image_input)
    if isnumeric(image_input) || islogical(image_input)
        % input is just cdata
        size_cdata = size(image_input); xdata = []; ydata = []; zdata = [];
        image_varargin = {};
    elseif iscell(image_input)
        if length(image_input)==1 && (isnumeric(image_input{1}) || islogical(image_input{1}))
            % input is just cdata, inside a cell
            size_cdata = size(image_input{1}); xdata = []; ydata = []; zdata = [];
            image_varargin = {};
        else
            % when more than one variables are specified
            if (isnumeric(image_input{1}) || islogical(image_input{1})) && ischar(image_input{2})
                % first input may be the cdata and rest are variable input
                % arguments.
                xdata = []; ydata = []; size_cdata = size(image_input{1});
                zdata = [];
                image_varargin = image_input(2:end);
            elseif (isnumeric(image_input{1}) && isvector(image_input{1})) ...
                    && (isnumeric(image_input{2}) && isvector(image_input{2})) ...
                    && (isnumeric(image_input{3}) || islogical(image_input{3}))
                % if input is (x,y,C)
                xdata = image_input{1}; ydata = image_input{2}; size_cdata = size(image_input{3});
                zdata = [];
                image_varargin = image_input(4:end);
            else
                image_varargin = image_input;
                xdata = []; ydata = []; size_cdata = [];
                for ii=1:2:length(image_input)
                    switch upper(image_input{ii})
                        case 'XDATA'
                            xdata = image_input{ii+1};
                        case 'YDATA'
                            ydata = image_input{ii+1};
                        case 'CDATA'
                            size_cdata = size(image_input{ii+1});
                    end
                end
                if isempty(xdata) && isempty(ydata) && isempty(size_cdata)
                    error('the input is something wrong');
                end
            end
        end
    end
end