function [hdrPath] = guessEnviHDRPATH(basename,dirPath)
% [hdrPath] = guessHDRPATH(basename,dirPath)
% Input Parameters
%   basename: string, basename of the header file
%   dirPath: string, directory path in which the header file is stored.
% Output Parameters
%   hdrPath: full file path to the header file
if ismac
    hdrPath = joinPath(dirPath,[basename '.hdr']);
    if ~exist(hdrPath,'file')
        hdrPath = joinPath(dirPath,[basename '.img.hdr']);
        if ~exist(hdrPath,'file')
            warning('Header file cannot be found.');
            hdrPath = '';
        end
    end
elseif isunix
    hdrname = [basename '.hdr'];
    [hdrname] = findfilei(hdrname,dirPath);
    if isempty(hdrname)
        hdrname = [basename '.img.hdr'];
        [hdrname] = findfilei(hdrname,dirPath);
        if isempty(hdrname)
           warning('Header file cannot be found');
        end
    end
    if ~isempty(hdrname)
        hdrPath = joinPath(dirPath,hdrname);
    end
end

end