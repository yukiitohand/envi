classdef ImageStackView < handle
    % ImageStackView(varargin)
    %   Detailed explanation goes here
    
    properties
        fig
        axim_master
        axim_aspectR
        ax_plot
        image
        
        image_panel
        image_visible_panel
        image_ordswtchbtn_list
        image_control_panel
        XY_COORDINATE_SYSTEM % NorthEast, PLANETOCENTRIC, IMAGEPIXELS
        hdt
        XLimHome
        YLimHome
        XLimHomeMan
        YLimHomeMan
        XLimHomeAuto
        YLimHomeAuto
        
        custom_image_cursor_fcn
        
        
    end
    
    methods
        %% CONSTRUCTOR FUNCTION
        function obj = ImageStackView(image_list,varargin)
            %--------------------------------------------------------------
            % Parse Inputs
            %--------------------------------------------------------------
            % obj.image_names = {};
            % image_clims = {};
            obj.XLimHomeMan = [];
            obj.YLimHomeMan = [];
            ydir = 'normal';
            obj.XY_COORDINATE_SYSTEM = 'IMAGEPIXELS';
            obj.custom_image_cursor_fcn = @obj.image_cursor;
            if ~isempty(varargin)
                for i=1:2:length(varargin)
                    switch upper(varargin{i})
                        % case {'IMAGE_NAMES','IMAGE_TITLES'}
                        %     obj.image_names = varargin{i+1};
                        % case 'CLIM'
                        %     image_clims = varargin{i+1};
                        case 'XLIM'
                            obj.XLimHomeMan = varargin{i+1};
                        case 'YLIM'
                            obj.YLimHomeMan = varargin{i+1};
                        case 'YDIR'
                            ydir = varargin{i+1};
                        case 'XY_COORDINATE_SYSTEM'
                            obj.XY_COORDINATE_SYSTEM = upper(varargin{i+1});
                        case 'IMAGE_CURSOR_FCN'
                            obj.custom_image_cursor_fcn = varargin{i+1};
                        otherwise
                            error('Unrecognized option: %s', varargin{i});
                    end
                end
            end

            %--------------------------------------------------------------
            % Initialize figure and its components
            %--------------------------------------------------------------
            [imp_pos,axim_pos,ivp_pos,icp_pos] = obj.init_Figure();
            obj.init_image_panel(imp_pos,axim_pos,ydir);
            obj.init_image_visible_panel(ivp_pos);
            obj.init_image_control_panel(icp_pos);

            %--------------------------------------------------------------
            % Load images
            %--------------------------------------------------------------
            if ~isempty(image_list)
                if iscell(image_list)
                    metainfo_image_input = [];
                    for i=1:length(image_list)
                        metainfo_image_input(i).class = class(image_list{i});
                        metainfo_image_input(i).size  =  size(image_list{i});
                        if strcmpi(metainfo_image_input(i).class,'char')
                            metainfo_image_input(i).char = image_list{i};
                        else
                            metainfo_image_input(i).char = '';
                        end
                    end
                    [i_cdata,i_xdata,i_ydata,i_zdata,i_image_varargin]...
                        = parse_metainfo_image_input(metainfo_image_input);
                    if isempty(i_cdata)
                        Nim = length(image_list);
                        for i=1:Nim
                            iflip = Nim-i+1;
                            obj.add_layer(image_list{iflip});   
                        end
                    else
                        % Nim = 1;
                        obj.add_layer(image_list);  
                    end
                else
                    % Nim = 1;
                    obj.add_layer(image_list);
                end
            end
            
            
            % Set some aspect Ratios.
            obj.Update_ImageAxes_LimHomeAuto();
            obj.Update_ImageAxes_LimHome();
            
            obj.Update_axim_aspectR();
            
            obj.Restore_ImageAxes2LimHome();

            %--------------------------------------------------------------
            % Redefine sizes
            %--------------------------------------------------------------
            w_fig = obj.fig.Position(3); h_fig = obj.fig.Position(4);
            obj.fig.SizeChangedFcn = @obj.resizeUI;
            [imp_pos,axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r] = obj.get_resizePosition(...
                  w_fig,h_fig,obj.axim_aspectR);
            set_figsize(obj.fig,w_fig_r,h_fig_r);
            obj.fig.Visible = 1;
            
            %--------------------------------------------------------------
            % Set up callback functions
            %--------------------------------------------------------------
            % image cursor
            % hdt = datacursormode(obj.fig);
            % hdt.Interpreter = 'none';
            % set(hdt,'UpdateFcn',image_cursor_fcn);
            
        end
        
        %%
        %=================================================================%
        % WINDOW INITIALIZE FUNCTIONS
        %=================================================================%
        
        % Initialize the main figure window
        function [imp_pos,axim_pos,ivp_pos,icp_pos] = init_Figure(obj)
            obj.fig = figure('Visible',0);
            w_fig = 600;
            h_fig = 600;
            aspectR = 1;
            [imp_pos,axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r] = obj.get_resizePosition(...
                 w_fig,h_fig,aspectR);
            set_figsize(obj.fig,w_fig_r,h_fig_r);
        end
        
        function [] = init_image_panel(obj,imp_pos,axim_pos,ydir)
            obj.image_panel = uipanel('Parent',obj.fig);
            obj.image_panel.Units = 'pixels';
            obj.image_panel.Position = imp_pos;
            obj.image_panel.BackgroundColor = [0.8 0.8 0.8];
            obj.image_panel.BorderWidth = 0;
            
            obj.axim_master = axes('Parent',obj.image_panel);
            obj.axim_master.Units = 'pixels';
            obj.axim_master.Position = axim_pos;
            obj.axim_master.DataAspectRatioMode = 'manual';
            obj.axim_master.DataAspectRatio = [1,1,1];
            obj.axim_master.YDir = ydir;
            obj.axim_master.Color = 'none';
            obj.set_custom_axim_toolbar(obj.axim_master);
            obj.axim_master.Box = 1;
            obj.axim_master.NextPlot = 'replacechildren';
            
            obj.XLimHomeAuto = [0 1];
            obj.YLimHomeAuto = [0 1];
            
            obj.ax_plot = axes('Parent',obj.image_panel);
            obj.ax_plot.Units = 'pixels';
            obj.ax_plot.Position = obj.axim_master.Position;
            obj.ax_plot.DataAspectRatioMode = 'manual';
            obj.ax_plot.DataAspectRatio = [1,1,1];
            obj.ax_plot.XLim = obj.axim_master.XLim;
            obj.ax_plot.YLim = obj.axim_master.YLim;
            obj.ax_plot.YDir = obj.axim_master.YDir;
            obj.ax_plot.PickableParts = 'all';
            obj.ax_plot.Color = 'none';
            obj.ax_plot.XTick = [];
            obj.ax_plot.YTick = [];
            obj.ax_plot.XAxis.Visible = 0;
            obj.ax_plot.YAxis.Visible = 0;
            obj.set_custom_axim_toolbar(obj.ax_plot);
            obj.ax_plot.Box = 0;
            set(obj.ax_plot,'ButtonDownFcn',@obj.custom_image_cursor_fcn);
            obj.ax_plot.NextPlot = 'replacechildren';
            
            hlink = linkprop([obj.axim_master obj.ax_plot],...
                {'DataAspectRatio','PlotBoxAspectRatio','XLim','YLim','Position','YDir'});
            setappdata(obj.image_panel,'HLink',hlink);
            
            

            
        end
        
        
        % Initialize the visibility panel
        function [] = init_image_visible_panel(obj,ivp_pos)
            % set UIPanel for image visibility and transparency
            obj.image_visible_panel = uipanel(obj.fig,'FontSize',12,'Units','pixels');
            obj.image_visible_panel.Position = ivp_pos;
            obj.image_visible_panel.BackgroundColor = [0.8 0.8 0.8];
            obj.image_visible_panel.BorderWidth = 0;
        end
        
        % Initialize image control panel
        function [] = init_image_control_panel(obj,icp_pos)
            obj.image_control_panel = uipanel(obj.fig,'FontSize',12,'Units','pixels');
            obj.image_control_panel.Position = icp_pos;
            obj.image_control_panel.BackgroundColor = [0.8 0.8 0.8];
            obj.image_control_panel.BorderWidth = 0;
            
            left_mrgn_imselpppmenu = 5;
            btm_mrgn_imselpppmenu  = 10;
            w_imselpppmenu = 150;
            
            left_mrgn_tpttl = 0;
            btm_mrgn_tpttl  = 20;
            w_tpttl    = 70;
            
            left_mrgn_tp_slider = 5;
            btm_mrgn_tp_slider  = 5;
            w_tp_slider    = 145;
            h_tp_slider    = 17;
            
            left_mrgn_tp_txtedt = 5;
            btm_mrgn_tp_txtedt  = 6;
            w_tp_txtedt    = 50;
            
            left_mrgn_tp_txtedtttl = left_mrgn_tp_txtedt;
            btm_mrgn_tp_txtedtttl  = 20;
            w_tp_txtedtttl    = 50;
            
            left_mrgn_ttlclimctrl = 5;
            btm_mrgn_ttlclimctrl  = 20;
            w_ttlclimctrl = 35;
            
            left_mrgn_climctrlmin_edit = 0;
            btm_mrgn_climctrlmin_edit  = 6;
            w_climctrlmin_edit = 50;
            left_mrgn_climctrlmin = 5;
            btm_mrgn_climctrlmin  = 1;
            w_climctrlmin = 25;
            
            left_mrgn_climctrlmax_edit = 0;
            btm_mrgn_climctrlmax_edit  = 6;
            w_climctrlmax_edit = 50;
            left_mrgn_climctrlmax = 5;
            btm_mrgn_climctrlmax  = 1;
            w_climctrlmax = 25;
            
            % popupmenu for the selection of the image to focus on.
            imsel_image_control_panel = uicontrol('Style','popupmenu','Parent',obj.image_control_panel ,...
                'String',{'- select image -'},'Value',1,'Callback',{@obj.ImageChanged_image_control_panel});
            imsel_image_control_panel.Position = [left_mrgn_imselpppmenu,btm_mrgn_imselpppmenu,...
                w_imselpppmenu,imsel_image_control_panel.Position(4)];
            
            % transparency
            title_transparency = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','Transparency: ', 'HorizontalAlignment','right','FontSize',9);
            title_transparency.Position = [...
                imsel_image_control_panel.Position(1)+imsel_image_control_panel.Position(3)+left_mrgn_tpttl,...
                btm_mrgn_tpttl,w_tpttl,title_transparency.Position(4)];
            title_transparency.BackgroundColor = obj.image_visible_panel.BackgroundColor;
            slider_transparency = uicontrol('Style','slider','Parent',obj.image_control_panel ,...
                'Tag','slider_transparency',...
                'Value',1,'Callback',{@obj.ValueChanged_transparency_slider});
            slider_transparency.Position = [...
                imsel_image_control_panel.Position(1)+imsel_image_control_panel.Position(3)+left_mrgn_tp_slider,...
                btm_mrgn_tp_slider, w_tp_slider, h_tp_slider];
            
            ttltxtedt_transparency = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','value (0-1) :', 'HorizontalAlignment','left','FontSize',9);
            ttltxtedt_transparency.Position = [...
                slider_transparency.Position(1)+slider_transparency.Position(3)+left_mrgn_tp_txtedtttl,...
                btm_mrgn_tp_txtedtttl,w_tp_txtedtttl,ttltxtedt_transparency.Position(4)];
            ttltxtedt_transparency.BackgroundColor = obj.image_visible_panel.BackgroundColor;
            
            text_transparency = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','text_transparency','Units','Pixels','String','',...
                'HorizontalAlignment','right',...
                'Callback',{@obj.TextStringChanged_transparency_slider});
            text_transparency.Position = [...
                slider_transparency.Position(1)+slider_transparency.Position(3)+left_mrgn_tp_txtedt,...
                btm_mrgn_tp_txtedt,w_tp_txtedt,text_transparency.Position(4)];
            
            
            % clim controller
            title_clim_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','CLim: ', 'HorizontalAlignment','right','FontSize',9);
            title_clim_control.Position = [...
                text_transparency.Position(1) + text_transparency.Position(3) + left_mrgn_ttlclimctrl,...
                btm_mrgn_ttlclimctrl,w_ttlclimctrl,title_clim_control.Position(4)];
            title_clim_control.BackgroundColor = obj.image_visible_panel.BackgroundColor;
            
            % clim min
            text_climmin_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','min.', 'HorizontalAlignment','right','FontSize',9);
            text_climmin_control.Position =[...
                title_clim_control.Position(1)+left_mrgn_climctrlmin,...
                btm_mrgn_climctrlmin,w_climctrlmin,text_climmin_control.Position(4)];
            text_climmin_control.BackgroundColor = obj.image_visible_panel.BackgroundColor;
            
            clim_min_input = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','climmin','Units','Pixels','String','','HorizontalAlignment','right',...
                'Callback',{@obj.CLim_Value_changed,1});
            clim_min_input.Position = [...
                text_climmin_control.Position(1)+text_climmin_control.Position(3)+left_mrgn_climctrlmin_edit,...
                btm_mrgn_climctrlmin_edit,w_climctrlmin_edit,clim_min_input.Position(4)];
            
            % clim max
            text_climmax_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
                'String','max.', 'HorizontalAlignment','right','FontSize',9);
            text_climmax_control.Position =[...
                clim_min_input.Position(1)+clim_min_input.Position(3)+left_mrgn_climctrlmax,...
                btm_mrgn_climctrlmax,w_climctrlmax,text_climmax_control.Position(4)];
            text_climmax_control.BackgroundColor = obj.image_visible_panel.BackgroundColor;
            
            clim_max_input = uicontrol('Style','edit','Parent',obj.image_control_panel,...
                'Tag','climmax','Units','Pixels','String','','HorizontalAlignment','right',...
                'Callback',{@obj.CLim_Value_changed,2});
            clim_max_input.Position = [...
                text_climmax_control.Position(1)+text_climmax_control.Position(3)+left_mrgn_climctrlmax_edit,...
                btm_mrgn_climctrlmax_edit,w_climctrlmax_edit,clim_max_input.Position(4)];
            
            % % colormap controller
            % text_cmap_control = uicontrol('Style','text','Parent',obj.image_control_panel ,...
            %     'String','ColorMap', 'HorizontalAlignment','right');
            % text_cmap_control.Position =[imsel_image_control_panel.Position(1)+imsel_image_control_panel.Position(3)+10,...
            %     imsel_image_control_panel.Position(2),50,text_cmap_control.Position(4)];
            % cmap_input = uicontrol('Style','edit','Parent',obj.image_control_panel,...
            %     'Tag','cmap','Units','Pixels','String','','HorizontalAlignment','left',...
            %     'Callback',{@obj.CMap_Changed});
            % cmap_input.Position = [text_cmap_control.Position(1)+text_cmap_control.Position(3)+5,...
            %     imsel_image_control_panel.Position(2),50,cmap_input.Position(4)];
            
            

        end
        
        %%
        %=================================================================%
        % WINDOW UPDATE FUNCTIONS
        %=================================================================%
        
        %-----------------------------------------------------------------%
        % Get the size of components and reconfigure the size of the main
        % figure window.
        %-----------------------------------------------------------------%
        function [imp_pos,axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r] = ...
                get_resizePosition(obj,w_fig,h_fig,aspectR)
            
            % given w_fig, h_fig
            imp_left_margin = 6; imp_btm_margin = 5;
            axim_left_margin = 60; axim_btm_margin = 50; 
            axim_right_margin = 10; axim_top_margin = 30;
            ivp_right_margin = 3;
            icp_btm_margin = 3; ivp_left_margin = 3; icp_top_margin = 3;
            icp_w = 600; icp_h = 40;
            ivp_w = 200; ivp_h_min = 200;
            axim_w_max = w_fig-ivp_w-ivp_left_margin-ivp_right_margin ...
                -axim_left_margin-axim_right_margin-imp_left_margin;
            axim_h_max = h_fig-icp_h-icp_btm_margin-icp_top_margin ...
                -axim_btm_margin-axim_top_margin-imp_btm_margin;
            aspectR_max = axim_w_max / axim_h_max;
            if aspectR_max>=aspectR
                axim_h = axim_h_max;
                axim_w = axim_h * aspectR;
            else
                axim_w = axim_w_max;
                axim_h = axim_w / aspectR;  
            end
            axim_pos = [axim_left_margin,axim_btm_margin,axim_w,axim_h];
            imp_pos = [imp_left_margin,imp_btm_margin,...
                axim_w+axim_left_margin+axim_right_margin,...
                axim_h+axim_btm_margin+axim_top_margin];
            ivp_pos = [imp_pos(1)+imp_pos(3)+ivp_left_margin, imp_pos(2), ivp_w, max(imp_pos(4),ivp_h_min)];
            icp_pos = [imp_left_margin,imp_pos(2)+imp_pos(4)+icp_btm_margin,icp_w,icp_h];
            w_fig_r = imp_left_margin + imp_pos(3) + ivp_left_margin + ivp_w + ivp_right_margin;
            h_fig_r = imp_btm_margin + imp_pos(4) + icp_btm_margin + icp_h + icp_top_margin;
        end
        
        function [ivp_chckbx_pos] = get_visibility_checkbox_position(obj,ivp_pos,im_id)
            ivp_chckbx_pos = [30,ivp_pos(4)-10-22*im_id,150,22];
        end
        function [ivp_ordswtchbtn_pos] = get_orderswitch_btn_position(obj,ivp_pos,im_id)
            ivp_ordswtchbtn_pos = [10,ivp_pos(4)-17-22*im_id,15,15];
        end
        
        function [icp_children] = get_icp_children(obj)
            icp_children = [];
            for i=1:length(obj.image_control_panel.Children)
                switch obj.image_control_panel.Children(i).Style
                    case 'edit'
                        switch lower(obj.image_control_panel.Children(i).Tag)
                            case 'text_transparency'
                                icp_children.text_transparency = obj.image_control_panel.Children(i);
                            case 'climmin'
                                icp_children.clim_min_input = obj.image_control_panel.Children(i);
                            case 'climmax'
                                icp_children.clim_max_input = obj.image_control_panel.Children(i);
                            case 'cmap'
                                icp_children.cmap_input = obj.image_control_panel.Children(i);
                        end
                    case 'slider'
                        icp_children.slider_transparency = obj.image_control_panel.Children(i);
                    case 'popupmenu'
                        icp_children.imsel_image_control_panel = obj.image_control_panel.Children(i);
                end
            end
        end
        
        function add_image_order_switch_button(obj,i)
            ivp_pos = obj.image_visible_panel.Position;
            [ivp_ordchgbtn_pos_i] = obj.get_orderswitch_btn_position(ivp_pos,i);
            obj.image_ordswtchbtn_list{i} = uicontrol('Style','pushbutton',...
                'Parent',obj.image_visible_panel,'Position',ivp_ordchgbtn_pos_i,...
                'String','>','FontSize',12,'Value',true,...
                'Callback',{@obj.image_order_switch,i},...
                'Tag',num2str(i));
        end
        
        function add_layer(obj,image_input)
            isvimage_obj = ISVImage(image_input,obj);
            
            hlink = getappdata(obj.image_panel,'HLink');
            addtarget(hlink,isvimage_obj.ax);
            
            Nim = length(obj.image);
            
            if Nim>0
                image_names = [{obj.image.name}];
            else
                image_names = {};
            end

            if isempty(isvimage_obj.name)
                i=1;
                flg = 1;
                while flg
                    image_name_tmp = sprintf('Image %03d',i);
                    if ~any(strcmpi(image_name_tmp,image_names))
                        isvimage_obj.name = image_name_tmp;
                        flg = 0;
                    else
                        i=i+1;
                    end
                end
            end
            
            isvimage_obj.id = 1;
            for i=1:Nim
                obj.image(i).id = obj.image(i).id + 1;
            end
            
            
            % resolve layer ordering. The added image is placed on top of
            % all the images.
            Nim = length(obj.image);
            for i=1:Nim
                obj.image(i).order = obj.image(i).order + 1;
            end
            isvimage_obj.order = 1;
            
            % add a newly created ISV_Image object to property
            if isempty(obj.image)
                obj.image = isvimage_obj;
            else
                obj.image = [isvimage_obj obj.image];
            end
            
            % add the image to image_visible_panel
            ivp_pos = obj.image_visible_panel.Position;
            [ivp_chckbx_pos_1] = obj.get_visibility_checkbox_position(ivp_pos,1);
            isvimage_obj.ui_checkbox_visbility = uicontrol(...
                 'Style','checkbox','Parent',obj.image_visible_panel,...
                 'Position',ivp_chckbx_pos_1,...
                 'String',isvimage_obj.name,'Value',true,...
                 'Callback',{@obj.change_image_visibility,isvimage_obj});
            addlistener(isvimage_obj,'name','PostSet',@obj.Listener_image_name);
            addlistener(isvimage_obj,'order','PostSet',@obj.Listener_Image_Order);
            addlistener(isvimage_obj,'transparency','PostSet',@obj.Listener_transparency);
            addlistener(isvimage_obj,'AlphaDataHome','PostSet',@obj.Listener_AlphaDataHome);
            addlistener(isvimage_obj,'cmap','PostSet',@obj.Listener_Colormap);
            addlistener(isvimage_obj,'clim','PostSet',@obj.Listener_CLim);
            
            cm = uicontextmenu(obj.fig);
            m2 = uimenu(cm,'Text','Rename','MenuSelectedFcn',{@obj.VisChkbx_Menu_rename_image,isvimage_obj});
            m4 = uimenu(cm,'Text','Change Colormap','MenuSelectedFcn',{@obj.VisChkbx_Menu_CMap_Change,isvimage_obj});
            m3 = uimenu(cm,'Text','Set Ignore Value','MenuSelectedFcn',{@obj.VisChkbx_Menu_change_alphadata,isvimage_obj});
            m1 = uimenu(cm,'Text','Remove','MenuSelectedFcn',{@obj.VisChkbx_Menu_remove_layer,isvimage_obj});
            % m1.MenuSelectedFcn = {@obj.remove_layer,isvimage_obj};
            isvimage_obj.ui_checkbox_visbility.ContextMenu = cm;
            isvimage_obj.ax.NextPlot = 'add';
            
            % add order change button
            i_oc = Nim;
            if i_oc>0
                obj.add_image_order_switch_button(i_oc);
            end

            % add the image to image_control_panel
            [icp_children] = obj.get_icp_children;
            icp_children.imsel_image_control_panel.String = ...
                [icp_children.imsel_image_control_panel.String(1) {isvimage_obj.name},...
                 reshape(icp_children.imsel_image_control_panel.String(2:end),1,[])];
            if icp_children.imsel_image_control_panel.Value>1
                icp_children.imsel_image_control_panel.Value = icp_children.imsel_image_control_panel.Value + 1;
            else
                
            end
            
            obj.Update_ImageAxes_LimHomeAuto();
            obj.Update_ImageAxes_LimHome();
            
            isvimage_obj.ax.DataAspectRatio = [1,1,1];
            
            obj.set_custom_axim_toolbar(isvimage_obj.ax);
            set(isvimage_obj.ax,'ButtonDownFcn',@obj.custom_image_cursor_fcn);
            
            uistack(obj.ax_plot,'top');
            
        end
        
        function remove_layer(obj,isvimage_obj)
            im_ord_idx = isvimage_obj.order;
            % image_order = [obj.image.order];
            im_idx = isvimage_obj.id;
            
            % im_idx = find(image_order==im_ord_idx);
            Nim = length(obj.image);
            idx_c = setdiff(1:Nim,im_idx);
            
            % remove the image from image axes
            delete(isvimage_obj.ax);
            delete(isvimage_obj.ui_checkbox_visbility);
            % delete(isvimage_obj.info);
            delete(isvimage_obj);
            
            % update list of the image
            obj.image = obj.image(idx_c);
            for i=1:(Nim-1)
                if obj.image(i).order > im_ord_idx
                    obj.image(i).order = obj.image(i).order-1;
                end
            end

            % Update the image control panel
            [icp_children] = obj.get_icp_children();
            if icp_children.imsel_image_control_panel.Value == im_idx
                icp_children.imsel_image_control_panel.Value = 1;
            elseif icp_children.imsel_image_control_panel.Value > im_idx
                icp_children.imsel_image_control_panel.Value = icp_children.imsel_image_control_panel.Value-1;
            end
            icp_children.imsel_image_control_panel.String = ...
                [icp_children.imsel_image_control_panel.String(1) ...
                reshape(icp_children.imsel_image_control_panel.String(idx_c+1),1,[])];
            obj.ImageChanged_image_control_panel(icp_children.imsel_image_control_panel,[]);

            % remove the image from the image visible panel
            if Nim>1
                delete(obj.image_ordswtchbtn_list{Nim-1});
                obj.image_ordswtchbtn_list = obj.image_ordswtchbtn_list(1:end-1);
            end
            
            
        end
        
        function [] = set_custom_axim_toolbar(obj,ax)
            [axtoolbar_obj,axtoolbar_btns] = axtoolbar(ax,{'restoreview','pan','zoomout','zoomin','datacursor'});
            for i=1:length(axtoolbar_btns)
                switch axtoolbar_btns(i).Tooltip
                    case 'Restore View'
                        btn_restore_view = axtoolbar_btns(i);
                end
            end
            btn_restore_view.ButtonPushedFcn = @obj.Restore_ImageAxes2LimHome;
        end
        
        function Update_ImageAxes_LimHomeAuto(obj)
            if isempty(obj.image)
                obj.XLimHomeAuto = [0 1];
                obj.XLimHomeAuto = [0 1];
            else
                image_xranges = cat(1,obj.image.XLimHome);
                image_yranges = cat(1,obj.image.YLimHome);
                obj.XLimHomeAuto = [min(image_xranges(:)) max(image_xranges(:))];
                obj.YLimHomeAuto = [min(image_yranges(:)) max(image_yranges(:))];
            end
        end
        
        function Update_ImageAxes_LimHome(obj)
            if isempty(obj.XLimHomeMan)
                obj.XLimHome = obj.XLimHomeAuto;
            else
                obj.XLimHome = obj.XLimHomeMan;
            end 
            if isempty(obj.YLimHomeMan)
                obj.YLimHome = obj.YLimHomeAuto;
            else
                obj.YLimHome = obj.YLimHomeMan;
            end
        end
        
        function Update_axim_aspectR(obj)
            S = abs(obj.XLimHome(2)-obj.XLimHome(1));
            L = abs(obj.YLimHome(2)-obj.YLimHome(1));
            obj.axim_aspectR = S/L;
        end
        
        function Restore_ImageAxes2LimHome(obj,hObj,eventData)
            obj.Update_axim_aspectR();
            obj.axim_master.XLim = obj.XLimHome;
            obj.axim_master.YLim = obj.YLimHome;
        end
        
        %% Listeners for the property of ISV_Image objects
        function [] = Listener_image_name(obj,hObject,eventData)
            eventData.AffectedObject.ui_checkbox_visbility.String = eventData.AffectedObject.name;
            im_idx = eventData.AffectedObject.id;
            [icp_children] = obj.get_icp_children();
            icp_children.imsel_image_control_panel.String{im_idx+1} = eventData.AffectedObject.name;
        end
        
        function [] = Listener_AlphaDataHome(obj,hObject,eventData)
            eventData.AffectedObject.imobj.AlphaData...
                = eventData.AffectedObject.AlphaDataHome * eventData.AffectedObject.transparency;
        end
        
        function [] = Listener_transparency(obj,hObject,eventData)
            eventData.AffectedObject.imobj.AlphaData...
                = eventData.AffectedObject.AlphaDataHome * eventData.AffectedObject.transparency;
        end
        
        function [] = Listener_Colormap(obj,hObject,eventData)
            colormap(eventData.AffectedObject.ax,eventData.AffectedObject.cmap);
        end
        
        function [] = Listener_CLim(obj,hObject,eventData)
            eventData.AffectedObject.ax.CLim ...
                = eventData.AffectedObject.clim;
        end
        
        function [] = Listener_Image_Order(obj,hObject,eventData)
            ivp_pos = obj.image_visible_panel.Position;
            [ivp_chckbx_pos] = obj.get_visibility_checkbox_position(ivp_pos,eventData.AffectedObject.order);
            eventData.AffectedObject.ui_checkbox_visbility.Position = ivp_chckbx_pos;
        end
        
        %%
        %=================================================================%
        % INTERACTIVE CALLBACK FUNCTIONS
        %=================================================================%
        %%
        %-----------------------------------------------------------------%
        % SizeChangedFcn for the main figure window.
        %-----------------------------------------------------------------%
        function resizeUI(obj,hObject,eventData)
            w_fig = hObject.Position(3);
            h_fig = hObject.Position(4);
            
            [imp_pos,axim_pos,ivp_pos,icp_pos,w_fig_r,h_fig_r]...
                = obj.get_resizePosition(w_fig,h_fig,obj.axim_aspectR);
            
            % scale image axes
            obj.image_panel.Position = imp_pos;
            Nim = length(obj.image);
            obj.axim_master.Position = axim_pos;
            for i=1:Nim
                obj.image(i).ax.Position = axim_pos;
            end
            
            % move Visiblity_panel
            obj.image_visible_panel.Position = ivp_pos;
            for i=1:Nim
                [ivp_chckbx_pos_i] = obj.get_visibility_checkbox_position(ivp_pos,i);
                obj.image(i).ui_checkbox_visbility.Position = ivp_chckbx_pos_i;
            end
            
            for i=1:(Nim-1)
                [ivp_ordswtchbtn_pos_i] = obj.get_orderswitch_btn_position(ivp_pos,i);
                % iflip = length(h_vis_chkbox_list)-i;
                obj.image_ordswtchbtn_list{i}.Position = ivp_ordswtchbtn_pos_i;
            end

            % replace transparency_panel
            obj.image_control_panel.Position = icp_pos;

        end
        
        %%
        %-----------------------------------------------------------------%
        % Visibility controller Callback function
        %-----------------------------------------------------------------%
        function [] = change_image_visibility(obj,hObject,eventData,isvimage_obj)
            im_idx = isvimage_obj.id;
            
            switch hObject.Value
                case 0
                    isvimage_obj.ax.Visible = 0;
                    isvimage_obj.imobj.Visible = 0;
                    %
                    [icp_children] = obj.get_icp_children();
                    if im_idx == icp_children.imsel_image_control_panel.Value-1
                        icp_children.imsel_image_control_panel.Value = 1;
                        obj.ImageChanged_image_control_panel(icp_children.imsel_image_control_panel,[]);
                    end
                case 1
                    isvimage_obj.ax.Visible = 1;
                    isvimage_obj.imobj.Visible = 1;
            end
        end
        
        %-----------------------------------------------------------------%
        % Image order change callback function 
        %-----------------------------------------------------------------%
        function [] = image_order_switch(obj,hObject,eventData,i)
            % change the image arange order.
            image_order = [obj.image.order];
            idx_ip1 = find(image_order==(i+1));
            idx_i   = find(image_order==i);
            uistack(obj.image(idx_ip1).ax,'up');
            obj.image(idx_i).order = obj.image(idx_i).order + 1;
            obj.image(idx_ip1).order = obj.image(idx_ip1).order - 1;
            
            % Listener will do the rest of work.
        end
        
        %-----------------------------------------------------------------%
        % Context menus
        %-----------------------------------------------------------------%
        function VisChkbx_Menu_remove_layer(obj,hObject,eventData,isvimage_obj)
            obj.remove_layer(isvimage_obj);
        end
        
        function [] = VisChkbx_Menu_rename_image(obj,hObject,eventData,isvimage_obj)
            new_name = inputdlg('New Name:','Rename Image',1,{isvimage_obj.name});
            if ~isempty(new_name)
                isvimage_obj.name = new_name{1};
            end
        end
        
        function [] = VisChkbx_Menu_CMap_Change(obj,hObject,eventData,isvimage_obj)
            cmap_new = inputdlg('Colormap:','Chage Colormap',1,{''});
            if ~isempty(cmap_new)
                isvimage_obj.cmap = cmap_new{1};
            end
        end
        
        function [] = VisChkbx_Menu_change_alphadata(obj,hObject,eventData,isvimage_obj)
            Answer = inputdlg_alphadata(isvimage_obj.name);
            ignore_val = Answer.ignore_value;
            if ~isempty(Answer)
                if strcmpi(ignore_val,'NaN')
                    ignore_val = NaN;
                    msk = double(~isnan(isvimage_obj.imobj.CData));
                else
                    ignore_val = str2double(ignore_val);
                    if isnan(ignore_val)
                        error('Input "Ignore Value" is invalid.');
                    end
                    msk = double(~isvimage_obj.imobj.CData==ignore_val);
                end
                switch Answer.option1.id
                    case 1 % 'Combine the current AlphaDataHome'
                        isvimage_obj.AlphaDataHome = isvimage_obj.AlphaDataHome.*msk;
                    case 2 % 'Overwrite the current AlphaDataHome'
                        isvimage_obj.AlphaDataHome = msk;
                end
            end
        end
        
        %%
        %-----------------------------------------------------------------%
        % Image control panel Callback functions
        %-----------------------------------------------------------------%
        % Change the image for which properties are controlled.
        function [] = ImageChanged_image_control_panel(obj,hObject,eventData)
            [icp_children] = obj.get_icp_children();
            id_im = hObject.Value-1;
            if id_im > 0
                if obj.image(id_im).ui_checkbox_visbility.Value==1
                    icp_children.slider_transparency.Value = obj.image(id_im).transparency;
                    icp_children.text_transparency.String = num2str(icp_children.slider_transparency.Value);
                    icp_children.clim_min_input.String = num2str(obj.image(id_im).ax.CLim(1));
                    icp_children.clim_max_input.String = num2str(obj.image(id_im).ax.CLim(2));
                    % icp_children.cmap_input.String = '';
                else
                    hObject.Value = 1;
                    ImageChanged_image_control_panel(obj,hObject,eventData);
                end
            else
                icp_children.slider_transparency.Value = 1;
                icp_children.text_transparency.String = '';
                icp_children.clim_min_input.String = '';
                icp_children.clim_max_input.String = '';
                % icp_children.cmap_input.String = '';
            end
            
        end
        
        % Controll the transparency of the image: TEXT INPUT
        function [] = ValueChanged_transparency_slider(obj,hObject,eventData)
            [icp_children] = obj.get_icp_children();
            id_im = icp_children.imsel_image_control_panel.Value-1;
            if id_im > 0
                icp_children.text_transparency.String = num2str(hObject.Value);
                obj.image(id_im).transparency = hObject.Value;
            else
                
            end
            
        end
        
        % Controll the transparency of the image: SLIDER INPUT
        function [] = TextStringChanged_transparency_slider(obj,hObject,eventData)
            [icp_children] = obj.get_icp_children();           
            v = str2double(hObject.String);
            if isnan(v)
                error('Input value is invalid');
            end
            id_im = icp_children.imsel_image_control_panel.Value-1;
            if if_im > 0
                icp_children.slider_transparency.Value = v;
                obj.image(id_im).transparency = v;
            else
                
            end
        end
        
        % Controll CLim of the image
        function [] = CLim_Value_changed(obj,hObject,eventData,climidx)
            [icp_children] = obj.get_icp_children();
            v = str2double(hObject.String);
            id_im = icp_children.imsel_image_control_panel.Value-1;
            if id_im > 0
                obj.image(id_im).clim(climidx) = v;
            end
        end
        
        %-----------------------------------------------------------------%
        % Image Cursor Callback function
        %-----------------------------------------------------------------%
        function image_cursor(obj,hObject,eventData)
            pos = eventData.IntersectionPoint;
            x = pos(1); y = pos(2);
            % im = get(event_obj,'Target');
            switch obj.XY_COORDINATE_SYSTEM
                case 'NORTHEAST'
                    xy_format = '%6.4f';
                    xy_str = '(eating, northing)';
                case 'PLANETOCENTRIC'
                    xy_str = '(latitude, pltc longitude)';
                case 'IMAGEPIXELS'
                    x = round(x); y = round(y);
                    xy_format = '% 6d';
                    xy_str = '(x, y)';
            end
            p = obj.plot(x,y,'Marker','none');
            expr = [xy_str ' = ' sprintf(['(' xy_format ',' xy_format ')'],x,y)];
            p.DataTipTemplate.DataTipRows(1).Label = expr;
            p.DataTipTemplate.DataTipRows(1).Value = '';
            p.DataTipTemplate.DataTipRows(1).Format = '%s';
            
            
            Nim = length(obj.image);
            for i=1:Nim
                if ((x>obj.image(i).XLimHome(1) && x<obj.image(i).XLimHome(2)) || (x>obj.image(i).XLimHome(2) && x<obj.image(i).XLimHome(1)) )...
                       && ((y>obj.image(i).YLimHome(1) && y<obj.image(i).YLimHome(2)) || (y>obj.image(i).YLimHome(2) && y<obj.image(i).YLimHome(1)) )...
                    [x_imi] = ceil((x-obj.image(i).XLimHome(1))/obj.image(i).Pixel_Size(1));
                    [y_imi] = ceil((y-obj.image(i).YLimHome(1))/obj.image(i).Pixel_Size(2));
                    val = obj.image(i).imobj.CData(y_imi,x_imi,:);
                else
                    x_imi = nan; y_imi = nan; val = nan;
                end
                if length(val)==1
                    % output_txt{end+1} = sprintf('%10s\n (% 6d, % 6d) : % 8.5f',...
                    %         obj.image(i).name,x_imi,y_imi,val);
                    expr = sprintf('%s\n (% 6d, % 6d) : % 8.5f',obj.image(i).name,x_imi,y_imi,val);
                    row = dataTipTextRow(expr,'','%s');
                elseif length(val)==3
                    % output_txt{end+1} = sprintf('%10s\n (% 6d, % 6d) : (% 5.5f % 5.5f % 5.5f)',...
                    %         obj.image(i).name,x_imi,y_imi,val(1),val(2),val(3));
                    expr = sprintf('%s\n (% 6d, % 6d) : (% 5.5f % 5.5f % 5.5f)',...
                            obj.image(i).name,x_imi,y_imi,val(1),val(2),val(3));
                    row = dataTipTextRow(expr,'','%s');
                end
                p.DataTipTemplate.DataTipRows(1+i) = row;
            end
            
            dt = datatip(p,x,y);
            
        end
        
        %-----------------------------------------------------------------%
        % Plot the image from the outside of the ImageStackView class
        % Create a top layer ax for plotting if it isn't initilized.
        %-----------------------------------------------------------------%
        function [imobj] = imagesc_overlay(obj,varargin)
            % hold(obj.ax_plot,'all');
            % xlim_tmp = obj.axim_master.XLim;
            % ylim_tmp = obj.axim_master.YLim;
            % ydir = obj.axim_master.YDir;
            imobj = imagesc(obj.ax_plot,varargin{:});
            set(imobj,'ButtonDownFcn',obj.ax_plot.ButtonDownFcn);
            % obj.ax_plot.XLim = xlim_tmp;
            % obj.ax_plot.YLim = ylim_tmp;
            % obj.ax_plot.YDir = ydir;
            % obj.ax_plot.Color = 'none';
            % obj.ax_plot.DataAspectRatio = [1,1,1];
            % obj.set_custom_axim_toolbar(obj.ax_plot);
            % set(obj.ax_plot,'ButtonDownFcn',@obj.custom_image_cursor_fcn);
        end
            
        function [p] = plot(obj,varargin)
            % xlim_tmp = obj.axim_master.XLim;
            % ylim_tmp = obj.axim_master.YLim;
            % ydir = obj.axim_master.YDir;
            p = plot(obj.ax_plot,varargin{:});
            % obj.ax_plot.XLim = xlim_tmp;
            % obj.ax_plot.YLim = ylim_tmp;
            % obj.ax_plot.YDir = ydir;
            % obj.ax_plot.Color = 'none';
            % obj.ax_plot.DataAspectRatio = [1,1,1];
            % obj.set_custom_axim_toolbar(obj.ax_plot);
            % set(obj.ax_plot,'ButtonDownFcn',@obj.custom_image_cursor_fcn);
            
            
        end  
        
    end
end

