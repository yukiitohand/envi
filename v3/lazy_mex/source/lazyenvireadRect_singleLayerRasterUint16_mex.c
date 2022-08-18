/* =====================================================================
 * lazyenvireadRect_singleLayerRasterUint16_mex.c
 * Read the specified rectangle region of an uint16 image data.
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
 * 0  subimg [samples x lines]   uint16_t (16bit)
 * #Note that the image needs to be transposed after this.
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
 *  2021 Jan. 23  created                                    Yuki Itoh.
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
 * int lazyenvireadRect_singleLayerInt16
 * Input Parameters
 *   char *imgpath      : path to the image
 *   EnviHeader hdr     : defined in envi.h
 *   size_t smpl_offset : pixel offset in the sample direction
 *   size_t line_offset : pixel offset in the line direction
 *   uint16_t **subimg  : pointer to the subimage [samples x lines] Values 
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

int lazyenvireadRect_singleLayerUint16_v2(char *imgpath, EnviHeader hdr, 
        size_t smpl_offset, size_t line_offset,
        uint16_t **subimg, size_t samplesc, size_t linesc)
{
    size_t i,j;
    long int skip_pri;
    uint16_t *buf;
    uint16_t *buf_offset;
    size_t s=sizeof(uint16_t);
    FILE *fid;
    size_t ncpy;
    uint16_t swapped;
    bool computer_isLSBF;
    bool data_isLSBF;
    bool swap_necessary;
    long int szfile,header_offset;
    size_t samples, lines;
    size_t N;
    
    samples = (size_t) hdr.samples;
    lines   = (size_t) hdr.lines;
    
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
    if(szfile < (long int) samples * (long int) lines * (long int) s + header_offset){
        fclose(fid);
        return -2;
    }
    fseek(fid, header_offset, SEEK_SET);
    
    /* Evaluate the endians of the computer and image data. */
    computer_isLSBF = isComputerLSBF();
    data_isLSBF = !((bool) hdr.byte_order);
    swap_necessary = (computer_isLSBF != data_isLSBF);
    
    /* skip lines */
    skip_pri = (long int) (samples * line_offset * s);
    fseek(fid,skip_pri,SEEK_CUR);
    
    /* read the data */
    ncpy = samplesc * s;
    buf = (uint16_t*) malloc(samples*s);
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
    
    if(swap_necessary){
        for(i=0;i<linesc;i++){
            for(j=0;j<samplesc;j++){
                swapped = (subimg[i][j]<<8) | (subimg[i][j]>>8);
                subimg[i][j] = swapped;
            }
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
    double smpl_offset_dbl,line_offset_dbl;
    mwSize smpl_offset,line_offset;
    uint16_t **subimg;
    double samples_dbl, lines_dbl;
    mwSize samples, lines;
    int errflg;

    /* -----------------------------------------------------------------
     * CHECK PROPER NUMBER OF INPUTS AND OUTPUTS
     * ----------------------------------------------------------------- */
    if(nrhs!=6) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:nrhs",
                "Six inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:nlhs",
                "One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsChar(prhs[0]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:notChar",
                "Input 0 (imgpath) needs to be a string.");
    }
    if( !mxIsStruct(prhs[1]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:notStruct",
                "Input 1 (ENVI header) needs to be a struct.");
    }
    if( !mxIsScalar(prhs[2]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:notScalar",
                "Input 2 (sample_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[3]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:notScalar",
                "Input 3 (line_offset) needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[4]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:notScalar",
                "Input 4 (number of samples of the subimage)"
                " needs to be a scalar.");
    }
    if( !mxIsScalar(prhs[5]) ) {
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:notScalar",
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
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "notnonnegative",
                "Input 2 (sample_offset) needs to be nonnegative.");
    
    line_offset_dbl = mxGetScalar(prhs[3]);
    if(line_offset_dbl>-1)
        line_offset = (mwSize) line_offset_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "notnonnegative",
                "Input 3 (line_offset) needs to be nonnegative.");
    
    /* INPUT 4/5 image rectangle size */
    samples_dbl = mxGetScalar(prhs[4]);
    if(samples_dbl>-1)
        samples = (mwSize) samples_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "notnonnegative",
                "Input 4 (the number of samples of the subimage"
                " needs to be nonnegative.");
    
    lines_dbl = mxGetScalar(prhs[5]);
    if(lines_dbl>-1)
        lines = (mwSize) lines_dbl;
    else
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "notnonnegative",
                "Input 5 (the number of lines of the subimage"
                " needs to be nonnegative.");
    
    /* Evaluate the input values are valid */
    if(samples+smpl_offset > (mwSize) hdr.samples){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "InvalidInput",
                "Sample range exceeds the image range.");
    }
    if(lines+line_offset > (mwSize) hdr.lines){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "InvalidInput",
                "Line range exceeds the image range.");
    }
    
    plhs[0] = mxCreateNumericMatrix(samples,lines,mxUINT16_CLASS,mxREAL);
    subimg = set_mxUint16Matrix(plhs[0]);
    
    /* -----------------------------------------------------------------
     * CALL MAIN COMPUTATION ROUTINE
     * ----------------------------------------------------------------- */
    if(mxIsEmpty(plhs[0])){
        errflg = 0;
    } else {
        errflg = lazyenvireadRect_singleLayerUint16_v2(imgpath,hdr,
                (size_t) smpl_offset, (size_t) line_offset,
                subimg, (size_t) samples, (size_t) lines);
    }
    
    if(errflg==-1){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "FileOpenError",
                "File: %s does not exist.",imgpath);
    } else if(errflg==-2){
        mexErrMsgIdAndTxt(
                "lazyenvireadRect_singleLayerRasterUint16_mex:"
                "FileSizeInvalid",
                "FileSize is incorrect.");
    }
        
    
    /* free memories */
    mxFree(imgpath);
    mxFree(subimg);
    
    
}
