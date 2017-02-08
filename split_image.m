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
if length(varargin)==1
    lsize = varargin{1};
elseif length(varargin)>1
    error('Too many inputs');
end

hdr = envihdrread_yuki([pdir bname '.hdr']);

lines = hdr.lines;
reps = ceil(lines/lsize);
for r = 1:reps
    l_strt = lsize*(r-1)+1;
    l_end = min(lsize*r,lines);
    
    hdrNew = hdrupdate(hdr,'lines',l_end-l_strt+1,'interleave','bil');
    bnameNew = sprintf('%s_%d',bname,l_strt)
    
    % delete if there exists a file with same folder.
    if exist([pdir bnameNew],'file')
        prompt = '%s exists. Do you want to proceed?(y/n)';
        flg = 1;
        while flg
            anser = input(prompt,'s');
            if strcmp(lower(anser),'y')
                delete([pdir bnameNew],[pdir bnameNew '.hdr']); flg=0;
            elseif strcmp(lower(anser),'n')
                return;
            else
                fprintf('Your input is invalid. Type carefully.\n');
            end
        end
    end
    
    envihdrwrite_yuki(hdrNew,[pdir bnameNew '.hdr']);
    for l=1:hdrNew.lines
        iml = lazyEnviReadl([pdir bname],hdr,l+l_strt-1);
        a = lazyEnviWritel([pdir bnameNew],iml,hdrNew,l,'a');
    end
end

end