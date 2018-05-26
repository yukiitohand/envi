classdef HSI < handle
    % Hyperspectral Image class
    %  Constructor Input
    %    basename: string, basename of the image file
    %    dirpath: string, directory path in which the image file is stored.
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
    %   dirpath   : string, directory path to the files
    %   hdrpath   : full file path to the header file
    %   imgpath   : full file path to the image file
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
        dirpath
        hdrpath
        imgpath
        img = [];
        wa = [];
        BP = [];
    end
    
    methods
        function obj = HSI(basename,dirpath,varargin)
            [hdrpath] = guessEnviHDRPATH(basename,dirpath,varargin{:});
            [imgpath] = guessEnviIMGPATH(basename,dirpath,varargin{:});
            
            obj.basename = basename;
            obj.dirpath = dirpath;
            obj.hdrpath = hdrpath;
            obj.imgpath = imgpath;
            
            if ~isempty(hdrpath)
                hdr = envihdrreadx(hdrpath);
                obj.hdr = hdr;
            end
            
        end
        function img = readimg(obj)
            img = envidataread_v2(obj.imgpath,obj.hdr);
            if nargout<1
                obj.img = img;
            end
        end
        function img = readimgi(obj)
            img = obj.readimg();
            img = flip(img,3);
            if nargout<1
                obj.img = img;
            end
        end
        function spc = lazyEnviRead(obj,s,l)
            spc = lazyEnviRead_v2(obj.imgpath,obj.hdr,s,l);
        end
        function spc = lazyEnviReadi(obj,s,l)
            spc = obj.lazyEnviRead(s,l);
            spc = flip(spc);
        end
        function imb = lazyEnviReadb(obj,b)
            imb = lazyEnviReadb_v2(obj.imgpath,obj.hdr,b);
        end
        function imc = lazyEnviReadc(obj,c)
            imc = lazyEnviReadc_v2(obj.imgpath,obj.hdr,c);
        end
        function imc = lazyEnviReadci(obj,c)
            imc = obj.lazyEnviReadc(c);
            imc = flip(imc,2);
        end
        function imrgb = lazyEnviReadRGB(obj,rgb)
            imrgb = lazyEnviReadRGB(obj.imgpath,obj.hdr,rgb);
        end
    end
    
end

