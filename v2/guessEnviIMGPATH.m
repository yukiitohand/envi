function [imgPath] = guessEnviIMGPATH(basename,dirPath)
% [imgPath] = guessHDRPATH(basename,dirPath)
% Input Parameters
%   basename: string, basename of the image file
%   dirPath: string, directory path in which the image file is stored.
% Output Parameters
%   imgPath: full file path to the image file

if ismac
    imgPath = joinPath(dirPath,[basename '.img']);
    if ~exist(imgPath,'file')
        imgPath = joinPath(dirPath,basename);
        if ~exist(imgPath,'file')
            warning('Image file cannot be found.');
            imgPath = '';
        end
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