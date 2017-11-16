classdef KeepPlot < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        crd = [];
        dataTip = [];
    end
    
    methods
        function obj = KeepPlot()
            
            
        end
        
        function obj = add(obj,crd,dataTip)
            obj.crd = [obj.crd; crd];
            obj.dataTip = [obj.dataTip; dataTip];
        end
        
        function obj = del(obj,idx)
            N = size(obj.crd,1);
            keepIdx = setdiff(1:N,idx);
            obj.crd = obj.crd(keepIdx,:);
            obj.dataTip = obj.dataTip(keepIdx);
        end
        
        function obj = clear(obj)
            obj.crd = []; obj.dataTip = [];
        end
        
    end
    
end

