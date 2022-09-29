function [ind] = rangelist2ind(rangelist)
% [[ind] = rangelist2ind(rangelist)
%  Convert range-based representation to direct indices. 
%  INPUTS
%    range_list: 2 column array whose ith row of which represents 
%    [start, end] indices of the ith set of continous indices.
%  OUTPUTS
%    indices: 1-dimensional list of indices.
%

ind = [];
for n=1:size(rangelist,1)
    ind = [ind rangelist(n,1):rangelist(n,2)];
end


end