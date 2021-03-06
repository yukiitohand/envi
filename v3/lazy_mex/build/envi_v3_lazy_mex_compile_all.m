% envi_v3_compile_all.m
source_filenames = { ...
    'lazyenvireadRect_multBandRasterInt16_mex.c'    ,   ...
    'lazyenvireadRect_multBandRasterSingle_mex.c'   ,   ...
    'lazyenvireadRect_multBandRasterUint16_mex.c'   ,   ...
    'lazyenvireadRect_multBandRasterUint8_mex.c'    ,   ...
    'lazyenvireadRect_singleLayerRasterInt16_mex.c' ,   ...
    'lazyenvireadRect_singleLayerRasterSingle_mex.c',   ...
    'lazyenvireadRect_singleLayerRasterUint16_mex.c',   ...
    'lazyenvireadRect_singleLayerRasterUint8_mex.c'     ...
};

switch computer
    case 'MACI64'
        out_dir = './maci64/';
    case 'GLNXA64'
        out_dir = './glnxa64/';
    case 'PCWIN64'
        out_dir = './pcwin64/';
    otherwise
        error('Undefined computer type %s.\n',computer);
end

if ~exist(out_dir,'dir')
    mkdir(out_dir);
end

for i=1:length(source_filenames)
    filename = source_filenames{i};
    fprintf('Compiling %s ...\n',filename);
    filepath = ['../source/' filename];
    mex(filepath, '-R2018a', 'CFLAGS="$CFLAGS -Wno-unused-result"', ...
        '-I../include/', ...
        '-outdir',out_dir);
end

fprintf('End of compiling.\n');