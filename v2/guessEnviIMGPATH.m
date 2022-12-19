function [imgPath] = guessEnviIMGPATH(basename,dirPath,varargin)
% [imgPath] = guessHDRPATH(basename,dirPath,varargin)
% Input Parameters
%   basename: string, basename of the image file
%   dirPath: string, directory path in which the image file is stored. if
%            empty, then './' will be set.
% Output Parameters
%   imgPath: full file path to the image file
% Optional Parameters
%   'WARNING': whether or not to shown warning when the file is not exist
%              (default) true

issue_warning = true;
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'WARNING'
                issue_warning = varargin{i+1};
        end
    end
end

if isempty(dirPath)
    dirPath = './';
end

imgname = [basename '.img'];
[imgname] = findfilei(imgname,dirPath);
if isempty(imgname)
    imgname = basename;
    [imgname] = findfilei(imgname,dirPath);
end
if isempty(imgname)
    if issue_warning
        warning('Image file %s cannot be found',basename);
    end
    imgPath='';
else
    if iscell(imgname)
        if all(strcmpi(imgname{1},imgname))
            imgname = imgname{1};
        else
            error('Ambiguity error. Multiple IMG files are detected.');
        end
    end
    imgPath = joinPath(dirPath,imgname);
end

% if ismac || ispc
%     imgPath = joinPath(dirPath,[basename '.img']);
%     if ~exist(imgPath,'file')
%         if iswarning
%             warning('Image file %s cannot be found.',basename);
%         end
%         imgPath = '';
%     end
% elseif isunix
%     imgname = [basename '.img'];
%     [imgname] = findfilei(imgname,dirPath);
%     if isempty(imgname)
%         imgname = basename;
%         [imgname] = findfilei(imgname,dirPath);
%     end
%     if isempty(imgname)
%         warning('Image file %s cannot be found',basename);
%         imgPath='';
%     else
%         if iscell(imgname)
%             if all(strcmpi(imgname{1},imgname))
%                 imgname = imgname{1};
%             else
%                 error('Ambiguity error. Multiple IMG files are detected.');
%             end
%         end
%         imgPath = joinPath(dirPath,imgname);
%     end
% end

end