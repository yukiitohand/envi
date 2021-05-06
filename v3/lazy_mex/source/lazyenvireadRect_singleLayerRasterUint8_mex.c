/* =====================================================================
 * lazyenvireadRect_singleLayerRasterUint8_mex.c
 * Read the specified rectangle region of an uint8 image data.
 * This function is endian free. The image data needs to be a binary image.
 * Rectangle part of the image:
 * [smpl_offset:(smpl_offset+samples), line_offset:(line_offset+lines)]
 * is read (the first index of the whole image is supposed to be 0).
 * 
 * INPUTS:
 * 0 imgpath       char*
 * 1 header        struct for Envi Header
 * 2 smpl_offset   integer
 * 3 line_offset   integer
 * 4 samples       integer
 * 5 lines         integer
 * 
 * 
 * OUTPUTS:
 * 0  subimg [samples x lines]   uint8 (8bit)
 * #Note that the image needs to be transposed after this.
 *
 *
 * This is a MEX file for MATLAB.
 *
 * ---------------
 * Update History
 * ---------------
 * |============|==========================================|==============|
 * | Date       | Comment                                  | Name         |
 * |============|==========================================|==============|
 *  2021 Jan. 17  created                                    Yuki Itoh.
 *  2021 Jan. 23  removed fseek from loop                    Yuki Itoh.
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
 * int lazyenvireadRect_singleLayerUint8
 * Input Parameters
 *   char *imgpath      : path to the image
 *   EnviHeader hdr     : defined in envi.h
 *   size_t smpl_offset : pixel offset in the sample direction
 *   size_t line_offset : pixel offset in the line direction
 *   uint8_t **subimg   : pointer to the subimage [samples x lines] Values 
 *                        are accesible with subimg[s][l]
 *   size_t samples     : number of sample pixels of the subimage
 *   size_t lines       : number of line pixels of the subimage  
 * Returns
 *   int error_flag
 *    0: no error happens
 *   -1: File Open Error: no file found
 *   -2: File Size Error: header information doesn't match the actual file 
 *       size.
 */
int lazyenvireadRect_singleLayerUint8(char *imgpath, EnviHeader hdr, 
        size_t smpl_offset, size_t line_offset,
        uint8_t **subimg, size_t samples, size_t lines)
{
    size_t i,j;
    long int skip_pri;
    long int skip_l, skip_r;
    uint8_t *buf;
    size_t s=sizeof(uint8_t);
    FILE *fid;
    size_t ncpy;
    long int szfile,header_offset;
    
    fid = fopen(imgpath,"rb");
    if(fid==NULL){
        fclose(fid);
        return -1;
    }
    /* Evaluate if the image header have valid information of the image */
    header_offset = (long int) hdr.header_offset;
    fseek(fid, 0L, SEEK_END);
    szfile = ftell(fid);
    /* If the image file size is less than the size indicated by the header
     * then return an error. */
    if(szfile < (long int) hdr.samples * (long int) hdr.lines * (long int) s + header_offset){
        fclose(fid);
        return -2;
    }
    fseek(fid, header_offset, SEEK_SET);
    
    /* skip lines */
    skip_pri = (long int) hdr.samples * (long int) line_offset * (long int) s;
    fseek(fid,skip_pri,SEEK_CUR);
    
    /* read the data */
    ncpy = samples * s;
    buf = (uint8_t*) malloc(ncpy);
    skip_l = (long int) s * (long int) smpl_offset;
    skip_r = ((long int) hdr.samples - (long int) samples) * (long int) s - skip_l;
    
    for(i=0;i<lines;i++){
        fseek(fid,skip_l,SEEK_CUR);
        fread(buf,s,samples,fid);
        memcpy(subimg[i],buf,ncpy);
        fseek(fid,skip_r,SEEK_CUR);
        //_fseeki64(fp,skips,SEEK_CUR);
    }
    
    free(buf);
    fclose(fid);
    
    return 0;
}

