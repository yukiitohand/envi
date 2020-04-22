function [image_input,im_info,clim,cmap] = get_ISVImage_info(image_input)
% parse image_input and get the valid input variables for image/imagesc,
% and take out additional information:
% (xrange, yrange, pixel_size, image_name, clim, cmap)
%  INPUTS
%   image_input: cell array of the inputs
%  OUTPUTS
%   image_input: cell array of the valid inputs for image/imagesc extracted
%   from the input.
%   im_info: ISV_ImageInfo class object
%   

if ~iscell(image_input)
    image_input = {image_input};
end

Nin = length(image_input);
im_info = [];
metainfo_image_input = [];
for i=1:Nin
    metainfo_image_input(i).class = class(image_input{i});
    metainfo_image_input(i).size  =  size(image_input{i});
    if strcmpi(metainfo_image_input(i).class,'char')
        metainfo_image_input(i).char = image_input{i};
    else
        metainfo_image_input(i).char = '';
    end
end

%% First get image ranges.
[i_cdata,i_xdata,i_ydata,i_zdata,i_image_varargin] = parse_metainfo_image_input(metainfo_image_input);
if isempty(i_xdata), xdata = []; else, xdata = image_input{i_xdata}; end
if isempty(i_ydata), ydata = []; else, ydata = image_input{i_ydata}; end
if isempty(i_cdata), error('no image is detected'); else, size_cdata = size(image_input{i_cdata}); end
[xrange,yrange,pixel_size] = get_image_lim(xdata,ydata,size_cdata);
im_info.xrange = xrange;
im_info.yrange = yrange;
im_info.pixel_size = pixel_size;

%% 
%  Second. separate it into valid input variables for image/imagesc, 
%  image_name, clim, and cmap
im_info.name = '';
clim = [];
cmap = [];

if ~isempty(i_image_varargin)
    is_image_input = true(1,length(image_input));
    for i=1:Nin
        if ischar(image_input{i})
            switch upper(image_input{i})
                case {'NAME','IMAGE_NAME','IMAGE_TITLE'}
                    im_info.name = image_input{i+1};
                    is_image_input([i i+1]) = false;
                case 'CLIM'
                    clim = image_input{i+1};
                    is_image_input([i i+1]) = false;
                case 'CMAP'
                    cmap = image_input{i+1};
                    is_image_input([i i+1]) = false;
            end
        end
    end
    image_input = image_input(is_image_input);
end


end