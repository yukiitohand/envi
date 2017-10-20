classdef HSI < handle
    % Hyperspectral Image class
    %  Constructor Input
    %    basename: string, basename of the image file
    %    dirPath: string, directory path in which the image file is stored.
    %
    %  #1 note that the header and image are supposed to be in the same
    %    directory.
    %  #2 the hdr file name and image file name are estimated. hdr file
    %     name could be either [basename '.hdr'] or [basename 'img.hdr']. 
    %     The imagefilename could be either [basename '.img'] or just 
    %     "basename". Case insensitive (if you are using a case sensitive 
    %     file system format, this may not be true.)
    %  
    %  Properties
    %   hdr       : struct of the header information
    %   basename  : string, basename
    %   dirPath   : string, directory path to the files
    %   hdrPath   : full file path to the header file
    %   imgPath   : full file path to the image file
    %   img       : (default) []
    %  
    %  Methods: readimg, lazyEnviRead, lazyEnviReadb, lazyEnviReadRGB
    %
    %  Usage:
    %  >> hsi = HSI('raw','./');
    %  >> hsi.readimg(); % read the image
    %  >> spc = hsi.lazyEnviRead(100,200); % read the spectrum [200, 100]
    %  >> rgb = hsi.lazyEnviReadRGB([125 85 49]); % read rgb image
    %  >> imb = hsi.lazyEnviReadb(125); % read one band image
    % 
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
            [hdrPath] = guessEnviHDRPATH(basename,dirPath);
            [imgPath] = guessEnviIMGPATH(basename,dirPath);
            
            obj.basename = basename;
            obj.dirPath = dirPath;
            obj.hdrPath = hdrPath;
            obj.imgPath = imgPath;
            
            if ~isempty(hdrPath)
                hdr = envihdrreadx(hdrPath);
                obj.hdr = hdr;
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

