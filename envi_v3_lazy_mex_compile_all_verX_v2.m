function [] = envi_v3_lazy_mex_compile_all_verX_v2(varargin)
% envi_v3_compile_all.m

mexCompileOpt = {};
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'MEXCOMPILEOPT'
                mexCompileOpt = varargin{i+1};
                if ~iscell(mexCompileOpt)
                    mexCompileOpt = {mexCompileOpt};
                end
            otherwise
                error('Unrecognized option: %s',varargin{i});
        end
    end
end

fpath_self = mfilename('fullpath');
[dirpath_self,filename] = fileparts(fpath_self);

idx_sep = strfind(dirpath_self,fullfile('v3','lazy_mex','build'));
envi_toolbox_path = dirpath_self(1:idx_sep-1);

envi_mex_include_path = fullfile(envi_toolbox_path, 'v3','lazy_mex','include');
envi_mex_source_path  = fullfile(envi_toolbox_path, 'v3','lazy_mex','source');
envi_mex_outdir_path  = fullfile(envi_toolbox_path, 'v3','lazy_mex','build');
envi_mex_libdir_path  = fullfile(envi_toolbox_path, 'v3','lazy_mex','lib');

% Sorry, these functions are currently not supported for MATLAB 9.3 or
% earlier. These requires another 
if verLessThan('matlab','9.4')
    compile_opt_api = '-R2017b';
else
    compile_opt_api = '-R2018a';
end

%%
source_lib_filenames = { ...
    'envi_v2.c', ...
};

lib_dir = envi_mex_libdir_path;

if ~exist(lib_dir,'dir'), mkdir(lib_dir); end

%%

out_filename_list = cell(1, length(source_lib_filenames));
for i=1:length(source_lib_filenames)
    filename = source_lib_filenames{i};
    [~,basename,~] = fileparts(filename);
    out_filename = [basename '.o'];
    fprintf('Compiling %s ...\n',filename);
    filepath = fullfile(envi_mex_source_path,filename);
    mex(filepath,'-v','-c',compile_opt_api, ...
        ... 'GCC=''/software/gcc-6.3.0/bin/gcc''', ...
        ['CFLAGS="$CFLAGS -c -O3 -fPIC -ffast-math ' ...
         '-fno-strict-aliasing -Wno-unused-result -std=c99 -pedantic"'], ...
        ['-I' envi_mex_include_path], '-outdir', lib_dir, mexCompileOpt{:});
    out_filename_arch = [basename '-' computer('arch') lower(compile_opt_api) '.o'];
    out_filename_list{i} = out_filename_arch;
    movefile(fullfile(lib_dir,out_filename),fullfile(lib_dir,out_filename_arch));
end

%%
source_filenames = { ...
    ...'lazyenvireadRect_singleLayerRasterInt8_mex.c'  ,   ...
    'lazyenvireadRectxv2_multBandRaster_mex.c'   ,   ...
    ...'lazyenvireadRect_singleLayerRasterInt16_mex.c' ,   ...
    ...'lazyenvireadRect_singleLayerRasterSingle_mex.c',   ...
    ...'lazyenvireadRect_singleLayerRasterUint16_mex.c',   ...
    ...'lazyenvireadRect_singleLayerRasterUint8_mex.c'     ...
};

api_wo_hyphen = lower(strip(compile_opt_api,'left','-'));
switch computer
    case 'MACI64'
        out_dir = fullfile(envi_mex_outdir_path,'maci64',api_wo_hyphen);
    case 'GLNXA64'
        out_dir = fullfile(envi_mex_outdir_path,'glnxa64',api_wo_hyphen);
    case 'PCWIN64'
        out_dir = fullfile(envi_mex_outdir_path,'win64',api_wo_hyphen);
    otherwise
        error('Undefined computer type %s.\n',computer);
end

if ~exist(out_dir,'dir'), mkdir(out_dir); end

%%
static_libraries = cellfun(@(x) fullfile(lib_dir,x), ...
    out_filename_list,'UniformOutput',false);
static_libraries = strjoin(static_libraries,' ');
for i=1:length(source_filenames)
    filename = source_filenames{i};
    fprintf('Compiling %s ...\n',filename);
    filepath = fullfile(envi_mex_source_path,filename);
    mex(filepath,'-v', compile_opt_api, static_libraries, ...
        ...'GCC=''/software/gcc-6.3.0/bin/gcc''', ...
        ['CFLAGS="$CFLAGS -c -O3 -fPIC -ffast-math ' ...
         '-fno-strict-aliasing -Wno-unused-result -std=c99 -pedantic"'], ...
        ['-I' envi_mex_include_path], ...
        '-outdir',out_dir, mexCompileOpt{:});
end

fprintf('End of compiling.\n');

end
