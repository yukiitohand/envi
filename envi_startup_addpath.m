function [] = envi_startup_addpath(error_if_not_unique,silent_if_not_unique)
% envi_startup_addpath
%  Add paths of envi toolbox, while solving dependent toolboxes.
%  Dependent toolboxes: 
%     base
% 
%  USAGE
%  >> envi_startup_addpath()
%  >> envi_startup_addpath(error_if_not_unique)
%  >> envi_startup_addpath(error_if_not_unique,silent_if_not_unique)
%  
% Optional Input Arguments
% error_if_not_unique: boolean, (default) false
%   whether throw an error if one of the dependent toolboxes cannot be 
%   found or multiple versions are detected.
% silent_if_not_unique: boolean, (default) false
%   whether print a meesage if one of the dependent toolboxes cannot be 
%   found or multiple versions are detected. If error_if_not_unique, then
%   this does not have any effect (since error will be thrown.)
%
% Only supports MATLAB versions since R2019b
% 

% arguments block only supported versions since R2019b
arguments
    error_if_not_unique  (1,1) {mustBeMember(error_if_not_unique,[0,1])}  = false;
    silent_if_not_unique (1,1) {mustBeMember(silent_if_not_unique,[0,1])} = false;
end


%% Automatically find the path to toolboxes
fpath_self = mfilename('fullpath');
[dirpath_self,filename] = fileparts(fpath_self);
[toolbox_root_dir,envi_toolbox_dirname] = fileparts(dirpath_self);

%% Find dependent toolboxes.
dList = dir(toolbox_root_dir);
pathCell = strsplit(path, pathsep);

% base toolbox
[base_toolbox_dir,base_toolbox_dirname,Nt] = get_toolbox_dirname(dList, ...
    'base',error_if_not_unique,silent_if_not_unique);
if Nt==1 && ~check_path_exist(base_toolbox_dir, pathCell)
    addpath(base_toolbox_dir);
end

%% envi toolbox
envi_toolbox_dir = fullfile(toolbox_root_dir, envi_toolbox_dirname);

if ~check_path_exist(envi_toolbox_dir, pathCell)
    addpath( ...
        envi_toolbox_dir                                     , ...
        fullfile(envi_toolbox_dir,'v2')                      , ...
        fullfile(envi_toolbox_dir,'v3')                      , ...
        fullfile(envi_toolbox_dir,'v3','lazy_mex')           , ...
        fullfile(envi_toolbox_dir,'v3','lazy_mex','wrapper')   ...
    );

    cmp_arch = computer('arch');
    
    if verLessThan('matlab','9.4')
        api = 'r2017b';
    else
        api = 'r2018a';
    end

    switch cmp_arch
        case 'maca64'
            % For Mac computers
            envi_mex_build_path = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','maca64');
            envi_mex_build_path2 = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','maca64',api);
        case 'maci64'
            % For Mac computers
            envi_mex_build_path = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','maci64');
            envi_mex_build_path2 = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','maci64',api);
        case 'glnxa64'
            % For Linux/Unix computers with x86-64 architechture
            envi_mex_build_path = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','glnxa64');
            envi_mex_build_path2 = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','glnxa64',api);
        case 'win64'
            envi_mex_build_path = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','win64');
            envi_mex_build_path2 = fullfile(envi_toolbox_dir,'v3','lazy_mex','build','win64',api);
        otherwise
            error('%s is not supported',cmp_arch);
    end

    if exist(envi_mex_build_path,'dir')
        addpath(envi_mex_build_path,envi_mex_build_path2);
    else
        addpath(envi_mex_build_path,envi_mex_build_path2);
        fprintf('Run envi/v3/lazy_mex/build/envi_v3_lazy_mex_compile_all.m to compile C/MEX sources.\n');
    end
end

end

%%
function [onPath] = check_path_exist(dirpath, pathCell)
    % pathCell = strsplit(path, pathsep, 'split');
    if ispc || ismac 
      onPath = any(strcmpi(dirpath, pathCell));
    else
      onPath = any(strcmp(dirpath, pathCell));
    end
end

function [toolbox_dirpath,toolbox_dirname,Nt] = get_toolbox_dirname( ...
    dList,toolbox_dirname_wover,error_if_not_unique,silent_if_not_unique)
