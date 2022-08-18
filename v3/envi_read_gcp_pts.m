function [gcps] = envi_read_gcp_pts(filepath)
% [gcps] = envi_read_gcp_pts(filepath)
% Read *.pts file
% ; ENVI Image to Image Tie Points File
% ; base file: /Users/yukiitoh/src/matlab/toolbox/crism_toolbox/spice/projection/demo/FRT0000B6F1_L_MSLGaleDEMproj_v0_b426_uint8.img
% ; warp file: /Users/yukiitoh/src/matlab/toolbox/crism_toolbox/spice/projection/demo/MSL_Gale_Orthophoto_Mosaic_25cm_v3_ave10_c4653t10713_l14573t20193.img
% ; Base Image (x,y), Warp Image (x,y)
% ;
%        7270.757324       5881.674805       3061.400000       2566.800000
%        7223.257324       5684.174805       3043.000000       2487.000000
%        7528.257324       6416.674805       3169.600000       2780.400000
%        7843.257324       7031.674805       3304.000000       3022.000000
%        7986.219238       9682.344727       3365.826660       4076.180420
%
% INPUTS
%  filepath: path to the file
% OUTPUTS
%  gcps: struct with two fields
%   base_xy: xy coordinate of the gcps in the base image
%   warp_xy: xy coordinate of the gcps in the warp image
% 
% 

fid = fopen(filepath,'r');
if fid==-1
    error('%s does not exist.',filepath);
end

% Evaluate if the line is header or not and skip 
flg = 1;
while flg
    fline = fgets(fid);
    flg   = ~isempty(regexp(fline,'^\s*;.*','once'));
    nl    = length(fline);
end
% File pointer is moved to the last line
fseek(fid,-nl,'cof');

data = textscan(fid,'%f %f %f %f','MultipleDelimsAsOne',1);

fclose(fid);

base_xy = [data{1:2}];
warp_xy = [data{3:4}];

gcps = struct('base_xy',num2cell(base_xy,2),'warp_xy',num2cell(warp_xy,2));

end