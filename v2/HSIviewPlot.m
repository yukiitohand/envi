classdef HSIviewPlot < handle
    % HSIviewPlot class
    %   Internal class for handling the plot. Mainly used for linking the
    %   spectral plot with image cursors in the ImageStackView
    
    properties
        cursor_obj
        line_obj
    end
    
    methods
        function obj = HSIviewPlot()
        end
    end
end

