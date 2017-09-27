function [hdrNew] = envi_bandByband(hdr,imgPath,imgNewPath,func,hdrcomponents)
% [hdrNew] = envi_bandByband(hdr,imgPath,imgNewPath,func)
%   perform band by band operation and dump image
%   Input Parameters
%      hdr: header for the imgPath
%      imgPath: path to the image on which processing applies
%      imgNewPath: path to the output image
%      func: function handle or the cell. function takes a band image 
%            (lines x sample) as the first input. In the case of the cell 
%            array, the first element should be the function handle, the 
%            second to last elements will be the input to the function (the
%            first input is always a band image and the second input is 
%            always band(scalar). The output of the function is always the
%            processed image with the same size
%      hdrcomponents:
%            cell, modification to the header file
%   Output
%      hdrNew: basically, this is the same as hdr except the component
%              specfied by "hdrcomponents" and 'interleave'
%      

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
hdrNew = hdrupdate(hdrNew,'interleave','bsq',hdrcomponents{:});

if iscell(func)
    funcHandle = func{1};
    varargin_funcHandle = func(2:end);
else
    funcHandle = func;
    varargin_funcHandle = {};
end

for b=1:hdr.bands
    imb = lazyEnviReadb_v2(imgPath,hdr,b);
    imb_processed = funcHandle(imb,b,varargin_funcHandle); 
    a = lazyEnviWriteb(imgNewPath,imb_processed,hdrNew,b,'a');
end
    
end