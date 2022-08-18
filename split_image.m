function [] = split_image(pdir,bname,varargin)
% [] = split_image(pdir,bname,LineMax)
% split a hyperspectral image into strips
%
%    Inputs
%       pdir: parent directory of the image
%       bname: basename of the file
%       lsize: maximum number of lines
%
%    Usage:
%       split_image(pdir,bname)
%       split_image(pdir,bname,lsize)
%    ---------------------------------------
%    names of the new images are []

lsize = 3000;
varargin_hdrupdate = {};
if length(varargin)==1
    lsize = varargin{1};
elseif length(varargin)>1
    varargin_hdrupdate = varargin(2:end);
end
hdrPath = joinPath(pdir,[bname '.hdr']);
imgPath = joinPath(pdir,bname);
hdr = envihdrreadx(hdrPath);

lines = hdr.lines;
reps = ceil(lines/lsize);
for r = 1:reps
    l_strt = lsize*(r-1)+1;
    l_end = min(lsize*r,lines);
    
    hdrNew = hdrupdate(hdr,'lines',l_end-l_strt+1,'interleave','bil');
    if isfield(hdrNew,'FrameIndex')
        hdrNew.FrameIndex = sprintf('frameIndex_%d.txt',l_strt-1);
    end
    hdrNew = hdrupdate(hdrNew,varargin_hdrupdate{:});
    bnameNew = sprintf('%s_%d',bname,l_strt-1);
    
    % delete if there exists a file with same folder.
    imgNewPath = joinPath(pdir,bnameNew);
    hdrNewPath = joinPath(pdir,[bnameNew '.hdr']);
    if exist(imgNewPath,'file')
        prompt = sprintf('%s exists. Do you want to proceed?(y/n)',imgNewPath);
        flg = 1;
        while flg
            anser = input(prompt,'s');
            if strcmp(lower(anser),'y')
                delete(imgNewPath,hdrNewPath); flg=0;
            elseif strcmp(lower(anser),'n')
                return;
            else
                fprintf('Your input is invalid. Type carefully.\n');
            end
        end
    end
    
    envihdrwritex(hdrNew,hdrNewPath);
    for l=1:hdrNew.lines
        iml = lazyEnviReadl(imgPath,hdr,l+l_strt-1);
        a = lazyEnviWritel(imgNewPath,iml,hdrNew,l,'a');
    end
end

end