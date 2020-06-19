classdef HSIview < handle
    % HSIview
    %   Create two 
    
    properties
        obj_ISV
        obj_SpecView
        hsiar
        nhsi
        obj_HSIviewPlot
        % plot properties
        plot_hold_status
    end
    
    methods
        function obj = HSIview(rgb,hsiar,varargin)
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
            
            if iscell(hsiar)
                if length(hsiar)==1
                    obj.nhsi = 1;
                    if iscell(hsiar{1})
                        obj.hsiar =  obj.parse_hsiar(hsiar{1});
                    elseif isa(hsiar{1},'HSI')
                        obj.hsiar = obj.parse_hsiar(hsiar);
                    else
                        error('Input hsiar is not proper.');
                    end
                elseif length(hsiar)>1
                    if isa(hsiar{1},'HSI') && ~(isa(hsiar{2},'HSI') || iscell(hsiar{2}))
                        obj.nhsi = 1;
                        obj.hsiar = obj.parse_hsiar(hsiar);
                    else
                        obj.nhsi = length(hsiar);
                        obj.hsiar = [];
                        for i=1:obj.nhsi
                            if iscell(hsiar{i})
                                obj.hsiar = [obj.hsiar obj.parse_hsiar(hsiar{i})];
                            elseif isa(hsiar{i},'HSI')
                                obj.hsiar = [obj.hsiar obj.parse_hsiar({hsiar{i}})];
                            else
                                error('Input hsiar is not proper.');
                            end
                        end
                    end
                end
            end
            
            % if isnumeric(rgb) || islogical(rgb)
            %     rgb = {rgb};
            % end
            obj.init_ImageStackView(rgb,...
                'IMAGE_CURSOR_FCN',@obj.image_BtnDwnFcn_HSIview,...
                'IMAGE_WINDOWKEYPRESS_FCN',@obj.image_WindowKeyPressFcn_HSIview,...
                'XY_COORDINATE_SYSTEM','IMAGEPIXELS',...
                varargin_ImageStackView{:});
            
            obj.init_SpecView('XLabel','Wavelength',...
                'XLim',SpecView_XLimMan,'YLim',SpecView_YLimMan);
            
            obj.obj_ISV.image_cursor_hold_chkbox.Callback = @obj.Change_image_cursor_hold_HSIview;
            
        end
        
        function [hsiar_i_struct] = parse_hsiar(obj,hsiar_i)
            % hsiar_i:
            %  {HSIobj,varargin...}
            hsiar_i_struct = [];
            hsiar_i_struct.hsi = hsiar_i{1};
            
            hsiar_i_varargin = hsiar_i(2:end);
            hsiar_i_struct.bands = [];
            hsiar_i_struct.is_bands_inverse = false;
            hsiar_i_struct.ave_window = [1 1];
            hsiar_i_struct.spc_shift = 0;
            hsiar_i_struct.varargin_plot = {};
            hsiar_i_struct.name = '';
            hsiar_i_struct.plot_gp_bp = 0;
            if (rem(length(hsiar_i_varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for n=1:2:(length(hsiar_i_varargin)-1)
                    switch upper(hsiar_i_varargin{n})                        
                        % Plot parameters
                        case 'BANDS'
                            hsiar_i_struct.bands = hsiar_i_varargin{n+1};
                        case 'BANDS_INVERSE'
                            hsiar_i_struct.is_bands_inverse = hsiar_i_varargin{n+1};
                        case 'AVERAGE_WINDOW'
                            hsiar_i_struct.ave_window = hsiar_i_varargin{n+1};
                        case 'SHIFT'
                            hsiar_i_struct.spc_shift = hsiar_i_varargin{n+1};
                        case 'VARARGIN_PLOT'
                            hsiar_i_struct.varargin_plot = hsiar_i_varargin{n+1};
                            if ~iscell(hsiar_i_struct.varargin_plot)
                                hsiar_i_struct.varargin_plot = {hsiar_i_struct.varargin_plot};
                            end
                        case {'LEGEND','NAME','IMAGE_NAME'}
                            hsiar_i_struct.name = hsiar_i_varargin{n+1};
                        otherwise
                            error('Unrecognized option: %s', hsiar_i_varargin{n});
                    end
                end
            end
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
            
            
            s = x; l = y;
                
            % cla(obj.obj_SpecView.ax);
            hold(obj.obj_SpecView.ax,'on');
            for i=1:obj.nhsi
                % get spectra
                [spc,wv,bdxes] = obj.hsiar(i).hsi.get_spectrum(s,l,...
                    'BANDS',obj.hsiar(i).bands,...
                    'BANDS_INVERSE',obj.hsiar(i).is_bands_inverse,...
                    'AVERAGE_WINDOW',obj.hsiar(i).ave_window);
                spc = spc + obj.hsiar(i).spc_shift;
                if obj.hsiar(i).is_bands_inverse
                    bdxes = obj.hsiar(i).hdr.bands-bdxes+1;
                end
                if length(hsivplot_obj.line_obj)<i
                    line_obj = obj.obj_SpecView.plot([wv,spc,obj.hsiar(i).varargin_plot,...
                        'DisplayName',sprintf('%s X:% 4d, Y:% 4d',obj.hsiar(i).name,s,l)],...
                        {'Band',bdxes});
                    % store line object into HSIviewPlot object.
                    if i==1
                       hsivplot_obj.line_obj = line_obj;
                    else
                       hsivplot_obj.line_obj = [hsivplot_obj.line_obj line_obj];
                    end
                else
                    hsivplot_obj.line_obj(i).XData = wv;
                    hsivplot_obj.line_obj(i).YData = spc;
                    hsivplot_obj.line_obj(i).DisplayName = sprintf('%s X:% 4d, Y:% 4d',obj.hsiar(i).name,s,l);
                end

            end
            obj.obj_SpecView.set_xlim();
            obj.obj_SpecView.set_ylim();
            
        end
        
        function image_BtnDwnFcn_HSIview(obj,hObject,eventData)
            % DataTip is created as the same way in ImageStackView
            [out] = obj.obj_ISV.image_BtnDwnFcn(hObject,eventData);
            out.cursor_obj.DeleteFcn = @obj.image_cursor_delete_current;
            
            % get (x,y) coordinate in the Hyperspectral image 
            % pos = eventData.IntersectionPoint;
            % s = pos(1); l = pos(2);
            % plot spectra

            obj.plot(out.cursor_obj);
            
        end
        
        function image_WindowKeyPressFcn_HSIview(obj,figobj,eventData)
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
            for i=1:length(cursor_obj.UserData.HSIviewPlot_obj.line_obj)
                delete(cursor_obj.UserData.HSIviewPlot_obj.line_obj(i));
            end
            delete(cursor_obj.UserData.HSIviewPlot_obj);
            obj.obj_ISV.image_cursor_delete_current(cursor_obj,eventData);
        end
    end
end

