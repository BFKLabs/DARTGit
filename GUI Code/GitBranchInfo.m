function varargout = GitBranchInfo(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitBranchInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @GitBranchInfo_OutputFcn, ...
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

% --- Executes just before GitBranchInfo is made visible.
function GitBranchInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitBranchInfo
handles.output = hObject;

% makes the version GUI invisible
hGV = findall(0,'tag','figGitVersion');

% sets the input arguments
setappdata(hObject,'mObj',varargin{1})
setappdata(hObject,'hGV',hGV)

% initialises the GUI objects
initGUIObjects(handles,hGV)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitBranchInfo wait for user response (see UIRESUME)
% uiwait(handles.figBranchInfo);

% --- Outputs from this function are returned to the command line.
function varargout = GitBranchInfo_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figBranchInfo.
function figBranchInfo_CloseRequestFcn(hObject, eventdata, handles)

% runs the exit file menu item
menuExit_Callback(handles.menuExit, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% retrieves the main GUI object handle
hGV = getappdata(handles.figBranchInfo,'hGV');

% deletes the GUI
delete(handles.figBranchInfo)

% makes the main GUI invisible
set(hGV,'visible','on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in listBranchDel.
function listBranchDel_Callback(hObject, eventdata, handles)

% enables the restore branch button
set(handles.buttonRestoreBranch,'enable','on')

% --- Executes on button press in buttonRestoreBranch.
function buttonRestoreBranch_Callback(hObject, eventdata, handles)

% retrieves the deleted listbox strings/values
dStr = get(handles.listBranchDel,'string');
iSel = get(handles.listBranchDel,'value');

% prompt the user if they want to restore the deleted branch
qStr = sprintf('Are you sure you want to restore "%s"?',dStr{iSel});
uChoice = questdlg(qStr,'Restore Deleted Branch?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% retrieves the main GUI object handle and commit ID#s
cID = getappdata(handles.figBranchInfo,'cID'); 
mObj = getappdata(handles.figBranchInfo,'mObj'); 

% restores the deleted branch
mObj.GitBranch.restoreDeletedBranch(dStr{iSel},cID{iSel})

% updates the current branch list
cStr = get(handles.listBranchCurr,'string');
set(handles.listBranchCurr,'string',[cStr;dStr{iSel}])

% updates
[ii,eStr] = deal(1:length(dStr) ~= iSel,{'off','on'});
set(handles.listBranchDel,'string',dStr(ii))
set(hObject,'enable',eStr{1+(sum(ii)>0)})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI objects
function initGUIObjects(handles,hGV)

% makes the main GUI invisible
set(hGV,'visible','off')

% retrieves the GitMenu object
mObj = getappdata(handles.figBranchInfo,'mObj');

% sets the current branch listbox values
cBrStr = cell2cell(mObj.GitBranch.bStrGrp);
set(handles.listBranchCurr,'string',cBrStr,...
                           'max',2,'value',[],'enable','inactive')

% determines if there are any deleted branches
delBrInfo0 = mObj.GitFunc.gitCmd('log-grep-all','Branch Delete');
if isempty(delBrInfo0)
    % if no deleted branches, then disable the branch restore button
    set(handles.buttonRestoreBranch,'enable','off')
else
    % retrieves the deleted branch information messages
    delBrInfo = strsplit(delBrInfo0,'\n');
    isMsg = cellfun(@(x)(startsWith(x,'Reflog message:')),delBrInfo);    
    delBrInfo = unique(delBrInfo(isMsg));
    
    % memory allocation
    nBr = length(delBrInfo);
    [cID,delBr] = deal(cell(nBr,1));
    
    % retrieves the names/last commit ID#s of the deleted branches
    for i = 1:nBr
        msgInfo0 = regexp(delBrInfo{i}, '[^()]*', 'match');
        msgInfo = strsplit(msgInfo0{2});
        [delBr{i},cID{i}] = deal(msgInfo{1},msgInfo{end});
    end
    
    % determines if the deleted branches is not included within the current
    % branch name list
    isOK = cellfun(@(x)(~any(strcmp(cBrStr,x))),delBr);
    if any(isOK)    
        % sets the listbox strings and commit ID strings
        set(handles.listBranchDel,'string',delBr(isOK),'max',1,'value',1)
        setappdata(handles.figBranchInfo,'cID',cID(isOK));
    else
        % if no deleted branches, then disable the branch restore button
        set(handles.buttonRestoreBranch,'enable','off') 
    end
end
