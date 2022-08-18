function [wkt_str] = struct2wkt(wktinfo)


wkt_str = '';
for k=1:length(wktinfo)
    flds = fieldnames(wktinfo(k));
    for i=1:length(flds)
        fld = flds{i};
        for j=1:length(wktinfo.(fld))
            switch lower(fld)
                case 'name'
                    str = ['"' fld '"'];
                case 'value'
                    for l=1:length()
                        
                    end
                otherwise
                    wkt_str = [wkt_str sprintf('%s[',fld)];
                    
            end
                    
            if j<length(wktinfo.(fld))
                wkt_str = [wkt_str ','];
            end     

        end
    end
end


end