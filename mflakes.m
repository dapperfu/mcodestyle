function mflakes(varargin)
% mflakes - A simple program which checks Matlab source files for errors.
%
% Syntax:
%	mflakes - Run mflake in current directory
%
% Inputs:
%	input1 - InputDescription
%	input2 - InputDescription
%	input3 - InputDescription
%
% Outputs:
%	output1 - OutputDescription
%	output2 - OutputDescription
%
% Example:
%	[output1,output2] = mflakes(directory, options)
%	[output1,output2] = mflakes(options)
%
% See also:

% Author: Jed Frey
% October 2017

%------------- BEGIN CODE --------------
%% Input Processing
% If not called with any arguments and in a Jenkins run.
if nargin==0 && ~isempty(getenv('WORKSPACE'))
    % Set the base_dir to the workspace.
    base_dir =  getenv('WORKSPACE');
    % Set the logfile_base to the job name + suffix.
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
        log_file='stderr';
    else
        % Otherwise grab the first argument.
        log_file = varargin{2};
    end
end

% Direct fprintf to:
if strcmp(log_file, 'stdout')
    % The command window.
    fid=1;
elseif strcmp(log_file, 'stderr')
    % The command window in red text.
    fid=2;
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
MCCABE_LIMIT = 10;
% Severity configuration. Otherwise defaults to Normal.
SEVERITY_CFG=struct();
SEVERITY_CFG.CABE = 'H';
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
    % If the check is McCabe complexity.
    if strcmp(check.id, 'CABE')
        % Get the current complexity.
        [~, complexity] = get_complexity(check);
        % If it is less than the threshold, move on.
        if complexity<MCCABE_LIMIT
            continue
        end
    end
    % If the ID is in the severity config struct.
    if isfield(SEVERITY_CFG, check.id)
        % Use that value.
        severity = SEVERITY_CFG.(check.id);
    else
        % Default to Normal.
        severity = 'N';
    end
    % Generate the lint line string.
    lint_str = sprintf('%s:%d [%s:%c] %s', ...
        checked_file_rel, ...
        check.line, ...
        check.id, ....
        severity, ...
        check.message);
    % Print to the corrent output.
    fprintf(fid, '%s\n', lint_str);
end
%%
function [fcn_name, complexity] = get_complexity(result)
% Get the message.
message = result.message;
% Split off the function name.
fcn_split = strsplit(message, '''');
fcn_name = fcn_split{2};
% Parse for complexity.
split = strsplit(message, ' ');
complexity = sscanf(split{end}, '%d');
%------------- END CODE ----------------
