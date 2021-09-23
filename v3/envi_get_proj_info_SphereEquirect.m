function [proj_info] = envi_get_proj_info_SphereEquirect(hdr)
% [proj_info] = envi_get_proj_info_SphereEquirect(hdr)

projcs_name = hdr.coordinate_system_struct.PROJCS.name;

if hdr.coordinate_system_struct.PROJCS.GEOGCS.DATUM.SPHEROID.value(2)~=0
    error('Datum is not spherical, but ellipsoidal.');
end

if ~strcmpi(hdr.coordinate_system_struct.PROJCS.PROJECTION.name,...
        'Equidistant_Cylindrical')
    error('Projection is not equirectangular');
end


latitude_of_origin = 0;
center_latitude    = [];
center_longitude   = [];

radius = hdr.coordinate_system_struct.PROJCS.GEOGCS.DATUM.SPHEROID.value(1);

for i=1:length(hdr.coordinate_system_struct.PROJCS.PARAMETER)
    switch lower(hdr.coordinate_system_struct.PROJCS.PARAMETER(i).name)
        case 'standard_parallel_1'
            standard_parallel = hdr.coordinate_system_struct.PROJCS.PARAMETER(i).value;
        case 'central_meridian'
            longitude_of_origin = hdr.coordinate_system_struct.PROJCS.PARAMETER(i).value;
        case 'central_parallel'
            fprintf('central parallel is currently not working.\n');
            % central_parllel = hdr.coordinate_system_struct.PROJCS.PARAMETER(i).value;
        case 'false_easting'
            false_easting = hdr.coordinate_system_struct.PROJCS.PARAMETER(i).value;
        case 'false_northing'
            false_northing = hdr.coordinate_system_struct.PROJCS.PARAMETER(i).value;
            
    end
end

proj_info = SphereEquiRectangularProj('name',projcs_name,...
    'Radius',radius,...
    'STANDARD_PARALLEL',standard_parallel,...
    'CenterLongitude',center_longitude,...
    'CenterLatitude',center_latitude,...
    'Latitude_of_origin',latitude_of_origin,...
    'Longitude_of_origin',longitude_of_origin);

pixel_size_x = hdr.map_info.dx;
pixel_size_y = hdr.map_info.dy;

cos_stdprll = cosd(standard_parallel);
lat_dstep = pixel_size_y/ (radius*pi) * 180;
lon_dstep = pixel_size_x/ (radius*pi) * 180 / cos_stdprll;

% [1,1] is considered as the center of the most upper left pixel by the 
% class SphereEquiRectangularProj, while in ENVI, [1.5 1.5] is considered 
% as the center of the most upper left pixel. [1 1] is the upper left
% vertex of the upper left most pixel.
easting1  = hdr.map_info.mapx + (1.5-hdr.map_info.image_coords(1))*pixel_size_x;
northing1 = hdr.map_info.mapy - (1.5-hdr.map_info.image_coords(2))*pixel_size_y;

proj_info.rdlat = 1./lat_dstep;
proj_info.rdlon = 1./lon_dstep;
proj_info.map_scale_x = pixel_size_x;
proj_info.map_scale_y = pixel_size_y;
proj_info.set_easting1(easting1);
proj_info.set_northing1(northing1);
lonend = proj_info.get_longitude(hdr.samples);
latend = proj_info.get_latitude(hdr.lines);
proj_info.longitude_range = [proj_info.lon1-0.5*lon_dstep lonend+0.5*lon_dstep];
proj_info.latitude_range  = [proj_info.lat1+0.5*lat_dstep latend-0.5*lat_dstep];



end