function envihdrwritex(hdr_info,hdrfile,varargin)
% ENVIHDRWRITE read and return ENVI image file header information.
%   INFO = ENVIHDRWRITE(info,'HDR_FILE') writes the ENVI header file
%   'HDR_FILE'. Parameter values are provided by the fields of structure
%   info.
%
%   Example:
%   >> hdr_info = envihdrread('my_envi_image.hdr')
%   hdr_info =
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
%     hdr_info = enviwrite('my_envi_image2.hdr');
%
% Felix Totir

% opt_cmout: added by Yuki on May 31, 2017, to determine if ";" is added to
% the fields outside of the activeFieldList
opt_cmout = true;

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'OPT_CMOUT'
                opt_cmout = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end
    end
end


params=fieldnames(hdr_info);

fid = fopen(hdrfile,'w');
fprintf(fid,'%s\r\n','ENVI');

activeFieldList = {'description','samples','lines','bands','header offset',...
    'file type','data type','interleave','sensor type','byte order',...
    'default bands','wavelength units','data ignore value',...
    'map info','projection info','pixel size',...
    'band names','wavelength','fwhm','bbl','spectra names'};
% the actveFieldList are created by Yuki on Jan. 12, 2015
% envihdrread_yuki.m
% the actveFieldList are updated by Yuki on May 31, 2017
% envihdrread_yuki.m

for idx=1:length(params)
    param = params{idx};
    value = hdr_info.(param);
    param(strfind(param,'_')) = ' '; %automatic name
    
    if strcmpi(param,'description')
        if ischar(value)
            line = [param ' = ' value];
        elseif iscell(value)
            value{1} = [param ' = ' value{1}];
            line = cellfun(@(x) [x '\r\n'],value,'UniformOutput',false);
        end
        
    elseif strcmp(param,'wavelength') || strcmp(param,'fwhm')
        % fwhm is added by Yuki on May 31, 2017
        % output is edited by Yuki on May 31, 2017
        val_str = sprintf('\r\n%13.6f,%13.6f,%13.6f,%13.6f,%13.6f,',value);
        if strcmp(val_str(end),',')
            val_str = val_str(1:end-1);
        end
        val_str = ['{' val_str '}'];
        line=[param,' = ',val_str];
    elseif strcmp(param,'default bands')
        val_str = sprintf('%d,',value);
        val_str = ['{' val_str(1:end-1) '}'];
        line=[param,' = ',val_str];
    elseif strcmp(param,'bbl')
        % bbl is added by Yuki on May 31, 2017
        val_str = '';
        for i=1:length(value)
            if rem(i,25)==1 && i<length(value)
                val_str = [val_str newline];
            end
            val_str = [val_str sprintf('%2d,',value(i))];
        end
        val_str = ['{' val_str(1:end-1) '}'];
        line=[param,' = ',val_str];
    elseif strcmp(param,'band names')
        % this case is added by Yuki Itoh on May 31, 2017
        val_str = newline;
        for i=1:length(value)
            itm_new = value{i};
            if (length(val_str)+length(itm_new)) > 75
                val_str = [val_str sprintf('\r\n %s,',itm_new)];
            else
                val_str = [val_str itm_new ','];
            end
        end
        val_str = ['{' val_str(1:end-1) '}'];
        line=[param,' = ',val_str];
    elseif strcmp(param,'spectra names')
        % this case is added by Yuki Itoh on May 31, 2017
        val_str = newline;
        for i=1:length(value)
            itm_new = value{i};
            if (length(val_str)+length(itm_new)) > 75
                val_str = [val_str sprintf('\r\n %s,',itm_new)];
            else
                val_str = [val_str itm_new];
            end
        end
        val_str = ['{' val_str(1:end-1) '}'];
        line=[param,' = ',val_str];
    elseif strcmp(param,'map info')
        val_str = sprintf('{%s,%d,%d,%2.20f,%2.20f,%1.20e,%1.20e,%s,units=%s}',...
            value.projection,value.image_coords(1),value.image_coords(2),...
            value.mapx,value.mapy,value.dx,value.dy,value.datum,value.units);
        line=[param,' = ',val_str];
    elseif strcmp(param,'projection info')
        line = [param,' = ', value]; 
    elseif any(strcmpi(param,activeFieldList))
        line=[param,' = ',num2str(value)];
    elseif any(strcmpi(param,{'x','y'}))
        line = '';
    elseif strcmp(param,'coordinate system struct')
        
    else
        if isnumeric(value) && ~isscalar(value)
            if all(value==floor(value))
                val_str = sprintf('%d,',value);
            else
                val_str = sprintf('%f,',value);
            end
            val_str = ['{' val_str(1:end-1) '}'];
            line=[param,' = ',val_str];
            if opt_cmout % added by Yuki on May 31, 2017
                line=[';' line];
            end
        else
            line=[param,' = ',num2str(value)];
            if opt_cmout % added by Yuki on May 31, 2017
                line=[';' line];
            end
        end
    end
    % the cases are created by Yuki Jan. 12, 2015 for customized
    % envihdrread_yuki.m
    if ~isempty(line)
        if ischar(line)
            fprintf(fid,'%s\r\n',line);
        elseif iscell(line)
            cellfun(@(x) fprintf(fid,x),line,'UniformOutput',false);
        end
    end
    
end

fclose(fid);

