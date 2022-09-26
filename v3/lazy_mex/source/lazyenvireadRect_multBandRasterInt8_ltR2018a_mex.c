/* =====================================================================
 * lazyenvireadRect_multBandRasterInt8_ltR2018a_mex.c
 * Read the specified rectangle region of an int8 image cube.
 * Support versions less than R2018a.
 * This function is endian free. The image data needs to be a binary image.
 * Rectangle part of the image:
 * [smpl_offset:(smpl_offset+samples), line_offset:(line_offset+lines),
 * band_offset:(band_offset+bands)]
 * is read (the first index of the whole image is supposed to be 0).
 * 
 * INPUTS:
 * 0 imgpath       char*
 * 1 header        struct for Envi Header
 * 2 smpl_offset   integer
 * 3 line_offset   integer
 * 4 band_offset   integer
 * 5 samples       integer
 * 6 lines         integer
 * 7 bands         integer
 * 
 * 
 * OUTPUTS:
 * 0  subimg 3 dimensional int8 (8bit) array, whose shape depends on 
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
 *  2022 Sep. 23  created                                    Yuki Itoh.
 *
 * -----------------
 * Copyright Notice
 * -----------------
 * Copyright (C) 2022 by Yuki Itoh <yukiitohand@gmail.com>
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
#include "mex_create_array_ltR2018a.h"

/* main computation routine
 * int lazyenvireadRect_multBandInt8
 * Input Parameters
 *   char *imgpath      : path to the image
 *   EnviHeader hdr     : defined in envi.h
 *   size_t smpl_offset : pixel offset in the sample direction
 *   size_t line_offset : pixel offset in the line direction
 *   size_t band_offset : pixel offset in the band direction
 *   int8_t **subimg    : pointer to the subimage [samples x lines] Values 
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
int lazyenvireadRect_multBandInt8(char *imgpath, EnviHeader hdr, 
        size_t smpl_offset, size_t line_offset, size_t band_offset,
        int8_t *subimg, size_t samples, size_t lines, size_t bands)
{
    size_t i,j,k;
    long int skip_pri;
    int8_t *buf;
    size_t s=sizeof(int8_t);
    FILE *fid;
    size_t ncpy;
    long int szfile,header_offset;
    size_t d1,d2,d3,d1c,d2c,d3c,d1_offset,d2_offset,d3_offset;
    size_t N;
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
    
    /* Evaluate interleave option */
    switch(hdr.interleave){
        case BSQ :
            d1        = (size_t) hdr.samples;
            d1c       = (size_t) samples;
            d1_offset = (size_t) smpl_offset;
            d2        = (size_t) hdr.lines;
            d2c       = (size_t) lines;
            d2_offset = (size_t) line_offset;
            d3        = (size_t) hdr.bands;
            d3c       = (size_t) bands;
            d3_offset = (size_t) band_offset;
            break;
        case BIL :
            d1        = (size_t) hdr.samples;
            d1c       = (size_t) samples;
            d1_offset = (size_t) smpl_offset;
            d2        = (size_t) hdr.bands;
            d2c       = (size_t) bands;
            d2_offset = (size_t) band_offset;
            d3        = (size_t) hdr.lines;
            d3c       = (size_t) lines;
            d3_offset = (size_t) line_offset;
            break;
        case BIP :
            d1        = (size_t) hdr.bands;
            d1c       = (size_t) bands;
            d1_offset = (size_t) band_offset;
            d2        = (size_t) hdr.samples;
            d2c       = (size_t) samples;
            d2_offset = (size_t) smpl_offset;
            d3        = (size_t) hdr.lines;
            d3c       = (size_t) lines;
            d3_offset = (size_t) line_offset;
            
            break;
            
    }
    
    /* skip bands */
    skip_pri = (long int) (d1 * d2 * d3_offset * s);
    fseek(fid,skip_pri,SEEK_CUR);


    /* read the data from the file */
    N = d1*d2;
    ncpy = N * s;
    buf = (int8_t*) malloc(ncpy);
    // ss = d1c*s;
    for(i=0;i<d3c;i++){
        fread(buf,s,N,fid);
        for(j=0;j<d2c;j++){
            // memcpy(subimg+i*d1c*d2c+j*d1c,buf+d1*(d2_offset+j)+d1_offset,ss);
            for(k=0;k<d1c;k++){
                subimg[i*d1c*d2c+j*d1c+k] = buf[d1*(d2_offset+j)+d1_offset+k];
            }
        }
    }
    
    free(buf);
    fclose(fid);
    
    return 0;
}



