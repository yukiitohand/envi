classdef ENVIRasterMultBandEquirectProjRot0 < ENVIRasterMultBand
    
    properties
        proj_info;
    end
     methods
        function obj = ENVIRasterMultBandEquirectProjRot0(...
                basename,dirpath,varargin)
            obj@ENVIRasterMultBand(basename,dirpath,varargin{:});
            if ~isempty(obj.hdr)
                obj.proj_info = envi_get_proj_info_SphereEquirect(obj.hdr);
            end
        end
        
        function [lons] = longitude(obj,varargin)
            if isempty(varargin)
                lons = obj.proj_info.get_longitude(1:obj.hdr.samples);
            elseif length(varargin)==1
                lons = obj.proj_info.get_longitude(varargin{1});
            else
                error('Invalid input');
            end
        end
        
        function [lats] = latitude(obj,varargin)
            if isempty(varargin)
                lats = obj.proj_info.get_latitude(1:obj.hdr.lines);
            elseif length(varargin)==1
                lats = obj.proj_info.get_latitude(varargin{1});
            else
                error('Invalid input');
            end
        end
        
        function [estng] = easting(obj,varargin)
            if isempty(varargin)
                estng = obj.proj_info.get_easting(1:obj.hdr.samples);
            elseif length(varargin)==1
                estng = obj.proj_info.get_easting(varargin{1});
            else
                error('Invalid input');
            end
        end
        
        function [nrthng] = northing(obj,varargin)
            if isempty(varargin)
                nrthng = obj.proj_info.get_northing(1:obj.hdr.lines);
            elseif length(varargin)==1
                nrthng = obj.proj_info.get_northing(varargin{1});
            else
                error('Invalid input');
            end
        end
        
        function [xi] = easting2x(obj,estng)
            xi = obj.proj_info.get_x_wEasting(estng);
        end
        function [xi] = lon2x(obj,lon)
            xi = obj.proj_info.get_x_wlon(lon);
        end
        function [yi] = northing2y(obj,nrthng)
            yi = obj.proj_info.get_y_wNorthing(nrthng);
        end
        function [yi] = lat2y(obj,lat)
            yi = obj.proj_info.get_y_wlat(lat);
        end
        
        % >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        % Following methods are added (2021.06.14)
        % lon/easting ctrranges are the ranges of longitude/easting of 
        % [1 hdr.samples]. (the pixel centers of the most left and right
        % pixels)
        % lat/northing ctrranges are the ranges of latitude/northing of 
        % [1 hdr.lines]. (the pixel centers of the upper and lower most
        % pixels)
        function [lat_range] = get_lat_ctrrange(obj)
            lat_range = obj.latitude([1 obj.hdr.lines]);
        end
        function [lon_range] = get_lon_ctrrange(obj)
            lon_range = obj.longitude([1 obj.hdr.samples]);
        end
        function [estng_range] = get_easting_ctrrange(obj)
            estng_range = obj.easting([1 obj.hdr.samples]);
        end
        function [nrthng_range] = get_northing_ctrrange(obj)
            nrthng_range = obj.northing([1 obj.hdr.lines]);
        end
        function [lat_range,lon_range] = get_latlon_ctrrange(obj)
            lat_range = obj.get_lat_ctrrange();
            lon_range = obj.get_lon_ctrrange();
        end
        function [nrthng_range,estng_range] = get_NE_ctrrange(obj)
            [estng_range]  = obj.get_easting_ctrrange();
            [nrthng_range] = obj.get_northing_ctrrange();
        end
        % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        
        function [subimg,xrange,yrange] = get_subimage_wlatlon(obj,...
                lon_range,lat_range,varargin)
            mrgn = 0;
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                varargin_rmIdx = [];
                for i=1:2:(length(varargin)-1)
                    switch upper(varargin{i})
                        case 'MARGIN'
                            mrgn = varargin{i+1};
                            varargin_rmIdx = [varargin_rmIdx i i+1];
                    end
                end
                varargin_retIdx = setdiff(1:length(varargin),...
                    varargin_rmIdx);
                varargin = varargin(varargin_retIdx);
            end
            [xrange] = obj.proj_info.get_xrange_wlon(lon_range,mrgn);
            [yrange] = obj.proj_info.get_yrange_wlat(lat_range,mrgn);
            s1 = max(1,xrange(1)); send = min(obj.hdr.samples,xrange(2));
            l1 = max(1,yrange(1)); lend = min(obj.hdr.lines,yrange(2));
            xrange = [s1 send]; yrange = [l1 lend];
            
            [subimg] = obj.get_subimage_wPixelRange(xrange,yrange,...
                varargin{:});
        end
        
        %------------------------------------------------------------------
        function [x_im,y_im] = get_xy_fromNE(obj,x_east,y_north)
            % if the (x_im,y_im) is outside of the image, then (nan,nan) is
            % returned.
            [x_im] = obj.easting2x(x_east);
            [y_im] = obj.northing2y(y_north);
            if ~obj.isValid_sampleline(x_im,y_im)
                x_im = nan; y_im = nan;
            end
        end
        function [x_im,y_im] = get_xy_fromlatlon(obj,x_lon,y_lat)
            % if the (x_im,y_im) is outside of the image, then (nan,nan) is
            % returned.
            [x_im] = obj.lon2x(x_lon);
            [y_im] = obj.lat2y(y_lat);
            if ~obj.isValid_sampleline(x_im,y_im)
                x_im = nan; y_im = nan;
            end
        end
        function [east_x_im,north_y_im] = get_NE_fromxy(obj,x_im,y_im)
            east_x_im = obj.easting(x_im);
            north_y_im = obj.northing(y_im);
        end
        
        function [xrnge_east,yrnge_north] = get_pixel_rangeNE_fromxy(obj,x_im,y_im)
            xrnge_east = obj.easting([x_im-0.5 x_im+0.5]);
            yrnge_north = obj.northing([y_im-0.5 y_im+0.5]);
        end
        
        function [xrnge_east,yrnge_north,x_im,y_im] = get_pixel_rangeNE_fromNE(obj,x_east,y_north)
            % evaluate overlapping MSLDEM pixels
            % first evaluate one pixel size
            [x_im,y_im] = obj.get_xy_fromNE(x_east,y_north);
            [xrnge_east,yrnge_north] = obj.get_pixel_rangeNE(x_im,y_im);
        end
        
     end
    
end