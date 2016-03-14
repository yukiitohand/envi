function [ hsi_roi ] = readHsiwROI( hsiFile,info,map,varargin )
% [ hsi_roi ] = readHsiwROI( ROIs,idx )
% This function create the hyperspectral image 
%    Inputs:
%       hsiFile: full file path to the hyperspectral image
%       info: info file for the hyperspectral image 
%             (output of envihdrread_yuki)
%       map: 2-dimensional ROI map: ROI has positive values and the
%            the complement region has zero. [line, sample] 
%    Optional parameters
%       'PADDINGALL' : true, false
%                   determine whether how the outside of the ROI is padded 
%                   or not. If true, the size of the output image is same 
%                   as that of the whole image. Otherwise, the size of the 
%                   output image is the least rectangle surrounding the
%                   ROI.
%                   (default): false
%
%       'PADDINGVALUE' : spefify the values for used for padding the 
%                        outside of the ROI. 
%                        (default) 0
%    Outputs:
%       hsi_roi: Hyperspectral image (3-dimensional array)
%                [y,x,band]
%   
%    

paddingall = false;
paddingvalue = 0;
%--------------------------------------------------------------------------
% Read the optional parameters
%--------------------------------------------------------------------------
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'PADDINGALL'
                padding = varargin{i+1};
            case 'PADDINGVALUE'
                paddingvalue = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end;
    end;
end

if size(map,1)~=info.lines || size(map,2)~=info.samples
    error('The size of map does not match hyperspectral image.\n');
end

if paddingall
    hsi_roi = zeros([ROIs.ImageDim nBands]);

    
map = map>0;

% select the least squared area and read only that part.




end