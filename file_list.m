function [files,total_files,files_struct] = file_list(toplevels,file_extensions,depth,filename_search,filename_exact)
%FILE_LIST Create list of files
%   [FILES,TOTAL_FILES,FILES_STRUCT] = FILE_LIST(TOPLEVEL,FILE_EXTENSION,DEPTH,FILENAME_SEARCH,FILENAME_EXACT) will
%   recurse through subdirectories of TOPLEVEL to a depth of DEPTH looking
%   for files that have the same extension as FILE_EXTENSION and matching
%   FILENAME_SEARCH. FILENAME_EXACT will match the filename exactly.
%
%   FILE_EXTENSION searches for the given the extension. Can be specified
%   with or without wildcards. '*.m' '.m' & 'm' are all equivalent. However
%   for wildcard searches '*' and '.*' are different. '*' will search for
%   all files (including those without extensions). '.*' will return all
%   extensions 
%
%   FILE_LIST(TOPLEVEL,FILE_EXTENSION) will search all subdirectories (to a
%   depth of infinity)
%
%   FILE_LIST(TOPLEVEL) will search for all files in a folder and sub
%   folders
%
%   TOPLEVEL and FILE_EXTENSION can also be cell arrays of multiple top
%   level directories or file extensions.
%
%   FILENAME_EXACT defaults to false. (For backwards compatability).
%
%   FILE_LIST is a cell array of all the file found
%   TOTAL_FILES is the total number of files found
%
%   The absolute path is always returned using GetFullPath.
%
%   Example:
%   [files,total]=file_list(pwd)
%   [files,total]=file_list(pwd,{'m','*mat','*.txt'})
%   [files,total]=file_list({'C:'},'.txt')
%   [files,total]=file_list({'C:'},{'m','mat'})
%   [files,total]=file_list({'C:'},'',inf,'NTUSER')
%
%   [files,total]=file_list(pwd,'*.mat',1);
%   for i=1:total
%       data=load(files{i});
%       % Do stuff with file
%   end

% Author: Jedediah Frey
% Created: Dec 2006
% Copyright 2006,2007,2008,2009

% Updated Jan 3, 2007
%   Added functionality for cell top level folders and file extensions
%   Will not fail on folder not existing

% Updated Dec 2012
%   Leveraging more functionality of dir and wildcards to speed up
%   execution.
%   Plus 5 additional years of coding experience and personal changes.
%   Incorporated GetFullPath flom MatlabCentral

%% Input Processing
% If no input 
if nargin < 1
    help(mfilename('fullpath'));
    warning('No input arguments given');
    return;
end
% If the top level is not a cell and just passed as a string, turn it into
% a cell
if ~iscell(toplevels)
    toplevels={toplevels};
end
if nargin < 3 || isempty(depth)
    depth=inf;
end
% If no file name search is specified, leave it blank
if nargin < 4 || isempty(filename_search)
    filename_search='';
end
% If the exactness of the filename_search isn't specified 
if nargin< 5 || isempty(filename_exact)
    filename_exact=false;
end
% If no file type is specified, search for all files
if nargin < 2 || isempty(file_extensions)
    if filename_exact
        file_extensions = {'.*'};
    else
        file_extensions = {'*'};
    end
end
% If the requested file_extension is not a cell, turn it into one
if ~iscell(file_extensions)
    file_extensions={file_extensions};
