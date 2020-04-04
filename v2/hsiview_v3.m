function [  ] = hsiview_v3( rgb,hsiar,legends,varargin )
% hyperspectral image viewer. When you click any pixel in the rgb image, a
% spectrum of the pixel is displayed in the other figure. There are several
% add-ons.
%   "Locate": form dialog will show up and you can enter the pixel
%             coordinate to get the spectrum of the pixel.
%   "Keep","Keep Delete"
%          : once "Keep" is pushed, then the spectra in the Axis is kept
%          and could be compared with other spectra. "Keep Delete" clear
%          this.
%  
%   You need to have the matlab third party module "sc".
%     https://www.mathworks.com/matlabcentral/fileexchange/16233-sc-powerful-image-rendering
%     or
%     https://github.com/ojwoodford/sc
%
%   There will be any bugs, some weird behaviors.
%   
%   Inputs
%     rgb: rgb image, [L x S x 3]
%     hsiar: cell array of instances of HSI class. For each of the hsi, you
%     could load image by using the method "readimg" for faster response.
%     If the image is not loaded, then each spectrum is read each time.
%     legends: prefix of the legend used for plotting function
%   Optional Parameters
%     future implementation
%   Outputs
%     none
%   Usage
%     >> hsi = HSI(base,dpath);
%     >> rgb = hsi.lazyEnviReadRGB([125 85 49]);
%     >> hsiview_v2(rgb,{hsi},{'raw'});
%   %% when you click any pixel in the image 

if exist('sc','file')~=2
    error(['Please install a third party module "sc".\n',...
           'https://www.mathworks.com/matlabcentral/fileexchange/16233-sc-powerful-image-rendering \n',... 
           'or \n https://github.com/ojwoodford/sc/']);
end

