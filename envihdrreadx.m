function info = envihdrreadx(hdrfile)
% ENVIHDRREAD Reads header of ENVI image.
%   INFO = ENVIHDRREAD('HDR_FILE') reads the ASCII ENVI-generated image
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
fid = fopen(hdrfile);
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
                info.(param)=value;
                % edited by Yuki below
%                 eval(['info.',param,' = ''',value,''';'])
            elseif strcmp(param,'cat_crism_obsid')
                % added by Yuki on May 31 2017
                info.(param) = value;
            elseif strcmp(param,'cat_sclk_start')
                % added by Yuki on May 31 2017
                info.(param) = value;
            else
                info.(param) = str2num(value);
            end
        end
    end
end
fclose(fid);

if isfield(info,'band_names')
    line = info.band_names;
    line = line(2:end-1);
    line = strsplit(line,',');
    for i=1:length(line)
        line{i} = strtrim(line{i});
    end
    info.band_names = line;
end
if isfield(info,'spectra_names')
    line = info.spectra_names;
    line = line(2:end-1);
    line = strsplit(line,',');
    for i=1:length(line)
        line{i} = strtrim(line{i});
    end
    info.spectra_names = line;
end
if isfield(info,'map_info')
    line = info.map_info;
    line(line == '{' | line == '}') = [];
    
    %originally: line = strtrim(split(line,','));
    %replaced by
    line=textscan(line,'%s','Delimiter',','); %behavior is not quite the same if "line" ends in ','
    % the above line is modified by Yuki.
    line=line{:};
    line=strtrim(line);
    %
    
    info.map_info = [];
    info.map_info.projection = line{1};
    info.map_info.image_coords = [str2num(line{2}),str2num(line{3})];
    info.map_info.mapx = str2num(line{4});
    info.map_info.mapy = str2num(line{5});
    info.map_info.dx  = str2num(line{6});
    info.map_info.dy  = str2num(line{7});
    if length(line) == 9
        info.map_info.datum  = line{8};
        info.map_info.units  = line{9}(7:end);
    elseif length(line) == 11
        info.map_info.zone  = str2num(line{8});
        info.map_info.hemi  = line{9};
        info.map_info.datum  = line{10};
        info.map_info.units  = line{11}(7:end);
    end
    
    %part below comes form the original enviread
    %% Make geo-location vectors
    xi = info.map_info.image_coords(1);
    yi = info.map_info.image_coords(2);
    xm = info.map_info.mapx;
    ym = info.map_info.mapy;
    %adjust points to corner (1.5,1.5)
    if yi > 1.5
        ym =  ym + ((yi*info.map_info.dy)-info.map_info.dy);
    end
    if xi > 1.5
        xm = xm - ((xi*info.map_info.dy)-info.map_info.dx);
    end
    
    info.x= xm + ((0:info.samples-1).*info.map_info.dx);
    info.y = ym - ((0:info.lines-1).*info.map_info.dy);
end

if isfield(info,'pixel_size')
    line = info.pixel_size;
    line(line == '{' | line == '}') = [];
    
    %originally: line = strtrim(split(line,','));
    %replaced by:
    line=textscan(line,'%s',','); %behavior is not quite the same if "line" ends in ','
    line=line{:};
    line=strtrim(line);
    
    info.pixel_size = [];
    info.pixel_size.x = str2num(line{1});
    info.pixel_size.y = str2num(line{2});
    info.pixel_size.units = line{3}(7:end);
end

if isfield(info,'wavelength')
    % info.wavelength = sscanf(info.wavelength(2:end-1),'%f,')';
    % strip the curly bracket
    info.wavelength = envihdr_testsplit_numeric_array(info.wavelength);
end

if isfield(info,'fwhm')
    % info.fwhm = sscanf(info.fwhm(2:end-1),'%f,')';
    info.fwhm = envihdr_testsplit_numeric_array(info.fwhm);
end

if isfield(info,'default_bands')
    % info.default_bands = sscanf(info.default_bands(2:end-1),'%d,')';
    info.default_bands = envihdr_testsplit_numeric_array(info.default_bands);
end

if isfield(info,'bbl')
    % info.bbl = sscanf(info.bbl(2:end-1),'%d,')';
    info.bbl = envihdr_testsplit_numeric_array(info.bbl);
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