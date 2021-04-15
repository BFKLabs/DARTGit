function varargout = GitVersion(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitVersion_OpeningFcn, ...
                   'gui_OutputFcn',  @GitVersion_OutputFcn, ...
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

% --- Executes just before GitVersion is made visible.
function GitVersion_OpeningFcn(hObject, eventdata, handles, varargin)

% % global variables
% global isDeleting
% isDeleting = false;

% Choose default command line output for GitVersion
handles.output = hObject;

% sets the input arguments
hFig = varargin{1};
set(hFig,'visible','off')

% initialises the data struct and other important fields
setappdata(hObject,'hTree',[])
setappdata(hObject,'gHist',[])
setappdata(hObject,'hFig',hFig)
setappdata(hObject,'iData',initDataStruct)
setappdata(hObject,'localBr','LocalWorking')

% sets the function handle
setappdata(hObject,'updateFcn',@panelVerFilt_SelectionChangedFcn)

% initialises the GUI objects
ok = initGUIObjects(handles);
if ok
    % Update handles structure
    guidata(hObject, handles);

    % makes the GUI visible
    set(hObject,'visible','on')
else
    % makes the main GUI visible again
    set(hFig,'visible','on')
    
    % deletes the current GUI and exits
    delete(hObject)
    return
end

% UIWAIT makes GitVersion wait for user response (see UIRESUME)
% uiwait(hFig);

% --- Outputs from this function are returned to the command line.
function varargout = GitVersion_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

% ----------------------------------------------------------------------- %
%                        FIGURE CALLBACK FUNCTIONS                        %
% ----------------------------------------------------------------------- %

% --- Executes when user attempts to close figGitVersion.
function figGitVersion_CloseRequestFcn(hObject, eventdata, handles)

% runs the GUI exit function
menuExit_Callback(handles.menuExit, [], handles)

% ----------------------------------------------------------------------- %
%                         MENU CALLBACK FUNCTIONS                         %
% ----------------------------------------------------------------------- %

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% prompts the user if they wish to close the tracking gui
uChoice = questdlg('Are you sure you want to close the Git Version GUI?',...
                   'Close Git Version GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit
    return
end

% retrieves the main GUI handle
hFig = getappdata(handles.figGitVersion,'hFig');

% removes the environment variable
gitEnvVarFunc('remove','GIT_DIR')

% changes the directory back down to the main directory and closes the GUI
cd(mainProgDir)
delete(handles.figGitVersion)

% sets the main GUI visible again
set(hFig,'visible','on')

% ----------------------------------------------------------------------- %
%                        OBJECT CALLBACK FUNCTIONS                        %
% ----------------------------------------------------------------------- %

% ------------------------------------------------- %
%       VERSION FILTER PANEL OBJECT CALLBACKS       %
% ------------------------------------------------- %

% --- Executes when selected object is changed in panelVerFilt.
function panelVerFilt_SelectionChangedFcn(hObject, eventdata, handles)

% initialisations
[pStr,eStr] = deal('off');

% sets the handle of the currently selected radio button
if ischar(eventdata)
    hRadioSel = hObject.SelectedObject;
else
    hRadioSel = eventdata.NewValue;
end

% updates the parameters based on the selection type
switch get(hRadioSel,'tag')
    case ('radioLastVer')
        eStr = 'on';
    case ('radioDateFilt')
        pStr = 'on';
end

% updates the other properties
set(handles.editVerCount,'enable',eStr)
setPanelProps(handles.panelFiltDate,pStr)

% enables the update filter button
set(handles.buttonUpdateFilt,'enable','on')

% --- Executes during object creation, after setting all properties.
function editVerCount_Callback(hObject, eventdata, handles)

% initialisations
nwVal = str2double(get(hObject,'string'));
iData = getappdata(handles.figGitVersion,'iData');

% determines if the new value is valid
if chkEditValue(nwVal,[1,1000],1)
    % if the new value is valid, then update the data struct
    iData.nHist = nwVal;
    setappdata(handles.figGitVersion,'iData',iData)
    
    % enables the update filter button
    set(handles.buttonUpdateFilt,'enable','on')
else
    % otherwise, revert back to the last valid value
    set(hObject,'string',num2str(iData.nHist))
end

% --- updates the data filter
function updateDateFilter(hObject, eventdata, handles)

% initialisations
iSel = get(hObject,'value');
[iData,iData0] = deal(getappdata(handles.figGitVersion,'iData'));
[dStr,abStr] = deal({'Day','Month','Year'},{'After','Before'});

% determines the type
[isBefore,dType] = getSelectedPopupType(hObject);
iData = updateDateValue(iData,dStr{dType},iSel+(dType==3)*iData.y0,isBefore);

if ~feasDateFilter(iData)
    % if not, then output an error to screen
    eStr = 'Error! The before filter date must be later than the after filter date';
    waitfor(errordlg(eStr,'Date Filter Error','modal'))
    
    % resets the popup menu value to the last feasible value
    iSelPrev = eval(sprintf('iData0.dNum%i.%s',isBefore,dStr{dType}));
    set(hObject,'value',iSelPrev-(dType==3)*iData.y0)

    % exits the function
    return
end

% enables the update filter button
set(handles.buttonUpdateFilt,'enable','on')

% determines if the current date object is a month popup box
if dType == 2
    % if so, then retrieve the maximum data count
    dNum = eval(sprintf('iData.dNum%i',isBefore));
    dMax = getDayCount(dNum.Month);

    % retrieves the corresponding day popupmenu object handle
    hListDay = eval(sprintf('handles.popup%sDay',abStr{1+isBefore}));

    % determines if the current selected day index exceeds the new count
    iSelD = get(hListDay,'value');
    if iSelD > dMax
        % if so, then 
        iSelD = dMax;
        iData = updateDateValue(iData,'Day',iSelD,isBefore);
    end
    
    % determines if the max day count matches the current day count
    if length(get(hListDay,'String')) ~= dMax
        % updates the 
        pStr = arrayfun(@num2str,1:dMax,'un',0)';
        set(hListDay,'string',pStr,'value',iSelD)
    end
end

% updates the data struct
setappdata(handles.figGitVersion,'iData',iData)

% --- Executes on button press in buttonUpdateFilt.
function buttonUpdateFilt_Callback(hObject, eventdata, handles)

% updates the commit history details
if isa(eventdata,'ProgressDialog')
    updateCommitHistoryDetails(handles,1)
else
    updateCommitHistoryDetails(handles)
end

% ----------------------------------------------------- %
%       VERSION DIFFERENCE PANEL OBJECT CALLBACKS       %
% ----------------------------------------------------- %

% --- callback function for altering the code difference tabs
function changeDiffTab(hObject, eventdata)

% Add code here...
a = 1;

% --- Executes on button press in buttonUpdateVer.
function buttonUpdateVer_Callback(hObject, eventdata, handles)

% creates the load bar
h = ProgressLoadbar('Updating Branch Version...');    

% retrieves the object handles/data structs
hFig = handles.figGitVersion;
GB = getappdata(hFig,'GitBranch');
GF = getappdata(hFig,'GitFunc');
hTree = getappdata(hFig,'hTree');
% iCurr = getappdata(hFig,'iCurr');
% gHistAll = getappdata(hFig,'gHistAll');

% resets the directory to the repository directory current directory
cDir0 = pwd;
cd(GF.gDirP);

% % if the current branch is the local-working branch, then change to master
% isLW = strcmp(cBr,localBr);
% if isLW
%     cBr = GB.updateLocalWorkingBranch();    
% end

% updates the repository information
updateRepoInfo(GF.gName);

% retrieves the version selection index 
jTree = get(hTree.getTree);
hNodeNw = hTree.SelectedNodes(1);
hNodePr = getSelectedNode(hTree.getRoot);

% checks if there are any branch modifications and is not detached. if so
% prompt how the user wants to handle it
uStatus = GB.checkBranchModifications(h);
switch uStatus
    case 1
        % if the user chose to cancel, then exit the function
        cd(cDir0)
        return
        
    case 2
        % determines if current branch is a local-working branch (for
        % non-developers only)
        if GF.uType > 0
            % if the commit being ignored is an uncommited node, then
            % remove it from explorer tree
            hNodeS = getSelectedNode(hTree.getRoot);            
            if strContains(hNodeS.getName,'Uncommited Changes*')
                % retrieves the parent                 
                hNodeP = hNodeS.getParent;
                                
                % removes the node from the history explorer tree
                hNodeP.remove(hNodeS);
                hTree.reloadNode(hNodeP);
                hTree.repaint;   
                
                % flag that there is no previous node
                hNodePr = [];
            end
        end
        
        % if the user chose to ignore, then force reset the commit
        cID = GB.GitFunc.gitCmd('commit-id');
        GB.GitFunc.gitCmd('force-checkout',cID);
end

% retrieves the git history struct for the current branch
cBr = GF.getCurrentBranch;
if GF.uType == 0
    % case is for developers    
    iSel = jTree.SelectionRows;    
    gHist = eval(sprintf('gHistAll.%s',strrep(cBr,'-','')));
    gHistNw = gHist(iSel);   
    
    % checkouts the version corresponding to the selected tree node
    if iSel == 1
        % if the latest commit, then checkout the main branch
        GB.checkoutBranch('remote',cBr)

    else
        % otherwise, checkout the later version via the commit ID
        GB.checkoutBranch('version',gHistNw.ID)
    end    
else
    % case is for users    
    iSel = hNodeNw.getUserObject;
    [gHistNw,bStr,iSel] = getUserGitHistory(hFig,iSel);
    
    % checks out the branch (if the current/new branches are different)
    if ~strcmp(bStr,cBr)
        GF.gitCmd('stash-save','dummy');        
        if iSel(end) == 1   
            % if checking out the first item, then reset to the branch head
            GF.gitCmd('checkout-local',bStr);
        else
            % otherwise, checkout the later version via the commit ID
            GB.checkoutBranch('version',gHistNw.ID)            
        end

        % removes the item from the list
        iList = GF.detStashListIndex('dummy');
        if ~isempty(iList)
            GF.gitCmd('stash-drop',iList-1)
        end        
        
    else
        if iSel(end) == 1   
            % if checking out the first item, then reset to the branch head
            GF.gitCmd('checkout-local',bStr);
        else
            % otherwise, checkout the later version via the commit ID
            GB.checkoutBranch('version',gHistNw.ID)            
        end       
    end        
end

% updates the current version
updateVersionDetails(handles,gHistNw,iSel(1))
updateDiffObjects(handles,splitCodeDiff(''))
set(handles.tableCodeLine,'data',[])
setObjEnable(hObject,'off')

% resets the tree-node colour scheme
updateTreeNode(hNodePr,'k')
updateTreeNode(hNodeNw,'r')
hTree.repaint

% changes the directory back to the original
cd(cDir0)

% ----------------------------------------------------------------------- %
%                             OTHER FUNCTIONS                             %
% ----------------------------------------------------------------------- %

% ----------------------------------------- %          
%       GUI OBJECT PROPERTY FUNCTIONS       %           
% ----------------------------------------- %

% --- initialises the GUI object properties
function ok = initGUIObjects(handles)

% initialisations
ok = true;
hFig = handles.figGitVersion;
hPanelFile = handles.panelFileSelect;
dYear = str2double(datestr(datenum(datestr(now)),'yyyy'));
iData = getappdata(handles.figGitVersion,'iData');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    HISTORY VERSION PANEL OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prompts the user for the git repo to be viewed
[rType,gDirP,gRepoDir,gName] = promptGitRepo(); 
if isempty(rType)
    ok = false;
    return
end

% creates the loadbar
h = ProgressLoadbar('Initialising Version Control GUI Objects...');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    HISTORY VERSION PANEL OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         

% creates the menu items
gitEnvVarFunc('add','GIT_DIR',gRepoDir)
GF0 = GitFunc(rType,gDirP,gName);
GM = GitMenu(handles,GF0);

% creates/sets the gitignore file 
createGitIgnoreFile(GF0);

% sets the class objects into the GUI
setappdata(hFig,'GitMenu',GM)
setappdata(hFig,'GitFunc',GM.GitFunc)
setappdata(hFig,'GitBranch',GM.GitBranch)

% initialises the commit history struct
setappdata(hFig,'gHistAll',initHistoryStruct(GM.GitBranch))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VERSION DIFFERENCE PANEL OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialisations
tStr = {'Altered','Added','Removed','Moved'};

% creates the tab objects
[jTab,hTabDiff] = setupVersionDiffObjects(hFig,hPanelFile,tStr);
setappdata(hFig,'jTab',jTab)

% sets the tab selection change callback function
setTabGroupCallbackFunc(hTabDiff,{@changeDiffTab});

% disables the update version button
set(handles.buttonUpdateVer,'enable','off')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    HISTORY VERSION PANEL OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialises the version filter panel
set(handles.radioAllVer,'value',1)
panelVerFilt_SelectionChangedFcn(handles.panelVerFilt, '1', handles)
set(handles.editVerCount,'string',num2str(iData.nHist))

% sets the callback function for all data popup objects
hPopup = findall(handles.panelFiltDate,'style','popupmenu');
for i = 1:length(hPopup)
    % sets the callback function
    hObj = hPopup(i);
    bFunc = @(hObj,e)GitVersion('updateDateFilter',hObj,[],guidata(hObj));
    set(hObj,'Callback',bFunc)
    
    % determines if the popup menu object is before
    [isBefore,dType] = getSelectedPopupType(hObj);      
    
    % sets up the popup menu strings based on the object type
    dNum = eval(sprintf('iData.dNum%i',isBefore));
    switch dType
        case 1
            % case is the day popupmenu            
            
            % determines the number of days given the selected month
            dMax = getDayCount(dNum.Month);          
            
            % sets the popup menu list strings
            iSel = dNum.Day;
            pStr = arrayfun(@num2str,1:dMax,'un',0)';
            
        case 2
            % case is the month popupmenu            
            
            % sets the popup menu list strings            
            iSel = dNum.Month;
            pStr = {'Jan','Feb','Mar','Apr','May','Jun',...
                    'Jul','Aug','Sep','Oct','Nov','Dec'}';
                
        case 3
            % case is the year popupmenu      
            
            % sets the popup menu list strings            
            iSel = dNum.Year - iData.y0;
            pStr = arrayfun(@num2str,2019:dYear,'un',0)';
            
    end
    
    % sets the popup strings
    set(hObj,'string',pStr,'value',iSel)
end

% initialises the codeline table properties
[cWid0,tPos] = deal(50,get(handles.tableCodeLine,'position'));
cWid = {cWid0,cWid0,tPos(3)-2*cWid0};
set(handles.tableCodeLine,'data',[],'columnwidth',cWid)
autoResizeTableColumns(handles.tableCodeLine)

% runs the initial update
buttonUpdateFilt_Callback(handles.buttonUpdateFilt, h, handles)

% deletes the loadbar
try; delete(h); end

% --- determines what type of popupmenu was selected
function [isBefore,dType] = getSelectedPopupType(hObj)

% initialisations
dStr = {'Day','Month','Year'};
hObjStr = get(hObj,'tag');

% determines if the object is a before popup object
isBefore = strContains(hObjStr,'Before');

% determines the date type of the popup menu object
dType = find(cellfun(@(x)(strContains(hObjStr,x)),dStr));

% -------------------------- %          
%       DATE FUNCTIONS       %
% -------------------------- %          

% --- retrieves the day count based on month index
function dCount = getDayCount(iMonth)

switch iMonth
    case (2) % case is February
        dCount = 28;
    case {4,6,9,11} % case is the 30 day months
        dCount = 30;                
    otherwise % case is the 31 day months
        dCount = 31;                                
end

% --- updates the date value
function iData = updateDateValue(iData,dStr,iSel,isBefore)

eval(sprintf('iData.dNum%i.%s = iSel;',isBefore,dStr))

% --- determines if the current before/after dates are feasible
function isFeas = feasDateFilter(iData)

% calculates the date-time objects and determines if feasible
[d0,d1] = deal(iData.dNum0,iData.dNum1);
isFeas = datetime(d1.Year,d1.Month,d1.Day) > ...
         datetime(d0.Year,d0.Month,d0.Day);
     
% ----------------------------------- %           
%       MISCELLANEOUS FUNCTIONS       %
% ----------------------------------- %

% --- initialises the GUI data struct
function iData = initDataStruct()

% retrieves the current date indices
dVal = cellfun(@str2double,strsplit(datestr(now,'dd/mm/yyyy'),'/'));

% retrieves the date string numbers for the start/end times
dNum0 = struct('Day',1,'Month',1,'Year',2019);
dNum1 = struct('Day',dVal(1),'Month',dVal(2),'Year',dVal(3));

% sets up the data struct
iData = struct('gHist',[],'nHist',20,...
               'dNum0',dNum0,'dNum1',dNum1,'y0',2018);     
     
% --- initialises the commit history struct           
function gHistAll = initHistoryStruct(GB)

% retrieves the branch names
brName = GB.getBranchNames(0);

% initialises the struct fields
gHistAll = struct();
for i = 1:length(brName)
    eval(sprintf('gHistAll.%s = [];',strrep(brName{i},'-','')));
end
