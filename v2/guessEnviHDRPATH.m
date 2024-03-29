function [hdrPath] = guessEnviHDRPATH(basename,dirPath,varargin)
% [hdrPath] = guessHDRPATH(basename,dirPath,varargin)
% Input Parameters
%   basename: string, basename of the header file
%   dirPath: string, directory path in which the header file is stored. if
%            empty, then './' will be set.
% Output Parameters
%   hdrPath: full file path to the header file
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

hdrname = [basename '.hdr'];
[hdrname] = findfilei(hdrname,dirPath);
if isempty(hdrname)
    hdrname = [basename '.img.hdr'];
    [hdrname] = findfilei(hdrname,dirPath);
end

if isempty(hdrname)
    if issue_warning
        warning('Header file cannot be found');
    end
    hdrPath = '';
else
    if iscell(hdrname)
        if all(strcmpi(hdrname{1},hdrname))
            hdrname = hdrname{1};
        else
            error('Ambiguity error. Multiple HDR files are detected.');
        end
    end
    hdrPath = joinPath(dirPath,hdrname);
end

% if ismac || ispc
%     hdrPath = joinPath(dirPath,[basename '.hdr']);
%     if ~exist(hdrPath,'file')
%         hdrPath = joinPath(dirPath,[basename '.img.hdr']);
%         if ~exist(hdrPath,'file') 
%             if iswarning
%                 warning('Header file cannot be found.');
%             end
%             hdrPath = '';
%         end
%     end
% elseif isunix
%     hdrname = [basename '.hdr'];
%     [hdrname] = findfilei(hdrname,dirPath);
%     if isempty(hdrname)
%         hdrname = [basename '.img.hdr'];
%         [hdrname] = findfilei(hdrname,dirPath);
%     end
%     
%     if isempty(hdrname) 
%         if iswarning
%             warning('Header file cannot be found');
%         end
%         hdrPath = '';
%     else
%         if iscell(hdrname)
%             if all(strcmpi(hdrname{1},hdrname))
%                 hdrname = hdrname{1};
%             else
%                 error('Ambiguity error. Multiple HDR files are detected.');
%             end
%         end
%         hdrPath = joinPath(dirPath,hdrname);
%     end
% end

end