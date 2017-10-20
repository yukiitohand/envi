function [hdrPath] = guessEnviHDRPATH(basename,dirPath)
% [hdrPath] = guessHDRPATH(basename,dirPath)
% Input Parameters
%   basename: string, basename of the header file
%   dirPath: string, directory path in which the header file is stored.
% Output Parameters
%   hdrPath: full file path to the header file

hdrPath = joinPath(dirPath,[basename '.hdr']);
if ~exist(hdrPath,'file')
    hdrPath = joinPath(dirPath,[basename '.img.hdr']);
    if ~exist(hdrPath,'file')
        warning('Header file cannot be found.');
        hdrPath = '';
    end
end

