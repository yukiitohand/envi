function [img] = replace_data_ignore_value(img,varargin)
% [img] = replace_data_ignore_value(img,varargin)
%  Replace the data_ignore_value with another,
%  Input Parameters
%    img: [L x C x B]
%  Optional Input Parameters
%    'DATA_IGNORE_VALUE': (default) 65535
%    'REPLACED_IGNORE_VALUE': (default) NaN
%  Output Parameters
%    img: [L x C x B]

data_ignore_value = 65535;
replaced_ignore_value = NaN;

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'DATA_IGNORE_VALUE'
                data_ignore_value = varargin{i+1};
            case 'REPLACED_IGNORE_VALUE'
                replaced_ignore_value = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{i} '''']);
        end
    end
end

img(img==data_ignore_value) = replaced_ignore_value;

end