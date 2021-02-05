classdef SphereEquiRectangularProj < handle
    % Projection for the Sphere based equirectangular projection
    % Spherical radius may be customized.
    % MAP rotation is not supported.
    % 
    properties
        % projection information
        name
        radius
        standard_parallel
        center_longitude
        center_latitude
        latitude_of_origin
        longitude_of_origin
        % map information
        latitude_range
        longitude_range
        rdlon          % <PIXELS/DEGREE>
        rdlat          % <PIXELS/DEGREE>
        map_scale_x    % <METERS/PIXEL>
        map_scale_y    % <METERS/PIXEL>
        lon1           % longitude at the sample 1 (westernmost sample)
        lat1           % latitude at the line 1 (most upper line)
        easting1       % easting at the sample 1
        northing1      % northing at the line 1
        Nx
        Ny
    end
    
    methods
        function obj = SphereEquiRectangularProj(varargin)
            %
            obj.name = '';
            obj.radius = [];
            obj.standard_parallel = 0;
            obj.center_longitude  = 0;
            obj.center_latitude = [];
            obj.latitude_of_origin  = 0;
            obj.longitude_of_origin = 0;
            obj.latitude_range  = [];
            obj.longitude_range = [];
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for i=1:2:(length(varargin)-1)
                    switch upper(varargin{i})
                        case 'NAME'
                            obj.name = varargin{i+1};
                        case {'R','RADIUS'}
                            obj.radius = varargin{i+1};
                        case 'STANDARD_PARALLEL'
                            obj.standard_parallel = varargin{i+1};
                        case 'CENTERLONGITUDE'
                            obj.center_longitude = varargin{i+1};
                        case 'CENTERLATITUDE'
                            obj.center_latitude = varargin{i+1};
                        case 'LONGITUDE_OF_ORIGIN'
                            obj.longitude_of_origin = varargin{i+1};
                        case 'LATITUDE_OF_ORIGIN'
                            obj.latitude_of_origin = varargin{i+1};
                        case 'LATITUDE_RANGE'
                            obj.latitude_range = varargin{i+1};
                        case 'LONGITUDE_RANGE'
                            obj.longitude_range = varargin{i+1};
                        otherwise
                            error('Parameter: %s', varargin{i});   
                    end
                end
            end
        end
        
        function [] = set_lat1(obj,lat1)
            obj.lat1 = lat1;
            obj.northing1 = obj.lat2northing(lat1);
            % obj.northing1 = deg2rad(lat1 - obj.latitude_of_origin) ...
            %     .* obj.radius;
        end
        
        function [] = set_lon1(obj,lon1)
            obj.lon1 = lon1;
            obj.easting1 = obj.lon2easting(lon1);
            % obj.easting1 = deg2rad(lon1 - obj.longitude_of_origin) ...
            %     .* obj.radius .* cosd(obj.standard_parallel);
        end
        
        function [] = set_northing1(obj,northing1)
            obj.northing1 = northing1;
            obj.lat1 = obj.northing2lat(northing1);
        end
        
        function [] = set_easting1(obj,easting1)
            obj.easting1 = easting1;
            obj.lon1 = obj.easting2lon(easting1);
        end
        
        function [easting] = get_easting(obj,sidx)
            easting = obj.easting1 + (sidx-1) .* obj.map_scale_x;
        end
        
        function [northing] = get_northing(obj,lidx)
            northing = obj.northing1 - (lidx-1) .* obj.map_scale_y;
        end
        
        function [lat] = get_latitude(obj,lidx)
            lat = obj.lat1 - (lidx-1) ./ obj.rdlat; 
        end
        
        function [lon] = get_longitude(obj,sidx)
            lon = (sidx-1) ./ obj.rdlon + obj.lon1; 
        end
        
        function [lon_range_sub] = get_lon_range(obj,xrange)
            lon_range_sub = obj.get_longitude([xrange(1)-0.5 xrange(2)+0.5]);
        end
        
        function [lat_range_sub] = get_lat_range(obj,yrange)
            lat_range_sub = obj.get_latitude([yrange(1)-0.5 yrange(2)+0.5]);
        end
        
        function [xrange] = get_xrange_wlon(obj,lon_range,mrgn)
            s1   = ceil( (lon_range(1)-obj.longitude_range(1))*obj.rdlon ) - mrgn;
            send = ceil( (lon_range(2)-obj.longitude_range(1))*obj.rdlon ) + mrgn;
            xrange = [s1,send];
        end
        
        function [yrange] = get_yrange_wlat(obj,lat_range,mrgn)
            l1   = ceil( (obj.latitude_range(1)-lat_range(1))*obj.rdlat ) - mrgn;
            lend = ceil( (obj.latitude_range(1)-lat_range(2))*obj.rdlat ) + mrgn;
            yrange = [l1 lend];
        end
        
        function [x] = get_x_wlon(obj,lon)
            x = (lon-obj.lon1) .* obj.rdlon + 1;
        end
        
        function [x] = get_x_wEasting(obj,easting)
            x = (easting-obj.easting1) .* obj.map_scale_x + 1;
        end
        
        function [y] = get_y_wlat(obj,lat)
            y = (obj.lat1-lat) .* obj.rdlat + 1;
        end
        
        function [y] = get_y_wNorthing(obj,northing)
            y = (obj.northing1-northing) .* obj.map_scale_y + 1;
        end
        
        function [lon] = easting2lon(obj,easting)
            lon = obj.longitude_of_origin + ...
                rad2deg(easting / ...
                          ( obj.radius .* cosd(obj.standard_parallel) ) ...
                        );
        end
        
        function [lat] = northing2lat(obj,northing)
            lat = obj.latitude_of_origin + rad2deg(northing/obj.radius);
        end
        
        function [northing] = lat2northing(obj,lat)
            northing = deg2rad(lat - obj.latitude_of_origin) .* obj.radius;
        end
        
        function [easting] = lon2easting(obj,lon)
            easting = deg2rad(lon - obj.longitude_of_origin) ...
                .* obj.radius .* cosd(obj.standard_parallel);
        end
        
        
        
    end
end

