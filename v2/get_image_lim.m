function [xlm,ylm,pixel_sizes] = get_image_lim(xdata,ydata,size_cdata)
% [xlm,ylm,pixel_sizes] = get_image_lim(xdata,ydata,size_cdata)
%  return valid image range for the image whose size is given.
% INPUTS:
%   xdata: vector, range of x
%   ydata: vector, range of y
%   size_cdata: size of cdata, size(cdata), first element is the size of y
%   and the second element is the size of x
% OUTPUTS
%   xlm: xlim, 1 x 2 size vector
%   ylm: ylim, 1 x 2 size vector
%   pixel_sizes: 1 x 2 size vector, the first element is the pixel size of
%   x and the second element is that of y.

[xlm,pixel_size_x] = get_image_lim_base(xdata,size_cdata,2);
[ylm,pixel_size_y] = get_image_lim_base(ydata,size_cdata,1);

pixel_sizes = [pixel_size_x pixel_size_y];

end


function [ilm,pixel_size_i] = get_image_lim_base(idata,size_cdata,i)
ilm = nan(1,2);
if isempty(idata)
    pixel_size_i = 1;
    ilm(1) = 1 - pixel_size_i/2;
    ilm(2) = size_cdata(i) + pixel_size_i/2;
elseif isvector(idata)   
    if length(idata) == 2
        % pixel_size could be a negative value. It is ok, by design.
        pixel_size_i = (idata(2)-idata(1)) / (size_cdata(i)-1);
        ilm(1) = idata(1) - pixel_size_i/2;
        ilm(2) = idata(2) + pixel_size_i/2;
    elseif length(idata) > 2
        % just extrapolate the edge coordinates.
        pixel_size_i = (idata(end)-idata(1))/(size_cdata(i)-1);
        ilm(1) = (3*idata(1)-idata(2))/2;
        ilm(2) = (3*idata(end)-idata(end-1))/2;
    else
        error('shape of idata is invalid');
    end
else
    error('shape of idata is invalid');
end


end