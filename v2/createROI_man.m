function [roimask,xi,yi,imcomp] = createROI_man(im,varargin)
% [roimask,xi,yi] = createROI_man(pdir,im,varargin)
%   create Region Of Interest MANually using ROI tool in MATLAB
%    Input Parameters
%      pdir: directroy where we are working on, string
%      im: image on which roi is created
%    Output Parameters
%      roimask: Boolean image, true is the position in ROI, same size as
%          the im
%      xi, yi: 1d array to represent the coordinate values of ROI.
%      imcomp: composite image of the original image with roimask.
%    Optional Parameters
%      future implementation

% if (rem(length(varargin),2)==1)
%     error('Optional parameters should always go by pairs');
% else
%     for i=1:2:(length(varargin)-1)
%         switch upper(varargin{i})
%             case 'OVERWRITE'
%                 overwrite = varargin{i+1};
%             otherwise
%                 % Hmmm, something wrong with the parameter string
%                 error(['Unrecognized option: ''' varargin{i} '''']);
%         end
%     end
% end
% 
% Note:
% 2017/09/30 first created by YI.


youthinkbad = 1;
while youthinkbad
    fig = figure; imagesc(im);
    set(gca,'dataAspectRatio',[1 1 1]);
    title('Focus, pan, and draw a ROI!!');
    flg = 1;
    while flg
        [roimask, xi, yi] = roipoly();
        if isempty(roimask)
            title('Try again');
        else
            flg = 0;
        end
    end

    close(fig);
%     fpath_im_color_mask = joinPath(pdir,sprintf('panel_%s_mask.bmp',color));
%     imwrite(roimask,fpath_im_color_mask);

    fig = figure; 
    imd = double(im);
    imcomp = sc(cat(3,imd.*roimask,imd),'prob');
    sc(imcomp);
    axis on;
    set(gca,'Position',[0.05 0.05 0.9 0.9]);
    title('Selected ROI');
%     fpath_im_color_comb = joinPath(pdir,sprintf('panel_%s_comb.bmp',color));
%     imwrite(img_combine,fpath_im_color_comb);

    answer = choosedialog;
    switch answer
        case 'Yes'
            youthinkbad = 0;
        case 'No'
        youthinkbad = 1;
    end
    set(gca,'dataAspectRatio',[1 1 1]);
    close(fig);
end

end

function choice = choosedialog

    d = dialog('Position',[300 300 250 150],'Name','Select One',...
        'WindowStyle','normal');
    txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 80 210 40],...
           'String','Are you satisfied?');
       
    popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[75 70 100 25],...
           'String',{'No';'Yes'},...
           'Callback',@popup_callback);
       
    btn = uicontrol('Parent',d,...
           'Position',[89 20 70 25],...
           'String','Ok',...
           'Callback','delete(gcf)');
       
    choice = 'Yes';
       
    % Wait for d to close before running to completion
    uiwait(d);
   
       function popup_callback(popup,event)
          idx = popup.Value;
          popup_items = popup.String;
          % This code uses dot notation to get properties.
          % Dot notation runs in R2014b and later.
          % For R2014a and earlier:
          % idx = get(popup,'Value');
          % popup_items = get(popup,'String');
          choice = char(popup_items(idx,:));
       end
end