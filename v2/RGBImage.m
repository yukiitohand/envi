classdef RGBImage < handle
    % RGBImage class
    %   stores scaled RGB image for viewing in MATLAB
    
    properties
        CData
        CData_Scaled
        CLim
        Tol
    end
    
    methods
        function obj = RGBImage(cdata,varargin)
            tol = 0;
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})                        
                        case 'TOL'
                            tol = varargin{n+1};
                        otherwise
                            error('Unrecognized option: %s', varargin{n});
                    end
                end
            end
            obj.CData = cdata;
            obj.update_tol(tol);
        end
        
        function [] = update_tol(obj,tol)
            [ rgb_stretched,lowhigh ] = im_hard_percentile_thresholding( obj.CData,tol );
            [ rgb_stretched] = im_lstretch(rgb_stretched,lowhigh);
            obj.Tol = tol;
            obj.CData_Scaled = rgb_stretched;
            obj.CLim = lowhigh;
        end

    end
end