bands = cell(1,length(hsiar));
is_bands_inverse = false(1,length(hsiar));
ave_window = cell(1,length(hsiar));
ave_window(:) = {[1 1]};
spc_shifts = zeros(1,length(hsiar));
varargin_plot = cell(1,length(hsiar));
varargin_plot(:) = {{}};
mode_ylim = 'STRETCH01';
xlim1 = [];
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for n=1:2:(length(varargin)-1)
        switch upper(varargin{n}) 
            case 'BANDS'
                bands = varargin{n+1};
            case 'BANDS_INVERSE'
                is_bands_inverse = varargin{n+1};
            case 'AVERAGE_WINDOW'
                ave_window = varargin{n+1};
            case 'XLIM'
                xlim1 = varargin{n+1};
            case 'SHIFTS'
                spc_shifts = varargin{n+1};
            case 'VARARGIN_PLOT'
                varargin_plot = varargin{n+1};
            case 'YLIM_MODE'
                mode_ylim = varargin{n+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error('Unrecognized option: %s', varargin{n});
        end
    end
end

fig_spc = figure; 
ax_spc = subplot(1,1,1);
keepHdl = KeepPlot();

fig_im = figure;
scx_rgb(rgb);
ax_im = gca;
ax_im.Position = [0.1 0.1 0.8 0.8];
axis(ax_im,'on');
set(ax_im,'dataAspectRatio',[1 1 1]);
hdt = datacursormode(gcf);
set(hdt,'UpdateFcn',{@map_cursor_crismx,rgb,ax_spc,hsiar,legends,keepHdl,...
    xlim1,bands,is_bands_inverse,ave_window,spc_shifts,mode_ylim,varargin_plot});

imgObj = ax_im.Children;

b = uicontrol(fig_im,'Style','pushbutton','String','Pixel Locate',...
    'Units','normalized','Position', [0.02 0.9 0.1 0.05],...
    'Callback',{@pixelLocator,imgObj,ax_im,ax_spc,hsiar,legends});

c = uicontrol(fig_im,'Style','pushbutton','String','Keep',...
    'Units','normalized','Position', [0.17 0.9 0.1 0.05],...
    'Callback',{@keep,ax_im,keepHdl});

d = uicontrol(fig_im,'Style','pushbutton','String','Keep Delete',...
    'Units','normalized','Position', [0.32 0.9 0.1 0.05],...
    'Callback',{@delkeep,ax_im,keepHdl});

end

function output_txt = map_cursor_crismx(obj,event_obj,CData,ax_spc,hsiar,legends,...
                               keepHdl,xlim1,bands,is_bands_inverse,ave_window,spc_shifts,mode_ylim,varargin_plot)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% cData        Color data
% ax_spc       axes object for spectrum plot
% hsiar        cell array contains hsi object (struct)
% legends      legends
% output_txt   Data cursor text string (string or cell array of strings).

pos = get(event_obj,'Position');
% im = get(event_obj,'Target');
output_txt = {['X: ',num2str(pos(1),4)],...
    ['Y: ',num2str(pos(2),4)],['Val: ' num2str(CData(pos(2),pos(1),:))]};

% If there is a Z-coordinate in the position, display it as well
if length(pos) > 2
    output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
end
% 
for i=1:length(hsiar)
    if isprop(hsiar{i},'glt_x') && isprop(hsiar{i},'glt_y')
        if ~isempty(hsiar{i}.glt_x) && ~isempty(hsiar{i}.glt_y)
            output_txt{end+1} = [legends{i} '-GLT_x: ',num2str(hsiar{i}.glt_x(pos(2),pos(1)))];
            output_txt{end+1} = [legends{i} '-GLT_y: ',num2str(hsiar{i}.glt_y(pos(2),pos(1)))];
        end
    end
end

if length(hsiar)~=length(legends)
    error('size of hsi and legends are different');
end

% plot kept spectra
nhsi = length(hsiar);
%spcminList = [];
%spcmaxList = [];
spcList = [];
if ~isempty(keepHdl.crd)
%     yyaxis(ax_spc,'right');
    for n=1:size(keepHdl.crd,1)
        l = keepHdl.crd(n,2); s = keepHdl.crd(n,1);
        for i=1:nhsi
            bands_i = bands{i};
            is_bands_inverse_i = is_bands_inverse(i);
            ave_window_i = ave_window{i};
            spc_shift = spc_shifts(i);
            varargin_plot_i = varargin_plot{i};
            [spc,wv] = hsiar{i}.get_spectrum(s,l,'BANDS',bands_i,...
                'BANDS_INVERSE',is_bands_inverse_i,'AVERAGE_WINDOW',ave_window_i);
            spc = spc+spc_shift;
            if ~isempty(varargin_plot_i)
                plot(ax_spc,wv,spc,varargin_plot_i{:},...
                            'DisplayName',sprintf('%s X:% 4d, Y:% 4d',legends{i},s,l));
            else
                plot(ax_spc,wv,spc,...
                            'DisplayName',sprintf('%s X:% 4d, Y:% 4d',legends{i},s,l));
            end
            hold(ax_spc,'on');
            if ~isempty(hsiar{i}.BP1nan)
                [spcbp,wv] = hsiar{i}.get_spectrum(s,l,...
                    'BANDS',bands_i,'BANDS_INVERSE',is_bands_inverse_i,...
                    'AVERAGE_WINDOW',ave_window_i,...
                    'COEFF',hsiar{i}.BP1nan(:,s),'COEFF_INVERSE',hsiar{i}.is_bp1nan_inverse);
                spcbp = spcbp+spc_shift;
                plot(ax_spc,wv,spcbp,'x-',...
                        'DisplayName',sprintf('BP - %s X:% 4d, Y:% 4d',legends{i},s,l));  
            end
            if ~isempty(hsiar{i}.GP1nan)
                [spcgp,wv] = hsiar{i}.get_spectrum(s,l,...
                    'BANDS',bands_i,'BANDS_INVERSE',is_bands_inverse_i,...
                    'AVERAGE_WINDOW',ave_window_i,...
                    'COEFF',hsiar{i}.GP1nan(:,s),'COEFF_INVERSE',hsiar{i}.is_gp1nan_inverse);
                spcgp = spcgp+spc_shift;
                plot(ax_spc,wv,spcgp,'+-',...
                        'DisplayName',sprintf('GP - %s X:% 4d, Y:% 4d',legends{i},s,l));  
            end
            hold(ax_spc,'on');
            spcList = [spcList;spc(~isnan(spc))];
            %spcminList = [spcminList nanmin(spc)]; spcmaxList = [spcmaxList nanmax(spc)];
        end
    end
%     ylim(ax_spc,[nanmin(spcminList)*0.9 nanmax(spcmaxList)*1.1]);
%     hold(ax_spc,'off');
end
% plot spectra
% yyaxis (ax_spc,'left');
% spcminList = zeros(size(hsiar));
% spcmaxList = zeros(size(hsiar));
s = pos(1); l = pos(2);
for i=1:nhsi
    bands_i = bands{i};
    is_bands_inverse_i = is_bands_inverse(i);
    ave_window_i = ave_window{i};
    spc_shift = spc_shifts(i);
    varargin_plot_i = varargin_plot{i};
    [spc,wv] = hsiar{i}.get_spectrum(s,l,'BANDS',bands_i,...
        'BANDS_INVERSE',is_bands_inverse_i,'AVERAGE_WINDOW',ave_window_i);
    spc = spc+spc_shift;
    if ~isempty(varargin_plot_i)
        p = plot(ax_spc,wv,spc,varargin_plot_i{:},...
                    'DisplayName',sprintf('%s X:% 4d, Y:% 4d',legends{i},s,l));
    else
        p = plot(ax_spc,wv,spc,...
                'DisplayName',sprintf('%s X:% 4d, Y:% 4d',legends{i},s,l));
    end
    hold(ax_spc,'on');
    if ~isempty(hsiar{i}.BP1nan)
        [spcbp,wv] = hsiar{i}.get_spectrum(s,l,...
            'BANDS',bands_i,'BANDS_INVERSE',is_bands_inverse_i,...
            'AVERAGE_WINDOW',ave_window_i,...
            'COEFF',hsiar{i}.BP1nan(:,s),'COEFF_INVERSE',hsiar{i}.is_bp1nan_inverse);
        spcbp = spcbp+spc_shift;
        p = plot(ax_spc,wv,spcbp,'x-',...
                'DisplayName',sprintf('BP - %s X:% 4d, Y:% 4d',legends{i},s,l));  
    end
    if ~isempty(hsiar{i}.GP1nan)
        [spcgp,wv] = hsiar{i}.get_spectrum(s,l,...
            'BANDS',bands_i,'BANDS_INVERSE',is_bands_inverse_i,...
        'AVERAGE_WINDOW',ave_window_i,...
        'COEFF',hsiar{i}.GP1nan(:,s),'COEFF_INVERSE',hsiar{i}.is_gp1nan_inverse);
        spcgp = spcgp+spc_shift;
        p = plot(ax_spc,wv,spcgp,'+-',...
                'DisplayName',sprintf('GP - %s X:% 4d, Y:% 4d',legends{i},s,l));  
    end
    row2 = dataTipTextRow('bidx',1:length(wv));
    p.DataTipTemplate.DataTipRows(end+1) = row2;
    row = dataTipTextRow('band',bands_i);
    p.DataTipTemplate.DataTipRows(end+1) = row;
    
    spcList = [spcList;spc(~isnan(spc))];
    % spcminList = [spcminList nanmin(spc)]; spcmaxList = [spcmaxList nanmax(spc)];
end

axis(ax_spc,'tight');
% ylim(ax_spc,[0,1]);
hold(ax_spc,'off');
xlabel(ax_spc,'Wavelength');
ylabel(ax_spc,'Reflectance');
legend(ax_spc,'Location','northwest','Interpreter','none');
if ~isempty(xlim1)
    xlim(ax_spc,xlim1);
end
switch upper(mode_ylim)
    case 'STRETCH01'
        [ ar_thed ] = hard_percentile_thresholding( spcList,0.01 );
    case 'NONE'
        ar_thed = spcList(:);
    otherwise
        error('Undefined YLim Mode: %s',mode_ylim);
end
ar_thed_max = max(ar_thed); ar_thed_min = min(ar_thed);
rg = ar_thed_max - ar_thed_min;
ylim(ax_spc,[ar_thed_min-rg*0.05 ar_thed_max+rg*0.05]);
% ylim(ax_spc,[nanmin(spcminList)*0.9 nanmax(spcmaxList)*1.1]);
end

function pixelLocator(src,event,imgobj,ax_im,ax_spc,hsiar,legends)
    cord = inputdlg({'Sample (X)','Line (Y)'},'Input locator', [1 10;1 10]);
    s = str2num(cord{1}); l=str2num(cord{2});
    if isempty(s) || isempty(l)
        return;
    end
    makedatatip(imgobj,[s l]);
    
end

function keep(src,event,ax_im,keepHdl)
    
    hDataCursorMgr = datacursormode(ancestor(ax_im,'figure'));
    
    currentCursor = hDataCursorMgr.getCursorInfo();
    % looks like cursor is a stack not a queue.
    hDatatip = createDatatip(hDataCursorMgr, currentCursor(1).Target);

    propPointDataCursor = get(hDatatip(end),'Cursor'); 
%     propPointDataCursor.DataIndex = pos; 
    propPointDataCursor.Position = currentCursor(1).Position;
    
    keepHdl.add(currentCursor(1).Position,1);
    
    updateDataCursors(hDataCursorMgr);
    
end

function delkeep(src,event,ax_im,keepHdl)
   keepHdl.clear(); 
end