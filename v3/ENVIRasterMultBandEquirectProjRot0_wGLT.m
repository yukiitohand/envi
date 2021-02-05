classdef ENVIRasterMultBandEquirectProjRot0_wGLT < ENVIRasterMultBandEquirectProjRot0
    % ENVIRasterMultBandEquirectProjRot0_wGLT
    %   Combine HSIdata with GLTdata
    %  Properties
    %   RGBProjImage: class object of RGBImage
    %   ENVIRaster: class object of HSI
    %   GLTdata: class object of HSI
    
    properties
        RasterSource
        GLTdata
    end
    
    methods
        function obj = ENVIRasterMultBandEquirectProjRot0_wGLT(objRaster,...
                objGLT,varargin)
            obj@ENVIRasterMultBandEquirectProjRot0('','',varargin{:});
            obj.RasterSource = objRaster;
            obj.GLTdata = objGLT;
            obj.proj_info = objGLT.proj_info;
            obj.set_dummy_hdr();
        end
        
        function set_dummy_hdr(obj)
            obj.hdr = obj.GLTdata.hdr;
            obj.hdr.data_type  = obj.RasterSource.hdr.data_type;
            obj.hdr.byte_order = obj.RasterSource.hdr.byte_order;
            obj.hdr.bands      = obj.RasterSource.hdr.bands;
            obj.hdr  = rmfield(obj.hdr,'band_names');
            if isfield(obj.RasterSource.hdr,'wavelength')
                obj.hdr.wavlength = obj.RasterSource.hdr.wavelength;
            end
            if isfield(obj.RasterSource.hdr,'wavelength_unit')
                obj.hdr.wavlength_unit = obj.RasterSource.hdr.wavelength_unit;
            end
        end
        
        function [img_proj] = readimg(obj,varargin)
            [img] = obj.RasterSource.readimg(varargin{:});
            [img_proj] = img_proj_w_glt(img,obj.GLTdata);
            if nargout<1
                obj.img = img;
                obj.is_img_band_inverse = false;
            end
        end
        
        function [spc,xf,yf] = lazyEnviRead(obj,s,l,varargin)
            xf = obj.GLTdata.img(l,s,1); yf = obj.GLTdata.img(l,s,2);
            if obj.isValid_sampleline(xf,yf)
                spc = obj.RasterSource.lazyEnviRead(xf,yf,varargin{:});
            else
                spc = [];
            end
        end
        
        function [spc,xf,yf] = lazyEnviReadi(obj,s,l,varargin)
            [spc,xf,yf] = obj.lazyEnviRead(s,l,varargin{:});
            spc = flip(spc,3);
        end
        
        function [imb_proj] = lazyEnviReadb(obj,b,varargin)
            [imb] = obj.RasterSource.lazyEnviReadb(b,varargin{:});
            [imb_proj] = img_proj_w_glt(imb,obj.GLTdata);
        end
        
        function [imb_proj] = lazyEnviReadbi(obj,b,varargin)
            b = obj.hdr.bands-b+1;
            [imb_proj] = obj.lazyEnviReadb(b,varargin{:});
        end
        
        function lazyEnviReadc(varargin)
            error('lazyEnviReadc is Undefined.');
        end
        
        function lazyEnviReadci(varargin)
            error('lazyEnviReadc is Undefined.');
        end
        
        function lazyEnviReadl(varargin)
            error('lazyEnviReadl is Undefined.');
        end
        
        function lazyEnviReadli(varargin)
            error('lazyEnviReadl is Undefined.');
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
            
            if length(xrange)~=2 || length(yrange)~=2
                error('Either the size of xrange or yrange is invalid');
            end
            
            if xrange(1)>xrange(2) || yrange(1)>yrange(2)
                error('Either of the range is not in the right order');
            end
            samplesc = xrange(2)-xrange(1)+1;
            linesc = yrange(2)-yrange(1)+1;
            bandsc = zrange(2)-zrange(1)+1; % band_offset = zrange(1)-1;
            subimg = nan(linesc,samplesc,bandsc);
            for yi=1:linesc
                for xi=1:samplesc
                    x=xrange(1)+xi-1; y=yrange(1)+yi-1;
                    xf = obj.GLTdata.img(y,x,1);
                    yf = obj.GLTdata.img(y,x,2);
                    [subimg(yi,xi,:)] = ...
                        obj.RasterSource.get_subimage_wPixelRange(...
                        [xf xf],[yf yf],zrange,varargin{:});
                end
            end
        end
        
        function [] = set_rgb(obj,varargin)
            rgb_bands_tmp = obj.RasterSource.hdr.default_bands;
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
        
        function [spc,wv,bdxes,xf,yf] = get_spectrum(obj,s,l,varargin)
            ave_wndw_domain = 'PROJECTIVE';
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                varargin_rmIdx = [];
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})                        
                        case 'AVERAGE_WINDOW_DOMAIN'
                            ave_wndw_domain = varargin{n+1};
                            varargin_rmIdx = [varargin_rmIdx n n+1];
                    end
                end
                varargin_retIdx = setdiff(1:length(varargin),varargin_rmIdx);
                varargin = varargin(varargin_retIdx);
            end
            
            switch upper(ave_wndw_domain)
                case 'PROJECTIVE'
                    xf = obj.GLTdata.img(l,s,1);
                    yf = obj.GLTdata.img(l,s,2);
                    if obj.isValid_sampleline(xf,yf)
                        [spc,wv,bdxes] = ...
                            get_spectrum_ENVIRasterMultBandEquirectProjRot0_wGLT(...
                            obj,s,l,varargin{:});
                    else
                        spc = []; wv = []; bdxes = [];
                    end
                    
                case 'SOURCE'
                    xf = obj.GLTdata.img(l,s,1);
                    yf = obj.GLTdata.img(l,s,2);
                    if obj.isValid_sampleline(xf,yf)
                        [spc,wv,bdxes] = ...
                            obj.RasterSource.get_spectrum(s,l,varargin{:});
                    else
                        spc = []; wv = []; bdxes = [];
                    end
                otherwise
                    error('Undefined AVERAGE_DOMAIN %s',ave_wndw_domain);
            end
            
        end
        function [spc,wv,bdxes,xf,yf] = get_spectrumi(obj,s,l,varargin)
            [spc,wv,bdxes,xf,yf] = obj.get_spectrum(s,l,varargin{:});
            bdxes = flip(obj.hdr.bands-flip(bdxes)+1);
            if numel(size(spc))>=3
                spc = flip(spc,3);
            else
                spc = flip(spc,1);
            end
            if ~isempty(wv)
                if isvector(wv)
                    wv = flip(wv); 
                elseif ismatrix(wv)
                    wv = flip(wv,1);
                elseif ndims(wv)==3
                    wv = flip(wv,3);
                end
            end
        end
        
    end
end