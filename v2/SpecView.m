classdef SpecView < handle
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        ax
        ax_Properties
        XLimMode
        XLimMargin
        XLimMan
        YLimMode
        YLimMargin
        YLimMan
        XLabel
        YLabel
        Legend_Position
        Legend_Interpreter
    end
    
    methods
        function [obj] = SpecView(varargin)
            % XLimMode {'manual','auto','stretch01'}
            figure_Position = [];
            figure_Units = 'pixels';
            ax_Position = [];
            ax_Units = 'normal';
            obj.XLimMode = 'auto';
            obj.XLimMargin = 0;
            obj.XLimMan = [];
            obj.YLimMode = 'auto';
            obj.YLimMargin = 0.05;
            obj.YLimMan = [];
            obj.XLabel = '';
            obj.YLabel = '';
            obj.Legend_Position = 'northwest';
            obj.Legend_Interpreter = 'none';
            
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for n=1:2:(length(varargin)-1)
                    switch upper(varargin{n})
                        case 'FIGURE_POSITION'
                            figure_Position = varargin{n+1};
                        case 'FIGURE_UNITS'
                            figure_Units = varargin{n+1};
                        case 'AX_POSITION'
                            ax_Position = varargin{n+1};
                        case 'AX_UNITS'
                            ax_Units = varargin{n+1};
                        case 'XLIMMODE'
                            obj.XLimMode = varargin{n+1};
                        case 'XLIMMARGIN'
                            obj.XLimMargin = varargin{n+1};
                        case 'XLIM'
                            obj.XLimMan = varargin{n+1};
                            if ~isempty(obj.XLimMan)
                                obj.XLimMode = 'manual';
                                obj.XLimMargin = [];
                            end
                        case 'YLIMMODE'
                            obj.YLimMode = varargin{n+1};
                        case 'YLIMMARGIN'
                            obj.YLimMargin = varargin{n+1};
                        case 'YLIM'
                            obj.YLimMan = varargin{n+1};
                            if ~isempty(obj.YLimMan)
                                obj.YLimMode = 'manual';
                                obj.YLimMargin = [];
                            end
                        case 'XLABEL'
                            obj.XLabel = varargin{n+1};
                        case 'YLABEL'
                            obj.YLabel = varargin{n+1};
                        case 'LEGEND_POSITION'
                            obj.Legend_Position = varargin{n+1};
                        case 'LEGEND_INTERPRETER'
                            obj.Legend_Interpreter = varargin{n+1};
                        otherwise
                            error('Unrecognized option: %s', varargin{n});
                    end
                end
            end
            
            obj.fig = figure();
            obj.fig.Units = figure_Units;
            if ~isempty(figure_Position)
                obj.fig.Position = figure_Position;
            end
            obj.ax = subplot(1,1,1);
            obj.ax.Units = ax_Units;
            if ~isempty(ax_Position)
                obj.ax.Position = ax_Position;
            end
            
        end
        
        function [] = plot(obj,plot_varargin,dataTipTextRow_varargin)
            p = plot(obj.ax,plot_varargin{:});
            % Always show indexes
            row_add1 = dataTipTextRow('Index', 1:length(p.XData));
            p.DataTipTemplate.DataTipRows(end+1) = row_add1;
            row_add = dataTipTextRow(dataTipTextRow_varargin{:});
            p.DataTipTemplate.DataTipRows(end+1) = row_add;
        end
        
        function [] = set_xlim(obj,varargin)
            xlim_val = obj.get_lim2D('X',varargin{:});
            xlim(obj.ax,xlim_val);
        end
        function [] = set_ylim(obj,varargin)
            ylim_val = obj.get_lim2D('Y',varargin{:});
            ylim(obj.ax,ylim_val);
        end
        
        function [lim_val] = get_lim2D(obj,axisID,varargin)
            axisID = upper(axisID);
            prop_name_LimMode   = [axisID 'LimMode'];
            prop_name_LimMan    = [axisID 'LimMan'];
            prop_name_LimMargin = [axisID 'LimMargin'];
            prop_name_ax_Lim    = [axisID 'Lim'];
            prop_name_ax_Data   = [axisID 'Data'];
            
            switch axisID
                case 'X'
                    axisID_theother = 'Y';
                case 'Y'
                    axisID_theother = 'X';
                otherwise
                    error('3D is not supported yet'); 
            end
            prop_name_ax_Data_theother   = [axisID_theother 'Data'];
                
            
            LIMMODE = obj.(prop_name_LimMode);
            LIMMARGIN = obj.(prop_name_LimMargin);
            
            switch upper(LIMMODE)
                case 'MANUAL'
                    if ~isempty(varargin)
                        lim_val = varargin{1};
                    elseif ~isempty(obj.(prop_name_LimMan))
                        lim_val = obj.(prop_name_LimMan);
                    else
                        error('Specify Lim');
                    end
                case {'AUTO','STRETCH01'}
                    if ~isempty(varargin)
                        fprintf('Specified range does not have any effect\n');
                    end
                    spcList = [];
                    for i=1:length(obj.ax.Children)
                        if strcmp(obj.ax.Children(i).Type,'line')
                            spcList = [spcList; ...
                                obj.ax.Children(i).(prop_name_ax_Data)(:)];
                        end
                    end
                    switch upper(LIMMODE)
                        case 'STRETCH01'
                            [ ar_thed ] = hard_percentile_thresholding( spcList,0.01 );
                        case 'AUTO'
                            ar_thed = spcList(:);
                    end
                    ar_thed_max = max(ar_thed); ar_thed_min = min(ar_thed);
                    rg = ar_thed_max - ar_thed_min;
                    lim_val = [ar_thed_min-rg*LIMMARGIN, ar_thed_max+rg*LIMMARGIN];
                    % ylim(obj.ax,...
                    %  [ar_thed_min-rg*LIMMARGIN, ar_thed_max+rg*LIMMARGIN]);
                otherwise
                    error('Undefined Lim Mode: %s',LIMMODE);
            end
            
        end
        
        function [] = cla(obj)
            obj.ax.Children = [];
        end
        
    end
end

