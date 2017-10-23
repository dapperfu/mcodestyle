function mflakes(varargin)
% mflakes - A simple program which checks Matlab source files for errors.
%
% Syntax:
%	mflakes - Run mflake in current directory
%
% Inputs:
%	input1 - InputDescription
%
% Example:
%	mflakes
%
% See also:
% Regex:
%     ^([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|
%
% Mapping Script:
%     import hudson.plugins.warnings.parser.Warning
%     import hudson.plugins.analysis.util.model.Priority
% 
%     String fileName = matcher.group(1)
%     Integer lineNumber = Integer.parseInt(matcher.group(2))
%     String type =  matcher.group(3)
%     String category = matcher.group(4)
%     String message = matcher.group(5)
%     String severity = matcher.group(6)
% 
%     Priority priority = Priority.NORMAL
% 
%     switch (severity) {
%         case "H":
%             priority = Priority.HIGH
%             break
%         case "N":
%             priority = Priority.NORMAL
%             break
%         case "L":
%             priority = Priority.LOW
%             break
%         default:
%             priority = Priority.NORMAL
%     }
% 
%     return new Warning(fileName, lineNumber, type, category, message, priority)
  
% Author: Jed Frey
% October 2017
%------------- BEGIN CODE --------------
%% Input Processing
% If not called with any arguments and in a Jenkins run.
if nargin==0 && ~isempty(getenv('WORKSPACE'))
    % Set the base_dir to the workspace.
    base_dir =  getenv('WORKSPACE');
    log_file_base = sprintf('%s.mflakes.log', getenv('JOB_BASE_NAME'));
    % Save the logfile to the workspace for gathering.
    log_file = fullfile(base_dir, log_file_base);
else
    if nargin<1
        % Default to the current working directory.
        base_dir = pwd;
    else
        % Otherwise grab the first argument.
        base_dir = varargin{1};
    end
    if nargin<2
        % Default to redtext.
        log_file='stdout';
    else
        % Otherwise grab the first argument.
        log_file = varargin{2};
    end
end

% Direct fprintf to:
if strcmp(log_file, 'stdout')
    % The command window.
    fid=1;
else
    % The log file.
    fid = fopen(log_file, 'w');
end

% Get all .m files in the base_directory
files = file_list(base_dir, '.m');
% For each of the files.
for file_idx = 1:numel(files)
    file = files{file_idx};
    % Check the file and fprintf destination.
    check_file(file, fid)
end
% Close the open file.
if fid>2
    fclose(fid);
end


function check_file(file, fid)
% Limit to report as a 'problem'.
MCCABE_LOW_LIMIT = 5;   % McCabe limit for low level
MCCABE_NORM_LIMIT = 10; % McCabe limit for normal level
MCCAME_HIGH_LIMIT = 15; % McCabe limit for high level
% Severity configuration. Otherwise defaults to Normal.
SEVERITY_CFG=struct();
SEVERITY_CFG.DEPGENAM = 'H';
SEVERITY_CFG.FXSET = 'L';
% Run checkcode and gather the results.
[check_results] = checkcode(file, '-struct', '-id', '-fullpath', '-cyc');

% Loop through each of the results.
for check_idx = 1:numel(check_results)
    % Get the current check in loop.
    check            = check_results(check_idx);
    % Strip off of the base folder since file is an absolute path.
    checked_file_rel = strrep(file, pwd, '.');
    checked_file_rel = checked_file_rel(3:end);
    % If the check is McCabe complexity.
    if strcmp(check.id, 'CABE') || strcmp(check.id, 'SCABE')
        % Get the current complexity.
        complexity = get_complexity(check);
        % If the complexity is lower than the low limit.
        if complexity < MCCABE_LOW_LIMIT
            % Continue and do nothing.
            continue;
        elseif complexity < MCCABE_NORM_LIMIT
            % Set severity to low.
            severity = 'L';
        elseif complexity < MCCAME_HIGH_LIMIT
            % Set severity to normal.
            severity = 'N';
        else
            % Set severity to high.
            severity = 'H';
        end
    elseif isfield(SEVERITY_CFG, check.id)
        % If the ID is in the severity config struct.
        % Use that value.
        severity = SEVERITY_CFG.(check.id);
    else
        if check.fix
            % If if an automatic fix is available. High since it requires no 
            % effort on the programmer's part to fix.
            severity = 'H';
        else
            % Normal is default if no fix is available.
            severity = 'N';
        end
    end
    % Generate the lint line string.
    fprintf(fid, '%s|', checked_file_rel);
    fprintf(fid, '%d|', check.line);
    fprintf(fid, '%s|', check.id);
    fprintf(fid, '%s|', check.id);
    fprintf(fid, '%s|', check.message);
    fprintf(fid, '%s|', severity);
    fprintf(fid, '\n');
end
%%
function [complexity] = get_complexity(result)
% Get the message.
message = result.message;
% Parse for complexity.
split = strsplit(message, ' ');
complexity = sscanf(split{end}, '%d');
%------------- END CODE ----------------
