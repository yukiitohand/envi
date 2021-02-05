function [radii] = mars_get_radii(opt)
% [radii] = mars_get_radii(opt)
%  get radii parameter for mars
%  INPUTS
%   opt: {'Sphere','Ellipsoid'}
%  OUTPUTS
%   radii: 'Sphere'    -> 3396190.0
%          'Ellipsoid' -> [3396190.0 3376200.0]

switch upper(opt)
    case 'SPHERE'
        radii = 3396190.0;
    case 'ELLIPSOID'
        radii = [3396190.0 3376200.0];
    otherwise
        error('Undefined opt: %s',opt);
end

end