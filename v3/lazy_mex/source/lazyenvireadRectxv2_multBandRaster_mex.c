/* =====================================================================
 * lazyenvireadRectxv2_multBandRaster_mex.c
 * Read the specified rectangle region of an float32 image cube.
 * This function is endian free. The image data needs to be a binary image.
 * Rectangle part of the image:
 * [smpl_offset:(smpl_offset+samples), line_offset:(line_offset+lines),
 * band_offset:(band_offset+bands)]
 * is read (the first index of the whole image is supposed to be 0).
 * 
 * INPUTS:
 * 0 imgpath       char*
 * 1 header        struct for Envi Header
 * 2 smpl_skips   integer
 * 3 line_skips   integer
 * 4 band_skips   integer
 * 5 samples        integer
 * 6 lines          integer
 * 7 bands          integer
 * 
 * 
 * OUTPUTS:
 * 0  subimg 3 dimensional float (32bit) array, whose shape depends on 
 * interleave in header.
 * #Note that the image needs to be permuted after this.
 *
 *
 * This is a MEX file for MATLAB.
 *
 * ---------------
 * Update History
 * ---------------
 * +============|==========================================|==============+
 * | Date       | Comment                                  | Name         |
 * +============|==========================================|==============+
 *  2022 Sep. 27  created                                    Yuki Itoh.
 *
 * -----------------
 * Copyright Notice
 * -----------------
 * Copyright (C) 2021 by Yuki Itoh <yukiitohand@gmail.com>
 *
 * ===================================================================== */
#include "io64.h"
#include "mex.h"
#include "matrix.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "envi_v2.h"
#include "mex_create_array.h"

