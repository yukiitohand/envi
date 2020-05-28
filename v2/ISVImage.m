classdef ISVImage < handle
    %ISVImage
    %   Image class (base of ImageStackView.m)
    
    properties (SetObservable)
        id
        name
        XLimHome
        YLimHome
        Pixel_Size
        % info
        clim
        cmap
        AlphaDataHome
        order
        ax
        imobj
        ui_checkbox_visbility
        transparency
    end
    
    methods
        function obj = ISVImage(image_input,ISVobj)
            [image_input,im_info,clim,cmap] = get_ISVImage_info(image_input);
            % obj.info = im_info;
            obj.clim = clim;
            obj.cmap = cmap;
            obj.imagesc(image_input,ISVobj);
            obj.transparency = 1;
            obj.clim = obj.ax.CLim;
            obj.name = im_info.name;
            obj.XLimHome = im_info.xrange;
            obj.YLimHome = im_info.yrange;
            obj.Pixel_Size = im_info.pixel_size;
        end
        
        function [] = imagesc(obj,image_input,ISV_obj)
            obj.ax = axes('Parent',ISV_obj.image_panel);
            obj.ax.Units = 'pixels';
            obj.ax.DataAspectRatioMode = 'manual';
            obj.ax.DataAspectRatio = [1,1,1];
            obj.ax.ActivePositionProperty = 'Position';
            obj.ax.Position = ISV_obj.axim_master.Position;
            
            obj.imobj = imagesc(obj.ax,image_input{:},'Parent',obj.ax);

            obj.AlphaDataHome = obj.imobj.AlphaData;
            
            obj.ax.XLim = ISV_obj.axim_master.XLim;
            obj.ax.YLim = ISV_obj.axim_master.YLim;
            obj.ax.Color = 'none';
            obj.ax.XTick = [];
            obj.ax.YTick = [];
            obj.ax.XAxis.Visible = 0;
            obj.ax.YAxis.Visible = 0;
            obj.ax.Box = 0;
            if ~isempty(obj.clim)
                obj.ax.CLim = obj.clim;
            end
            if ~isempty(obj.cmap)
                obj.ax.ColorMap = colormap(obj.cmap);
                obj.cmap = obj.ax.ColorMap;
            end
            obj.ax.DataAspectRatio = [1,1,1];
            obj.ax.YDir = ISV_obj.axim_master.YDir;
        end

    end
end