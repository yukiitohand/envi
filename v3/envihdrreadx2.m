function hdr = envihdrreadx2(hdrpath)
% ENVIHDRREAD Reads header of ENVI image.
%   hdr = ENVIHDRREAD('HDR_FILE') reads the ASCII ENVI-generated image
%   header file and returns all the information in a structure of
%   parameters.
%
%   Example:
%   >> info = envihdrread('my_envi_image.hdr')
%   info =
%          description: [1x101 char]
%              samples: 658
%                lines: 749
%                bands: 3
%        header_offset: 0
%            file_type: 'ENVI Standard'
%            data_type: 4
%           interleave: 'bsq'
%          sensor_type: 'Unknown'
%           byte_order: 0
%             map_info: [1x1 struct]
%      projection_info: [1x102 char]
%     wavelength_units: 'Unknown'
%           pixel_size: [1x1 struct]
%           band_names: [1x154 char]
%
%   NOTE: This function is used by ENVIREAD to import data.

% Ian M. Howat, Applied Physics Lab, University of Washington
% ihowat@apl.washington.edu
% Version 1: 19-Jul-2007 00:50:57
% Modified by Felix Totir

% Commented out below. It is case insensitive already 10/10/2017
% if ~exist(hdrfile,'file')
%     [pathstr,bname,ext] = fileparts(hdrfile);
%     hdrfile_candidates = [bname ext];
%     hdrfname = findfilei(hdrfile_candidates,pathstr);
%     if isempty(hdrfname)
%         error('File does not exist. Check the file path\n %s',hdrfile);
%     else
%         hdrfile = joinPath(pathstr,hdrfname);
%     end
% end

cmout = '^;.*$'; % added by Yuki for read commented out parameters
fid = fopen(hdrpath);
while true
    line = fgetl(fid);
    if line == -1
        break
    else
        if ~isempty(regexp(line,cmout))
            line = line(2:end);
        end
        eqsn = findstr(line,'=');
        if ~isempty(eqsn)
            param = strtrim(line(1:eqsn-1));
            param(findstr(param,':')) = '_';
            param(findstr(param,' ')) = '_';
            param(findstr(param,'(')) = '';
            param(findstr(param,')')) = '';
            param(findstr(param,'/')) = '';
            value = strtrim(line(eqsn+1:end));
            if isempty(str2num(value))
                if ~isempty(findstr(value,'{')) && isempty(findstr(value,'}'))
                    while isempty(findstr(value,'}'))
                        line = fgetl(fid);
                        value = [value,strtrim(line)];
                    end
                end
                hdr.(param)=value;
                % edited by Yuki below
%                 eval(['info.',param,' = ''',value,''';'])
            elseif strcmp(param,'cat_crism_obsid')
                % added by Yuki on May 31 2017
                hdr.(param) = value;
            elseif strcmp(param,'cat_sclk_start')
                % added by Yuki on May 31 2017
                hdr.(param) = value;
            else
                hdr.(param) = str2num(value);
            end
        end
    end
end
fclose(fid);

if isfield(hdr,'band_names')
    line = hdr.band_names;
    line = line(2:end-1);
    line = strsplit(line,',');
    for i=1:length(line)
        line{i} = strtrim(line{i});
    end
    hdr.band_names = line;
end
if isfield(hdr,'spectra_names')
    line = hdr.spectra_names;
    line = line(2:end-1);
    line = strsplit(line,',');
    for i=1:length(line)
        line{i} = strtrim(line{i});
    end
    hdr.spectra_names = line;
end
if isfield(hdr,'map_info')
    line = hdr.map_info;
    line(line == '{' | line == '}') = [];
    
    %originally: line = strtrim(split(line,','));
    %replaced by
    line=textscan(line,'%s','Delimiter',','); %behavior is not quite the same if "line" ends in ','
    % the above line is modified by Yuki.
    line=line{:};
    line=strtrim(line);
    %
    
    map_info = [];
    map_info.projection = line{1};
    map_info.image_coords = [str2num(line{2}),str2num(line{3})];
    map_info.mapx = str2num(line{4});
    map_info.mapy = str2num(line{5});
    map_info.dx  = str2num(line{6});
    map_info.dy  = str2num(line{7});
    if length(line) == 9
        map_info.datum  = line{8};
        map_info.units  = line{9}(7:end);
    elseif length(line) == 11
        map_info.zone  = str2num(line{8});
        map_info.hemi  = line{9};
        map_info.datum  = line{10};
        map_info.units  = line{11}(7:end);
    end
    hdr.map_info = map_info;
    %
end

if isfield(hdr,'coordinate_system_string')
    hdr.coordinate_system_struct = wkt2struct(...
        hdr.coordinate_system_string(2:end-1));
end

if isfield(hdr,'pixel_size')
    line = hdr.pixel_size;
    line(line == '{' | line == '}') = [];
    
    %originally: line = strtrim(split(line,','));
    %replaced by:
    line=textscan(line,'%s',','); %behavior is not quite the same if "line" ends in ','
    line=line{:};
    line=strtrim(line);
    
    hdr.pixel_size = [];
    hdr.pixel_size.x = str2num(line{1});
    hdr.pixel_size.y = str2num(line{2});
    hdr.pixel_size.units = line{3}(7:end);
end

if isfield(hdr,'wavelength')
    % info.wavelength = sscanf(info.wavelength(2:end-1),'%f,')';
    % strip the curly bracket
    hdr.wavelength = envihdr_testsplit_numeric_array(hdr.wavelength);
end

if isfield(hdr,'fwhm')
    % info.fwhm = sscanf(info.fwhm(2:end-1),'%f,')';
    hdr.fwhm = envihdr_testsplit_numeric_array(hdr.fwhm);
end

if isfield(hdr,'default_bands')
    % info.default_bands = sscanf(info.default_bands(2:end-1),'%d,')';
    hdr.default_bands = envihdr_testsplit_numeric_array(hdr.default_bands);
end

if isfield(hdr,'bbl')
    % info.bbl = sscanf(info.bbl(2:end-1),'%d,')';
    hdr.bbl = envihdr_testsplit_numeric_array(hdr.bbl);
end

% function split is only used when replacements above do not work
% function A = split(s,d)
%This function by Gerald Dalley (dalleyg@mit.edu), 2004
% A = {};
% while (~isempty(s))
%     [t,s] = strtok(s,d);
%     A = {A{:}, t};
% end
end

function [numar] = envihdr_testsplit_numeric_array(str_numar)
str_numar = regexpi(str_numar,'^\s*\{\s*(?<wv_content>.*)\s*\}\s*$','names');
str_numar = [str_numar.wv_content ','];
ptrn_array = '\s*(?<element>[^,]*)\s*,';
value = regexpi(str_numar,ptrn_array,'names');
value = {value.element};
value = str2double(value);
numar = value;
end