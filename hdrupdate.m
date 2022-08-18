function [ hdr_new ] = hdrupdate( hdr,varargin )
% [ hdr_new ] = hdrupdate( hdr,varargin )
%   update new or existing fields of hdr

%   Inputs
%      hdr: image header file
%      varargin: any combination of fields and values. the length should be
%      even numbers.
%   Outputs:
%      hdr_new: new header file

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
end

hdr_new = hdr;
if ~isempty(varargin)
    for i=1:2:(length(varargin)-1)
        hdr_new.(varargin{i}) = varargin{i+1};
    end
end

end

