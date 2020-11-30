classdef HSIview < handle
    % HSIview
    %   Viewer for spectral image cubes. It basically supports
    %   hyperspectral image cubes but also can be used for viewing
    %   multispectral image cubes.
    
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
        function obj = HSIview(rgb,hsiar_input,varargin)
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
            obj.nhsi = 0;
            % decode the input hsiar
            obj.init_hsiar(hsiar_input);
            
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
                        obj.add_HSIelem(hsiar_input{1}{:});
                    elseif isa(hsiar_input{1},'HSI') || isa(hsiar_input{1},'HSIdataGLTproj') || isa(hsiar_input{1},'MASTCAMMSI')
                        obj.add_HSIelem(hsiar_input{:});
                    else
                        error('Input hsiar is not proper.');
                    end
                elseif length(hsiar_input)>1
                    if (isa(hsiar_input{1},'HSI') || isa(hsiar_input{1},'HSIdataGLTproj') || isa(hsiar_input{1},'MASTCAMMSI')) ...
                            && ~(isa(hsiar_input{2},'HSI') || isa(hsiar_input{2},'HSIdataGLTproj') || isa(hsiar_input{2},'MASTCAMMSI') || iscell(hsiar_input{2}))
                        obj.add_HSIelem(hsiar_input{:});
                    else
                        nelem = length(hsiar_input);
                        for i=1:nelem
                            if iscell(hsiar_input{i})
                                obj.add_HSIelem(hsiar_input{i}{:});
                            elseif isa(hsiar_input{i},'HSI') || isa(hsiar_input{i},'HSIdataGLTproj') || isa(hsiar_input{i},'MASTCAMMSI')
                                obj.add_HSIelem(hsiar_input{i});
                            else
                                error('Input hsiar is not proper.');
                            end
                        end
                    end
                end
            elseif isa(hsiar_input,'HSI') || isa(hsiar_input,'HSIdataGLTproj') || isa(hsiar_input,'MASTCAMMSI')
                obj.add_HSIelem(hsiar_input);
            end
        end
        
        function add_HSIelem(obj,varargin)
            % hsiar_i:
            %  {HSIobj,varargin...}
            if length(varargin)==1 && isa(varargin{1},'HSIview_HSIelem')
                obj_HSIelem = varargin{1};
            else
                obj_HSIelem = HSIview_HSIelem(varargin{:});
            end
            if isempty(obj.hsiar)
                obj.hsiar = obj_HSIelem;
            else
                obj.hsiar = [obj.hsiar obj_HSIelem];
            end
            obj.nhsi = obj.nhsi + length(obj_HSIelem);
        end
        
        function [] = init_ImageStackView(obj,rgb,varargin)
            obj.obj_ISV = ImageStackView(rgb,varargin{:});
        end
        
        function [] = init_SpecView(obj,varargin)
            obj.obj_SpecView = SpecView(varargin{:});
        end
        
        
        % function [s,l] = get_hsi_coord_HSI(obj,x,y,hsiari)
        %     switch obj.obj_ISV.XY_COORDINATE_SYSTEM
        %         case 'NORTHEAST'
        %             [s] = round((x-hsiari.hdr.x(1))/hsiari.hdr.map_info.dx + 1);
        %             [l] = round((hsiari.hdr.y(1)-y)/hsiari.hdr.map_info.dy + 1);
        % 
        %         case 'PLANETOCENTRIC'
        %             error('Not implemented yet');
        %         case 'IMAGEPIXELS'
        %             s = x; l = y;
        %     end
        %     if s<1 || s > hsiari.hsi.hdr.samples || l<1 || l > hsiari.hsi.hdr.lines
        %         s = nan; l = nan;
        %     end
        % end
        
