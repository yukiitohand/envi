function [  ] = hsiview_v2( rgb,hsiar,legends,varargin )
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

bands = 'all';
xlim1 = [];
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for n=1:2:(length(varargin)-1)
        switch upper(varargin{n}) 
            case 'BANDS'
                bands = varargin{n+1};
            case 'XLIM'
                xlim1 = varargin{n+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error(['Unrecognized option: ''' varargin{n} '''']);
        end
    end
end

if ischar(bands) && strcmp(bands,'all')
    bands = '';
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
set(hdt,'UpdateFcn',{@map_cursor_crismx,rgb,ax_spc,hsiar,legends,keepHdl,xlim1,bands});

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

function output_txt = map_cursor_crismx(obj,event_obj,CData,ax_spc,hsiar,legends,keepHdl,xlim1,bands)
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
spcminList = [];
spcmaxList = [];
if ~isempty(keepHdl.crd)
%     yyaxis(ax_spc,'right');
    for n=1:size(keepHdl.crd,1)
        l = keepHdl.crd(n,2); s = keepHdl.crd(n,1);
        for i=1:nhsi
            if isempty(hsiar{i}.img)
                spc = hsiar{i}.lazyEnviRead(s,l);
                if ~isempty(bands)
                    spc = spc(bands);
                end
            else
                spc = squeeze(hsiar{i}.img(l,s,:));
                if ~isempty(bands)
                    spc = spc(bands);
                end
            end
            if ~isempty(hsiar{i}.wa)
                if isempty(bands)
                    wa = hsiar{i}.wa(:,s);
                else
                    wa = hsiar{i}.wa(bands,s);
                end
                ln = plot(ax_spc,wa,spc,'-',...
                        'DisplayName',[legends{i} ' X: ',num2str(s,4),' Y: ',num2str(l,4)]);
                hold(ax_spc,'on');
                if ~isempty(hsiar{i}.BP)
                    if isempty(bands)
                        spcbp = spc.*hsiar{i}.BP(:,s);
                    else
                        spcbp = spc.*hsiar{i}.BP(bands,s);
                    end
                    plot(ax_spc,wa,spcbp,'X',...
                    'DisplayName',['BP-' legends{i} ' X: ',num2str(pos(1),4),' Y: ',num2str(pos(2),4)]);
                end
            else
                if isempty(bands)
                    wv = hsiar{i}.hdr.wavelength;
                else
                    wv =hsiar{i}.hdr.wavelength(bands);
                end
                plot(ax_spc,wv,spc,'-','DisplayName',[legends{i} ' X: ',num2str(s,4),...
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
        if ~isempty(bands)
            spc = spc(bands);
        end
    else
        spc = squeeze(hsiar{i}.img(pos(2),pos(1),:));
        if ~isempty(bands)
            spc = spc(bands);
        end
    end
    if ~isempty(hsiar{i}.wa)
        if isempty(bands)
            wa = hsiar{i}.wa(:,pos(1));
        else
            wa = hsiar{i}.wa(bands,pos(1));
        end
        plot(ax_spc,wa,spc,'-',...
            'DisplayName',[legends{i} ' X: ',num2str(pos(1),4),' Y: ',num2str(pos(2),4)]);
        hold(ax_spc,'on');
        if ~isempty(hsiar{i}.BP)
            if isempty(bands)
                spcbp = spc.*hsiar{i}.BP(:,pos(1));
            else
                spcbp = spc.*hsiar{i}.BP(bands,pos(1));
            end
            plot(ax_spc,wa,spcbp,'X',...
                'DisplayName',['BP-' legends{i} ' X: ',num2str(pos(1),4),' Y: ',num2str(pos(2),4)]);
        end
    else
        if isempty(bands)
            wv = hsiar{i}.hdr.wavelength;
        else
            wv =hsiar{i}.hdr.wavelength(bands);
        end
        plot(ax_spc,wv,spc,'-',...
            'DisplayName',[legends{i} ' X: ',num2str(pos(1),4),' Y: ',num2str(pos(2),4)]);
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
if ~isempty(xlim1)
    xlim(ax_spc,xlim1);
end
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