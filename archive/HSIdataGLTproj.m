classdef HSIdataGLTproj < handle
    % HSIdataGLTproj
    %   Combine HSIdata with GLTdata
    %  Properties
    %   RGBProjImage: class object of RGBImage
    %   HSIdata: class object of HSI
    %   GLTdata: class object of HSI
    %   bands_rgb: 1x3 array specifying the RGB bands.
    
    properties
        RGBProjImage
        HSIdata
        GLTdata
        bands_rgb
    end
    
    methods
        function obj = HSIdataGLTproj(obj_hsidata,obj_gltdata,varargin)
            if isfield(obj_hsidata.hdr,'default_bands') && ~isempty(obj_hsidata.hdr.default_bands)
                bands_rgb_tmp = obj_hsidata.hdr.default_bands;
            end
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
            obj.HSIdata = obj_hsidata;
            obj.GLTdata = obj_gltdata;
            if ~isempty(bands_rgb_tmp)
                obj.proj_rgb('BANDS',bands_rgb_tmp,'TOLRGB',tolrgb);
            end
            obj.bands_rgb = bands_rgb_tmp;
        end
        
        function [] = proj_rgb(obj,varargin)
            if isfield(obj.HSIdata.hdr,'default_bands') && ~isempty(obj.HSIdata.hdr.default_bands)
                bands_rgb_tmp = obj.HSIdata.hdr.default_bands;
            end
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
            [ProjRGBdata] = crism_proj_w_glt_v2(obj.HSIdata,obj.GLTdata,'Bands',bands_rgb_tmp);
            obj.RGBProjImage = RGBImage(ProjRGBdata.img,'Tol',tolrgb);
            obj.bands_rgb = bands_rgb_tmp;
        end
        
        function [x_hsi,y_hsi,x_glt,y_glt] = get_hsixy_fromNE(obj,x_east,y_north)
            [x_glt,y_glt] = obj.get_GLTxy_fromNE(x_east,y_north);
            if isnan(x_glt) || isnan(y_glt)
                x_hsi = nan; y_hsi = nan;
            else
                [x_hsi,y_hsi] = obj.get_hsixy_fromGLTxy(x_glt,y_glt);
            end
        end
        
        function [x_hsi,y_hsi] = get_hsixy_fromGLTxy(obj,x_glt,y_glt)
            x_hsi = obj.GLTdata.img(y_glt,x_glt,1);
            y_hsi = obj.GLTdata.img(y_glt,x_glt,2);
            if ~obj.HSIdata.isValid_sampleline(x_hsi,y_hsi)
                x_hsi = nan; y_hsi = nan; 
            end
        end

        function [x_glt,y_glt] = get_GLTxy_fromNE(obj,x_east,y_north)
            [x_glt,y_glt] = obj.GLTdata.get_xy_fromNE(x_east,y_north);
        end
        
        function [east_x_glt,north_y_glt] = get_NE_fromGLTxy(obj,x_glt,y_glt)
            [east_x_glt,north_y_glt] = obj.GLTdata.get_NE_fromxy(x_glt,y_glt);
        end
        
        function [xrnge_east,yrnge_north] = get_pixel_rangeNE_fromGLTxy(obj,x_glt,y_glt)
            % evaluate overlapping MSLDEM pixels
            % first evaluate one pixel size
            [xrnge_east,yrnge_north] = obj.GLTdata.get_pixel_rangeNE_fromxy(x_glt,y_glt);
        end
        
        function [xrnge_east,yrnge_north,x_glt,y_glt] = get_pixel_rangeNE_fromNE(obj,x_east,y_north)
            % evaluate overlapping MSLDEM pixels
            % first evaluate one pixel size
            [xrnge_east,yrnge_north,x_glt,y_glt] = obj.GLTdata.get_pixel_rangeNE_fromNE(x_east,y_north);
        end
        
    end
end