function [data,lgnd_clmns] = enviPlotFileRead(fpath)
% Read Plot file saved with ENVI in the ascii format
%  Input Parameters
%    fpath: file path to the file
%  Output Parameters
%    data: numeric array, stored in the text file
%    lgnd_clmns: cell array, storing the name of each column.
%  
% Read something like:
%
% ENVI ASCII Plot File [Wed May 16 01:11:54 2018]
% Column 1: Wavelength
% Column 2: c1rs38.txt:C2~~1
% Column 3: bir1sr076a.txt:C2~~3
% Column 4: bkr1sr076.txt:C2~~4
% Column 5: bkr1sr076a.txt:C2~~5
% Column 6: c1sr76.txt:C2~~7
% Column 7: cape50.txt:C2~~9
% Column 8: nasb66.txt:C2~~12
%   1.021000  0.201456  0.282651  0.195874  0.480627  0.195874  0.502875  0.164182
%   1.027550  0.199727  0.282294  0.196228  0.480542  0.196228  0.502908  0.163839
%   1.034100  0.198506  0.282113  0.196487  0.480883  0.196487  0.502141  0.164092
%   1.040650  0.197693  0.282071  0.196793  0.481383  0.196793  0.501088  0.164622

ptrn_headerdesc = '^\s*ENVI ASCII Plot File.*\s*$';
ptrn_legend = '^\s*Column\s*(?<column>[\d]+)\s*:\s*(?<name>.+)\s*$';
ptrn_blankline = '^\s*$';

fp = fopen(fpath,'r');

% read description in the header
headerdesc_fin = false;
while ~headerdesc_fin
    tline = fgetl(fp);
    headerdesc_fin  =  regexpi(tline,ptrn_headerdesc,'ONCE');
end

% read columns
lgnd_clmns = {};
headerlgnd_fin = false;
while ~headerlgnd_fin
    tline = fgetl(fp);
    lgnd_match  =  regexpi(tline,ptrn_legend,'names');
    if isempty(lgnd_match)
        if isempty(regexpi(tline,ptrn_blankline,'once'))
            % skip any blankline
            headerlgnd_fin = true;
        end
    else
        column_id = str2num(lgnd_match.column);
        lgnd_clmns{column_id} = lgnd_match.name;
    end
end

formatSpec_cell = cell(1,length(lgnd_clmns));
formatSpec_cell(:) = {'%f'};
formatSpec = strjoin(formatSpec_cell);

data_firstline = sscanf(tline,formatSpec);
data = fscanf(fp,formatSpec,[length(lgnd_clmns),inf]);

data = cat(2,data_firstline,data);
data = data';
    
    
end