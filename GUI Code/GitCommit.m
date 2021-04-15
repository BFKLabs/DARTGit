function varargout = GitCommit(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitCommit_OpeningFcn, ...
                   'gui_OutputFcn',  @GitCommit_OutputFcn, ...
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

% --- Executes just before GitCommit is made visible.
function GitCommit_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitCommit
handles.output = hObject;

% sets the input arguments
hFig = varargin{1};
set(hFig,'visible','off')

% sets the GUI run type
switch length(varargin)
    case (1) % case is the 
        [rType,gDirP,~,gName] = promptGitRepo();
        if isempty(rType)
            % if the user cancelled, then delete the GUI and exit
            delete(hObject)
            set(hFig,'visible','on')
            return
        else
            % otherwise, create the GitFunc class object
            [GF,runFromGV] = deal(GitFunc(rType,gDirP,gName),false);
        end
        
    case (2)
        % if there are input arguments, then set their local values
        [GF,runFromGV] = deal(varargin{2},true);        
end

% creates the loadbar
h = ProgressLoadbar('Determining Current Local Changes...');

% initialises the important class objects
setappdata(hObject,'GitFunc',GF)
setappdata(hObject,'hFig',hFig)
setappdata(hObject,'runFromGV',runFromGV)

% initialises the GUI objects
initGUIObjects(handles)

% deletes the loadbar
delete(h)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitCommit wait for user response (see UIRESUME)
uiwait(handles.figGitCommit);

% --- Outputs from this function are returned to the command line.
function varargout = GitCommit_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figGitCommit.
function figGitCommit_CloseRequestFcn(hObject, eventdata, handles)

% runs the GUI exit function
try; menuExit_Callback(handles.menuExit, [], handles); end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    FILE MENU ITEMS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% prompts the user if they wish to close the tracking gui
uChoice = questdlg('Are you sure you want to close the Git Commit GUI?',...
                   'Close Git Commit GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit
    return
end

% retrieves the GitFunc object
hFig = getappdata(handles.figGitCommit,'hFig');
GF = getappdata(handles.figGitCommit,'GitFunc');
runFromGV = getappdata(handles.figGitCommit,'runFromGV');
 
% changes the directory back down to the main directory and closes the GUI
cd(mainProgDir)
delete(handles.figGitCommit)

% determines if GitCommit was run from the GitVersion GUI
if runFromGV
    % if so, then determine if there any uncommitted modifications 
    if GF.detIfBranchModified()
        % if so, then prompt the user if they want to stash these files
        qStr = sprintf(['There are still uncommitted changes on the ',...
                        'current branch.\nDo you want to stash these ',...
                        'uncommitted changes?']);
        uChoiceM = questdlg(qStr,'Stash Uncommited Changes?',...
                            'Yes','No','Yes');
        if strcmp(uChoiceM,'Yes')
            % if so, then stash the files for the current branch
            GF.stashBranchFiles()
        end
    end    
end

% sets the main GUI visible again
set(hFig,'visible','on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonPushCommit.
function buttonPushCommit_Callback(hObject, eventdata, handles)

% parameters
cDir = pwd;
nLast = 10;
eStr = {'off','on'};

% import data objects
jRoot = getappdata(handles.figGitCommit,'jRoot');
sDiff = getappdata(handles.figGitCommit,'sDiff');
GF = getappdata(handles.figGitCommit,'GitFunc');

% retrieves the current branch
cBr = GF.gitCmd('current-branch');

% retrieves the full name of the selected files (exit if none selected)
[sNode,hasCommFiles] = deal(getSelectedTreeNodes(jRoot),true);
if isempty(sNode)
    if isempty(sDiff.Removed)
        return
    else
        hasCommFiles = false;
    end
end

% retrieves the commit message (only if adding files to the repository)
if hasCommFiles
    % retrieves the current commit message
    cMsg = get(handles.editCommitMsg,'string');

    % retrieves the last nLast commit messages  
    logStr = GF.gitCmd('n-log',nLast);
    logStrGrp = getCommitHistGroups(logStr,1);
    cMsgPrev = cellfun(@(x)(x{end}),logStrGrp,'un',0);
        
    % if the same commit message is being used, then prompt the user
    % if they want to continue
    if any(strcmp(cMsgPrev,cMsg))               
        qStr = sprintf(['This commit message is same as a recent commit.',...
                        '\nAre you sure you want to continue?']);        
        uChoice = questdlg(qStr,'Duplicate Commit Message','Yes','No','Yes');
        if ~strcmp(uChoice,'Yes')
            % if the user cancelled, then exit the function
            return
        end
    end
end
    
% memory allocation
cFile = struct('Altered',[],'Added',[],'Removed',[]);
cType = fieldnames(cFile);

% sets the selected files into their respective categories
for i = 1:length(sNode)
    % determines what type of file the current file is
    fileSp = strsplit(sNode{i},'\');
    iType = cellfun(@(x)(strContains(fileSp{2},x)),cType);
    
    % sets the file name into the corresponding struct field array
    fileNw = strjoin(fileSp(3:end),'/');
    eval(sprintf('cFile.%s{end+1} = fileNw;',cType{iType}));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    ADDING OF SELECTED FILES TO REPOSITORY    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% creates the loadbar
h = ProgressLoadbar('Applying Commit To Git Repository...');

% changes the directory to the main directory
cd(GF.gDirP);

% adds the altered files to the repository
for i = 1:length(cFile.Altered)
    GF.gitCmd('add-file',cFile.Altered{i});
end

% adds the added files to the repository
for i = 1:length(cFile.Added)
    GF.gitCmd('add-file',cFile.Added{i});
end

% adds the added files to the repository
for i = 1:length(cFile.Removed)
    GF.gitCmd('remove-file',cFile.Removed{i});
end

% re-adds any files flagged for deletion but were kept otherwise
if length(sDiff.Removed) > length(cFile.Removed)
    % fetches the files from the remote branch
    GF.gitCmd('remote-fetch',cBr);
    for i = 1:length(sDiff.Removed)
        % re-adds the file if the current file is to be kept
        if ~any(strcmp(cFile.Removed,sDiff.Removed{i}))
            GF.gitCmd('checkout-remote-file',cBr,sDiff.Removed{i})
        end
    end
end

% returns to the original directory
cd(cDir);

% runs the commit (only if there were files added to the repository)
if hasCommFiles
    GF.gitCmd('commit-simple',cMsg);
    GF.gitCmd('force-push');    
    GF.gitCmd('force-push',1);    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    HOUSE-KEEPING EXERCISES    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieves the difference/selected file name field cell arrays
sDiffC = getAllStructFields(sDiff);
cFileC = getAllStructFields(cFile);

% removes the files that have been selected
for i = 1:length(sDiffC)
    if ~isempty(sDiffC{i}) && ~isempty(cFileC{i})
        isRmv = cellfun(@(x)(any(strcmp(cFileC{i},x))),sDiffC{i});
        sDiffC{i} = sDiffC{i}(~isRmv);
        eval(sprintf('sDiff.%s = sDiffC{i};',cType{i}));
    end
end

% deletes the current tree object and replaces it with a new one
jTree = findall(handles.panelFileChanges,'type','hgjavacomponent');
if ~isempty(jTree); delete(jTree); end

% creates the commit explorer tree
jRoot = createCommitExplorerTree(handles,sDiff);

% updates the code difference listboxes
updateCodeDifferenceListboxes(handles,sDiff,false)

% resets the data struct/objects within the GUI
setappdata(handles.figGitCommit,'sDiff',sDiff)
setappdata(handles.figGitCommit,'jRoot',jRoot)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    HOUSE-KEEPING EXERCISES    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determines if there are any files that still need commiting
hasFiles = any(cellfun(@length,sDiffC) > 1);

% clears/disables all code difference objects associated
set(handles.tableCodeLine,'data',[])
set(handles.textFilePath,'string','')

% disables the file select panel
set(hObject,'enable',eStr{1+hasFiles})
setPanelProps(handles.panelFileSelect,eStr{1+hasFiles})

% deletes the loadbar
delete(h)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
%%%%    GUI OBJECT PROPERTY FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI objects
function initGUIObjects(handles)

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% initialisations
cDir = pwd;
sDiff = struct('Altered',[],'Added',[],'Removed',[]);

% gui object handles
hFig = handles.figGitCommit;
GF = getappdata(hFig,'GitFunc');

% creates/sets the gitignore file 
createGitIgnoreFile(GF);

% retrieves the status string and splits into by line
cd(GF.gDirP)
GF.gitCmd('show-all-untracked');
sStr = GF.gitCmd('branch-status',1);
sStrSp = strsplit(sStr,'\n')';    
cd(cDir)

% case is there are files for update
for i = 1:length(sStrSp)
    if ~isempty(sStrSp{i})
        % retrieves the file name
        fFull = strrep(sStrSp{i}(4:end),'"','');

        % only add files with accepted directories/file extensions 
        switch sStrSp{i}(1:2)
            case (' M') % case is modifying a file
                sDiff.Altered{end+1} = fFull;      

            case (' D') % case is deleting a file
                sDiff.Removed{end+1} = fFull;                    

            case ('??') % case is adding a file
                % determines if the file is valid for addition to the
                % repository
                sDiff.Added{end+1} = fFull;
        end
    end
end

% creates the commit explorer tree
jRoot = createCommitExplorerTree(handles,sDiff);

% sets the difference parameter struct into the GUI
setappdata(handles.figGitCommit,'jRoot',jRoot)
setappdata(handles.figGitCommit,'sDiff',sDiff)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    COMMIT MESSAGE OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sets the default message
cMsg0 = sprintf('%s Update (%s)',GF.gName,datestr(now,1));
set(handles.editCommitMsg,'string',cMsg0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    CODE DIFFERENCE OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialises the codeline table properties
[cWid0,tPos] = deal(50,get(handles.tableCodeLine,'position'));
cWid = {cWid0,cWid0,tPos(3)-2*cWid0};
set(handles.tableCodeLine,'data',[],'columnwidth',cWid)
autoResizeTableColumns(handles.tableCodeLine)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VERSION DIFFERENCE OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% updates the code difference listboxes
updateCodeDifferenceListboxes(handles,sDiff,true)

% retrieves the code difference struct and updates the difference objects
diffStr = GF.gitCmd('diff');
if isfield(sDiff,'Added')
    diffStr = [diffStr,getAddedDiffStr(GF,sDiff.Added)];
end

% sets the difference parameter struct into the GUI
setappdata(handles.figGitCommit,'pDiff',splitCodeDiff(diffStr))

% --- gets the difference strings for the files that have been added
function diffStrAdd = getAddedDiffStr(GF,pAdded)

% memory allocation
diffStrAdd = [];

% retrieves the file contents for all added files
for i = 1:length(pAdded)
    % add the new file, retrieves the information and then removes again
    GF.gitCmd('add-file',pAdded{i});
    diffStrNw = GF.gitCmd('cached-diff',pAdded{i});        
    GF.gitCmd('reset-file',pAdded{i});
    
    % appends the new string to the difference string
    diffStrAdd = [diffStrAdd,diffStrNw];
end

% --- updates the code difference listboxes
function updateCodeDifferenceListboxes(handles,sDiff,isInit)

% retrieves the object handles
hFig = handles.figGitCommit;
hPanelFile = handles.panelFileSelect;

% sets the tab header strings
sDiffC = getAllStructFields(sDiff);
nFile = cellfun(@length,sDiffC);

% retrieves the fieldnames from struct
tStr = fieldnames(sDiff);

% creates the version difference objects
if isInit
    % creates the code difference tabs
    [jTab,hTabDiff] = setupVersionDiffObjects(hFig,hPanelFile,tStr,1);

    % updates the objects within the GUI
    setappdata(handles.figGitCommit,'jTab',jTab)
    setappdata(handles.figGitCommit,'hTabDiff',hTabDiff)
else
    % retrieves the tab handles
    jTab = getappdata(handles.figGitCommit,'jTab');
    hTabDiff = getappdata(handles.figGitCommit,'hTabDiff');
end

% sets the difference object properties
for i = 1:length(tStr)
    % retrieves the list strings
    if isempty(sDiffC{i})
        lStr = [];
    else
        lStr = cellfun(@(x)(getFileName(x,1)),sDiffC{i}(:),'un',0);
    end

    % updates the listbox
    hList = findall(get(hTabDiff,'Children'),'style',...
                                 'listbox','tag',tStr{i});
    set(hList,'string',lStr,'max',2,'value',[])

    % sets the plural string
    if length(lStr) == 1
        % case is there is only 1 file so no pluralisation
        pStr = '';
    else
        % otherwise, set the plural string
        pStr = 's';
    end
    
    % sets the tab enabled properties
    jTab.setEnabledAt(i-1,~isempty(lStr))
    
    % sets the text label string
    hTxt = findall(get(hTabDiff,'Children'),'tag',[tStr{i},'T']);
    set(hTxt,'string',sprintf('%i File%s %s',length(lStr),pStr,tStr{i}))    
end

% if no files are altered, then disable the file select/code diff panels
if all(nFile == 0)
    setPanelProps(handles.panelFileSelect,'off')
    setPanelProps(handles.panelCodeDiff,'off')    
end