int lazyenvireadRect_singleLayerUint8_v2(char *imgpath, EnviHeader hdr, 
        size_t smpl_offset, size_t line_offset,
        uint8_t **subimg, size_t samplesc, size_t linesc)
{
    size_t i,j;
    long int skip_pri;
    uint8_t *buf;
    uint8_t *buf_offset;
    size_t s=sizeof(uint8_t);
    FILE *fid;
    size_t ncpy;
    long int szfile,header_offset;
    size_t samples, lines;
    size_t N;
    
    samples = (size_t) hdr.samples;
    lines   = (size_t) hdr.lines;
    
    fid = fopen(imgpath,"rb");
    if(fid==NULL){
        fclose(fid);
        return -1;
    }
    /* Evaluate if the image header have valid information of the image */
    header_offset = (long int) hdr.header_offset;
    fseek(fid, 0L, SEEK_END);
    szfile = ftell(fid);
    /* If the image file size is less than the size indicated by the header
     * then return an error. */
    if(szfile < (long int) samples * (long int) lines * (long int) s + header_offset){
        fclose(fid);
        return -2;
    }
    fseek(fid, header_offset, SEEK_SET);
    
    /* Evaluate the endians of the computer and image data. */
    
    /* skip lines */
    skip_pri = (long int) (samples * line_offset * s);
    fseek(fid,skip_pri,SEEK_CUR);
    
    /* read the data */
    ncpy = samplesc * s;
    buf = (uint8_t*) malloc(samples*s);
    buf_offset = buf+smpl_offset;
    for(i=0;i<linesc;i++){
        fread(buf,s,samples,fid);
        memcpy(subimg[i],buf_offset,ncpy);
        //for(j=0;j<samplesc;j++){
        //    subimg[i][j] = buf[smpl_offset+j];
        //}
        
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
    double smpl_offset_dbl,line_offset_dbl;
    mwSize smpl_offset,line_offset;
    uint8_t **subimg;
    double samples_dbl, lines_dbl;
    mwSize samples, lines;
    int errflg;

    /* -----------------------------------------------------------------
     * CHECK PROPER NUMBER OF INPUTS AND OUTPUTS
     * ----------------------------------------------------------------- */
    if(nrhs!=6) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:nrhs",
                "Six inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:nlhs",
                "One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsChar(prhs[0]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:notChar",
                "Input 0 (imgpath) needs to be a string.");
    }
    if( !mxIsStruct(prhs[1]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:notStruct",
                "Input 1 (ENVI header) needs to be a struct.");
    }
    if( !mxIsScalar(prhs[2]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:notScalar",
                "Input 2 (sample_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[3]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:notScalar",
                "Input 3 (line_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[4]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:notScalar",
                "Input 4 (number of samples of the subimage)"
                " needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[5]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:notScalar",
                "Input 5 (number of lines of the subimage)"
                " needs to be a scalar.");
    }
    
    /* -----------------------------------------------------------------
     * I/O SETUPs
     * ----------------------------------------------------------------- */
    
    /* INPUT 0 imgpath */
    imgpath = mxArrayToString(prhs[0]);
    
    /* INPUT 1 msldem_header */
    hdr = mxGetEnviHeader(prhs[1]);
    
    /* INPUT 2/3 sample_offset/line_offset */
    smpl_offset_dbl = mxGetScalar(prhs[2]);
    if(smpl_offset_dbl>-1)
        smpl_offset = (mwSize) smpl_offset_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "notnonnegative",
                "Input 2 (sample_offset) needs to be nonnegative.");
    
    line_offset_dbl = mxGetScalar(prhs[3]);
    if(line_offset_dbl>-1)
        line_offset = (mwSize) line_offset_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "notnonnegative",
                "Input 3 (line_offset) needs to be nonnegative.");
    
    /* INPUT 4/5 image rectangle size */
    samples_dbl = mxGetScalar(prhs[4]);
    if(samples_dbl>-1)
        samples = (mwSize) samples_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "notnonnegative",
                "Input 4 (the number of samples of the subimage"
                " needs to be nonnegative.");
    
    lines_dbl = mxGetScalar(prhs[5]);
    if(lines_dbl>-1)
        lines = (mwSize) lines_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "notnonnegative",
                "Input 5 (the number of lines of the subimage"
                " needs to be nonnegative.");
    
    /* Evaluate the input values are valid */
    if(samples+smpl_offset > (mwSize) hdr.samples){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "InvalidInput",
                "Sample range exceeds the image range.");
    }
    if(lines+line_offset > (mwSize) hdr.lines){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "InvalidInput",
                "Line range exceeds the image range.");
    }
    
    plhs[0] = mxCreateNumericMatrix(samples,lines,mxUINT8_CLASS,mxREAL);
    subimg = set_mxUint8Matrix(plhs[0]);
    
    /* -----------------------------------------------------------------
     * CALL MAIN COMPUTATION ROUTINE
     * ----------------------------------------------------------------- */
    if(mxIsEmpty(plhs[0])){
        errflg = 0;
    } else {
        errflg = lazyenvireadRect_singleLayerUint8_v2(imgpath,hdr,
                (size_t) smpl_offset, (size_t) line_offset,
                subimg, (size_t) samples, (size_t) lines);
    }
    
    if(errflg==-1){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "FileOpenError",
                "File: %s does not exist.",imgpath);
    } else if(errflg==-2){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint8_mex:"
                "FileSizeInvalid",
                "FileSize is incorrect.");
    }
        
    
    /* free memories */
    mxFree(imgpath);
    mxFree(subimg);
    
    
}
