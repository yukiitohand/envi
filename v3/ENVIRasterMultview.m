classdef ENVIRasterMultview < handle
    % ENVIRasterMultview
    %   Viewer for spectral image cubes. It basically supports
    %   hyperspectral image cubes but also can be used for viewing
    %   multispectral image cubes.
    
    properties
        obj_ISV
        obj_SpecView
        RasterElems
        nRaster
        obj_HSIviewPlot
        % plot properties
        plot_hold_status
    end
    
    methods
        function obj = ENVIRasterMultview(rgb,raster_input,varargin)
            % obj = HSIview(hsiar,varargin)
            % USAGE
            %  HSIview(rgb,hsicell)
            
            varargin_ImageStackView = {};
            
            SpecView_XLimMan = [];
            SpecView_YLimMan = [];
            
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})
                        case {'ISV','IMAGESTACKVIEW'}
                            obj.obj_ISV = varargin{n+1};
                        case {'SPECVIEW'}
                            obj.obj_SpecView = varargin{n+1};
                        % ImageStackView parameters
                        case 'VARARGIN_IMAGESTACKVIEW'
                            varargin_ImageStackView = varargin{n+1};
                        
                        % General SpecView parameters
                        case 'SPC_XLIM'
                            SpecView_XLimMan = varargin{n+1};
                        case 'SPC_YLIMMODE'
                            SpecView_YLimMode = varargin{n+1};
                        
                        otherwise
                            error('Unrecognized option: %s', varargin{n});
                    end
                end
            end
            obj.nRaster = 0;
            % decode the input hsiar
            obj.init_hsiar(raster_input);
            
            if isempty(obj.obj_ISV)
                obj.init_ImageStackView(rgb,...
                    'IMAGE_CURSOR_FCN',@obj.image_BtnDwnFcn_HSIview,...
                    'IMAGE_WINDOWKEYPRESS_FCN',@obj.image_WindowKeyPressFcn_HSIview,...
                    'XY_COORDINATE_SYSTEM','IMAGEPIXELS',...
                    varargin_ImageStackView{:});
            else
                obj.obj_ISV.decode_image_list(rgb);
            end
            
            if isempty(obj.obj_SpecView)
                obj.init_SpecView('XLabel','Wavelength',...
                    'XLim',SpecView_XLimMan,'YLim',SpecView_YLimMan);
            end
            
            obj.obj_ISV.image_cursor_hold_chkbox.Callback = @obj.Change_image_cursor_hold_HSIview;
            
        end
        
        function init_hsiar(obj,hsiar_input)
            if isempty(hsiar_input)
                % skip if input hsiar is empty.
            elseif iscell(hsiar_input)
                if length(hsiar_input)==1
                    if iscell(hsiar_input{1})
                        obj.add_RasterElem(hsiar_input{1}{:});
                    elseif isa(hsiar_input{1},'ENVIRaster') || isa(hsiar_input{1},'MASTCAMMSI')
                        obj.add_RasterElem(hsiar_input{:});
                    else
                        error('Input hsiar is not proper.');
                    end
                elseif length(hsiar_input)>1
                    if isa(hsiar_input{1},'ENVIRaster') ...
                            && ~isa(hsiar_input{2},'ENVIRaster') || isa(hsiar_input{1},'MASTCAMMSI')
                        obj.add_RasterElem(hsiar_input{:});
                    else
                        nelem = length(hsiar_input);
                        for i=1:nelem
                            if iscell(hsiar_input{i})
                                obj.add_RasterElem(hsiar_input{i}{:});
                            elseif isa(hsiar_input{i},'ENVIRaster') || isa(hsiar_input{1},'MASTCAMMSI')
                                obj.add_RasterElem(hsiar_input{i});
                            else
                                error('Input hsiar is not proper.');
                            end
                        end
                    end
                end
            elseif isa(hsiar_input,'ENVIRaster')
                obj.add_RasterElem(hsiar_input);
            end
        end
        
        function add_RasterElem(obj,varargin)
            % hsiar_i:
            %  {HSIobj,varargin...}
            if length(varargin)==1 && isa(varargin{1},'ENVIRasterMultview_Rasterelem')
                obj_RasterElem = varargin{1};
            else
                obj_RasterElem = ENVIRasterMultview_Rasterelem(varargin{:});
            end
            if isempty(obj.RasterElems)
                obj.RasterElems = obj_RasterElem;
            else
                obj.RasterElems = [obj.RasterElems obj_RasterElem];
            end
            obj.nRaster = obj.nRaster + length(obj_RasterElem);
        end
        
        function [] = init_ImageStackView(obj,rgb,varargin)
            obj.obj_ISV = ImageStackView(rgb,varargin{:});
        end
        
        function [] = init_SpecView(obj,varargin)
            obj.obj_SpecView = SpecView(varargin{:});
        end
        
        function [] = plot(obj,cursor_obj)
            % First get the pointer to HSIviewPlot object linked to the
            % cursor.
            if isfield(cursor_obj.UserData,'HSIviewPlot_obj')
                hsivplot_obj = cursor_obj.UserData.HSIviewPlot_obj;
            else
                hsivplot_obj = HSIviewPlot();
                hsivplot_obj.cursor_obj = cursor_obj;
                cursor_obj.UserData.HSIviewPlot_obj = hsivplot_obj;
            end
            
            x = cursor_obj.X; y = cursor_obj.Y;
                
            % cla(obj.obj_SpecView.ax);
            % once the plot is performed, NextPlot property is always on.
            % The deletion of the plot is controlled by the cursor_obj. All
            % the plot should be linked to cursor obj and when it is
            % destroyed, plot is also destroed.
            % hold(obj.obj_SpecView.ax,'on');
            for i=1:obj.nRaster
                % convert (x,y) into (s,l) in the reference image
                % coordinate.
                [s,l] = obj.RasterElems(i).get_im_coord(x,y,obj.obj_ISV.XY_COORDINATE_SYSTEM);
                % get spectra
                if ~isnan(s) && ~isnan(l)
                    [spc,wv,bdxes,spcstr] = obj.RasterElems(i).get_spectrum(s,l);
                    if isempty(spc)
                        hsivplot_obj.line_obj(i).XData = wv;
                        hsivplot_obj.line_obj(i).YData = spc;
                        hsivplot_obj.line_obj(i).DisplayName = spcstr;
                    elseif all(isnan(spc))
                        spc = []; wv = []; spcstr = '';
                        hsivplot_obj.line_obj(i).XData = wv;
                        hsivplot_obj.line_obj(i).YData = spc;
                        hsivplot_obj.line_obj(i).DisplayName = spcstr;
                    elseif length(hsivplot_obj.line_obj)<i
                        line_obj = obj.obj_SpecView.plot(...
                            [wv,spc,obj.RasterElems(i).varargin_plot,...
                             'DisplayName',spcstr ...
                            ], {'Band',bdxes});
                        % store line object into HSIviewPlot object.
                        hsivplot_obj.add_lineobj(line_obj);
                    else
                        hsivplot_obj.line_obj(i).XData = wv;
                        hsivplot_obj.line_obj(i).YData = spc;
                        hsivplot_obj.line_obj(i).DisplayName = spcstr;
                    end
                else
                    spc = []; wv = []; spcstr = '';
                    hsivplot_obj.line_obj(i).XData = wv;
                    hsivplot_obj.line_obj(i).YData = spc;
                    hsivplot_obj.line_obj(i).DisplayName = spcstr;
                end
                

            end
            obj.obj_SpecView.set_xlim();
            if ~isempty(spc)
                obj.obj_SpecView.set_ylim();
            end
            
        end
        
        function [out] = image_BtnDwnFcn_HSIview(obj,hObject,eventData)
            % DataTip is created as the same way in ImageStackView
            [out] = obj.obj_ISV.image_BtnDwnFcn(hObject,eventData);
            out.cursor_obj.DeleteFcn = @obj.image_cursor_delete_current;

            obj.plot(out.cursor_obj);
            
        end
        
        function [out] = image_WindowKeyPressFcn_HSIview(obj,figobj,eventData)
            [out] = obj.obj_ISV.ISVWindowKeyPressFcn(figobj,eventData);
            if isfield(out,'cursor_obj') && ~isempty(out.cursor_obj)
                switch eventData.Key
                    case {'rightarrow','leftarrow','uparrow','downarrow'}
                        obj.plot(out.cursor_obj);
                end
            end
        end
        
        function Change_image_cursor_hold_HSIview(obj,hObject,eventData)
            obj.obj_ISV.Change_image_cursor_hold(hObject,eventData);
            switch hObject.Value
                case 0
                    obj.plot_hold_status = 0;
                case 1
                    obj.plot_hold_status = 1;
            end
        end
        
        function image_cursor_delete_current(obj,cursor_obj,eventData)
            delete(cursor_obj.UserData.HSIviewPlot_obj);
            obj.obj_ISV.image_cursor_delete_current(cursor_obj,eventData);
        end
    end
end

