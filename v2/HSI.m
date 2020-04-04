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
        GP = [];
        BP1nan = [];
        GP1nan = [];
        is_hdr_band_inverse = false;
        is_img_band_inverse = false;
        is_wa_band_inverse = false;
        is_bp1nan_inverse = false;
        is_gp1nan_inverse = false;
        fid_img = -1;
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
                obj.is_img_band_inverse = true;
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
        function imb = lazyEnviReadbi(obj,b)
            b = obj.hdr.bands-b+1;
            imb = lazyEnviReadb_v2(obj.imgpath,obj.hdr,b);
        end
        function imc = lazyEnviReadc(obj,c)
            imc = lazyEnviReadc_v2(obj.imgpath,obj.hdr,c);
        end
        function imcList = lazyEnviReadcList(obj,cList)
            imcList = [];
            for c=cList
                imc = lazyEnviReadc_v2(obj.imgpath,obj.hdr,c);
                imcList = cat(3,imcList,imc);
            end
        end
        function imcList = lazyEnviReadcListi(obj,cList)
            imcList = obj.lazyEnviReadcList(cList);
            imcList = flip(imcList,2);
        end
        function imc = lazyEnviReadci(obj,c)
            imc = obj.lazyEnviReadc(c);
            imc = flip(imc,2);
        end
        function [iml] = lazyEnviReadl(obj,l,varargin)
            % USAGE
            %  hsi.lazyEnviReadl(l)
            %  hsi.lazyEnviReadl(l,0) % when you want to keep file id to
            %  the image open. This is faster when you read many lines
            %  repeatedly. You do not need to move the position of the file
            %  pointer (counted always from the top).
            closefile = true;
            if length(varargin)==1
                closefile = varargin{1};
            elseif isempty(varargin)
                
            else
                error('Too many parameters');
            end
            if obj.fid_img == -1
                obj.fid_img = fopen(obj.imgpath,'r');
            end
            iml = lazyEnviReadl(obj.fid_img,obj.hdr,l);
            
            if closefile
                obj.fclose_img();
            end   
        end
        function [iml] = lazyEnviReadli(obj,l)
            iml = obj.lazyEnviReadl(l);
            iml = flip(iml,1);
        end
        function imrgb = lazyEnviReadRGB(obj,rgb)
            imrgb = lazyEnviReadRGB(obj.imgpath,obj.hdr,rgb);
        end
        function [spc,wv,bdxes] = get_spectrum(obj,s,l,varargin)
            [spc,wv,bdxes] = get_spectrum_HSI(obj,s,l,...
                'WA_BAND_INVERSE',obj.is_wa_band_inverse,...
                'IMG_BAND_INVERSE',obj.is_img_band_inverse,...
                varargin{:});
        end
        function [spc,wv,bdxes] = get_spectrumi(obj,s,l,varargin)
            [spc,wv,bdxes] = obj.get_spectrum(s,l,varargin{:});
            % [spc,wv] = get_spectrum(obj,s,l,varargin{:});
            wv = flip(wv,1);
            bdxes = flip(bdxes,1);
            if numel(size(spc))>=3
                spc = flip(spc,3);
            else
                spc = flip(spc,1);
            end
        end
        function setwa(obj,wa,is_wa_band_inverse)
            obj.wa = wa;
            obj.is_wa_band_inverse = is_wa_band_inverse;
        end
        function setBP1nan(obj,BP1nan,is_bp1nan_inverse)
            obj.BP1nan = BP1nan;
            obj.is_bp1nan_inverse = is_bp1nan_inverse;
        end
        
        function setGP1nan(obj,GP1nan,is_gp1nan_inverse)
            obj.GP1nan = GP1nan;
            obj.is_gp1nan_inverse = is_gp1nan_inverse;
        end
        function [] = fclose_img(obj)
            fclose(obj.fid_img);
            obj.fid_img = -1;
        end
        
    end
    
end

