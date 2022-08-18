classdef HSIview_HSIelem < handle
    % HSIview_HSIelem
    %   class handling each component in HSIview
    
    properties
        rgb
        hsi
        bands
        is_bands_inverse
        ave_window
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
        function obj = HSIview_HSIelem(HSIdata,varargin)
            obj.bands = [];
            obj.is_bands_inverse = false;
            obj.ave_window = [1 1];
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
            
            obj.hsi = HSIdata;
            if isa(obj.hsi,'HSI')
                obj.get_spectrum = @obj.get_spectrum_HSI;
                obj.get_hsi_coord = @obj.get_hsi_coord_HSI;
                obj.get_xy_fromNE = @obj.get_xy_fromNE_HSI;
                obj.imszx = HSIdata.hdr.samples;
                obj.imszy = HSIdata.hdr.lines;
            elseif isa(obj.hsi,'HSIdataGLTproj')
                obj.get_spectrum = @obj.get_spectrum_HSIdataGLTproj;
                obj.get_hsi_coord = @obj.get_hsi_coord_HSIdataGLTproj;
                obj.get_xy_fromNE = @obj.get_xy_fromNE_HSIdataGLTproj;
                obj.imszx = HSIdata.GLTdata.hdr.samples;
                obj.imszy = HSIdata.GLTdata.hdr.lines;
            elseif isa(obj.hsi,'MASTCAMMSI')
                obj.get_spectrum = @obj.get_spectrum_MASTCAMMSI;
                obj.get_hsi_coord = @obj.get_hsi_coord_MASTCAMMSI;
                obj.imszx = HSIdata.hdr.samples;
                obj.imszy = HSIdata.hdr.lines;
            else
                error('class %s is not supported for HSIview', class(HSIdata));
            end
            
        end
        
        function [spc,wv,bdxes] = get_spectrum_HSI(obj,s,l)
            [spc,wv,bdxes] = obj.hsi.get_spectrum(s,l,...
                    'BANDS',obj.bands,...
                    'BANDS_INVERSE',obj.is_bands_inverse,...
                    'AVERAGE_WINDOW',obj.ave_window);
            spc = spc + obj.spc_shift;
            if obj.is_bands_inverse
                bdxes = obj.hdr.bands-bdxes+1;
            end
        end
        
        function [spc,wv,bdxes] = get_spectrum_HSIdataGLTproj(obj,s,l)
            [spc,wv,bdxes] = obj.hsi.HSIdata.get_spectrum(s,l,...
                    'BANDS',obj.bands,...
                    'BANDS_INVERSE',obj.is_bands_inverse,...
                    'AVERAGE_WINDOW',obj.ave_window);
            spc = spc + obj.spc_shift;
            if obj.is_bands_inverse
                bdxes = obj.hdr.bands-bdxes+1;
            end
        end
        
        function [spc,wv,bdxes] = get_spectrum_MASTCAMMSI(obj,s,l)
            [spc,wv,bdxes] = obj.hsi.get_spectrum(s,l,...
                    'BANDS',obj.bands,...
                    'BANDS_INVERSE',obj.is_bands_inverse,...
                    'AVERAGE_WINDOW',obj.ave_window);
            spc = spc + obj.spc_shift;
            if obj.is_bands_inverse
                bdxes = obj.hdr.bands-bdxes+1;
            end
        end
        
        function [x_im,y_im] = get_xy_fromNE_HSIdataGLTproj(obj,x_east,y_north)
            [x_im,y_im] = obj.hsi.get_GLTxy_fromNE(x_east,y_north);
        end
        
        function [x_im,y_im] = get_xy_fromNE_HSI(obj,x_east,y_north)
            [x_im,y_im] = obj.hsi.get_xy_fromNE(x_east,y_north);
        end
        
        function [s,l] = get_hsi_coord_HSI(obj,x,y,XY_COORDINATE_SYSTEM)
            switch XY_COORDINATE_SYSTEM
                case 'IMAGEPIXELS'
                    s = x; l = y;
                    if ~obj.hsi.isValid_sampleline(s,l)
                        s = nan; l = nan;
                    end
                case 'NORTHEAST'
                    [s,l] = obj.hsi.get_xy_fromNE(x,y);
                case 'PLANETOCENTRIC'
                    error('Not implemented yet'); 
            end
        end
        
        function [s,l] = get_hsi_coord_HSIdataGLTproj(obj,x,y,XY_COORDINATE_SYSTEM)
            switch XY_COORDINATE_SYSTEM
                case 'NORTHEAST'
                    [s,l,s_proj,l_proj] = obj.hsi.get_hsixy_fromNE(x,y);
                case 'IMAGEPIXELS'
                    if ~obj.hsi.GLTdata.isValid_sampleline(x,y)
                        s = nan; l = nan;
                    else
                        [s,l] = obj.hsi.get_hsixy_fromGLTxy(x,y);
                    end
                case 'PLANETOCENTRIC'
                    error('Not implemented yet');
            end
        end
        
        function [s,l] = get_hsi_coord_MASTCAMMSI(obj,x,y,XY_COORDINATE_SYSTEM)
            switch XY_COORDINATE_SYSTEM
                case 'IMAGEPIXELS'
                    s = x; l = y;
                    % if ~obj.hsi.isValid_sampleline(s,l)
                    %     s = nan; l = nan;
                    % end
                case {'NORTHEAST','PLANETOCENTRIC'}
                    error('Not supported');
            end
        end
        
    end
end