end
% reshape everything so that 'for' can just be used.
toplevels=reshape(toplevels,1,numel(toplevels));
file_extensions=reshape(file_extensions,1,numel(file_extensions));
%% Sanity Checks
i=1;
% Use a while loop because if the folder doesn't exist, drop it from the
% 'rotation'.
while i<=numel(toplevels)
    % Get the full absolute path
    toplevels{i}=GetFullPath(toplevels{i});
    if ~exist(toplevels{i},'dir')
        warning('FILE_LIST:FOLDERDNE',['Top level directory ' strrep(toplevels{i},'\','\\') ' does not exist']);
        toplevels(i)='';
        continue
    end
    % If the top level is not passed with a trailing file separator, add it
    if ~strcmp(toplevels{i}(end),filesep);
        toplevels{i}=[toplevels{i} filesep];
    end
    i=i+1;
end
% If no valid toplevel folders are found error out.
if numel(toplevels)==0
   error('FILE_LIST:NOVALIDFOLDERS','No top level directories found');
end
%% Cleanup extensions.
for n=1:numel(file_extensions)
    if strcmp(file_extensions{n},'*')||strcmp(file_extensions{n},'.*')
       continue;
    end
    % If the user puts a wildcard (*) before the file type extension remove
    % it
    if ~strcmp(file_extensions{n},'*')
        if strncmp(file_extensions{n},'*',1);
            file_extensions{n}(1)='';
        end
    end
    % If the user does not preappend the file type extension with a dot
    % insert it
    if ~strcmp(file_extensions{n}(1),'.')
        file_extensions{n}=['.' file_extensions{n}];
    end
end
%% Process files
level=1;
files=[];
for toplevel=toplevels
    files=dig(toplevel{1},file_extensions,files,level,depth,filename_search,filename_exact);
end
files=reshape(files,1,numel(files));
files_struct=files;
total_files=size(files,2);
files={files_struct.name};
files=reshape(files,1,numel(files));
end

function files=dig(folder,file_extensions,files,level,depth,filename_search,filename_exact)
if (level+1<=depth)
    tempDirectories = dir(folder);
    tempDirectories=reshape(tempDirectories,1,numel(tempDirectories));
    directories=[tempDirectories.isdir];
    for tempDirectory=tempDirectories(directories)
        % If the file/folder is . or .. (current or previous folder)
        if strcmp(tempDirectory.name,'.') || strcmp(tempDirectory.name,'..')
            continue;
        end
        files=dig(fullfile(folder,tempDirectory.name),file_extensions,files,level+1,depth,filename_search,filename_exact);
    end
end
for file_extension=file_extensions
    if isempty(filename_search)
        dirStr=fullfile(folder,sprintf('*%s',file_extension{1}));
    elseif ~filename_exact&&~isempty(filename_search)
        dirStr=fullfile(folder,sprintf('*%s*%s',filename_search,file_extension{1}));
    elseif filename_exact&&~isempty(filename_search)
        dirStr=fullfile(folder,sprintf('%s%s',filename_search,file_extension{1}));
    else
        error('Unpossible');
    end
    tempFiles=dir(dirStr);
    isFile=~[tempFiles.isdir];
    tempFiles=tempFiles(isFile);
    tempFiles=reshape(tempFiles,1,numel(tempFiles));
    tempFiles=addFullPath(folder,tempFiles);
    files=[files tempFiles]; %#ok<AGROW>
end
return;
end

function files=addFullPath(folder,files)
%% Add the full path
for i=1:numel(files)
    files(i).name=fullfile(folder,files(i).name);
end
end

%% http://www.mathworks.com/matlabcentral/fileexchange/28249-getfullpath/content/GetFullPath.m
function File = GetFullPath(File)
% GetFullPath - Get absolute path of a file or folder [MEX]
% FullName = GetFullPath(Name)
% INPUT:
%   Name: String or cell string, file or folder name with or without relative
%         or absolute path.
%         Unicode characters and UNC paths are supported.
%         Up to 8192 characters are allowed here, but some functions of the
%         operating system may support 260 characters only.
%
% OUTPUT:
%   FullName: String or cell string, file or folder name with absolute path.
%         "\." and "\.." are processed such that FullName is fully qualified.
%         For empty strings the current directory is replied.
%         The created path need not exist.
%
% NOTE: The Mex function calls the Windows-API, therefore it does not run
%   on MacOS and Linux.
%   The magic initial key '\\?\' is inserted on demand to support names
%   exceeding MAX_PATH characters as defined by the operating system.
%
% EXAMPLES:
%   cd(tempdir);                    % Here assumed as C:\Temp
%   GetFullPath('File.Ext')         % ==>  'C:\Temp\File.Ext'
%   GetFullPath('..\File.Ext')      % ==>  'C:\File.Ext'
%   GetFullPath('..\..\File.Ext')   % ==>  'C:\File.Ext'
%   GetFullPath('.\File.Ext')       % ==>  'C:\Temp\File.Ext'
%   GetFullPath('*.txt')            % ==>  'C:\Temp\*.txt'
%   GetFullPath('..')               % ==>  'C:\'
%   GetFullPath('Folder\')          % ==>  'C:\Temp\Folder\'
%   GetFullPath('D:\A\..\B')        % ==>  'D:\B'
%   GetFullPath('\\Server\Folder\Sub\..\File.ext')
%                                   % ==>  '\\Server\Folder\File.ext'
%   GetFullPath({'..', 'new'})      % ==>  {'C:\', 'C:\Temp\new'}
%
% COMPILE: See GetFullPath.c
%   Run the unit-test uTest_GetFullPath after compiling.
%
% Tested: Matlab 6.5, 7.7, 7.8, 7.13, WinXP/32, Win7/64
% Compiler: LCC 2.4/3.8, OpenWatcom 1.8, BCC 5.5, MSVC 2008
% Author: Jan Simon, Heidelberg, (C) 2010-2011 matlab.THISYEAR(a)nMINUSsimon.de
%
% See also Rel2AbsPath, CD, FULLFILE, FILEPARTS.

% $JRev: R-x V:023 Sum:BNPK16hXCfpM Date:22-Oct-2011 00:51:51 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $UnitTest: uTest_GetFullPath $
% $File: Tools\GLFile\GetFullPath.m $
% History:
% 001: 20-Apr-2010 22:28, Successor of Rel2AbsPath.
% 010: 27-Jul-2008 21:59, Consider leading separator in M-version also.
% 011: 24-Jan-2011 12:11, Cell strings, '~File' under linux.
%      Check of input types in the M-version.
% 015: 31-Mar-2011 10:48, BUGFIX: Accept [] as input as in the Mex version.
%      Thanks to Jiro Doke, who found this bug by running the test function for
%      the M-version.
% 020: 18-Oct-2011 00:57, BUGFIX: Linux version created bad results.
%      Thanks to Daniel.

% Initialize: ==================================================================
% Do the work: =================================================================

% #############################################
% ### USE THE MUCH FASTER MEX ON WINDOWS!!! ###
% #############################################

% Difference between M- and Mex-version:
% - Mex-version cares about the limit MAX_PATH.
% - Mex does not work under MacOS/Unix.
% - M is remarkably slower.
% - Mex calls Windows system function GetFullPath and is therefore much more
%   stable.
% - Mex is much faster.

% Disable this warning for the current Matlab session:
%   warning off JSimon:GetFullPath:NoMex
% If you use this function e.g. under MacOS and Linux, remove this warning
% completely, because it slows down the function by 40%!
%warning('JSimon:GetFullPath:NoMex', ...
%  'GetFullPath: Using slow M instead of fast Mex.');

% To warn once per session enable this and remove the warning above:
%persistent warned
%if isempty(warned)
%   warning('JSimon:GetFullPath:NoMex', ...
%           'GetFullPath: Using slow M instead of fast Mex.');
%    warned = true;
% end

% Handle cell strings:
% NOTE: It is faster to create a function @cell\GetFullPath.m under Linux,
% but under Windows this would shadow the fast C-Mex.
if isa(File, 'cell')
   for iC = 1:numel(File)
      File{iC} = GetFullPath(File{iC});
   end
   return;
end

isWIN = strncmpi(computer, 'PC', 2);

% DATAREAD is deprecated in 2011b, but available:
hasDataRead = ([100, 1] * sscanf(version, '%d.%d.', 2) <= 713);

if isempty(File)  % Accept empty matrix as input
   if ischar(File) || isnumeric(File)
      File = cd;
      return;
   else
      error(['JSimon:', mfilename, ':BadInputType'], ...
         ['*** ', mfilename, ': Input must be a string or cell string']);
   end
end

if ischar(File) == 0  % Non-empty inputs must be strings
   error(['JSimon:', mfilename, ':BadInputType'], ...
      ['*** ', mfilename, ': Input must be a string or cell string']);
end

if isWIN  % Windows: --------------------------------------------------------
   FSep = '\';
   File = strrep(File, '/', FSep);
   
   isUNC   = strncmp(File, '\\', 2);
   FileLen = length(File);
   if isUNC == 0                        % File is not a UNC path
      % Leading file separator means relative to current drive or base folder:
      ThePath = cd;
      if File(1) == FSep
         if strncmp(ThePath, '\\', 2)   % Current directory is a UNC path
            sepInd  = strfind(ThePath, '\');
            ThePath = ThePath(1:sepInd(4));
         else
            ThePath = ThePath(1:3);     % Drive letter only
         end
      end
      
      if FileLen < 2 || File(2) ~= ':'  % Does not start with drive letter
         if ThePath(length(ThePath)) ~= FSep
            if File(1) ~= FSep
               File = [ThePath, FSep, File];
            else  % File starts with separator:
               File = [ThePath, File];
            end
         else     % Current path ends with separator, e.g. "C:\":
            if File(1) ~= FSep
               File = [ThePath, File];
            else  % File starts with separator:
               ThePath(length(ThePath)) = [];
               File = [ThePath, File];
            end
         end
         
      elseif isWIN && FileLen == 2 && File(2) == ':'   % "C:" => "C:\"
         % "C:" is the current directory, if "C" is the current disk. But "C:" is
         % converted to "C:\", if "C" is not the current disk:
         if strncmpi(ThePath, File, 2)
            File = ThePath;
         else
            File = [File, FSep];
         end
      end
   end
   
else         % Linux, MacOS: ---------------------------------------------------
   FSep = '/';
   File = strrep(File, '\', FSep);
   
   if strcmp(File, '~') || strncmp(File, '~/', 2)  % Home directory:
      HomeDir = getenv('HOME');
      if ~isempty(HomeDir)
         File(1) = [];
         File    = [HomeDir, File];
      end
      
   elseif strncmpi(File, FSep, 1) == 0
      % Append relative path to current folder:
      ThePath = cd;
      if ThePath(length(ThePath)) == FSep
         File = [ThePath, File];
      else
         File = [ThePath, FSep, File];
      end
   end
end

% Care for "\." and "\.." - no efficient algorithm, but the fast Mex is
% recommended at all!
if ~isempty(strfind(File, [FSep, '.']))
   if isWIN
      if strncmp(File, '\\', 2)  % UNC path
         index = strfind(File, '\');
         if length(index) < 4    % UNC path without separator after the folder:
            return;
         end
         Drive            = File(1:index(4));
         File(1:index(4)) = [];
      else
         Drive     = File(1:3);
         File(1:3) = [];
      end
   else  % Unix, MacOS:
      isUNC   = false;
      Drive   = FSep;
      File(1) = [];
   end
   
   hasTrailFSep = (File(length(File)) == FSep);
   if hasTrailFSep
      File(length(File)) = [];
   end
   
   if hasDataRead
      if isWIN  % Need "\\" as separator:
         C = dataread('string', File, '%s', 'delimiter', '\\');  %#ok<REMFF1>
      else
         C = dataread('string', File, '%s', 'delimiter', FSep);  %#ok<REMFF1>
      end
   else  % Use the slower REGEXP in Matlab > 2011b:
      C = regexp(File, FSep, 'split');
   end
   
   % Remove '\.\' directly without side effects:
   C(strcmp(C, '.')) = [];
   
   % Remove '\..' with the parent recursively:
   R = 1:length(C);
   for dd = reshape(find(strcmp(C, '..')), 1, [])
      index    = find(R == dd);
      R(index) = [];
      if index > 1
         R(index - 1) = [];
      end
   end
   
   if isempty(R)
      File = Drive;
      if isUNC && ~hasTrailFSep
         File(length(File)) = [];
      end
      
   elseif isWIN
      % If you have CStr2String, use the faster:
      %   File = CStr2String(C(R), FSep, hasTrailFSep);
      File = sprintf('%s\\', C{R});
      if hasTrailFSep
         File = [Drive, File];
      else
         File = [Drive, File(1:length(File) - 1)];
      end
      
   else  % Unix:
      File = [Drive, sprintf('%s/', C{R})];
      if ~hasTrailFSep
         File(length(File)) = [];
      end
   end
end
return;
end
