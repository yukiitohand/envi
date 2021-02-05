classdef ENVIRasterSingleLayerEquirectProjRot0 < ENVIRasterSingleLayer
    
    properties
        proj_info;
    end
     methods
        function obj = ENVIRasterSingleLayerEquirectProjRot0(...
                basename,dirpath,varargin)
            obj@ENVIRasterSingleLayer(basename,dirpath,varargin{:});
            
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
        
     end
    
end