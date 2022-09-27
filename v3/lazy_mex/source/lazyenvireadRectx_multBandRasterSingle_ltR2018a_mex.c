/* =====================================================================
 * lazyenvireadRectx_multBandRasterSingle_ltR2018a_mex.c
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
#include "envi.h"
#include "mex_create_array.h"

/* main computation routine
 * int lazyenvireadRect_multBandSingle
 * Input Parameters
 *   char *imgpath      : path to the image
 *   EnviHeader hdr     : defined in envi.h
 *   size_t smpl_offset : pixel offset in the sample direction
 *   size_t line_offset : pixel offset in the line direction
 *   size_t band_offset : pixel offset in the band direction
 *   float **subimg     : pointer to the subimage [samples x lines] Values 
 *                        are accesible with subimg[s][l]
 *   size_t samples     : number of sample pixels of the subimage
 *   size_t lines       : number of line pixels of the subimage  
 *   size_t bands       : number of band pixels of the subimage
 * Returns
 *   int error_flag
 *    0: no error happens
 *   -1: File Open Error: no file found
 *   -2: File Size Error: header information doesn't match the actual file 
 *       size.
 */
int lazyenvireadRectx_multBandSingle(char *imgpath, EnviHeader hdr, 
        long int* smpl_skipszlist, size_t* smpl_readszlist, 
        size_t N_smpl_skipread, long int smpl_skip_last,
        long int* line_skipszlist, size_t* line_readszlist,
        size_t N_line_skipread, long int line_skip_last,
        long int* band_skipszlist, size_t* band_readszlist,
        size_t N_band_skipread, long int band_skip_last,
        float *subimg, mwSize *dims_subimg)
{
    size_t i,j,k, ii, jj,kk;
    long int skip_pri;
    float *buf;
    size_t s=sizeof(float);
    long int s_li;
    FILE *fid;
    size_t ncpy;
    float swapped;
    bool computer_isLSBF;
    bool data_isLSBF;
    bool swap_necessary;
    long int szfile,header_offset;
    
    long int d1, d2, d3;
    size_t *d1_readszlist, *d2_readszlist, *d3_readszlist;
    long int *d1_skipszlist, *d2_skipszlist, *d3_skipszlist;
    size_t N_d1_skipread, N_d2_skipread, N_d3_skipread;
    long int d1_skip_last, d2_skip_last, d3_skip_last;

    size_t N;

    size_t subimg_offset,curskip;

    s_li = (long int) s;

    // size_t offset1,offset2,offset2_buf;
    // size_t ss;
    fid = fopen(imgpath,"rb");
    if(fid==NULL){
        return -1;
    }
    /* Evaluate if the image header have valid information of the image */
    header_offset = (long int) hdr.header_offset;
    fseek(fid, 0L, SEEK_END);
    szfile = ftell(fid);
    /* If the image file size is less than the size indicated by the header
     * then return an error. */
    if(szfile < (long int) hdr.samples * (long int) hdr.lines * (long int) hdr.bands * (long int) s + header_offset){
        fclose(fid);
        return -2;
    }
    fseek(fid, header_offset, SEEK_SET);
    
    /* Evaluate the endians of the computer and image data. */
    computer_isLSBF = isComputerLSBF();
    data_isLSBF = !((bool) hdr.byte_order);
    swap_necessary = (computer_isLSBF != data_isLSBF);
    /* Evaluate interleave option */
    switch(hdr.interleave){
        case BSQ :
            d1 = (long int) hdr.samples;
            d1_skipszlist = smpl_skipszlist;
            d1_readszlist = smpl_readszlist;
            N_d1_skipread = N_smpl_skipread;
            d1_skip_last   = smpl_skip_last;

            d2 = (long int) hdr.lines;
            d2_skipszlist = line_skipszlist;
            d2_readszlist = line_readszlist;
            N_d2_skipread = N_line_skipread;
            d2_skip_last   = line_skip_last;
            
            d3 = (long int) hdr.bands;
            d3_skipszlist = band_skipszlist;
            d3_readszlist = band_readszlist;
            N_d3_skipread = N_band_skipread;
            d3_skip_last   = band_skip_last;

            break;

        case BIL :
            d1 = (long int) hdr.samples;
            d1_skipszlist = smpl_skipszlist;
            d1_readszlist = smpl_readszlist;
            N_d1_skipread = N_smpl_skipread;
            d1_skip_last   = smpl_skip_last;
            
            d2 = (long int) hdr.bands;
            d2_skipszlist = band_skipszlist;
            d2_readszlist = band_readszlist;
            N_d2_skipread = N_band_skipread;
            d2_skip_last   = band_skip_last;
            
            d3 = (long int) hdr.lines;
            d3_skipszlist = line_skipszlist;
            d3_readszlist = line_readszlist;
            N_d3_skipread = N_line_skipread;
            d3_skip_last   = line_skip_last;

            break;

        case BIP :
            d1 = (long int) hdr.bands;
            d1_skipszlist = band_skipszlist;
            d1_readszlist = band_readszlist;
            N_d1_skipread = N_band_skipread;
            d1_skip_last   = band_skip_last;
            
            d2 = (long int) hdr.samples;
            d2_skipszlist = smpl_skipszlist;
            d2_readszlist = smpl_readszlist;
            N_d2_skipread = N_smpl_skipread;
            d2_skip_last   = smpl_skip_last;
            
            d3 = (long int) hdr.lines;
            d3_skipszlist = line_skipszlist;
            d3_readszlist = line_readszlist;
            N_d3_skipread = N_line_skipread;
            d3_skip_last   = line_skip_last;
            
            break;
            
    }
    /* skip bands */
    skip_pri = (long int) (d1 * d2 * d3_skipszlist[0] * s);
    fseek(fid,skip_pri,SEEK_CUR);


    /* read the data from the file */
    N = d1*d2;
    ncpy = N * s;
    buf = (float*) malloc(ncpy);
    // ss = d1c*s;
    subimg_offset = 0;
    for(i=0;i<N_d3_skipread;i++){
        // printf("i=%d\n",i);
        fseek(fid,d1*d2*d3_skipszlist[i]*s_li,SEEK_CUR);
        for(ii=0;ii<d3_readszlist[i];ii++){
            fread(buf,s,N,fid);
            curskip = 0;
            for(j=0;j<N_d2_skipread;j++){
                // printf("j=%d\n",j);
                curskip += d1*d2_skipszlist[j];
                for(jj=0;jj<d2_readszlist[j];jj++){
                    for(k=0;k<N_d1_skipread;k++){
                        // printf("k=%d\n",k);
                        curskip += d1_skipszlist[k];
                        for(kk=0;kk<d1_readszlist[k];kk++){
                            *(subimg+subimg_offset) = *(buf+curskip);
                            subimg_offset++;
                            curskip++;
                        }
                    }
                    curskip += d1_skip_last;
                }
            }
        }
    }


//     subimg_offset = 0;
//     for(i=0;i<N_d3_skipread;i++){
//         fseek(fid,d1*d2*d3_skipszlist[i]*s_li,SEEK_CUR);
//         for(ii=0;ii<d3_readszlist[i];ii++){
//             for(j=0;j<N_d2_skipread;j++){
//                 fseek(fid,d1*d2_skipszlist[j]*s_li,SEEK_CUR);
//                 for(jj=0;j<d2_readszlist[j];jj++){
//                     for(k=0;k<N_d1_skipread;k++){
//                         fseek(fid,d1_skipszlist[k]*s_li,SEEK_CUR);
//                         fread(subimg+subimg_offset,s,d1_readszlist[k],fid);
//                         subimg_offset += d1_readszlist[k];
//                     }
//                     fseek(fid,d1_skip_last*s_li,SEEK_CUR);
//                 }
//             }
//             fseek(fid,d1*d2_skip_last*s_li,SEEK_CUR);
//         }
//     }
//     for(i=0;i<d3c;i++){
//         fread(buf,s,N,fid);
//         // offset1 = i*d1c*d2c;
//         for(j=0;j<d2c;j++){
//             // offset2 = j*d1c+offset1;
//             // offset2_buf = d1*(d2_offset+j)+d1_offset;
//             // memcpy(subimg+i*d1c*d2c+j*d1c,buf+d1*(d2_offset+j)+d1_offset,ss);
//             for(k=0;k<d1c;k++){
//                 subimg[i*d1c*d2c+j*d1c+k] = buf[d1*(d2_offset+j)+d1_offset+k];
//                 // subimg[offset2+k] = buf[offset2_buf+k];
//                 // subimg[d1c*d3c*j+d3c*k+i] = buf[d1*(d2_offset+j)+d1_offset+k];
//             }
//         }
//     }
    
    free(buf);
    fclose(fid);
    
    /* Swap bytes if necessary */
    if(swap_necessary){
        N = dims_subimg[0]*dims_subimg[1]*dims_subimg[2];
        for(i=0;i<N;i++){
            swapped = swapFloat(subimg[i]);
            subimg[i] = swapped;
        }
    }
    
    return 0;
}



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

    float *subimg;
    double samples_dbl, lines_dbl,bands_dbl;
    mwSize samples, lines, bands;
    mwSize dims[3];
    int errflg;

    /* -----------------------------------------------------------------
     * CHECK PROPER NUMBER OF INPUTS AND OUTPUTS
     * ----------------------------------------------------------------- */
    if(nrhs!=8) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:nrhs",
                "Eight inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:nlhs",
                "One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsChar(prhs[0]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notChar",
                "Input 0 (imgpath) needs to be a string.");
    }
    if( !mxIsStruct(prhs[1]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notStruct",
                "Input 1 (ENVI header) needs to be a struct.");
    }
    if( !mxIsDouble(prhs[2]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notDouble",
                "Input 2 (smpl_skipszlist) needs to be a double vector");
    }
    if( !mxIsDouble(prhs[3]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notDouble",
                "Input 3 (smpl_readszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[4]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notDouble",
                "Input 4 (line_skipszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[5]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notDouble",
                "Input 5 (line_readszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[6]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notDouble",
                "Input 6 (band_skipszlist) needs to be a double vector.");
    }
    if( !mxIsDouble(prhs[7]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:notDouble",
                "Input 7 (band_readszlist) needs to be a double vector.");
    }
    
    /* Check the size of input variables */
    /* 2: smpl_skipszlist and 3: smpl_readszlist */
    ndim_skip = mxGetNumberOfDimensions(prhs[2]);
    ndim_read = mxGetNumberOfDimensions(prhs[3]);
    if(ndim_skip != ndim_read){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectx_multBandRasterSingle_mex:"
            "DimensionMismatch",
            "Inputs 2 (smpl_skipszlist) and 3 (smpl_readszlist) need to have the same number of dimensions.");
    }
    dims_skip = mxGetDimensions(prhs[2]);
    dims_read = mxGetDimensions(prhs[3]);
    for(i=0;i<ndim_skip;i++){
        if(dims_skip[i] != dims_read[i]){
            mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
                "SizeMismatch",
                "Inputs 2 (smpl_skipszlist) and 3 (smpl_readszlist) needs to have the same shape.");
        }
    }
    /* 4: line_skipszlist and 5: line_readszlist */
    ndim_skip = mxGetNumberOfDimensions(prhs[4]);
    ndim_read = mxGetNumberOfDimensions(prhs[5]);
    if(ndim_skip != ndim_read){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectx_multBandRasterSingle_mex:"
            "DimensionMismatch",
            "Inputs 4 (line_skipszlist) and 5 (line_readszlist) need to have the same number of dimensions.");
    }
    dims_skip = mxGetDimensions(prhs[4]);
    dims_read = mxGetDimensions(prhs[5]);
    for(i=0;i<ndim_skip;i++){
        if(dims_skip[i] != dims_read[i]){
            mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
                "SizeMismatch",
                "Inputs 4 (line_skipszlist) and 5 (line_readszlist) needs to have the same shape.");
        }
    }
    /* 6: band_skipszlist and 7: band_readszlist */
    ndim_skip = mxGetNumberOfDimensions(prhs[6]);
    ndim_read = mxGetNumberOfDimensions(prhs[7]);
    if(ndim_skip != ndim_read){
        mexErrMsgIdAndTxt(
            "lazyenvireadRectx_multBandRasterSingle_mex:"
            "DimensionMismatch",
            "Inputs 6 (band_skipszlist) and 7 (band_readszlist) need to have the same number of dimensions.");
    }
    dims_skip = mxGetDimensions(prhs[6]);
    dims_read = mxGetDimensions(prhs[7]);
    for(i=0;i<ndim_skip;i++){
        if(dims_skip[i] != dims_read[i]){
            mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
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
                "lazyenvireadRectx_multBandRasterSingle_mex:"
                "Invalid Value",
                "Inputs 2 (smpl_skipszlist) have invalid values (needs to be nonnegative).");
        }
        if(smpl_readszlist_dbl[i] > -0.5){
            smpl_readszlist[i] = (size_t) smpl_readszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
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
            "lazyenvireadRectx_multBandRasterSingle_mex:"
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
                "lazyenvireadRectx_multBandRasterSingle_mex:"
                "Invalid Value",
                "Inputs 4 (line_skipszlist) have invalid values (needs to be nonnegative).");
        }
        if(line_readszlist_dbl[i] > -0.5){
            line_readszlist[i] = (size_t) line_readszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
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
            "lazyenvireadRectx_multBandRasterSingle_mex:"
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
                "lazyenvireadRectx_multBandRasterSingle_mex:"
                "Invalid Value",
                "Inputs 6 (band_skipszlist) have invalid values (needs to be nonnegative).");
        }
        if(band_readszlist_dbl[i] > -0.5){
            band_readszlist[i] = (size_t) band_readszlist_dbl[i];
        } else {
            mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
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
            "lazyenvireadRectx_multBandRasterSingle_mex:"
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
    plhs[0] = mxCreateNumericArray(3,dims,mxSINGLE_CLASS,mxREAL);
    subimg = (float) mxGetData(plhs[0]);
    
    /* -----------------------------------------------------------------
     * CALL MAIN COMPUTATION ROUTINE
     * ----------------------------------------------------------------- */
    if(mxIsEmpty(plhs[0])){
        errflg = 0;
    } else {
        errflg = lazyenvireadRectx_multBandSingle(imgpath, hdr, 
            smpl_skipszlist, smpl_readszlist, N_smpl_skipread, smpl_skip_last,
            line_skipszlist, line_readszlist, N_line_skipread, line_skip_last,
            band_skipszlist, band_readszlist, N_band_skipread, band_skip_last,
            subimg, dims);
    }
    
    if(errflg == -1){
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
                "FileOpenError",
                "File: %s does not exist.",imgpath);
    } else if(errflg == -2){
        mexErrMsgIdAndTxt(
                "lazyenvireadRectx_multBandRasterSingle_mex:"
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
