classdef ENVIRasterMultview_Rasterelem < handle
    % ENVIRasterMultview_Rasterelem
    %   class handling each component in HSIview
    
    properties
        rgb
        Raster
        bands
        is_bands_inverse
        ave_window
        ave_window_domain
        spc_shift
        varargin_plot
        name
        plot_gp_bp
        get_spectrum
        get_hsi_coord
        get_xy_fromNE
        imszx
        imszy
    end
    
    methods
        function obj = ENVIRasterMultview_Rasterelem(rastermb,varargin)
            obj.bands = [];
            obj.is_bands_inverse = false;
            obj.ave_window = [1 1];
            obj.ave_window_domain = [];
            obj.spc_shift = 0;
            obj.varargin_plot = {};
            obj.name = '';
            obj.plot_gp_bp = 0;
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})                        
                        % Plot parameters
                        case 'BANDS'
                            obj.bands = varargin{n+1};
                        case 'BANDS_INVERSE'
                            obj.is_bands_inverse = varargin{n+1};
                        case 'AVERAGE_WINDOW'
                            obj.ave_window = varargin{n+1};
                        case 'AVERAGE_WINDOW_DOMAIN'
                            obj.ave_window_domain = varargin{n+1};
                        case 'SHIFT'
                            obj.spc_shift = varargin{n+1};
                        case 'VARARGIN_PLOT'
                            obj.varargin_plot = varargin{n+1};
                            if ~iscell(obj.varargin_plot)
                                obj.varargin_plot = {obj.varargin_plot};
                            end
                        case {'LEGEND','NAME','IMAGE_NAME'}
                            obj.name = varargin{n+1};
                        otherwise
                            error('Unrecognized option: %s', varargin{n});
                    end
                end
            end
            
                
            if isa(rastermb, 'ENVIRasterMultBandEquirectProjRot0_wGLT') ...
                    && isempty(obj.ave_window_domain)
                obj.ave_window_domain = 'PROJECTIVE';
            end
            
            obj.Raster = rastermb;
            obj.get_hsi_coord = @obj.get_im_coord;
            obj.imszx = rastermb.hdr.samples;
            obj.imszy = rastermb.hdr.lines;
            if isa(obj.Raster, 'ENVIRasterMultBandEquirectProjRot0_wGLT')
                obj.get_spectrum =  @obj.get_spectrum_RasterMultBandEquirectProjRot0_wGLT;
            elseif isa(obj.Raster,'ENVIRasterMultBand') || isa(obj.Raster,'MASTCAMMSI')
                obj.get_spectrum =  @obj.get_spectrum_RasterMultBand;
            else
                error('class %s is not supported for ENVIRasterMultview',...
                    class(rastermb));
            end
            
        end
        
        function [spc,wv,bdxes,spcstr] = get_spectrum_RasterMultBand(obj,s,l)
            [spc,wv,bdxes] = obj.Raster.get_spectrum(s,l,...
                    'BANDS',obj.bands,...
                    'BANDS_INVERSE',obj.is_bands_inverse,...
                    'AVERAGE_WINDOW',obj.ave_window);
            spc = spc + obj.spc_shift;
            if ~isempty(spc)
                spcstr = sprintf('%s X:% 4d, Y:% 4d',obj.name,s,l);
            else
                spcstr = '';
            end
        end
        
        function [spc,wv,bdxes,spcstr] = get_spectrum_RasterMultBandEquirectProjRot0_wGLT(obj,s,l)
            [spc,wv,bdxes,xf,yf] = obj.Raster.get_spectrum(s,l,...
                    'BANDS',obj.bands,...
                    'BANDS_INVERSE',obj.is_bands_inverse,...
                    'AVERAGE_WINDOW',obj.ave_window,...
                    'AVERAGE_WINDOW_DOMAIN',obj.ave_window_domain);
            spc = spc + obj.spc_shift;
            if ~isempty(spc)
                spcstr = sprintf('%s X:% 4d, Y:% 4d (XF:% 4d, YF:% 4d)',obj.name,s,l,xf,yf);
            else
                spcstr = '';
            end
        end
        
        function [s,l] = get_im_coord(obj,x,y,XY_COORDINATE_SYSTEM)
            switch XY_COORDINATE_SYSTEM
                case 'IMAGEPIXELS'
                    s = x; l = y;
                    if ~obj.Raster.isValid_sampleline(s,l)
                        s = nan; l = nan;
                    end
                case 'NORTHEAST'
                    [s,l] = obj.Raster.get_xy_fromNE(x,y);
                case 'LATLON'
                    [s,l] = obj.Raster.get_xy_fromlatlon(x,y);
            end
        end
        
    end
end

