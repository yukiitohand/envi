function [ hsi ] = envireadx( imgfile,varargin )
% [ hsi ] = envireadx( imgfile )
%   Read an image saved in the default Envi file format
%    Inputs
%      imgfile: filepath to the image file
%      hdrfile (optional): filepath to the header file
%    Outputs
%      hsi: (struct) having two fields, {'hdr','img'}
%          'hdr' stores header information
%          'img' stores the image
%   Usage
%     [ hsi ] = envireadx( imgfile )
%     [ hsi ] = envireadx( imgfile,hdrfile )

%     With hdrfile is unspecified, the path will be guessed.


if ~exist(imgfile,'file')
    error('imgfile %s does not exist.',imgfile);
end

if length(varargin)==1
    hdrfile = varargin{1};
    if ~exist(hdrfile,'file')
        error('%s does not exist',hdrfile);
    end
elseif isempty(varargin)
    % guess the header file name
    if isempty(regexp(imgfile,'^.*\.img$'))
        [pathstr,bname,ext] = fileparts(imgfile);
        hdrfile_candidates = [bname '.hdr'];
        hdrfile = findfilei(hdrfile_candidates,pathstr);
        if isempty(hdrfile)
            error('No hdr file is found');
        elseif length(hdrfile)==1
            hdrfile = fullfile(pathstr,hdrfile{1});
        else
            error('Multiple header files are detected');
        end
    else
        [pathstr,bname,ext] = fileparts(imgfile);
        hdrfile_candidates = {[bname '.hdr'],[bname '.img.hdr']};
        hdrfile = findfilei(hdrfile_candidates,pathstr);
        if isempty(hdrfile)
            error('No hdr file is found');
        elseif length(hdrfile)==1
            hdrfile = fullfile(pathstr,hdrfile{1});
        else
            error('Multiple header files are detected');
        end
    end
else
    error('The number of inputs is not valid.');
end

fprintf('Guessed hdr file is\n');
fprintf('%s\n',hdrfile);

hdr = envihdrreadx(hdrfile);
img = envidataread_v2(imgfile,hdr);

hsi.img = img;
hsi.hdr = hdr;

end