%         function [s,l] = get_hsi_coord_HSIdataGLTproj(obj,x,y,hsiari)
%             switch obj.obj_ISV.XY_COORDINATE_SYSTEM
%                 case 'NORTHEAST'
%                     [s_proj] = round((x-hsiari.hsi.GLTdata.hdr.easting(1))/hsiari.hsi.GLTdata.hdr.map_info.dx + 1);
%                     [l_proj] = round((hsiari.hsi.GLTdata.hdr.northing(1)-y)/hsiari.hsi.GLTdata.hdr.map_info.dy + 1);
% 
%                 case 'PLANETOCENTRIC'
%                     error('Not implemented yet');
%                 case 'IMAGEPIXELS'
%                     s_proj = x; l_proj = y;
%             end
%             if s_proj<1 || s_proj > hsiari.hsi.GLTdata.hdr.samples || l_proj<1 || l_proj > hsiari.hsi.GLTdata.hdr.lines
%                 s = nan; l = nan;
%             else
%                 s = hsiari.hsi.GLTdata.img(l_proj,s_proj,1);
%                 l = hsiari.hsi.GLTdata.img(l_proj,s_proj,2);
%             end
%             if s<1 || s > hsiari.hsi.HSIdata.hdr.samples || l<1 || l > hsiari.hsi.HSIdata.hdr.lines
%                 s = nan; l = nan;
%             end
%         end
%         
%         function [s,l] = get_hsi_coord_MASTCAMMSI(obj,x,y,hsiari)
%             switch obj.obj_ISV.XY_COORDINATE_SYSTEM
%                 case {'NORTHEAST','PLANETOCENTRIC'}
%                     error('Not supported');
%                 case 'IMAGEPIXELS'
%                     s = x; l = y;
%             end
%             if s<1 || s > hsiari.hsi.hdr.samples || l<1 || l > hsiari.hsi.hdr.lines
%                 s = nan; l = nan;
%             end
%         end
            
        
%         function [s,l] = get_hsi_coord(obj,x,y,i)
%             hsiari = obj.hsiar(i);
%             if isa(hsiari.hsi,'HSI')
%                 [s,l] = obj.get_hsi_coord_HSI(x,y,hsiari);
% %                 switch obj.obj_ISV.XY_COORDINATE_SYSTEM
% %                     case 'NORTHEAST'
% %                         [s] = round((x-hsiari.hdr.x(1))/hsiari.hdr.map_info.dx + 1);
% %                         [l] = round((hsiari.hdr.y(1)-y)/hsiari.hdr.map_info.dy + 1);
% %                     case 'PLANETOCENTRIC'
% %                         error('Not implemented yet');
% %                     case 'IMAGEPIXELS'
% %                         s = x; l = y;
% %                 end
% %                 if s<1 || s > hsiari.hsi.hdr.samples || l<1 || l > hsiari.hsi.hdr.lines
% %                     s = nan; l = nan;
% %                 end
%                 
%             elseif isa(hsiari.hsi,'HSIdataGLTproj')
%                 [s,l] = obj.get_hsi_coord_HSIdataGLTproj(x,y,hsiari);
% %                 switch obj.obj_ISV.XY_COORDINATE_SYSTEM
% %                     case 'NORTHEAST'
% %                         [s_proj] = round((x-hsiari.hsi.GLTdata.hdr.easting(1))/hsiari.hsi.GLTdata.hdr.map_info.dx + 1);
% %                         [l_proj] = round((hsiari.hsi.GLTdata.hdr.northing(1)-y)/hsiari.hsi.GLTdata.hdr.map_info.dy + 1);
% %                         
% %                     case 'PLANETOCENTRIC'
% %                         error('Not implemented yet');
% %                     case 'IMAGEPIXELS'
% %                         s_proj = x; l_proj = y;
% %                 end
% %                 if s_proj<1 || s_proj > hsiari.hsi.GLTdata.hdr.samples || l_proj<1 || l_proj > hsiari.hsi.GLTdata.hdr.lines
% %                     s = nan; l = nan;
% %                 else
% %                     s = hsiari.hsi.GLTdata.img(l_proj,s_proj,1);
% %                     l = hsiari.hsi.GLTdata.img(l_proj,s_proj,2);
% %                 end
% %                 if s<1 || s > hsiari.hsi.HSIdata.hdr.samples || l<1 || l > hsiari.hsi.HSIdata.hdr.lines
% %                     s = nan; l = nan;
% %                 end
%             elseif isa(hsiari.hsi,'MASTCAMMSI')
%                 [s,l] = obj.get_hsi_coord_MASTCAMMSI(x,y,hsiari);
% %                 switch obj.obj_ISV.XY_COORDINATE_SYSTEM
% %                     case {'NORTHEAST','PLANETOCENTRIC'}
% %                         error('Not supported');
% %                     case 'IMAGEPIXELS'
% %                         s = x; l = y;
% %                 end
% %                 if s<1 || s > hsiari.hsi.hdr.samples || l<1 || l > hsiari.hsi.hdr.lines
% %                     s = nan; l = nan;
% %                 end
%             end
%                
%         end
        
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
            for i=1:obj.nhsi
                % convert (x,y) into (s,l) in the reference image
                % coordinate.
                [s,l] = obj.hsiar(i).get_hsi_coord(x,y,obj.obj_ISV.XY_COORDINATE_SYSTEM);
                % get spectra
                if ~isnan(s) && ~isnan(l)
                    [spc,wv,bdxes] = obj.hsiar(i).get_spectrum(s,l);
                    % if isa(obj.hsiar(i).hsi,'HSI')
                    %     % [s,l] = obj.get_hsi_coord_HSI(x,y,obj.hsiar(i));
                    %     [spc,wv,bdxes] = obj.hsiar(i).hsi.get_spectrum(s,l,...
                    %         'BANDS',obj.hsiar(i).bands,...
                    %         'BANDS_INVERSE',obj.hsiar(i).is_bands_inverse,...
                    %         'AVERAGE_WINDOW',obj.hsiar(i).ave_window);
                    % elseif isa(obj.hsiar(i).hsi,'HSIdataGLTproj')
                    %     % [s,l] = obj.get_hsi_coord_HSIdataGLTproj(x,y,obj.hsiar(i));
                    %     [spc,wv,bdxes] = obj.hsiar(i).hsi.HSIdata.get_spectrum(s,l,...
                    %         'BANDS',obj.hsiar(i).bands,...
                    %         'BANDS_INVERSE',obj.hsiar(i).is_bands_inverse,...
                    %         'AVERAGE_WINDOW',obj.hsiar(i).ave_window);
                    % elseif isa(obj.hsiar(i).hsi,'MASTCAMMSI')
                    %     % [s,l] = obj.get_hsi_coord_MASTCAMMSI(x,y,obj.hsiar(i));
                    %     [spc,wv,bdxes] = obj.hsiar(i).hsi.get_spectrum(s,l,...
                    %         'BANDS',obj.hsiar(i).bands,...
                    %         'BANDS_INVERSE',obj.hsiar(i).is_bands_inverse,...
                    %         'AVERAGE_WINDOW',obj.hsiar(i).ave_window);
                    % end
                    % spc = spc + obj.hsiar(i).spc_shift;
                    % if obj.hsiar(i).is_bands_inverse
                    %     bdxes = obj.hsiar(i).hdr.bands-bdxes+1;
                    % end
                    if length(hsivplot_obj.line_obj)<i
                        line_obj = obj.obj_SpecView.plot([wv,spc,obj.hsiar(i).varargin_plot,...
                            'DisplayName',sprintf('%s X:% 4d, Y:% 4d',obj.hsiar(i).name,s,l)],...
                            {'Band',bdxes});
                        % store line object into HSIviewPlot object.
                        hsivplot_obj.add_lineobj(line_obj);
                    else
                        hsivplot_obj.line_obj(i).XData = wv;
                        hsivplot_obj.line_obj(i).YData = spc;
                        hsivplot_obj.line_obj(i).DisplayName = sprintf('%s X:% 4d, Y:% 4d',obj.hsiar(i).name,s,l);
                    end
                end

            end
            obj.obj_SpecView.set_xlim();
            obj.obj_SpecView.set_ylim();
            
        end
        
        function [out] = image_BtnDwnFcn_HSIview(obj,hObject,eventData)
            % DataTip is created as the same way in ImageStackView
            [out] = obj.obj_ISV.image_BtnDwnFcn(hObject,eventData);
            out.cursor_obj.DeleteFcn = @obj.image_cursor_delete_current;
            
            % get (x,y) coordinate in the Hyperspectral image 
            % pos = eventData.IntersectionPoint;
            % s = pos(1); l = pos(2);
            % plot spectra

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
            % for j=1:length(cursor_obj.UserData.HSIviewPlot_obj)
            %     delete(cursor_obj.UserData.HSIviewPlot_obj(j));
            % end
            delete(cursor_obj.UserData.HSIviewPlot_obj);
            obj.obj_ISV.image_cursor_delete_current(cursor_obj,eventData);
        end
    end
end

