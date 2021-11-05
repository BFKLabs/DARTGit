function createGitIgnoreFile(GF)

% global variables
global mainProgDir

% initialisations
zipFile = [];

% sets the base git repository directory
gDir = fullfile(mainProgDir,'Git','Repo');

% sets the git repository type dependent on the input
switch GF.rType
    case 'Main'
        gRepo = 'DART';
       
        % sets the zip file array
        fexDir = fullfile(mainProgDir,'Code','Common','File Exchange');
        zipFile = {'ExeUpdate.zip';...
                   fullfile(fexDir,'ColoredFieldCellRenderer.zip')};
        
    case 'AnalysisGen'
        gRepo = 'DARTAnalysisGen';
        
    case 'Git'
        gRepo = 'DARTGit';
end

% determines if the git ignore for the repository exists
igDir = fullfile(gDir,gRepo);
igFile = fullfile(igDir,'.gitignore');
if exist(igFile,'file')
    % reads the data from the ignore file
    igData = readIgnoreFile(igFile);
    if strContains(igData,'/Common/Git')
        delete(igFile);
        pause(0.05);
    else    
        % loops through each of the listed zip files. if the zip file is
        % present on the drive, but not the ignore file, then delete the
        % ignore file and exit the loop
        for i = 1:length(zipFile)
            if exist(zipFile{i},'file') && ~strContains(igData,zipFile{i})
                delete(igFile);
                pause(0.05);
                break
            end
        end
    end
        
    % if the file exists, then exit the function
    if exist(igFile,'file')
        igFileF = ['"',igFile,'"'];
        GF.gitCmd('unset-global-config','core.excludesfile')    
        GF.gitCmd('set-global-config','core.excludesFile',igFileF);
        return
    end
end

% initialisations
[ignoreFileR,allowFileR] = deal([]);
allowFileC = {'*.fig'};

% sets the repository specific files to ignore
switch GF.rType
    case 'Main' % case is the main DART repository
        allowFileR = {'*.m','*.zip','*.p','/Code'};
        ignoreFileR = {'/Git',...
                       '/Code/Executable Only',...
                       '/Code/External Apps'};        
        
    case 'Git' % case is the Git functions
        allowFileR = {'*.p','*.m'};
        ignoreFileR = {'Repo'};
        
    case 'AnalysisGen' % case is the general analysis functions
        allowFileR = {'*.m'};
        ignoreFileR = {'*/*'};
        
end

% adds the zip files to the array
ignoreFileR = [ignoreFileR(:);convertZipFilePath(zipFile(:))];

% otherwise, create the file object
fid = fopen(igFile,'w');

% prints the top line
fprintf(fid,'# flag to ignore all files\n*.*\n/*\n');

% outputs the allowed files/directories
fprintf(fid,'\n# allowed files/directories\n');
allowFile = [allowFileC,allowFileR];
for i = 1:length(allowFile)
    fprintf(fid,'!%s\n',allowFile{i});
end

% outputs the ignored files/directories
fprintf(fid,'\n# ignored files/directories\n');
for i = 1:length(ignoreFileR)
    fprintf(fid,'%s\n',ignoreFileR{i});
end
    
% closes the file
fclose(fid);

% sets the exclusion file location
GF.gitCmd('unset-global-config','core.excludesfile')
GF.gitCmd('set-global-config','core.excludesFile',sprintf('"%s"',igFile));

% --- reads the data from the ignore data file
function igData = readIgnoreFile(igFile)

fid = fopen(igFile,'r'); 
igData = fread(fid,'*char')'; 
fclose(fid);

% --- converts the zip file path
function zipFile = convertZipFilePath(zipFile)

% global variables
global mainProgDir

% exits if the zip file is empty
if isempty(zipFile); return; end

% converts the absolute path to the relative path
for i = 1:length(zipFile)
    zipFile{i} = strrep(zipFile{i},mainProgDir,'');
    zipFile{i} = strrep(zipFile{i},'\','/');
end
