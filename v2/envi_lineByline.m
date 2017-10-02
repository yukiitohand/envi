function [hdrNew] = envi_lineByline(hdr,imgPath,imgNewPath,func,varargin)
% [hdrNew] = envi_lineByline(hdr,imgPath,imgNewPath,func)
%   perform line by line operation and dump image
%   Input Parameters
%      hdr: header for the imgPath
%      imgPath: path to the image on which processing applies
%      imgNewPath: path to the output image
%      func: function handle or the cell. function takes a line image 
%            (bands x sample) as the first input. In the case of the cell 
%            array, the first element should be the function handle, the 
%            second to last elements will be the input to the function (the
%            first input is always a line image and the second input is 
%            always line(scalar). The output of the function is always the
%            processed image with the same size
%   Optional parameters
%      hdrcomponents:
%            cell, modification to the header file, need to have an even
%            number of the elements.
%   Output
%      hdrNew: basically, this is the same as hdr except the component
%              specfied by "hdrcomponents" and 'interleave'
%
%   Usage:
%      [hdrNew] = envi_linebyline(hdr,imgPath,imgNewPath,func);
%      [hdrNew] =
%      envi_linebyline(hdr,imgPath,imgNewPath,func,hdrcomponents);

hdrcomponents = {};
if ~isempty(varargin)
    hdrcomponents = varargin{1};
end  

if exist(imgNewPath,'file')
    prompt = sprintf('%s exists. Do you want to proceed?(y/n)',imgNewPath);
    flg = 1;
    while flg
        anser = input(prompt,'s');
        if strcmpi(anser,'y')
            delete(imgNewPath,hdrNewPath); flg=0;
        elseif strcmpi(anser,'n')
            return;
        else
            fprintf('Your input is invalid. Type carefully.\n');
        end
    end
end

hdrNew = hdr;
hdrNew = hdrupdate(hdrNew,'interleave','bil',hdrcomponents{:});

if iscell(func)
    funcHandle = func{1};
    varargin_funcHandle = func(2:end);
else
    funcHandle = func;
    varargin_funcHandle = {};
end

for l=1:hdr.lines
    iml = lazyEnviReadl_v2(imgPath,hdr,l);
    iml_processed = funcHandle(iml,l,varargin_funcHandle{:}); 
    a = lazyEnviWritel(imgNewPath,iml_processed,hdrNew,l,'a');
end
    
end