% [toolbox_dirpath,toolbox_dirname,Nt] = get_toolbox_dirname( ...
%     dList,toolbox_dirname_wover,error_if_not_unique,silent_if_not_unique)
%  get directory path to the toolbox specified by "toolbox_dirname_wover",
%  which is the directory name of the toolbox without a version suffix. 
%  Also the directory name of the toolbox with the version is returned.
%  If no such toolbox is found or multiple of them are found, then: 
%    throws an error when error_if_not_unique = true
%    outputs an message when error_if_not_unique = false and silent_if_not_unique = false
%    return empty when error_if_not_unique = false and silent_if_not_unique=true
%    and no toolbox is found
%    return cell arrays when error_if_not_unique = false and silent_if_not_unique=true
%    and multiple toolboxes are found.
%
%  Inputs:
%   dList: struct, output of dir function
%   toolbox_dirname_wover: directory name of the toolbox without version
%      numbers.
%   error_if_not_unique: boolean. whether or not to throw an error if no
%   toolbox or multiple toolboxes are detected.
%   silent_if_not_unique: boolean. whether or not to print a message if no
%   toolbox or multiple toolboxes are detected. No effect when
%   error_if_not_unique is true(1).
%  OUTPUTS
%   toolbox_dirpath: empty, char, cell array of chars.
%     directory path of the toolbox (with versions if exists).
%   toolbox_dirname: empty, char, cell array of chars.
%     directory name of the toolbox (without versions if exists).
%   Nt: number of toolboxes detected.
%
    dirname_ptrn = sprintf('(?<toolbox_dirname>%s(-[\\d\\.]+){0,1}[%s]{0,1})',...
        toolbox_dirname_wover,filesep);
    mtch_toolbox_dirname = regexpi({dList.name},dirname_ptrn,'names');
    mtchidx = find(not(cellfun('isempty',mtch_toolbox_dirname)));
    toolbox_root_dir = dList(1).folder;
    if length(mtchidx)==1
        toolbox_dirname = mtch_toolbox_dirname{mtchidx}.toolbox_dirname;
        toolbox_dirpath = fullfile(toolbox_root_dir, toolbox_dirname);
        Nt = 1;
    elseif isempty(mtchidx)
        toolbox_dirname = [];
        toolbox_dirpath = [];
        Nt = 0;
        if error_if_not_unique
            mid = strcat(toolbox_dirname_wover,':notfind');
            ME = MException(mid, ...
                ['Cannot find %s toolbox in\n %s', ...
                 'Download from\n', ...
                 '   https://github.com/yukiitohand/%s/'], ...
                toolbox_dirname_wover,toolbox_root_dir,toolbox_dirname_wover);

            throwAsCaller(ME);
        else
            if ~silent_if_not_unique
                fprintf(['Cannot find %s toolbox in.\n %s', ...
                       'If necessary, download it from\n', ...
                       '   https://github.com/yukiitohand/%s/\n', ...
                       'Otherwise, manually set path to %s toolbox.\n'
                      ], ...
                    toolbox_dirname_wover,toolbox_root_dir, ...
                    toolbox_dirname_wover,toolbox_dirname_wover);
            end
        end
    else % length(mtchidx)>1
        toolbox_dirname = {cat(2,mtch_toolbox_dirname{mtchidx}).toolbox_dirname};
        toolbox_dirpath = cellfun(@(x) fullfile(toolbox_root_dir,x), ...
            toolbox_dirname, 'UniformOutput',false);
        Nt = length(mtchidx);
        if error_if_not_unique
            mid = strcat(toolbox_dirname_wover,':multifind');
            toolbox_root_dir = dList(1).folder;
            ME = MException(mid, ...
                ['Multiple %s toolboxes, %s, are detected in %s\n', ...
                 'Manually set path to %s toolbox.\n' ], ...
                toolbox_dirname_wover,strjoin(toolbox_dirname,','), ...
                toolbox_root_dir, toolbox_dirname_wover);
            throwAsCaller(ME);
        else
            if ~silent_if_not_unique
                fprintf([ ...
                    'Multiple %s toolboxes, %s, are detected in %s\n', ...
                    'Manually set path to %s toolbox.\n' ...
                    ], ...
                    toolbox_dirname_wover,strjoin(toolbox_dirname,', '), ...
                    toolbox_root_dir,toolbox_dirname_wover);
            end
        end
        
    end
end
