classdef ImageStackView < handle
    % ImageStackView(varargin)
    %   Detailed explanation goes here
    
    properties
        fig
        axim_master
        axim_list
        ax_plot
        image_titles
        image_xranges
        image_yranges
        image_pixel_sizes
        image_alpha_list
        image_visible_panel
        image_control_panel
        transparency_value
        label
        XY_COORDINATE_SYSTEM % NorthEast, PLANETOCENTRIC, IMAGEPIXELS
        image_order
    end
    
    methods
        %% CONSTRUCTOR FUNCTION
        function obj = ImageStackView(image_list,varargin)
            %--------------------------------------------------------------
            % Parse Inputs
            %--------------------------------------------------------------
            obj.image_titles = {};
            image_clims = {};
            xlim_val = [];
            ylim_val = [];
            ydir = [];
            obj.XY_COORDINATE_SYSTEM = '';
            image_cursor_fcn = @obj.image_cursor;
            if ~isempty(varargin)
                for i=1:2:length(varargin)
                    switch upper(varargin{i})
                        case 'IMAGE_TITLES'
                            obj.image_titles = varargin{i+1};
                        case 'CLIM'
                            image_clims = varargin{i+1};
                        case 'XLIM'
                            xlim_val = varargin{i+1};
                        case 'YLIM'
                            ylim_val = varargin{i+1};
                        case 'YDIR'
                            ydir = varargin{i+1};
                        case 'XY_COORDINATE_SYSTEM'
                            obj.XY_COORDINATE_SYSTEM = varargin{i+1};
                        case 'IMAGE_CURSOR_FCN'
                            image_cursor_fcn = varargin{i+1};
                        otherwise
                            error('Unrecognized option: %s', varargin{i});
                    end
                end
            end
            
            %--------------------------------------------------------------
            % Pre-process some parameters
            %--------------------------------------------------------------
            Nim = length(image_list);
            
            if isempty(obj.image_titles)
                obj.image_titles = cellstr(num2str((1:Nim)','Image %03d'))';
            end
            if isempty(image_clims), image_clims = cell(1,Nim); end
            
            % Check image size and set xlim and ylim
            obj.image_xranges = nan(Nim,2);
            obj.image_yranges = nan(Nim,2);
            obj.image_pixel_sizes = nan(Nim,2);
            for i=1:Nim
                image_listi = image_list{i};
                [cdata,xdata,ydata,zdata] = parse_image_input(image_listi);
                [obj.image_xranges(i,:),obj.image_yranges(i,:),obj.image_pixel_sizes(i,:)] = ...
                    get_image_lim(xdata,ydata,cdata);
            end
            xlim_val_auto = [min(obj.image_xranges(:)) max(obj.image_xranges(:))];
            ylim_val_auto = [min(obj.image_yranges(:)) max(obj.image_yranges(:))];
            if isempty(xlim_val), xlim_val = xlim_val_auto; end
            if isempty(ylim_val), ylim_val = ylim_val_auto; end

            % Get Aspect ratio of the image.
            S = abs(xlim_val(2)-xlim_val(1));
            L = abs(ylim_val(2)-ylim_val(1));
            aspectR = S/L;
            
            %--------------------------------------------------------------
            % Initialize figure
            %--------------------------------------------------------------
            [axim_pos,ivp_pos,icp_pos] = obj.init_Figure(S,L,aspectR);
            
            %--------------------------------------------------------------
            % Initialize Image Axes
            %--------------------------------------------------------------
            obj.init_image_axes(axim_pos,image_list,Nim,image_clims,xlim_val,ylim_val,ydir);
            
            %--------------------------------------------------------------
            % Initialize control panels
            %--------------------------------------------------------------
            obj.init_image_visible_panel(ivp_pos,Nim);
            obj.init_image_control_panel(icp_pos,Nim);
            
            %--------------------------------------------------------------
            % Set up callback functions
            %--------------------------------------------------------------
            obj.fig.SizeChangedFcn = {@obj.resizeUI,aspectR};
            % image cursor
            hdt = datacursormode(obj.fig);
            set(hdt,'UpdateFcn',image_cursor_fcn);
            
        end
        
        %%
        %=================================================================%
        % WINDOW INITIALIZE FUNCTIONS
        %=================================================================%
        
        % Initialize the main figure window
        function [axim_pos,ivp_pos,icp_pos] = init_Figure(obj,S,L,aspectR)
            obj.fig = figure();
            w_fig = min(1000,S+200);
            h_fig = min(800,L+50);
            [axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r] = obj.get_resizePosition(...
                w_fig,h_fig,aspectR);
            set_figsize(obj.fig,w_fig_r,h_fig_r);
        end
        
        % Initialize the image axes
        function [] = init_image_axes(obj,axim_pos,image_list,Nim,image_clims,xlim_val,ylim_val,ydir)
            axim = axes('Parent',obj.fig);
            axim.Units = 'pixels';
            axim.Position = axim_pos;
            axim.XLim = xlim_val;
            axim.YLim = ylim_val;
            axim.DataAspectRatio = [1,1,1];
            obj.axim_master = axim;
            view(obj.axim_master,[0 90]);

            obj.axim_list = cell(1,Nim);
            for i=1:Nim
                iflip = Nim-i+1;
                axi = axes('Parent',obj.fig);
                axi.Units = 'pixels';
                axi.DataAspectRatio = [1,1,1];
                axi.Position = obj.axim_master.Position;
                if iscell(image_list{iflip})
                    image_list_i = image_list{iflip};
                    imobj = imagesc(axi,image_list_i{:},'Parent',axi);
                else
                    imobj = imagesc(image_list{iflip},'Parent',axi);
                end
                imobj.Tag = obj.image_titles{iflip};
                obj.image_alpha_list{iflip} = imobj.AlphaData;
                axis(axi,'off');
                axi.XLim = obj.axim_master.XLim;
                axi.YLim = obj.axim_master.YLim;
                axi.Color = 'none';
                axi.XTick = [];
                axi.YTick = [];
                if ~isempty(image_clims{iflip})
                    axi.CLim = image_clims{iflip};
                end
                obj.axim_list{iflip} = axi;
                axi.DataAspectRatio = [1,1,1];
            end
            
            if ~isempty(ydir)
                obj.axim_master.YDir = ydir;
                for i=1:Nim
                    obj.axim_list{i}.YDir = ydir;
                end
            end
            
            linkaxes([obj.axim_master cat(2,obj.axim_list{:})],'xy');
            hlink = linkprop([obj.axim_master cat(2,obj.axim_list{:})],'Position');
            obj.image_order = 1:Nim;
        end
        
        % Initialize the visibility panel
        function [] = init_image_visible_panel(obj,ivp_pos,Nim)
            % set UIPanel for image visibility and transparency
            obj.image_visible_panel = uipanel(obj.fig,'FontSize',12,'Units','pixels');
            obj.image_visible_panel.Position = ivp_pos;
            
            vis_chkbox_list = cell(1,Nim);
            for i=1:Nim
                [ivp_chckbx_pos_i] = obj.get_visibility_checkbox_position(ivp_pos,i);
                vis_chkbox_list{i} = uicontrol('Style','checkbox','Parent',obj.image_visible_panel,...
                    'Position',ivp_chckbx_pos_i,...
                    'String',obj.image_titles{i},'Value',true,'Callback',{@obj.change_image_visibility,i});
            end
            
            
            for i=1:(Nim-1)
                [ivp_ordchgbtn_pos_i] = obj.get_orderchange_btn_position(ivp_pos,i);
                vis_chkbox_list{i} = uicontrol('Style','pushbutton','Parent',obj.image_visible_panel,...
                    'Position',ivp_ordchgbtn_pos_i,...
                    'String','>','FontSize',12,'Value',true,'Callback',{@obj.image_order_change,i},...
                    'Tag',num2str(i));
            end
            
        end
        
        % Initialize image control panel
        function [] = init_image_control_panel(obj,icp_pos,Nim)
            obj.image_control_panel = uipanel(obj.fig,'FontSize',12,'Units','pixels');
            obj.image_control_panel.Position = icp_pos;
            imsel_image_control_panel = uicontrol('Style','popupmenu','Parent',obj.image_control_panel ,...
                'String',obj.image_titles,'Value',1,'Callback',{@obj.ImageChanged_image_control_panel});
             imsel_image_control_panel.Position = [5,obj.image_control_panel.Position(4)-30,...
                100,imsel_image_control_panel.Position(4)];
            
            % clim controller
            title_clim_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','CLim: ', 'HorizontalAlignment','right');
            title_clim_control.Position = [5,32,80,title_clim_control.Position(4)];
            text_climmin_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','min.', 'HorizontalAlignment','right');
            text_climmin_control.Position =[title_clim_control.Position(1)+title_clim_control.Position(3)+5,...
                32,30,text_climmin_control.Position(4)];
            clim_min_input = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','climmin',...
                'Units','Pixels','String',num2str(obj.axim_list{imsel_image_control_panel.Value}.CLim(1)),...
                'HorizontalAlignment','right',...
                'Callback',{@obj.CLim_Value_changed,1});
            clim_min_input.Position = [text_climmin_control.Position(1)+text_climmin_control.Position(3)+5,...
                32,50,clim_min_input.Position(4)];
            
            text_climmax_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','max.', 'HorizontalAlignment','right');
            text_climmax_control.Position =[clim_min_input.Position(1)+clim_min_input.Position(3)+10,...
                32,30,text_climmax_control.Position(4)];
            clim_max_input = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','climmax',...
                'Units','Pixels','String',num2str(obj.axim_list{imsel_image_control_panel.Value}.CLim(2)),...
                'HorizontalAlignment','right',...
                'Callback',{@obj.CLim_Value_changed,2});
            clim_max_input.Position = [text_climmax_control.Position(1)+text_climmax_control.Position(3)+5,...
                32,50,clim_max_input.Position(4)];
            
            % colormap controller
            text_cmap_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','ColorMap', 'HorizontalAlignment','right');
            text_cmap_control.Position =[imsel_image_control_panel.Position(1)+imsel_image_control_panel.Position(3)+10,...
                imsel_image_control_panel.Position(2),50,text_cmap_control.Position(4)];
            cmap_input = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','cmap',...
                'Units','Pixels','String',colormap(obj.axim_list{imsel_image_control_panel.Value}),...
                'HorizontalAlignment','right',...
                'Callback',{@obj.CMap_Changed});
            cmap_input.Position = [text_cmap_control.Position(1)+text_cmap_control.Position(3)+5,...
                imsel_image_control_panel.Position(2),50,cmap_input.Position(4)];
            
            % transparency
            title_transparency = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','Transparency: ', 'HorizontalAlignment','right');
            title_transparency.Position = [5,10,80,title_transparency.Position(4)];
            slider_transparency = uicontrol('Style','slider','Parent',obj.image_control_panel ,...
                'Tag','slider_transparency',...
                'Value',1,'Callback',{@obj.ValueChanged_transparency_slider});
            slider_transparency.Position = [...
                title_transparency.Position(1)+title_transparency.Position(3)+5,...
                10, 145, 17];
            text_transparency = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','text_transparency',...
                'Units','Pixels','String',num2str(slider_transparency.Value),...
                'HorizontalAlignment','right',...
                'Callback',{@obj.TextStringChanged_transparency_slider});
            text_transparency.Position = [slider_transparency.Position(1)+slider_transparency.Position(3)+5,...
                10,50,text_transparency.Position(4)];

            obj.transparency_value = ones(1,Nim);
        end
        
        %%
        %=================================================================%
        % UTILITY FUNCTIONS
        %=================================================================%
        
        %-----------------------------------------------------------------%
        % Get the size of components and reconfigure the size of the main
        % figure window.
        %-----------------------------------------------------------------%
        function [axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r] = ...
                get_resizePosition(obj,w_fig,h_fig,aspectR)
            
            % given w_fig, h_fig
            left_margin = 60; btm_margin = 50; ivp_right_margin = 5;
            icp_btm_margin = 22; ivp_left_margin = 10; icp_top_margin = 5;
            icp_w = 330; icp_h = 100;
            ivp_w = 200; ivp_h_min = 200;
            % aspectR = S/L;
            axim_w_max = w_fig-ivp_w-ivp_left_margin-left_margin-ivp_right_margin;
            axim_h_max = h_fig-icp_h-btm_margin-icp_btm_margin-icp_top_margin;
            aspectR_max = axim_w_max / axim_h_max;
            if aspectR_max>=aspectR
                axim_h = axim_h_max;
                axim_w = axim_h * aspectR;
                axim_pos = [left_margin,btm_margin,axim_w,axim_h];
            else
                axim_w = axim_w_max;
                axim_h = axim_w / aspectR;
                axim_pos = [left_margin,btm_margin,axim_w,axim_h];
            end
            ivp_pos = [axim_pos(1)+axim_pos(3)+ivp_left_margin, axim_pos(2), ivp_w, max(axim_pos(4),ivp_h_min)];
            icp_pos = [left_margin,axim_pos(2)+axim_pos(4)+icp_btm_margin,icp_w,icp_h];
            w_fig_r = left_margin + axim_w + ivp_left_margin+ivp_w + ivp_right_margin;
            h_fig_r = btm_margin + axim_h + icp_btm_margin + icp_h + icp_top_margin;
        end
        
        function [ivp_chckbx_pos] = get_visibility_checkbox_position(obj,ivp_pos,im_id)
            ivp_chckbx_pos = [30,ivp_pos(4)-10-22*im_id,100,22];
        end
        function [ivp_chckbx_pos] = get_orderchange_btn_position(obj,ivp_pos,im_id)
            ivp_chckbx_pos = [10,ivp_pos(4)-17-22*im_id,15,15];
        end
        
        %%
        %=================================================================%
        % INTERACTIVE CALLBACK FUNCTIONS
        %=================================================================%
        
        %-----------------------------------------------------------------%
        % SizeChangedFcn for the main figure window.
        %-----------------------------------------------------------------%
        function resizeUI(obj,hObject,eventData,aspectR)
            w_fig = hObject.Position(3);
            h_fig = hObject.Position(4);
            
            [axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r]...
                = obj.get_resizePosition(w_fig,h_fig,aspectR);
            
            % scale image axes
            obj.axim_master.Position = axim_pos;
            for i=1:length(obj.axim_list)
                obj.axim_list{i}.Position = axim_pos;
            end
            
            % replace Visiblity_panel
            obj.image_visible_panel.Position = ivp_pos;
            h_vis_chkbox_list = findobj(obj.image_visible_panel.Children,'Style','checkbox');
            %for i=1:length(h_vis_chkbox_list)
            %    iflip = length(h_vis_chkbox_list)-i+1;
            %    h_vis_chkbox_list(iflip).Position = obj.get_visibility_checkbox_position(ivp_pos,iflip);
            %end
            for i=1:length(h_vis_chkbox_list)
                [ivp_chckbx_pos_i] = obj.get_visibility_checkbox_position(ivp_pos,i);
                iflip = length(h_vis_chkbox_list)-i+1;
                h_vis_chkbox_list(iflip).Position = ivp_chckbx_pos_i;
            end
            
            h_vis_btn_list = findobj(obj.image_visible_panel.Children,'Style','pushbutton');
            for i=1:length(h_vis_chkbox_list)-1
                [ivp_ordchgbtn_pos_i] = obj.get_orderchange_btn_position(ivp_pos,i);
                iflip = length(h_vis_chkbox_list)-i;
                h_vis_btn_list(iflip).Position = ivp_ordchgbtn_pos_i;
            end

            % replace transparency_panel
            obj.image_control_panel.Position = icp_pos;

        end
        
        %-----------------------------------------------------------------%
        % Visibility controller Callback function
        %-----------------------------------------------------------------%
        function [] = change_image_visibility(obj,hObject,eventData,i)
            switch hObject.Value
                case 0
                    obj.axim_list{i}.Visible = 0;
                    obj.axim_list{i}.Children.Visible = 0;
                case 1
                    obj.axim_list{i}.Visible = 1;
                    obj.axim_list{i}.Children.Visible = 1;
            end
        end
        
        function [] = image_order_change(obj,hObject,eventData,i)
            
            % first change the checkboxes
            h_vis_chkbox_list = findobj(obj.image_visible_panel.Children,'Style','checkbox');
            Nim = length(h_vis_chkbox_list);
            pos_i = h_vis_chkbox_list(Nim-i+1).Position;
            pos_ip1 = h_vis_chkbox_list(Nim-i).Position;

            h_vis_chkbox_list(Nim-i+1).Position = pos_ip1;
            h_vis_chkbox_list(Nim-i).Position = pos_i;

            % change the image
            uistack(obj.axim_list{obj.image_order(i+1)},'up');
            obj.image_order([i,i+1]) = obj.image_order([i+1,i]);
        end
        
        %-----------------------------------------------------------------%
        % Image control panel Callback functions
        %-----------------------------------------------------------------%
        % Change the image for which properties are controlled.
        function [] = ImageChanged_image_control_panel(obj,hObject,eventData)
            for i=1:length(obj.image_control_panel.Children)
                switch obj.image_control_panel.Children(i).Style
                    case 'edit'
                        switch lower(obj.image_control_panel.Children(i).Tag)
                            case 'text_transparency'
                                text_transparency = obj.image_control_panel.Children(i);
                            case 'climmin'
                                clim_min_input = obj.image_control_panel.Children(i);
                            case 'climmax'
                                clim_max_input = obj.image_control_panel.Children(i);
                            case 'cmap'
                                cmap_input = obj.image_control_panel.Children(i);
                        end
                    case 'slider'
                        slider_transparency = obj.image_control_panel.Children(i);
                    case 'popupmenu'
                        imsel_image_control_panel = obj.image_control_panel.Children(i);
                end
            end
            
            id_im = hObject.Value;
            slider_transparency.Value = obj.transparency_value(id_im);
            text_transparency.String = num2str(slider_transparency.Value);
            clim_min_input.String = num2str(obj.axim_list{id_im}.CLim(1));
            clim_max_input.String = num2str(obj.axim_list{id_im}.CLim(2));
            cmap_input.String = colormap(obj.axim_list{id_im});
            
        end
        
        function [] = CMap_Changed(obj,hObject,eventData)
            for i=1:length(obj.image_control_panel.Children)
                switch obj.image_control_panel.Children(i).Style
                    case 'edit'
                        switch lower(obj.image_control_panel.Children(i).Tag)
                            case 'text_transparency'
                                text_transparency = obj.image_control_panel.Children(i);
                            case 'climmin'
                                clim_min_input = obj.image_control_panel.Children(i);
                            case 'climmax'
                                clim_max_input = obj.image_control_panel.Children(i);
                            case 'cmap'
                                cmap_input = obj.image_control_panel.Children(i);
                        end
                    case 'slider'
                        slider_transparency = obj.image_control_panel.Children(i);
                    case 'popupmenu'
                        imsel_image_control_panel = obj.image_control_panel.Children(i);
                end
            end
            
            id_im = imsel_image_control_panel.Value;
            colormap(obj.axim_list{id_im},hObject.String);
            
        end
        
        % Controll the transparency of the image: TEXT INPUT
        function [] = ValueChanged_transparency_slider(obj,hObject,eventData)
            for i=1:length(obj.image_control_panel.Children)
                switch obj.image_control_panel.Children(i).Style
                    case 'edit'
                        switch lower(obj.image_control_panel.Children(i).Tag)
                            case 'text_transparency'
                                text_transparency = obj.image_control_panel.Children(i);
                            case 'climmin'
                                clim_min_input = obj.image_control_panel.Children(i);
                            case 'climmax'
                                clim_min_input = obj.image_control_panel.Children(i);
                        end
                    case 'slider'
                        slider_transparency = obj.image_control_panel.Children(i);
                    case 'popupmenu'
                        imsel_image_control_panel = obj.image_control_panel.Children(i);
                end
            end
            
            text_transparency.String = num2str(hObject.Value);
            id_im = imsel_image_control_panel.Value;
            obj.axim_list{id_im}.Children.AlphaData = hObject.Value.*obj.image_alpha_list{id_im};      
            obj.transparency_value(id_im) = hObject.Value;
            
        end
        
        % Controll the transparency of the image: SLIDER INPUT
        function [] = TextStringChanged_transparency_slider(obj,hObject,eventData)
            for i=1:length(obj.image_control_panel.Children)
                switch obj.image_control_panel.Children(i).Style
                    case 'edit'
                        switch lower(obj.image_control_panel.Children(i).Tag)
                            case 'text_transparency'
                                text_transparency = obj.image_control_panel.Children(i);
                            case 'climmin'
                                clim_min_input = obj.image_control_panel.Children(i);
                            case 'climmax'
                                clim_min_input = obj.image_control_panel.Children(i);
                        end
                    case 'slider'
                        slider_transparency = obj.image_control_panel.Children(i);
                    case 'popupmenu'
                        imsel_image_control_panel = obj.image_control_panel.Children(i);
                end
            end
            
            v = str2double(hObject.String);
            if isnan(v)
                error('Input value is invalid');
            end
            slider_transparency.Value = v;
            id_im = imsel_image_control_panel.Value;
            obj.axim_list{id_im}.Children.AlphaData =  v .* obj.image_alpha_list{id_im};   
            obj.transparency_value(id_im) = v;
            
        end
        
        % Controll CLim of the image
        function [] = CLim_Value_changed(obj,hObject,eventData,climidx)
            for i=1:length(obj.image_control_panel.Children)
                switch obj.image_control_panel.Children(i).Style
                    case 'edit'
                        switch lower(obj.image_control_panel.Children(i).Tag)
                            case 'text_transparency'
                                text_transparency = obj.image_control_panel.Children(i);
                            case 'climmin'
                                clim_min_input = obj.image_control_panel.Children(i);
                            case 'climmax'
                                clim_min_input = obj.image_control_panel.Children(i);
                        end
                    case 'slider'
                        slider_transparency = obj.image_control_panel.Children(i);
                    case 'popupmenu'
                        imsel_image_control_panel = obj.image_control_panel.Children(i);
                end
            end
            v = str2double(hObject.String);
            id_im = imsel_image_control_panel.Value;
            obj.axim_list{id_im}.CLim(climidx) = v;
            
        end
        
        %-----------------------------------------------------------------%
        % Image Cursor Callback function
        %-----------------------------------------------------------------%
        function [output_txt] = image_cursor(obj,hObject,eventData)
            pos = get(eventData,'Position');
            x = pos(1); y = pos(2);
            % im = get(event_obj,'Target');
            output_txt = {['X: ',sprintf('%6.4f',x)],...
                ['Y: ',sprintf('%6.4f',y)]};

            for i=1:length(obj.axim_list)
                if ((x>obj.image_xranges(i,1) && x<obj.image_xranges(i,2)) || (x>obj.image_xranges(i,2) && x<obj.image_xranges(i,1)) )...
                       && ((y>obj.image_yranges(i,1) && y<obj.image_yranges(i,2)) || (y>obj.image_yranges(i,2) && y<obj.image_yranges(i,1)) )...
                    [x_imi] = ceil((x-obj.image_xranges(i,1))/obj.image_pixel_sizes(i,1));
                    [y_imi] = ceil((y-obj.image_yranges(i,1))/obj.image_pixel_sizes(i,2));
                    val = obj.axim_list{i}.Children.CData(y_imi,x_imi,:);
                else
                    x_imi = nan; y_imi = nan; val = nan;
                end
                if length(val)==1
                    output_txt{end+1} = sprintf('%10s\n (% 6d, % 6d) : % 8.5f',...
                            obj.image_titles{i},x_imi,y_imi,val);
                elseif length(val)==3
                    output_txt{end+1} = sprintf('%10s\n (% 6d, % 6d) : (% 5.5f % 5.5f % 5.5f)',...
                            obj.image_titles{i},x_imi,y_imi,val(1),val(2),val(3));
                end
            end
        end
        
        %-----------------------------------------------------------------%
        % Plot the image from the outside of the ImageStackView class
        % Create a top layer ax for plotting if it isn't initilized.
        %-----------------------------------------------------------------%
        function [p] = plot(obj,varargin)
            if isempty(obj.ax_plot)
                obj.ax_plot = axes('Parent',obj.fig);
                obj.ax_plot.Units = 'pixels';
                obj.ax_plot.DataAspectRatio = [1,1,1];
                obj.ax_plot.Position = obj.axim_master.Position;
                obj.ax_plot.XLim = obj.axim_master.XLim;
                obj.ax_plot.YLim = obj.axim_master.YLim;
                obj.ax_plot.Color = 'none';
                obj.ax_plot.XTick = [];
                obj.ax_plot.YTick = [];
                
                linkaxes([obj.axim_master cat(2,obj.axim_list{:}) obj.ax_plot],'xy');
                hlink_p = linkprop([obj.axim_master cat(2,obj.axim_list{:}) obj.ax_plot],'Position');
            end
            
            p = plot(obj.ax_plot,varargin{:});
            
            obj.ax_plot.XLim = obj.axim_master.XLim;
            obj.ax_plot.YLim = obj.axim_master.YLim;
            
        end  
        
    end
end

