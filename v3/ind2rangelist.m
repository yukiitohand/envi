function [rangelist] = ind2rangelist(indices)
% [rngs] = ind2ranges(indices)
%  Convert direct indices to range-based representation. The list of direct
%  indices are divided at discontinuities and grouped into the sets of
%  continuous indexes. Each continous range is represented by [start end] 
%  indexes, and stacked in the row direction. 
%  INPUTS
%    indices: 1-dimensional list of indices.
%  OUTPUTS
%    range_list: 2 column array whose ith row of which represents 
%    [start, end] indices of the ith set of continous indices.
%

indices = indices(:);
indices_diff = indices(2:end) - indices(1:end-1);
range_bounds = find(indices_diff>1);

rangelist = [ [indices(1);indices(range_bounds+1)],[indices(range_bounds);indices(end)] ];


end