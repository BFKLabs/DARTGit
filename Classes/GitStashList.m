classdef GitStashList < handle
    
    % class properties
    properties
        % main class fields
        gfObj
        hFigM
        
        % gui object handles
        hFig
        hTxtS
        hEditS
        hButS
        hButC
        hTable
        hPanel
        
        % object dimensions
        hghtBut = 25;
        hghtEdit = 21;
        hghtTxt = 16;
        hghtPanel = 40;
        widEdit = 125;
        widBut = 100;
        widPanel = 330;
        widTxt = 85;
        hghtPanelL
        
        % object offsets
        dX = 10;
        dXB = 8;
        
        % other fields
        saveStr = '';
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = GitStashList(hFigM,gfObj)
        
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.gfObj = gfObj;
            
            % initialises the object properties
            obj.initObjProps();
            
            % makes the gui visible again
            setObjVisibility(obj.hFigM,'off')
            setObjVisibility(obj.hFig,'on')
            
        end
        
        % --- initialises the object properties
        function initObjProps(obj) 
            
            % global variables
            global H0T HWT
            
            % memory allocation
            obj.hPanel = cell(3,1);
            
            % calculates the other object dimensions
            nRowMax = 5;
            hghtTable = H0T + nRowMax*HWT;
            obj.hghtPanelL = hghtTable + 2*obj.dX;

            % sets up the table data
            tData = [];
            
            % ----------------------- %
            % --- FIGURE CREATION --- %
            % ----------------------- % 
            
            % sets up the figure dimensions
            fWid = 2*obj.dX + obj.widPanel;
            fHght = 4*obj.dX + 2*obj.hghtPanel + obj.hghtPanelL;
            fPos = [100,100,fWid,fHght];
            
            % figure creation
            obj.hFig = figure('Position',fPos,'tag','figStashList',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Stashed Code List','Resize','off',...
                              'NumberTitle','off','Visible','off');            
            
            % ------------------------ %
            % --- STASH SAVE PANEL --- %
            % ------------------------ %
            
            % initialisations
            cbFcn = {@obj.buttonStashApply,...
                     @obj.buttonStashDelete,...
                     @obj.buttonClose};
            bStr = {'Apply Stash','Delete Stash','Close Window'};
            obj.hButC = cell(length(bStr),1);
            
            % creates the panel object
            pPos1 = [obj.dX*[1,1],obj.widPanel,obj.hghtPanel];
            obj.hPanel{1} = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                             'Position',pPos1);            
            
            % creates the button objects
            for i = 1:length(bStr)
                x0 = obj.dX + (i-1)*(obj.dX/2 + obj.widBut);
                bPos = [x0,obj.dXB,obj.widBut,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanel{1},'Style',...
                            'pushbutton','Position',bPos,'Callback',...
                            cbFcn{i},'FontUnits','Pixels','FontSize',12,...
                            'FontWeight','bold','String',bStr{i});                        
            end                               
                  
            % sets the button object properties
            setObjEnable(obj.hButC{1},~isempty(tData));
            setObjEnable(obj.hButC{2},~isempty(tData));
            
            % ------------------------ %
            % --- STASH LIST PANEL --- %
            % ------------------------ %
            
            % creates the panel object
            y0 = 2*obj.dX + obj.hghtPanel;
            pPos2 = [obj.dX,y0,obj.widPanel,obj.hghtPanelL];
            obj.hPanel{2} = uipanel(obj.hFig,'Title','','Units',...
                                             'Pixels','Position',pPos2);            
            
            % sets the table properties
            cWid = {135,140};
            cName = {'Stash Name','Stash Creation Date'};
            tPos = [obj.dX*[1,1],obj.widPanel-2*obj.dX,hghtTable];            
                                         
            % creates the list table object
            obj.hTable = uitable(obj.hPanel{2},'Data',tData,...
                                'Units','Pixels','Position',tPos,...
                                'ColumnName',cName,'ColumnWidth',cWid,...
                                'CellSelectionCallback',@obj.tableSelect,...
                                'ColumnEditable',[false,false],...
                                'RowName',[]);                        
                      
            % automatically resizes the table columns
            autoResizeTableColumns(obj.hTable);
                            
            % ---------------------------- %
            % --- CONTROL BUTTON PANEL --- %
            % ---------------------------- % 
            
            % initialisations
            tStrS = 'Stash Name: ';
            bStrS = 'Save Stash';
            
            % creates the panel object
            y0 = 3*obj.dX + (obj.hghtPanelL + obj.hghtPanel);
            pPos3 = [obj.dX,y0,obj.widPanel,obj.hghtPanel];
            obj.hPanel{3} = uipanel(obj.hFig,'Title','','Units',...
                                             'Pixels','Position',pPos3);                        
                
            % creates the edit object
            tPos = [obj.dX/2,obj.dXB+2,obj.widTxt,obj.hghtTxt];
            obj.hTxtS = uicontrol(obj.hPanel{3},'Style','Text',...
                        'Position',tPos,'FontUnits','Pixels','FontSize',...
                        12,'FontWeight','bold','String',tStrS);                                         
                                         
            % creates the text label object
            x0 = obj.dX/2 + obj.widTxt;
            ePos = [x0,obj.dXB,obj.widEdit,obj.hghtEdit];
            obj.hEditS = uicontrol(obj.hPanel{3},'Style','Edit',...
                        'Position',ePos,'Callback',@obj.editStashName,...
                        'HorizontalAlignment','left');            
            
            % creates the button object
            x0 = obj.dX + obj.widTxt + obj.widEdit;
            bPos = [x0,obj.dXB-2,obj.widBut,obj.hghtBut];
            obj.hButS = uicontrol(obj.hPanel{3},'Style','PushButton',...
                        'Position',bPos,'Callback',@obj.buttonStashSave,...
                        'FontUnits','Pixels','FontSize',12,...
                        'FontWeight','bold','String',bStrS,'Enable','off');
            
            % if the branch is not modified, then disable the panel
            if ~obj.gfObj.detIfBranchModified    
                setPanelProps(obj.hPanel{3},'off')
            end
            
            % resets the figure position
            centreFigPosition(obj.hFig,2)
                    
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- stash name editbox callback function
        function editStashName(obj,hObj,~)
            
            % determines if the new string is valid            
            nwStr = get(hObj,'String');
            
            % determines if the new string is valid
            if chkDirString(nwStr,1)
                % if so, determine if it is a repeat
                obj.saveStr = nwStr;
                setObjEnable(obj.hButS,~isempty(obj.saveStr));
            else
                % otherwise, reset the stash string name
                set(obj.hEdit,'String',obj.saveStr);                 
            end           
            
        end
        
        % --- save stash callback function
        function buttonStashSave(obj,~,~)
            
            % determines if there is any stored data in the table
            tData = get(obj.hTable,'Data');
            if ~isempty(tData)
                % if there is previous data, then determine if the new
                % stash save name string is unique
                if any(strcmp(tData,obj.saveStr))
                    % if there is a match, then output an error to screen
                    eStr = sprintf('The stash list name "%s" already ',...
                                   'exists.',obj.saveStr);
                    waitfor(msgbox(eStr,'Duplicate Stash Names','modal'))
                    
                    % exits the function
                    return
                end
            end
            
            % creates a loadbar
            h = ProgressLoadbar('Saving Code Stash...');
            
            % stashes the code and updates the table
            obj.gfObj.gitCmd('stash-save',obj.saveStr);
            obj.updateTableData();
            
            % deletes the loadbar
            delete(h);
            
        end        
        
        % --- table list stash selection callback function
        function tableSelect(obj,~,~)
            
            % enables the button properties
            obj.updateButtonProps(1);
                        
        end                
        
        % --- apply stash callback function
        function buttonStashApply(obj,~,~)
            
            % prompts the user if they wish to delete the stash
            qStr = 'Are you sure you want to apply the selected stash?';
            uChoice = questdlg(qStr,'Apply Stash?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end  
            
            % creates a loadbar
            h = ProgressLoadbar('Applying Selected Stash...');            
            
            % applies the selected stash
            iRow = getTableCellSelection(obj.hTable);
            obj.gfObj.gitCmd('stash-pop',iRow-1);
            
            % updates the table data
            obj.updateTableData();
            
            % disables the button properties
            obj.updateButtonProps(0);    
            
            % deletes the loadbar
            delete(h);            
            
        end        
        
        % --- delete stash callback function
        function buttonStashDelete(obj,~,~)
            
            % prompts the user if they wish to delete the stash
            qStr = 'Are you sure you want to delete the selected stash?';
            uChoice = questdlg(qStr,'Delete Stash?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end
            
            % creates a loadbar
            h = ProgressLoadbar('Deleting Selected Stash...');                        
            
            % deletes the selected stash
            iRow = getTableCellSelection(obj.hTable);
            obj.gfObj.gitCmd('stash-drop',iRow-1);
            
            % updates the table data
            obj.updateTableData();
            
            % disables the button properties
            obj.updateButtonProps(0);
            
            % deletes the loadbar
            delete(h);            
            
        end    
        
        % --- close window callback function
        function buttonClose(obj,~,~)
            
            % deletes the GUI
            delete(obj.hFig);
            
            % makes the main GUI visible again
            setObjVisibility(obj.hFigM,'on')
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %        
        
        % --- updates the button properties
        function updateButtonProps(obj,state)
            
            % enables the apply/delete control buttons
            cellfun(@(x)(setObjEnable(x,state)),obj.hButC(1:2));            
            
        end        
        
        % --- sets up the data for the stashed list table
        function updateTableData(obj)
            
            % retrieves the stash list
            stList = obj.gfObj.gitCmd('stash-list','date-local');
            
            % sets up the table data array
            if isempty(stList)
                % if there is no stash code, then set an empty list
                tData = [];
            else
                % splits the stash list data by line
                stLine = strsplit(stList,'\n');
                
                % sets up the table data array
                tData = cell(length(stLine),2);
                for i = 1:length(stLine)   
                    % sets the stash list names
                    sStrSp = regexp(stLine{i},'[{}*]','split');
                    
                    % sets the stash list name
                    sStrSp2 = strsplit(sStrSp{end},':');
                    tData{i,1} = strtrim(sStrSp2{end});                    
                    
                    % sets the date time string
                    dNum = datenum(sStrSp{2},'ddd mmm dd HH:MM:SS yyyy');
                    tData{i,2} = datestr(dNum,'dd-mmm-yyyy');                    
                end
                
            end
            
            % updates the table data
            set(obj.hTable,'Data',tData);
            removeTableSelection(obj.hTable);
            
        end
        
    end
    
end