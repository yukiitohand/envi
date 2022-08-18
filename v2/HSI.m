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
        objRGBImage;
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
        
        function [] = fopen_img(obj)
            obj.fid_img = fopen(obj.imgpath,'r');
        end
        
        function [] = fclose_img(obj)
            fclose(obj.fid_img);
            obj.fid_img = -1;
        end
        
        function [] = get_rgb(obj,varargin)
            bands_rgb_tmp = obj.hdr.default_bands;
            tolrgb = 0.01;
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})                        
                        case 'BANDS'
                            bands_rgb_tmp = varargin{n+1};
                        case 'TOLRGB'
                            tolrgb = varargin{n+1};
                        otherwise
                            error('Unrecognized option: %s', varargin{n});
                    end
                end
            end
            if ~isempty(bands_rgb_tmp)
                rgbim = obj.lazyEnviReadRGB(bands_rgb_tmp);
                obj.objRGBImage = RGBImage(rgbim,'Tol',tolrgb);
                obj.bands_rgb = bands_rgb_tmp;
            end
        end
        
        function [tf] = isValid_sampleline(obj,smpl,ln)
            if smpl<1 || smpl>obj.hdr.samples || ln<1 || ln>obj.hdr.lines
                tf = false;
            else
                tf = true;
            end
        end
        
        function [x_im,y_im] = get_xy_fromNE(obj,x_east,y_north)
            % if the (x_im,y_im) is outside of the image, then (nan,nan) is
            % returned.
            [x_im] = round((x_east-obj.hdr.easting(1))/obj.hdr.map_info.dx + 1);
            [y_im] = round((obj.hdr.northing(1)-y_north)/obj.hdr.map_info.dy + 1);
            if ~obj.isValid_sampleline(x_im,y_im)
                x_im = nan; y_im = nan;
            end
        end
        function [east_x_im,north_y_im] = get_NE_fromxy(obj,x_im,y_im)
            east_x_im = obj.hdr.easting(x_im);
            north_y_im = obj.hdr.northing(y_im);
        end
        
        function [xrnge_east,yrnge_north] = get_pixel_rangeNE_fromxy(obj,x_im,y_im)
            % evaluate overlapping MSLDEM pixels
            % first evaluate one pixel size
            [east_x_im,north_y_im] = obj.get_NE_fromxy(x_im,y_im);
            xrnge_east = [east_x_im-obj.hdr.map_info.dx/2,east_x_im+obj.hdr.map_info.dx/2];
            yrnge_north = [north_y_im-obj.hdr.map_info.dy/2,north_y_im+obj.hdr.map_info.dy/2];
        end
        
        function [xrnge_east,yrnge_north,x_im,y_im] = get_pixel_rangeNE_fromNE(obj,x_east,y_north)
            % evaluate overlapping MSLDEM pixels
            % first evaluate one pixel size
            [x_im,y_im] = obj.get_xy_fromNE(x_east,y_north);
            [xrnge_east,yrnge_north] = obj.get_pixel_rangeNE(x_im,y_im);
        end
        
        function delete(obj)
            if obj.fid_img ~= -1
                fclose(obj.fid_img);
            end
        end
        
    end
    
end

