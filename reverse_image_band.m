function [img] = reverse_image_band(img)
% [img] = reverse_image_band(img)
%   Reverse the image along band direcrion
img = flip(img,3);
end