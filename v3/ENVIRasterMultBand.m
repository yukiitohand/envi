classdef ENVIRasterMultBand < ENVIRaster
    % ENVIRasterMultBand class
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
    %  >> hsi = ENVIRaster('raw','./');
    %  >> hsi.readimg(); % read the image
    %  >> spc = hsi.lazyEnviRead(100,200); % read the spectrum [200, 100]
    %  >> rgb = hsi.lazyEnviReadRGB([125 85 49]); % read rgb image
    %  >> imb = hsi.lazyEnviReadb(125); % read one band image
    % 
    properties
        is_img_band_inverse;
        RGB;
    end
    
    methods
        function obj = ENVIRasterMultBand(basename,dirpath,varargin)
            obj@ENVIRaster(basename,dirpath,varargin{:});
            
        end
        
        %------------------------------------------------------------------
        % Methods for basic image read
        %------------------------------------------------------------------
        % readimg, readimgi, lazyEnviRead, lazyEnviReadi, lazyEnviReadb
        % lazyEnviReadbi, lazyEnviReadc, lazyEnviReadci, lazyEnviReadl
        % lazyEnviReadli, get_subimage_wPixelRange,
        % get_subimage_wPixelRangei
        % 
        % 1. function with *i are all read the image with band direction
        %    flipped.
        % 2. varargin has the same format. All the functions has the
        %    following keyword arguments. 
        % 3. Following functions allow users to specify the type of indexes
        %    as either of "Direct" and "Range", can be specified as an
        %    input after the index, before keyword arguments if any.
        %      lazyEnviRead, lazyEnviReadi, lazyEnviReadb
        %      lazyEnviReadbi, lazyEnviReadc, lazyEnviReadci, lazyEnviReadl
        %      lazyEnviReadli
        % The following is the list of common keyword arguments.
        % Optional Parameters
        %  Refer "lazyenvireadRect_singleLayerRaster_mexw.m".
        %   "PRECISION": char, string; data type of the output image.
        %       'double', 'single','int16','uint8','raw'
        %      if 'raw', the data is returned with the original data 
        %      type of the image.
        %      (default) 'double'
        %  "Replace_data_ignore_value": boolean, 
        %      whether or not to replace data_ignore_value with NaNs or
        %      not.
        %      (default) true (for single and double data types)
        %                false (for integer types)
        %  "RepVal_data_ignore_value": 
        %      replaced values for the pixels with data_ignore_value.
        %      (default) nan (for double and single precisions). Need
        %      to specify for integer precisions.
        function [img] = readimg(obj,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            img = lazyenvireadRectxv2_multBandRaster_mexw(...
                obj.imgpath,obj.hdr,[1 obj.hdr.samples],[1 obj.hdr.lines], ...
                [1,obj.hdr.bands],varargin{:});
            if nargout<1
                obj.img = img;
                obj.is_img_band_inverse = false;
            end
        end
        function [img] = readimgi(obj,varargin)
            img = obj.readimg(varargin{:});
            img = flip(img,3);
            if nargout<1
                obj.img = img;
                obj.is_img_band_inverse = true;
            end
        end
        function spc = lazyEnviRead(obj,s,l,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            if any(size(s)~=size(l))
                error('Input s and l has different shape');
            end
            spc = lazyenvireadRectxv2_multBandRaster_mexw(...
                obj.imgpath,obj.hdr,[s s],[l l],[1,obj.hdr.bands],varargin{:});
        end
        
        function spc = lazyEnviReadi(obj,s,l,varargin)
            spc = obj.lazyEnviRead(s,l,varargin{:});
            spc = flip(spc,3);
        end
        function imb = lazyEnviReadb(obj,b,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            imb = lazyEnviReadb_multBandRaster(obj.imgpath,obj.hdr,b,...
                varargin{:});
        end
        function imb = lazyEnviReadbi(obj,b,varargin)
            b = obj.hdr.bands-b+1;
            imb = obj.lazyEnviReadb(b,varargin{:});
        end
        function imc = lazyEnviReadc(obj,c,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            imc = lazyEnviReadc_multBandRaster(obj.imgpath,obj.hdr,c,...
                varargin{:});
        end
        function imc = lazyEnviReadci(obj,c,varargin)
            imc = obj.lazyEnviReadc(c,varargin{:});
            imc = flip(imc,3);
        end
        function [iml] = lazyEnviReadl(obj,l,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            iml = lazyEnviReadl_multBandRaster(obj.imgpath,obj.hdr,l,...
                varargin{:});
        end
        function [iml] = lazyEnviReadli(obj,l,varargin)
            iml = obj.lazyEnviReadl(l,varargin{:});
            iml = flip(iml,3);
        end        
        function [subimg] = get_subimage_wPixelRange(obj,xrange,yrange,...
                zrange,varargin)
            % [subimg] = get_subimage_wPixelRange(obj,xrange,yrange,...
            %   zrange,varargin)
            % Get a rectangular region of the image.
            % INPUTS
            %   xrange: [1 x 2] length vector, range of the rectangle
            %           region of the image in the horizontal direction.
            %   yrange: [1 x 2] length vector, range of the rectangle
            %           region of the image in the vertical direction.
            %   zrange: [1 x 2] length vector, range of the rectangle
            %           region of the image in the depth direction.
            % OUTPUTS
            %   subimage: a rectangle region of the image cube, data type
            %             depends on "Precision".
            
            if isempty(obj.hdr)
                error('no img is found');
            end
            
            if length(xrange)~=2 || length(yrange)~=2
                error('Either the size of xrange or yrange is invalid');
            end
            
            if xrange(1)>xrange(2) || yrange(1)>yrange(2)
                error('Either of the range is not in the right order');
            end
            
            [subimg] = lazyenvireadRectxv2_multBandRaster_mexw(...
                obj.imgpath,obj.hdr,xrange,yrange,zrange,varargin{:});
        end
        
        function [subimg] = get_subimage_wPixelRangei(obj,xrange,yrange,...
                zrange,varargin)
            zrangei = hdr.bands-zrange+1;
            zrangei = flip(zrangei);
            [subimg] = obj.get_subimage_wPixelRange(xrange,yrange,...
                zrangei,varargin{:});
            subimg = flip(subimg,3);
        end
        
        %------------------------------------------------------------------
        function [] = set_rgb(obj,varargin)
            rgb_bands_tmp = obj.hdr.default_bands;
            tolrgb = 0.01;
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                varargin_rmIdx = [];
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})                        
                        case 'BANDS'
                            rgb_bands_tmp = varargin{n+1};
                            varargin_rmIdx = [varargin_rmIdx n n+1];
                        case 'TOLRGB'
                            tolrgb = varargin{n+1};
                            varargin_rmIdx = [varargin_rmIdx n n+1];
                        case {'PRECISION','REPLACE_DATA_IGNORE_VALUE',...
                                'REPVAL_DATA_IGNORE_VALUE'}
                        otherwise
                            error('Unrecognized option: %s', varargin{n});
                    end
                end
                varargin_retIdx = setdiff(1:length(varargin),varargin_rmIdx);
                varargin = varargin(varargin_retIdx);
            end
            if ~isempty(rgb_bands_tmp)
                rgbim = obj.lazyEnviReadb(rgb_bands_tmp,varargin{:});
                obj.RGB = RGBImage(rgbim,'Tol',tolrgb);
            end
        end
        
        function [] = set_rgbi(obj,varargin)
            
        end
        
        function [spc,wv,bdxes] = get_spectrum(obj,s,l,varargin)
            [spc,wv,bdxes] = get_spectrum_ENVIRasterMultBand(obj,s,l,...
                varargin{:});
        end
        function [spc,wv,bdxes] = get_spectrumi(obj,s,l,varargin)
            [spc,wv,bdxes] = obj.get_spectrum(s,l,varargin{:});
            bdxes = obj.hdr.bands-flip(bdxes)+1;
            if numel(size(spc))>=3
                spc = flip(spc,3);
            else
                spc = flip(spc,1);
            end
        end
        
    end
    
end