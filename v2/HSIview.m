classdef HSIview < handle
    % HSIview
    %   Create two 
    
    properties
        obj_ImageStackView
        obj_SpecView
        hsiar
        nhsi
        % plot properties
    end
    
    methods
        function obj = HSIview(rgb,hsiar,varargin)
            % obj = HSIview(hsiar,varargin)
            % USAGE
            %  HSIview(rgb,hsicell)
            
            varargin_ImageStackView = {};
            
            SpecView_XLimMode = 'auto';
            SpecView_XLimMan = [];
            SpecView_YLimMode = 'stretch01';
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
                if iscell(hsiar{1})
                    obj.nhsi = length(hsiar);
                    obj.hsiar = [];
                    for i=1:obj.nhsi
                        obj.hsiar = [obj.hsiar obj.parse_hsiar(hsiar{i})];
                    end
                elseif isa(hsiar{1},'HSI')
                    obj.nhsi = 1;
                    obj.hsiar = obj.parse_hsiar(hsiar);
                end
            end
            
            obj.init_ImageStackView({rgb},...
                'IMAGE_CURSOR_FCN',{@obj.image_cursorHSI},...
                varargin_ImageStackView{:});
            
            obj.init_SpecView('XLabel','Wavelength',...
                'XLIMMODE',SpecView_XLimMode,'XLim',SpecView_XLimMan,...
                'YLIMMODE',SpecView_YLimMode,'YLim',SpecView_YLimMan);
            
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
            hsiar_i_struct.legend = '';
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
                        case 'SHIFTS'
                            hsiar_i_struct.spc_shift = hsiar_i_varargin{n+1};
                        case 'VARARGIN_PLOT'
                            hsiar_i_struct.varargin_plot = hsiar_i_varargin{n+1};
                        case 'LEGEND'
                            hsiar_i_struct.legends = hsiar_i_varargin{n+1};
                        otherwise
                            error('Unrecognized option: %s', hsiar_i_varargin{n});
                    end
                end
            end
        end
        
        function [] = init_ImageStackView(obj,rgb,varargin)
            obj.obj_ImageStackView = ImageStackView(rgb,varargin{:});
        end
        
        function [] = init_SpecView(obj,varargin)
            obj.obj_SpecView = SpecView(varargin{:});
        end
        
        function [] = plot(obj,s,l)
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
                
                obj.obj_SpecView.plot([wv,spc,obj.hsiar(i).varargin_plot,...
                    'DisplayName',sprintf('%s X:% 4d, Y:% 4d',obj.hsiar(i).legend,s,l)],...
                    {'Band',bdxes});
            
                
%                 if ~isempty(obj.hsiar(i).hsi.BP1nan)
%                     [spcbp,wv] = obj.hsiar(i).hsi.get_spectrum(s,l,...
%                         'BANDS',obj.hsiar(i).bands,...
%                         'BANDS_INVERSE',obj.hsiar(i).is_bands_inverse,...
%                         'AVERAGE_WINDOW',obj.hsiar(i).ave_window,...
%                         'COEFF',obj.hsiar(i).hsi.BP1nan(:,s),...
%                         'COEFF_INVERSE',obj.hsiar(i).hsi.is_bp1nan_inverse);
%                     spcbp = spcbp+obj.hsiar(i).spc_shift;
%                     obj.obj_SpecView.plot({wv,spcbp,'x-',...
%                             'DisplayName',sprintf('BP - %s X:% 4d, Y:% 4d',obj.hsiar(i).legend,s,l)});
%                 end
%                 if ~isempty(hsiar(i).hsi.GP1nan)
%                     [spcgp,wv] = obj.hsiar(i).hsi.get_spectrum(s,l,...
%                         'BANDS',obj.hsiar(i).bands,...
%                         'BANDS_INVERSE',obj.hsiar(i).is_bands_inverse,...
%                         'AVERAGE_WINDOW',obj.hsiar(i).ave_window,...
%                         'COEFF',obj.hsiar(i).hsi.GP1nan(:,s),...
%                         'COEFF_INVERSE',obj.hsiar(i).hsi.is_gp1nan_inverse);
%                     spcbp = spcbp+obj.hsiar(i).spc_shift;
%                     obj.obj_SpecView.plot({wv,spcgp,'x-',...
%                             'DisplayName',sprintf('GP - %s X:% 4d, Y:% 4d',obj.hsiar(i).legend,s,l)});   
%                 end
                obj.obj_SpecView.set_xlim();
                obj.obj_SpecView.set_ylim();
            end
            
        end
        
        function [output_txt] = image_cursorHSI(obj,hObject,eventData)
            % DataTip is created as the same way in ImageStackView
            [output_txt] = obj.obj_ImageStackView.image_cursor(...
                hObject,eventData);
            
            % get (x,y) coordinate in the Hyperspectral image 
            pos = get(eventData,'Position');
            s = pos(1); l = pos(2);
            % plot spectra
            obj.plot(s,l);
        end
    end
end

