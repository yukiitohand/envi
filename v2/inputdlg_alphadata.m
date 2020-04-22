function Answer = inputdlg_alphadata(text_ttl)
% Create figure
pos_fig = [200,200,300,180];

left_margin = 30;
pos_okbtn = [left_margin 20 50 20];
pos_cancelbtn = [pos_okbtn(1)+pos_okbtn(3)+10,pos_okbtn(2),pos_okbtn(3),pos_okbtn(4)];

h_uiopt = 55; left_margin_uiopt = 30;
right_margin_uiopt = 30; btm_margin_uiopt = 10;
pos_bg  = [left_margin_uiopt,btm_margin_uiopt+pos_okbtn(2)+pos_okbtn(4),...
    pos_fig(3)-left_margin_uiopt-right_margin_uiopt,h_uiopt];

btm_margin_igval = 10; h_igval = 20;
pos_igval_text  = [left_margin,btm_margin_igval+pos_bg(2)+pos_bg(4),80,h_igval];
pos_igval_edit  = [pos_igval_text(1)+pos_igval_text(3),...
                   pos_igval_text(2),80,h_igval];

pos_title  = [left_margin,10+pos_igval_text(2)+pos_igval_text(4),200,20];


fig = dialog('Units','pixels','Position',pos_fig,...
             'Name','Set Ignore Value',...
             'KeyPressFcn',@FigureKeyPress);
         
% Create OK pushbutton   
ui_okbtn = uicontrol('Style','pushbutton','Parent',fig,'Units','pixels',...
                'Position',pos_okbtn,'string','OK','UserData','OK',...
                'Callback',@Callback_OKCancel,...
                'KeyPressFcn',@ControlKeyPress);
% Create Cancel pushbutton   
ui_cancelbtn = uicontrol('style','pushbutton','Parent',fig,'Units','pixels',...
                'Position',pos_cancelbtn,'String','Cancel','UserData','Cancel',...
                'Callback',@Callback_OKCancel,...
                'KeyPressFcn',@ControlKeyPress);

% Create text field
text_igval = uicontrol('Style','text','Parent',fig,'Units','pixels',...
                'Position',pos_igval_text,...
                'String','Ignore Value: ','FontSize',12); 
ui_igval = uicontrol('Style','edit','Parent',fig,'Units','pixels',...
                'Position',pos_igval_edit,'String','',...
                'HorizontalAlignment','right','FontSize',10.5);% ,...
                % 'Callback',@TextKeyPress); 
            
% Create a list of options.
bg = uibuttongroup(fig,'Units','pixels','Position',pos_bg);

bg_rb1 = uicontrol('Style','radiobutton','Parent',bg,...
    'String','Combine the current AlphaData_Home',...
    'Position',[10 30 200 20],'UserData',1);
bg_rb2 = uicontrol('Style','radiobutton','Parent',bg,...
    'String','Overwrite the current AlphaData_Home',...
    'Position',[10 10 200 20],'UserData',2);

% create title
ui_title = uicontrol('Style','text','Parent',fig,'Units','pixels',...
                'Position',pos_title,...
                'String',['Set Ignore Value for ' text_ttl],'FontSize',12,...
                'HorizontalAlignment','left'); 

%%
% uiresume(fig);
uiwait(fig);
if ishghandle(fig)
    Answer=[];
    if strcmpi(get(fig,'UserData'),'OK')
        Answer.ignore_value = ui_igval.String;
        Answer.option1 = [];
        Answer.option1.id = bg.SelectedObject.UserData;
        Answer.option1.string = bg.SelectedObject.String;
    end
    delete(fig);
else
    Answer=[];
end
drawnow; % Update the view to remove the closed figure (g1031998)
    
end

function Callback_OKCancel(hobj,eventData)
    fig = hobj.Parent;
    if ~strcmpi(hobj.UserData,'Cancel')
        fig.UserData = 'OK';
        uiresume(fig);
    else
        delete(fig);
    end
end


function FigureKeyPress(hobj, evd)
    switch(evd.Key)
        case {'return','space'}
            hobj.UserData = 'OK';
            uiresume(hobj);
        case {'escape'}
            delete(hobj);
    end
end

function ControlKeyPress(hobj, evd)
    fig = hobj.Parent;
    switch(evd.Key)
        case {'return'}
            if ~strcmpi(hobj.UserData,'Cancel')
                fig.UserData = 'OK';
                uiresume(fig);
            else
                delete(fig)
            end
        case 'escape'
            delete(fig)
    end
end

% function TextKeyPress(hobj, evd)
%     fig = hobj.Parent;
%     if ~strcmpi(hobj.UserData,'Cancel')
%         fig.UserData = 'OK';
%         uiresume(fig);
%     else
%         delete(fig)
%     end
% end

