classdef HSI < handle
    % Hyperspectral Image class
    
    properties
        hdr
        basename
        dirPath
        hdrPath
        imgPath
        img = [];
    end
    
    methods
        function obj = HSI(basename,dirPath)
            obj.dirPath = dirPath;
            hdrPath = joinPath(dirPath,[basename '.hdr']);
            if ~exist(hdrPath,'file')
                error('%s does not exist', hdrPath);
            else
                obj.hdrPath = hdrPath;
            end
            hdr = envihdrreadx(hdrPath);
            obj.basename = basename;
            obj.hdr = hdr;
            if exist(joinPath(dirPath,[basename '.img']),'file')
                obj.imgPath = joinPath(dirPath,[basename '.img']);
            elseif exist(joinPath(dirPath,[basename]),'file')
                obj.imgPath = joinPath(dirPath,[basename]);
            end
        end
        function img = readimg(obj)
            img = envidataread_v2(obj.hdr,obj.imgPath);
            if nargout<1
                obj.img = img;
            end
        end
        function spc = lazyEnviRead(obj,s,l)
            spc = lazyEnviRead_v2(obj.imgPath,obj.hdr,s,l);
        end
        function imb = lazyEnviReadb(obj,b)
            imb = lazyEnviReadb_v2(obj.imgPath,obj.hdr,b);
        end
        function imrgb = lazyEnviReadRGB(obj,rgb)
            imrgb = lazyEnviReadRGB(obj.imgPath,obj.hdr,rgb);
        end
    end
    
end

