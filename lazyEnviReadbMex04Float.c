/*
 * lazyEnviReadbMex04Float.c
 * Read a specified band of hyperspectral image data with data_type 4(float) 
 * Input: 
 * fpath: (string) path to the image file
 * hdr_info: (structure) stores the header information 
 * of the hyperspectral data.
 * b: band to be read
 *
 * 
 * Output:
 * im: (Sample x Line) Matrix of the band of the image in double format
 * The calling syntax is:
 *
 *		im = lazeEnviReadbMex(fpath, hdr_info, b)
 *
 * This is a MEX file for MATLAB.
*/
#include "mex.h"
#include "matrix.h"
#include <stdio.h>
#include <stdlib.h>

/* The gateway function */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
/* variable declarations here */
    mwSize samples;
    mwSize lines;
    mwSize bands;
    mwSize header_offset;
    mwSize s;
    mwSize offset;
    mwSize skips;
    mwSize l;
    mwSize sa;
    mwSize N;
    const mxArray *fPtr;
    char interleave[5];
    mwIndex data_type;
    char fpath[100];
    FILE *fp;
    mwSize b;
    float* imb;
    float* buf;

/* code here */
    fPtr = mxGetField(prhs[1],0,"samples");
    samples = (mwSize)*mxGetPr(fPtr); 
    fPtr = mxGetField(prhs[1],0,"lines");
    lines = (mwSize)*mxGetPr(fPtr);
    fPtr = mxGetField(prhs[1],0,"bands");
    bands = (mwSize)*mxGetPr(fPtr);
    fPtr = mxGetField(prhs[1],0,"header_offset");
    header_offset = (mwSize)*mxGetPr(fPtr);
    fPtr = mxGetField(prhs[1],0,"interleave");
    N = (mwSize)mxGetN(fPtr);
    mxGetString(fPtr,interleave,N+1);
    fPtr = mxGetField(prhs[1],0,"data_type");
    data_type = (mwSize)*mxGetPr(fPtr);
    N = (mwSize)mxGetN(prhs[0]);
    mxGetString(prhs[0],fpath,N+1);
    b = (mwSize)*mxGetPr(prhs[2]);
    
/* check the variables */
//     printf("samples: %d\n",samples);
//     printf("lines: %d\n",lines);
//     printf("bands: %d\n",bands);
//     printf("header_offset: %d\n",header_offset);
//     printf("interleave: %s\n",interleave);
//     printf("data_type: %d\n",data_type);
//     printf("fpath: %s\n",fpath);
//     printf("b: %d\n",b);

s = sizeof(float);
/* check the data_type is corret */
    if(data_type!=4)
    {   
        mexErrMsgIdAndTxt( "MATLAB:lazyEnviReadbMexFloat04:data_type",
            "Wrong function for this data_type");
    }
printf("s:%d\n",s);
/* read the image file */
    plhs[0] = mxCreateNumericMatrix(samples, lines, mxSINGLE_CLASS, mxREAL);
    imb = mxGetPr(plhs[0]);
    buf = (float *)malloc(s*samples);
    fp = fopen(fpath,"rb");
    if (~strcmp(interleave,"bil")) {
        // BIL type: sample -> band -> line
        offset = s*(samples*(b-1)) + header_offset;
        skips = s*samples*(bands-1);
        fseek(fp, offset, SEEK_SET);
        for (l=0; l<lines; l++) 
        {   
            fread(buf,s,samples,fp);
            // memcpy is faster??
            memcpy(imb+l*samples,buf,s*samples);
//             for (sa=0; sa<samples; sa++) {
// //                 printf("buf1: %d\n",buf[sa]);
// //                 printf("tmp: %lf\n",tmp);
// //                 printf("mem: %d\n",sa+l*samples);
//                 *(imb+(l*samples+sa)) = buf[sa];
//                 //printf("buf:%f\n",imb[l,sa]);
//             }
            _fseeki64(fp,skips,SEEK_CUR);
        }
    }
    else if (strcmp(interleave,"bsq")){
            // sample -> line -> band
            offset = s*(samples*lines*(b-1))+header_offset;
            fseek(fp, offset, SEEK_SET);
            fread(buf,s,samples*lines,fp);
            memcpy(imb,buf,s*samples*lines);
            //imb = reshape(imb,[samples,lines])
    }
    else {
            mexErrMsgIdAndTxt( "MATLAB:lazyEnviRead:interleave",
                "Unsupported interleave.");
    }
    fclose(fp);
    free(buf);

}

    


