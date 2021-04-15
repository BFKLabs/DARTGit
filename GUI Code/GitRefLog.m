function varargout = GitRefLog(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitRefLog_OpeningFcn, ...
                   'gui_OutputFcn',  @GitRefLog_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before GitRefLog is made visible.
function GitRefLog_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isChange
isChange = false;

% Choose default command line output for GitRefLog
handles.output = hObject;

% retrieves the main GUI handle
hGV = findall(0,'tag','figGitVersion');
mObj = varargin{1};
cBr = mObj.GitFunc.getCurrentBranch();

% sets the input arguments
setappdata(hObject,'mObj',mObj);
setappdata(hObject,'cBr',cBr);
setappdata(hObject,'hGV',hGV);

% initialises the GUI objects
initGUIObjects(handles,hGV,cBr)
setappdata(hObject,'hRLP',RefLogPara(mObj,hObject,cBr));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitRefLog wait for user response (see UIRESUME)
uiwait(handles.figRefLog);


% --- Outputs from this function are returned to the command line.
function varargout = GitRefLog_OutputFcn(hObject, eventdata, handles) 

% global variables
global isChange

% Get default command line output from handles structure
varargout{1} = isChange;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figRefLog.
function figRefLog_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
menuExit_Callback(handles.menuExit, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuResetHist_Callback(hObject, eventdata, handles)

% global variables
global isChange

% prompts the user if they want to reset the history
qStr = 'Are you sure you want to reset the history to this point?';
uChoice = questdlg(qStr,'Reset Log History?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if not, then exit the function
    return
else
    % otherwise, flag that a change has occured
    isChange = true;
end

% retrieves the important fields from the current GUI
hFig = handles.figRefLog;
iRow = getappdata(hFig,'iRow');
hRLP = getappdata(hFig,'hRLP');
mObj = getappdata(hFig,'mObj');

% retrieves the important fields from the parameter GUI
updateFcn = getappdata(hRLP,'updateRefLogTable');

% hard-resets to the selected history point
tData = get(handles.tableRefLog,'Data');
mObj.GitFunc.resetHistoryPoint(tData{iRow,1})

% resets the table and the other properties
updateFcn(guidata(hRLP))

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% retrieves the main GUI handle
hRLP = getappdata(handles.figRefLog,'hRLP');
hGV = getappdata(handles.figRefLog,'hGV');

% deletes the RefLog GUIs and makes the main GUI visible again
delete(hRLP)
delete(handles.figRefLog)

% makes the main GUI visible again
set(hGV,'visible','on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected cell(s) is changed in tableRefLog.
function tableRefLog_CellSelectionCallback(hObject, eventdata, handles)

% if no indices are selected, then exit the function
if isempty(eventdata.Indices)
    return
end

% initialisations
col = 'rk';
eStr = {'off','on'};
iRow = eventdata.Indices(1);

% only rows with a new commit ID w
Data = get(hObject,'Data');
isNew = ~strcmp(Data{1,1},Data{iRow,1});

% updates the selected row text and reset history menu enabled props
set(handles.textCurrSel,'string',sprintf('Row #%i',iRow),...
                        'foregroundcolor',col(1+isNew));
set(handles.menuResetHist,'enable',eStr{1+isNew})

% sets the selected row index
setappdata(handles.figRefLog,'iRow',iRow)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
%%%%    GUI OBJECT PROPERTY FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI object properties
function initGUIObjects(handles,hGV,cBr)

% makes the main GUI invisible
set(hGV,'visible','off')
set(handles.menuResetHist,'enable','off')

% sets the reference log panel title
pLbl = sprintf('REFERENCE LOG HISTORY (%s)',cBr);
set(handles.panelRefLog,'Title',pLbl)
