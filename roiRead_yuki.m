function ROIs = roiRead_yuki(roiFile,varargin)
% FUNCTION ROIs = roiRead_yuki(roiFile)
% This funciton reads in an ENVI ROI file and outputs a Struct of ROI
% information.
%    Parameters:
%       roiFile: file path to the roi ascii file (not *.roi binary!)
%    Optional parameters:
%       'MAPPADDINGVALUE': padding value for ROIs.MAP
%                          (default) nan
%    Outputs:
%       ROIs: a struct of ROIs containing fields:-
%
% number of ROIs     ROIs.NumROI                   (scalar)
% Image dimensions   ROIs.ImageDim                 (vector) [lines,sample]
% Number of bands    ROIs.nBand                    (scalar)
% ROIs Name:         ROIs.Name{'ROI Number'}       (Chars)
% ROIs Color:        ROIs.Color('ROI Number',:)    (vector)
% ROIs Num Points:   ROIs.NumPoints('ROI Number')  (scalar)
% ROIs records:      ROIs.Records                  (Cell)
% ROIs Data:         ROIs.Points                   (Cell of structs)
%                                                  fields:
%                                                  ID,X,Y,Spectrum
% ROIs Map:          ROIs.Map                      (matrix)
%                                                  [lines, sample, NumROI]
% ROIs Map padding   ROIs.MapPaddingValue          (scalar)
%
%--------------------------------------------------------------------------
% Additional notes (Modification by Yuki Itoh, Jan. 21,2016)
% The additional field 'MapPaddingValue' is added. The padding value of the
% map is now controlled via an optional parameter called 'MAPPADDINGVALUE'
%
% Additional notes (Modification by Yuki Itoh, Jan. 20, 2016)
% 
% Major changes
% 1. The two new fields are added: 'ImageDim' and 'Map'
% 2. The format of the field 'Points' has been changed
%
% 'ImageDim' stores the size of the image on which ROIs are used. 
% The vector is 1x2 and the order is [lines, samples]. 
% 
% 'Map' stores the IDs of the ROI of each class in the 2-D image. The
% image size is defined by the ROIs.ImageDim and zeros are padded to pixels
% outside of the ROIs. 
% The size of ROIs.Map is [lines, samples, number of ROIs]. The map for
% each ROI is concatenated along the 3rd dimension.
%
% Each of the 'Points' has four fields: ID, X, Y, and Spectrum. 
% The Lat/Lon information is currently not supported. 
% Spectrum has the size of [d x 1] where d is the number of bands. 
%
%
%--------------------------------------------------------------------------
%
% Descritption in the original roiRead
% http://www.mathworks.com/matlabcentral/fileexchange/27492-envi-roi-file-reader
%
%--------------------------------------------------------------------------
% 
% The data in each cell of the struct is as outlined above.  The matrix is
% of size # of bands plus the ID number, and (X,Y) coordinates (maybe including Lat,Lon and so on)
% by the number of points in the ROIs.
%
% Note that this funcion assumes a strict formatting standard for the ROI
% file.  IT IS DESIGNED TO ONLY WORK ON THE ENVI ROI FILES SAVED IN ASCII 
% FORMAT.  The ROI points must follow immediately after the last ROI
% information line in the file top matter.  A more robust algorithm will 
% test for the start of the ROI points so as to avoid strict formatting 
% errors.  
%
% Written by Jared Herweg, Rochester Institute of Technology, May 2010
% jxh6389@rit.edu
% 

% MODIFICATION HISTORY:
%   Written by Jared Herweg
%   4 May 2010    Origional Code
%   9 March 2012  Yang Li,Beijing Normal University in China
%                   Added ability to handle ROI's from geo-tagged imagery
%                   and optimized improvements
%   15 Mar 2012 Jared Herweg, Rochester Institute of Technology, USA
%                   Cleaned up code for additional readability and 
%                   function.
%   14 Jun 2012 Jared Herweg, Rochester Institute of Technology, USA
%                   Added a check for blank lines in the ROI file saved on
%                   a machine with a Microsoft Windows OS.
% 
% Copyright (c) 2010-2012, Jared Herweg
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%   - Redistributions of source code must retain the above copyright 
%     notice, this list of conditions and the following disclaimer.
% 
%   - Redistributions in binary form must reproduce the above copyright 
%     notice, this list of conditions and the following disclaimer in the 
%     documentation and/or other materials provided with the distribution.
% 
%   - Neither the name of Rochester Institute of Technology nor the names 
%     of its contributors may be used to endorse or promote products 
%     derived from this software without specific prior written permission.
% 
% DISCLAMER: 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

paddingvalue = nan;

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'MAPPADDINGVALUE'
                paddingvalue = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end;
    end
end



% Open File
    fid = fopen(roiFile);
    
