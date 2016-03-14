function [ hsiROI,varargout ] = makeHsiwROI( ROIs,idx,varargin )
% [ hsi_roi,varargout ] = makeHsiwROI( ROIs,idx )
% This function create the hyperspectral image 
%    Inputs:
%       ROIs: struct (output of the roiRead_yuki)
%       idx: indices of the specific ROI to process
%    Optional parameters
%       'PADDINGALL' : true, false (currently option true is not supported)
%                   determine whether how the outside of the ROI is padded 
%                   or not. If true, the size of the output image is same 
%                   as that of the whole image. Otherwise, the size of the 
%                   output image is the least rectangle surrounding the
%                   ROI.
%                   (default): the same as ROIs.MapPaddingValue.
%
%       'PADDINGVALUE' : spefify the values for used for padding the 
%                        outside of the ROI. 
%                        (default) nan
%    Outputs:
%       hsiROI: Hyperspectral image (3-dimensional array)
%                [y,x,band]
% Usage
%    [ hsiROI ] = makeHsiwROI( ROIs,idx )
%
%    [ hsiROI, map_croped] = makeHsiwROI( ROIs,idx);
%    map_cropped is the cropped version of the ROIs.Map(:,:,idx)
%
%    [ hsiROI,map_cropped, upperLeft,lowerRight ] = makeHsiwROI( ROIs,idx )
%    upperLeft [y,x] defines the pixel coordinate of the vertex at the upper left
%    of the rectangle. lowerRight [y x] is the pixel coordinate of the vertex at
%    lower left of the rectangle. 
%
%    

paddingall = false;
paddingvalue = ROIs.MapPaddingValue;
%--------------------------------------------------------------------------
% Read the optional parameters
%--------------------------------------------------------------------------
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'PADDINGALL'
                paddingall = varargin{i+1};
            case 'PADDINGVALUE'
                paddingvalue = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end;
    end;
end

nBands = ROIs.nBand;
lines = ROIs.ImageDim(1); samples = ROIs.ImageDim(2);
map = ROIs.Map(:,:,idx);
% process with padding nan 
if ~isnan(ROIs.MapPaddingValue)
    map(map==ROIs.MapPaddingValue) = nan;
end


if paddingall
    error('Sorry, paddingall=true is not supported yet.\n');
%     mapBool1d = find(reshape(map,[1,lines*samples])>0);
%     hsi2d = zeros([nBands,lines*samples]);
%     hsi2d(:,:) = paddingall;
%     spectra = cat(2,ROIs.Points{idx}.Spectrum);
% 
%     hsi2d(:,mapBool1d) = spectra;
%     hsiROI = reshape(hsi2d',[samples,lines,nBands]);
%     hsiROI = permute(hsiROI,[2,1,3]);
    
else
    mapX = find(nansum(map,1)>0); mapY = find(nansum(map,2)>0);
    xmax = max(mapX); xmin = min(mapX);
    ymax = max(mapY); ymin = min(mapY);
    
    rectx = xmax - xmin + 1; recty = ymax - ymin + 1;
    map_cropped = map(ymin:ymax,xmin:xmax);
    map_croppedBool1d = ~isnan(reshape(map_cropped',[1,rectx*recty]));
    
    hsi2d = zeros([nBands,rectx*recty]);
    hsi2d(:,:) = paddingall;
    spectra = cat(2,ROIs.Points{idx}.Spectrum);
    hsi2d(:,map_croppedBool1d) = spectra;
    hsiROI = reshape(hsi2d',[rectx,recty,nBands]);
    hsiROI = permute(hsiROI,[2,1,3]);
    
    map_cropped(isnan(map_cropped)) = paddingvalue;
    
    varargout{1} = map_cropped;
    varargout{2} = [ymin,xmin]; varargout{3} = [ymax,xmax];
    
end


end