/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    char *imgpath;
    EnviHeader hdr;
    double *smpl_skipszlist_dbl, *smpl_readszlist_dbl;
    double *line_skipszlist_dbl, *line_readszlist_dbl;
    double *band_skipszlist_dbl, *band_readszlist_dbl;

    long int *smpl_skipszlist, *line_skipszlist, *band_skipszlist;
    size_t   *smpl_readszlist, *line_readszlist, *band_readszlist;

    mwSize ndim_skip, ndim_read;
    const mwSize *dims_skip, *dims_read;
    size_t N_smpl_skipread, N_line_skipread, N_band_skipread;
    size_t i;

    size_t samplesc, linesc, bandsc;
    long int smpl_skips, line_skips, band_skips;
    long int smpl_skip_last, line_skip_last, band_skip_last;

    void *subimg;
    size_t sz;
    mwSize samples, lines, bands;
    mwSize dims[3];
    size_t dims_size_t[3];
    int errflg;

    /* -----------------------------------------------------------------
     * CHECK PROPER NUMBER OF INPUTS AND OUTPUTS
     * ----------------------------------------------------------------- */
    if(nrhs!=8) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:nrhs",
                "Eight inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:nlhs",
                "One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsChar(prhs[0]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notChar",
                "Input 0 (imgpath) needs to be a string.");
    }
    if( !mxIsStruct(prhs[1]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notStruct",
                "Input 1 (ENVI header) needs to be a struct.");
    }
    if( !mxIsDouble(prhs[2]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notDouble",
                "Input 2 (smpl_skipszlist) needs to be a double vector");
    }
    if( !mxIsDouble(prhs[3]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notDouble",
                "Input 3 (smpl_readszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[4]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notDouble",
                "Input 4 (line_skipszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[5]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notDouble",
                "Input 5 (line_readszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[6]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notDouble",
                "Input 6 (band_skipszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[7]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:notDouble",
                "Input 7 (band_readszlist) needs to be a double vector.");
    }
    
    /* Check the size of input variables */
    /* 2: smpl_skipszlist and 3: smpl_readszlist */
    ndim_skip = mxGetNumberOfDimensions(prhs[2]);
    ndim_read = mxGetNumberOfDimensions(prhs[3]);
    if(ndim_skip != ndim_read){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectxv2_multBandRaster_mex:"
            "DimensionMismatch",
            "Inputs 2 (smpl_skipszlist) and 3 (smpl_readszlist) need to have the same number of dimensions.");
    }
    dims_skip = mxGetDimensions(prhs[2]);
    dims_read = mxGetDimensions(prhs[3]);
    for(i=0;i<ndim_skip;i++){
        if(dims_skip[i] != dims_read[i]){
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "SizeMismatch",
                "Inputs 2 (smpl_skipszlist) and 3 (smpl_readszlist) needs to have the same shape.");
        }
    }
    /* 4: line_skipszlist and 5: line_readszlist */
    ndim_skip = mxGetNumberOfDimensions(prhs[4]);
    ndim_read = mxGetNumberOfDimensions(prhs[5]);
    if(ndim_skip != ndim_read){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectxv2_multBandRaster_mex:"
            "DimensionMismatch",
            "Inputs 4 (line_skipszlist) and 5 (line_readszlist) need to have the same number of dimensions.");
    }
    dims_skip = mxGetDimensions(prhs[4]);
    dims_read = mxGetDimensions(prhs[5]);
    for(i=0;i<ndim_skip;i++){
        if(dims_skip[i] != dims_read[i]){
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "SizeMismatch",
                "Inputs 4 (line_skipszlist) and 5 (line_readszlist) needs to have the same shape.");
        }
    }
    /* 6: band_skipszlist and 7: band_readszlist */
    ndim_skip = mxGetNumberOfDimensions(prhs[6]);
    ndim_read = mxGetNumberOfDimensions(prhs[7]);
    if(ndim_skip != ndim_read){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectxv2_multBandRaster_mex:"
            "DimensionMismatch",
            "Inputs 6 (band_skipszlist) and 7 (band_readszlist) need to have the same number of dimensions.");
    }
    dims_skip = mxGetDimensions(prhs[6]);
    dims_read = mxGetDimensions(prhs[7]);
    for(i=0;i<ndim_skip;i++){
        if(dims_skip[i] != dims_read[i]){
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "SizeMismatch",
                "Inputs 6 (band_skipszlist) and 7 (band_readszlist) needs to have the same shape.");
        }
    }
    /* -----------------------------------------------------------------
     * I/O SETUPs
     * ----------------------------------------------------------------- */
    
    /* INPUT 0 imgpath */
    imgpath = mxArrayToString(prhs[0]);
    
    /* INPUT 1 msldem_header */
    hdr = mxGetEnviHeader(prhs[1]);

    /* INPUT 2/3 smpl_skipszlist/smpl_readszlist */
    N_smpl_skipread = (size_t) mxGetNumberOfElements(prhs[2]);
    smpl_skipszlist_dbl = mxGetDoubles(prhs[2]);
    smpl_readszlist_dbl = mxGetDoubles(prhs[3]);
    smpl_skipszlist = (long int*) malloc( (size_t) N_smpl_skipread*sizeof(long int) );
    smpl_readszlist = (size_t*) malloc( (size_t) N_smpl_skipread*sizeof(size_t) );
    for(i=0;i<N_smpl_skipread;i++){
        if(smpl_skipszlist_dbl[i] > -0.5){
            smpl_skipszlist[i] = (long int) smpl_skipszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "Invalid Value",
                "Inputs 2 (smpl_skipszlist) have invalid values (needs to be nonnegative).");
        }
        if(smpl_readszlist_dbl[i] > -0.5){
            smpl_readszlist[i] = (size_t) smpl_readszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "Invalid Value",
                "Inputs 3 (smpl_readszlist) have invalid values (needs to be nonnegative).");
        }
    }
    samplesc = 0; smpl_skips=0;
    for(i=0;i<N_smpl_skipread;i++){
        samplesc += smpl_readszlist[i];
        smpl_skips += smpl_skipszlist[i];
    }
    smpl_skip_last = (long int) hdr.samples - smpl_skips - (long int) samplesc;
    if(smpl_skip_last < 0){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectxv2_multBandRaster_mex:"
            "SizeInconsistent",
            "Inputs 2 & 3 (smpl_skipszlist & smpl_readszlist) is inconsistent with the image size.");
    }

    /* INPUT 4/5 line_skipszlist/line_readszlist */
    N_line_skipread = (size_t) mxGetNumberOfElements(prhs[4]);
    line_skipszlist_dbl = mxGetDoubles(prhs[4]);
    line_readszlist_dbl = mxGetDoubles(prhs[5]);
    line_skipszlist = (long int*) malloc( (size_t) N_line_skipread*sizeof(long int) );
    line_readszlist = (size_t*) malloc( (size_t) N_line_skipread*sizeof(size_t) );
    for(i=0;i<N_line_skipread;i++){
        if(line_skipszlist_dbl[i] > -0.5){
            line_skipszlist[i] = (long int) line_skipszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "Invalid Value",
                "Inputs 4 (line_skipszlist) have invalid values (needs to be nonnegative).");
        }
        if(line_readszlist_dbl[i] > -0.5){
            line_readszlist[i] = (size_t) line_readszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "Invalid Value",
                "Inputs 5 (line_readszlist) have invalid values (needs to be nonnegative).");
        }
    }
    linesc = 0; line_skips=0;
    for(i=0;i<N_line_skipread;i++){
        linesc += line_readszlist[i];
        line_skips += line_skipszlist[i];
    }
    line_skip_last = (long int) hdr.lines - line_skips - (long int) linesc;
    if(band_skip_last < 0){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectxv2_multBandRaster_mex:"
            "SizeInconsistent",
            "Inputs 4 & 5 (line_skipszlist & line_readszlist) is inconsistent with the image size.");
    }

    /* INPUT 6/7 band_skipszlist/band_readszlist */
    N_band_skipread = (size_t) mxGetNumberOfElements(prhs[6]);
    band_skipszlist_dbl = mxGetDoubles(prhs[6]);
    band_readszlist_dbl = mxGetDoubles(prhs[7]);
    band_skipszlist = (long int*) malloc( (size_t) N_band_skipread*sizeof(long int) );
    band_readszlist = (size_t*) malloc( (size_t) N_band_skipread*sizeof(size_t) );
    for(i=0;i<N_band_skipread;i++){
        if(band_skipszlist_dbl[i] > -0.5){
            band_skipszlist[i] = (long int) band_skipszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "Invalid Value",
                "Inputs 6 (band_skipszlist) have invalid values (needs to be nonnegative).");
        }
        if(band_readszlist_dbl[i] > -0.5){
            band_readszlist[i] = (size_t) band_readszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "Invalid Value",
                "Inputs 7 (band_readszlist) have invalid values (needs to be nonnegative).");
        }
    }
    
    bandsc = 0; band_skips=0;
    for(i=0;i<N_band_skipread;i++){
        bandsc += band_readszlist[i];
        band_skips += band_skipszlist[i];
    }

    band_skip_last = (long int) hdr.bands - band_skips - (long int) bandsc;
    if(band_skip_last < 0){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectxv2_multBandRaster_mex:"
            "SizeInconsistent",
            "Inputs 6 & 7 (band_skipszlist & band_readszlist) is inconsistent with the image size.");
    }
    
    
    
    // N = samples*lines*bands;
    switch(hdr.interleave){
        case BSQ :
            dims[0] = (mwSize) samplesc;
            dims[1] = (mwSize) linesc;
            dims[2] = (mwSize) bandsc;
            break;
        case BIL :
            dims[0] = (mwSize) samplesc;
            dims[1] = (mwSize) bandsc;
            dims[2] = (mwSize) linesc;
            break;
        case BIP :
            dims[0] = (mwSize) bandsc;
            dims[1] = (mwSize) samplesc;
            dims[2] = (mwSize) linesc;
            break;
            
    }
    
    
    
    /* -----------------------------------------------------------------
     * CALL MAIN COMPUTATION ROUTINE
     * ----------------------------------------------------------------- */
    switch(hdr.data_type){
        case 1:
            plhs[0] = mxCreateNumericArray(3,dims,mxUINT8_CLASS,mxREAL);
            sz = sizeof(uint8_t);
            break;
        case 2:
            plhs[0] = mxCreateNumericArray(3,dims,mxINT16_CLASS,mxREAL);
            sz = sizeof(int16_t);
            break;
        case 4:
            plhs[0] = mxCreateNumericArray(3,dims,mxSINGLE_CLASS,mxREAL);
            sz = sizeof(float);
            break;
        case 12:
            plhs[0] = mxCreateNumericArray(3,dims,mxUINT16_CLASS,mxREAL);
            sz = sizeof(uint16_t);
            break;
        case 16:
            plhs[0] = mxCreateNumericArray(3,dims,mxINT8_CLASS,mxREAL);
            sz = sizeof(int8_t);
            break;
        default:
            mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "UnsupportedDataType",
                "data_type=%d is not supported.",hdr.data_type);
    }
    if(mxIsEmpty(plhs[0])){
        errflg = 0;
    } else {
        subimg = mxGetData(plhs[0]);

        dims_size_t[0] = (size_t) dims[0];
        dims_size_t[1] = (size_t) dims[1];
        dims_size_t[2] = (size_t) dims[2];

        errflg = lazyenvireadRectx_multBand(imgpath, hdr, 
            smpl_skipszlist, smpl_readszlist, 
            N_smpl_skipread, smpl_skip_last,
            line_skipszlist, line_readszlist,
            N_line_skipread, line_skip_last,
            band_skipszlist, band_readszlist,
            N_band_skipread, band_skip_last,
            subimg, dims_size_t, sz);
    
    }
    
    if(errflg==0){
        /* Byte Swap if necessary */
        switch(hdr.data_type){
            case 2:
                image_byteswapInt16(subimg, dims_size_t, hdr.byte_order);
                break;
            case 4:
                image_byteswapFloat(subimg, dims_size_t, hdr.byte_order);
                break;
            case 12:
                image_byteswapUint16(subimg, dims_size_t, hdr.byte_order);
                break;
        }
    } else if(errflg == -1){
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "FileOpenError",
                "File: %s does not exist.",imgpath);
    } else if(errflg == -2){
        mexErrMsgIdAndTxt(
                "lazyenvireadRectxv2_multBandRaster_mex:"
                "FileSizeInvalid",
                "FileSize is incorrect.");
    }
        
    
    /* free memories */
    mxFree(imgpath);
    free(smpl_skipszlist);
    free(smpl_readszlist);
    free(line_skipszlist);
    free(line_readszlist);
    free(band_skipszlist);
    free(band_readszlist);
}
