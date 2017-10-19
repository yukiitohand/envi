function [  ] = hsiview_v2( rgb,hsiar,legends )
% hyperspectral image viewer
%   Inputs

%       
%   Optional Parameters

%   Outputs

%   Usage



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
set(hdt,'UpdateFcn',{@map_cursor_crismx,rgb,ax_spc,hsiar,legends,keepHdl});

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

function output_txt = map_cursor_crismx(obj,event_obj,CData,ax_spc,hsiar,legends,keepHdl)
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

if length(hsiar)~=length(legends)
    error('size of hsi and legends are different');
end

% plot kept spectra
nhsi = length(hsiar);
spcminList = [];
spcmaxList = [];
if ~isempty(keepHdl.crd)
%     yyaxis(ax_spc,'right');
    for n=1:size(keepHdl.crd,1)
        l = keepHdl.crd(n,2); s = keepHdl.crd(n,1);
        for i=1:nhsi
            if isempty(hsiar{i}.img)
                spc = hsiar{i}.lazyEnviRead(s,l);
            else
                spc = squeeze(hsiar{i}.img(l,s,:));
            end
            if isfield(hsiar{i},'wa') && ~isempty(hsiar{i}.wa)
                plot(ax_spc,hsiar{i}.wa(:,s),spc,'-','DisplayName',[legends{i} ' X: ',num2str(s,4),...
            ' Y: ',num2str(l,4)]);
            else
                plot(ax_spc,hsiar{i}.hdr.wavelength,spc,'-','DisplayName',[legends{i} ' X: ',num2str(s,4),...
            ' Y: ',num2str(l,4)]);
            end
            hold(ax_spc,'on');
            spcminList = [spcminList nanmin(spc)]; spcmaxList = [spcmaxList nanmax(spc)];
        end
    end
%     ylim(ax_spc,[nanmin(spcminList)*0.9 nanmax(spcmaxList)*1.1]);
%     hold(ax_spc,'off');
end
% plot spectra
% yyaxis (ax_spc,'left');
% spcminList = zeros(size(hsiar));
% spcmaxList = zeros(size(hsiar));
for i=1:nhsi
    if isempty(hsiar{i}.img)
        spc = hsiar{i}.lazyEnviRead(pos(1),pos(2));
    else
        spc = squeeze(hsiar{i}.img(pos(2),pos(1),:));
    end
    if isfield(hsiar{i},'wa') && ~isempty(hsiar{i}.wa)
        plot(ax_spc,hsiar{i}.wa(:,pos(1)),spc,'-','DisplayName',[legends{i} ' X: ',num2str(pos(1),4),...
    ' Y: ',num2str(pos(2),4)]);
    else
        plot(ax_spc,hsiar{i}.hdr.wavelength,spc,'-','DisplayName',[legends{i} ' X: ',num2str(pos(1),4),...
    ' Y: ',num2str(pos(2),4)]);
    end
    hold(ax_spc,'on');
    spcminList = [spcminList nanmin(spc)]; spcmaxList = [spcmaxList nanmax(spc)];
end
axis(ax_spc,'tight');
% ylim(ax_spc,[0,1]);
hold(ax_spc,'off');
xlabel(ax_spc,'Wavelength');
ylabel(ax_spc,'Reflectance');
legend(ax_spc);
ylim(ax_spc,[nanmin(spcminList)*0.9 nanmax(spcmaxList)*1.1]);
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