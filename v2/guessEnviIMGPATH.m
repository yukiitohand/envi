function [imgPath] = guessEnviIMGPATH(basename,dirPath,varargin)
% [imgPath] = guessHDRPATH(basename,dirPath,varargin)
% Input Parameters
%   basename: string, basename of the image file
%   dirPath: string, directory path in which the image file is stored.
% Output Parameters
%   imgPath: full file path to the image file
% Optional Parameters
%   'WARNING': whether or not to shown warning when the file is not exist
%              (default) false

iswarning = false;
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'WARNING'
                iswarning = varargin{i+1};
        end
    end
end

if ismac
    imgPath = joinPath(dirPath,[basename '.img']);
    if ~exist(imgPath,'file')
        if iswarning
            warning('Image file cannot be found.');
        end
        imgPath = '';
    end
elseif isunix
    imgname = [basename '.img'];
    [imgname] = findfilei(imgname,dirPath);
    if isempty(imgname)
        imgname = basename;
        [imgname] = findfilei(imgname,dirPath);
        if isempty(imgname)
           warning('Image file cannot be found');
        end
    end
    if ~isempty(imgname)
        imgPath = joinPath(dirPath,imgname);
    end
end

end