/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    char *imgpath;
    EnviHeader hdr;
    double smpl_offset_dbl,line_offset_dbl,band_offset_dbl;
    mwSize smpl_offset,line_offset,band_offset;
    int8_t *subimg;
    double samples_dbl, lines_dbl,bands_dbl;
    mwSize samples, lines, bands;
    mwSize dims[3];
    int errflg;

    /* -----------------------------------------------------------------
     * CHECK PROPER NUMBER OF INPUTS AND OUTPUTS
     * ----------------------------------------------------------------- */
    if(nrhs!=8) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:nrhs",
                "Eight inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:nlhs",
                "One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsChar(prhs[0]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notChar",
                "Input 0 (imgpath) needs to be a string.");
    }
    if( !mxIsStruct(prhs[1]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notStruct",
                "Input 1 (ENVI header) needs to be a struct.");
    }
    if( !mxIsScalar(prhs[2]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notScalar",
                "Input 2 (sample_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[3]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notScalar",
                "Input 3 (line_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[4]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notScalar",
                "Input 4 (band_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[5]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notScalar",
                "Input 5 (number of samples of the subimage)"
                " needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[6]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notScalar",
                "Input 6 (number of lines of the subimage)"
                " needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[7]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:notScalar",
                "Input 7 (number of bands of the subimage)"
                " needs to be a scalar.");
    }
    
    /* -----------------------------------------------------------------
     * I/O SETUPs
     * ----------------------------------------------------------------- */
    
    /* INPUT 0 imgpath */
    imgpath = mxArrayToString(prhs[0]);
    
    /* INPUT 1 msldem_header */
    hdr = mxGetEnviHeader(prhs[1]);
    /* INPUT 2/3/4 sample_offset/line_offset/band_offset */
    smpl_offset_dbl = mxGetScalar(prhs[2]);
    if(smpl_offset_dbl>-1)
        smpl_offset = (mwSize) smpl_offset_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "notnonnegative",
                "Input 2 (sample_offset) needs to be nonnegative.");
    
    line_offset_dbl = mxGetScalar(prhs[3]);
    if(line_offset_dbl>-1)
        line_offset = (mwSize) line_offset_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "notnonnegative",
                "Input 3 (line_offset) needs to be nonnegative.");
    band_offset_dbl = mxGetScalar(prhs[4]);
    if(band_offset_dbl>-1)
        band_offset = (mwSize) band_offset_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "notnonnegative",
                "Input 4 (band_offset) needs to be nonnegative.");
    
    /* INPUT 4/5 image rectangle size */
    samples_dbl = mxGetScalar(prhs[5]);
    if(samples_dbl>-1)
        samples = (mwSize) samples_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "notnonnegative",
                "Input 5 (the number of samples of the subimage"
                " needs to be nonnegative.");
    
    lines_dbl = mxGetScalar(prhs[6]);
    if(lines_dbl>-1)
        lines = (mwSize) lines_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "notnonnegative",
                "Input 6 (the number of lines of the subimage"
                " needs to be nonnegative.");
    bands_dbl = mxGetScalar(prhs[7]);
    if(bands_dbl>-1)
        bands = (mwSize) bands_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "notnonnegative",
                "Input 7 (the number of bands of the subimage"
                " needs to be nonnegative.");
    
    /* Evaluate the input values are valid */
    if(samples+smpl_offset > (mwSize) hdr.samples){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "InvalidInput",
                "Sample range exceeds the image range.");
    }
    if(lines+line_offset > (mwSize) hdr.lines){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "InvalidInput",
                "Line range exceeds the image range.");
    }
    if(bands+band_offset > (mwSize) hdr.bands){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "InvalidInput",
                "Band range exceeds the image range.");
    }
    
    // N = samples*lines*bands;
    switch(hdr.interleave){
        case BSQ :
            dims[0] = samples;
            dims[1] = lines;
            dims[2] = bands;
            break;
        case BIL :
            dims[0] = samples;
            dims[1] = bands;
            dims[2] = lines;
            break;
        case BIP :
            dims[0] = bands;
            dims[1] = samples;
            dims[2] = lines;
            break;
            
    }
    plhs[0] = mxCreateNumericArray(3,dims,mxINT8_CLASS,mxREAL);
    subimg = (int8_T *) mxGetData(plhs[0]);
    
    /* -----------------------------------------------------------------
     * CALL MAIN COMPUTATION ROUTINE
     * ----------------------------------------------------------------- */
    if(mxIsEmpty(plhs[0])){
        errflg = 0;
    } else {
        errflg = lazyenvireadRect_multBandInt8(imgpath,hdr,
                (size_t) smpl_offset, (size_t) line_offset, 
                (size_t) band_offset,
                subimg, (size_t) samples, (size_t) lines, (size_t) bands);
    }
    
    if(errflg==-1){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "FileOpenError",
                "File: %s does not exist.",imgpath);
    } else if(errflg==-2){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_multBandRasterUint8_mex:"
                "FileSizeInvalid",
                "FileSize is incorrect.");
    }
        
    
    /* free memories */
    mxFree(imgpath);
}
