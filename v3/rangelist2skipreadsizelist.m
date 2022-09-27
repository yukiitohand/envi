function [skipszlist,readszlist] = rangelist2skipreadsizelist(rangelist)
% [skipszlist,readszlist] = rangelist2skipreadsizelist(rangelist)
%  Convert the range-based representation of indices to skip-read size
%  based representation.
%  INPUTS
%    rangelist: 2 column array whose ith row of which represents 
%    [start, end] indices of the ith set of continous indices of the
%    selected indices.
%  OUTPUTS
%     skipszlist: 1-dim vector, the ith element is the number of indices
%     skipped between the (i-1)th and ith sets of the countinous indices.
%     readszlist: 1-dim vector, the ith element is the number of indices of
%     the set of continous indices.
%

skipszlist = rangelist(:,1) - 1;
skipszlist(2:end) = skipszlist(2:end) - rangelist(1:end-1,2);
readszlist = rangelist(:,2) - rangelist(:,1) + 1;

end
