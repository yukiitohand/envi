function [wktinfo] = wkt2struct(wkt_str)
% [wktinfo] = wkt2struct(wkt_str)
%  read wkt string and arrange its contents into struct
% INPUTS
%   wkt_str: char array, 
% OUTPUTS
%   wktinfo: struct, storing information in WKT
%

wktinfo = struct;


LevSup = {}; LevCur = '';
j=1;
while j<length(wkt_str)
    % a keyword or value between the (j-1)th separators and the jth
    % separators are picked up.
    j_strt = j;
    % val = wkt_str(j);
    if strcmp(wkt_str(j),'"')
        j=j+1;
        while ~strcmp(wkt_str(j),'"')
            % val = [val wkt_str(j)];
            j=j+1;
        end
        j_end = j;
        j=j+1;
    else
        while ~any(strcmp(wkt_str(j),{'[',']',','}))
            % val = [val wkt_str(j)];
            j=j+1;
        end
        j_end = j-1;
    end
    val = wkt_str(j_strt:j_end);
    % any control characters such as newline codes are removed.
    tf = isstrprop(val, 'cntrl');
    val = strip(val(~tf),'"');
    
    switch wkt_str(j_end+1) % seprator after the current value
        case '['
            if ~isempty(LevCur)
                LevSup = [LevSup {LevCur} {{idxLevCur}}];
            end
            idxLevCur  = 1;
            nc = 1;
            LevCur = val;
            if ~isempty(LevSup)
                g = getfield(wktinfo,LevSup{:});
                if isfield(g,LevCur)
                    idxLevCur = length(g.(LevCur))+1;
                    flds = fieldnames(g.(LevCur));
                    input_structs = cell(1,length(flds)*2);
                    input_structs(1:2:end) = flds;
                    wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},struct(input_structs{:}));
                else
                    wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},struct);
                end
            else
                wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},struct);
            end
        case ','
            switch wkt_str(j_strt-1) % seprator before the current value
                case '['
                    wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},'name',val);
                case ','
                    val_nume = str2double(val);
                    if isnan(val_nume)
                        val = {val};
                    else
                        val = val_nume;
                    end
                    g = getfield(wktinfo,LevSup{:},LevCur,{idxLevCur});
                    if ~isfield(g,'value') || (isfield(g,'value') && isempty(g.value))
                        wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},'value',val);
                    else
                        wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},'value',{nc},val);
                    end
                    nc = nc+1;
            end
        case ']'
            switch wkt_str(j_strt-1) % seprator before the current value
                case '['
                    wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},'name',val);
                    nc = nc+1;
                case ','
                    val_nume = str2double(val);
                    if isnan(val_nume)
                        val = {val};
                    else
                        val = val_nume;
                    end
                    g = getfield(wktinfo,LevSup{:},LevCur,{idxLevCur});
                    if ~isfield(g,'value') || (isfield(g,'value') && isempty(g.value))
                        wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},'value',val);
                    else
                        wktinfo = setfield(wktinfo,LevSup{:},LevCur,{idxLevCur},'value',{nc},val);
                    end
                    nc = nc+1;
            end
            if ~isempty(LevSup)
                idxLevCur = LevSup{end}{1};
                LevCur = LevSup{end-1};
                LevSup = LevSup(1:end-2);
            end

    end
    j=j+1;
end
