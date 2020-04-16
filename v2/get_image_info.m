function [image_input,im_info] = get_image_info(image_input)
% parse image_input and get the valid input variables for image/imagesc,
% and take out additional information:
% (xrange, yrange, pixel_size, image_name, clim, cmap)
%  INPUTS
%   image_input: cell array of the inputs
%  OUTPUTS
%   image_input: cell array of the valid inputs for image/imagesc extracted
%   from the input.
%   im_info: struct having some information
%     fields: 'xrange', 'yrange', 'pixel_size', 'image_name', 'clim',
%     'cmap'
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
end

%% First get image ranges.
[i_cdata,i_xdata,i_ydata,i_zdata,i_image_varargin] = parse_metainfo_image_input(metainfo_image_input);
[xrange,yrange,pixel_size] = get_image_lim(image_input{i_xdata},...
    image_input{i_ydata},size(image_input{i_cdata}));
im_info.xrange = xrange;
im_info.yrange = yrange;
im_info.pixel_size = pixel_size;

%% 
%  Second. separate it into valid input variables for image/imagesc, 
%  image_name, clim, and cmap

if ~isempty(i_image_varargin)
    is_image_input = true(1,length(image_input));
    for i=1:Nin
        switch upper(image_input{i})
            case {'IMAGE_NAME','IMAGE_TITLE'}
                im_info.image_name = image_input{i+1};
                is_image_input([i i+1]) = false;
            case 'CLIM'
                im_info.clim = image_input{i+1};
                is_image_input([i i+1]) = false;
            case 'CMAP'
                im_info.cmap = image_input{i+1};
                is_image_input([i i+1]) = false;
        end
    end
    image_input = image_input(is_image_input);
end


end