function [spc] = roimean(roimask,imgPath,hdr,varargin)
% [spc,wv] = roimean(pm,imgPath,hdr,varargin)
%   take average spectrum of the ROI in the image.
%    Input Parameters
%      roimask: ROI mask, value 1 in ROI, 0 otherwise
%      imgPath: path to the image
%      hdr: header information for the image
%    Output Parameters
%      spc: average spectra, one dimensional array
%
%    Optional Parameters
%      'MODE': {'BATCH','SmallBATCH'} (default) 'BATCH'
%              how to read the spectra in the mask.
%              'BATCH' : read the whole image, and apply the mask
%              'SmallBATCH': extract the smallest cardinal rectangular
%                            pixels and read only that region to perform
%                            panel mask.

[L,S] = size(roimask);

if L~=hdr.lines || S~=hdr.samples
    error('size of the panel mask and the image does not match');
end

read_mode = 'BATCH';
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'MODE'
                read_mode = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end
    end
end

switch upper(read_mode)
    case 'BATCH'
        roimask = logical(roimask(:));
        img = envidataread_v2(imgPath,hdr);
        img = reshape(img,L*S,hdr.bands)';
        spc = nanmean(img(:,roimask),2);
    case 'SMALLBATCH'
        roimaskl = any(roimask,2); roimaskc = any(roimask,1);
        lines_active = find(roimaskl); colu_active = find(roimaskc);
        roimask_s = roimask(lines_active,colu_active);
        lrange = [lines_active(1),lines_active(end)];
        crange = [colu_active(1),colu_active(end)];
        brange = [1,hdr.bands];
        [ img_s ] = lazyEnviReadRect_v2(imgPath,hdr,crange,lrange,brange);
        [L,S,B] = size(img_s);
        roimask_s = logical(roimask_s(:));
        img_s = reshape(img_s,L*S,B)';
        spc = nanmean(img_s(:,roimask_s),2);
        
    otherwise
        error('Unsupported mode');
end