% Get ROI header information
% Initialize Struct
    ROIs = struct('NumROI',[],'ImageDim',[],'nBand',[],'Name',{},...
        'Color',[],'NumPoints',[],'Records',{},'Points',{},...
        'Map',[],'MapPaddingValue',[]);
    % another field 'MapPaddingValue' is added
    % by Yuki Itoh, on Jan. 21, 2015
    % another field 'ImageDim' and 'Map' are added
    % by Yuki Itoh, on Jan. 20, 2015
    ROIs(1).MapPaddingValue = [paddingvalue];
    
    
% Find number of ROIs
    test = []; % test variable for holding current line from text file
    while isempty(test)
        fline = fgetl(fid);
        test = strmatch('; Number of',fline); 
    end
    ROIs(1).NumROI = str2num(strtrim(fline(strfind(fline,':')+1:end)));

% Find dimension of the original image
% added by Yuki Itoh, on Jan. 20, 2015
    test = []; % test variable for holding current line from text file
    while isempty(test)
        fline = fgetl(fid);
        test = strmatch('; File Dimension',fline); 
    end
    ROIs(1).ImageDim = sscanf(fline(strfind(fline,':')+1:end), '%d x %d');
    ROIs(1).ImageDim = [ROIs(1).ImageDim(2) ROIs(1).ImageDim(1)];
    
    
% For each ROI, get associated info
    test = []; % Reinitialize get line test variable
    for count = 1:ROIs.NumROI 
        while isempty(test)
            fline = fgetl(fid);
            test = strmatch('; ROI name',fline);
        end
        ROIName = strtrim(fline(strfind(fline,':')+1:end));
        fline = fgetl(fid);
        if isempty(fline); fline = fgetl(fid); end
        ROIcolor = str2num(strtrim(fline(strfind(fline,'{')+1:end-1)));
        fline = fgetl(fid);
        if isempty(fline); fline = fgetl(fid); end
        ROI_numPts = strtrim(fline(strfind(fline,':')+1:end));
        
        % Dynamically expand struct and assign ROI information to cell
        % fields
        ROIs.Name{count} = ROIName;
        ROIs.Color(count,:) = ROIcolor;
        ROIs.NumPoints(count) = str2num(ROI_numPts);
        test = [];% Reinitialize get line test variable for while loop
    end 
% Get the ROI Points for each ROI
    % Advance to the start of the ROI points
    test = [];% Reinitialize get line test variable for while loop
    while isempty(test)
        fline = fgetl(fid);
        if isempty(fline); fline = fgetl(fid); end
        exp = '[^ \f\n\r\t\v.,:]*';
        teststr = regexp(fline,exp,'match');
        teststr = [teststr{:}];
        test = strcmpi(';ID',teststr(1:3));
    end
    % Get records in ROI
%     ROIsRecordsTmp = regexp(fline,'\s{2,}','split');
    ROIsRecordsTmp = regexp(fline,'\s+','split');
    % edited by Yuki Itoh Jan. 20, 2016
    ROIs.Records = ROIsRecordsTmp(2:end);   
    
    % Set number of fields contained in the ROI database
    % i.e. x, y, map locations, band numbers, etc. (see ROI ASCII file).
    NumRecords = length(ROIs.Records);

    % For each ROI, get the associative ROI points
    % and stor points information into the fields 'Points' and 'Map'
    idx_ids = strncmp('ID',ROIs.Records,1);
    idx_x = strncmp('X',ROIs.Records,1);
    idx_y = strncmp('Y',ROIs.Records,1);
    idx_b = cellfun(@(x) ~isempty(regexp(x,'^B\d+$')),ROIs.Records);
    ROIs.nBand = sum(idx_b);
    for count = 1:ROIs.NumROI
        % modified by Yuki Itoh, Jan. 20 2016
        % 'Points' is a struct composed of four fields:- 
        % 'ID', 'X', 'Y', and 'Spectrum' 
        ROIs.Points{count} = zeros(ROIs.NumPoints(count),NumRecords);
        points = struct('ID',[],'X',[],'Y',[],'nBand',[],'Spectrum',[]);
        map = zeros([ROIs.ImageDim(1),ROIs.ImageDim(2)]);
        map(:,:) = paddingvalue;
        for count2 = 1:ROIs.NumPoints(count)
            fline = fgetl(fid);
            % Windows might add up to two extra lines between ROI fields,
            % so this makes sure the blank lines are skipped.
            if isempty(fline); fline = fgetl(fid); end
            if isempty(fline); fline = fgetl(fid); end
%             ROIs.Points{count}(count2,:) = str2num(fline);
            points_raw = str2num(fline);
            
            points(count2).ID = points_raw(idx_ids);
            points(count2).X = points_raw(idx_x);
            points(count2).Y = points_raw(idx_y);
            points(count2).Spectrum = points_raw(idx_b)';
       
            % store 'ID' information into map format
            map(points(count2).Y,points(count2).X) = points(count2).ID;
            
        end
        ROIs.Map = cat(3,ROIs.Map,map);
        ROIs.Points{count} = points;
        fline = fgetl(fid); % skips the blank line
    end
    
% Close ROI File
    fclose(fid);
end
