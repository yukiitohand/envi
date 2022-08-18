/*
 * lazyEnviReadcMex04Float.c
 * Read a specified column of hyperspectral image data with Float type.
 * Input: 
 * fpath: (string) path to the image file
 * samples: integer
 * lines: integer
 * bands: integer
 * header_offset: integer
 * data_type: integer
 * interleave: string
 * byte_order
 * c: column to be read,integer
 *
 * 
 * Output:
 * imc: (image x Line) Matrix of the band of the image in double format
 * The calling syntax is:
 *
 *		imc = lazeEnviReadcMex(fpath,samples,lines,bands,header_offset,data_type,interleave,byte_order,c)
 *
 * This is a MEX file for MATLAB.
*/
#include "mex.h"
#include "matrix.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* The computational routine */
void readimageUint16(char* fpath, int samples, int lines, int bands, int header_offset, char* interleave, int byte_order, int c, int s, unsigned short* im)
{
    unsigned short* buf;
    mwSize offset;
    mwSize skips;
    mwSize l;
    mwSize b;
    mwSize sz;
    unsigned short tmp1;
    unsigned short tmp2;
    FILE *fp;
    
    if(byte_order==2){
        mexErrMsgIdAndTxt( "MATLAB:lazyEnviRead:byte_order",
                "Unsupported byte_order.");
    }
    
    buf = (unsigned short *)malloc(s);
    fp = fopen(fpath,"rb");
    fseek(fp, 0, SEEK_END);
    sz = ftell(fp);
    if (sz < samples*s*lines*bands){
        mexErrMsgIdAndTxt( "MATLAB:lazyEnviRead:Input",
                "Some input data seems wrong.");
    }
    fseek(fp, 0, SEEK_SET); 
    
    
    if (~strcmp(interleave,"bil")) {
        // BIL type: sample -> band -> line
        offset = s*(c-1) + header_offset;
        skips = s*(samples-1);
        fseek(fp, offset, SEEK_SET);
        for (l=0; l<lines; l++) 
            for (b=0; b<bands; b++)
            {   
                fread(buf,s,1,fp);
                if(byte_order==1)
                {
                    tmp1 = *buf / 256;
                    tmp2 = *buf % 256;
                    *buf = tmp2*256+tmp1;
                }
                // memcpy is faster??
                memcpy(im+b+l*bands,buf,s);
                _fseeki64(fp,skips,SEEK_CUR);
        }
    }
    else {
            mexErrMsgIdAndTxt( "MATLAB:lazyEnviRead:interleave",
                "Unsupported interleave.");
    }
    fclose(fp);
    free(buf);
}


/* The gateway function */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* variable declarations here */
    char fpath[500];
    mwSize samples;
    mwSize lines;
    mwSize bands;
    mwSize header_offset;
    mwSize data_type;
    char interleave[5];
    mwSize byte_order;
    mwSize c;
    mwSize N;
    mwSize s;
    unsigned short* imc;
    
//     printf("%d\n",nrhs);
    if(nrhs != 9) {
        mexErrMsgIdAndTxt("lazyEnviReadcMex:nrhs","Nine inputs required.");
    }
    


    /* code here */
    samples = (mwSize)mxGetScalar(prhs[1]);
    lines = (mwSize)mxGetScalar(prhs[2]);
    bands = (mwSize)mxGetScalar(prhs[3]);
    header_offset = (mwSize)mxGetScalar(prhs[4]);
    data_type = (mwSize)mxGetScalar(prhs[5]);
    byte_order = (mwSize)mxGetScalar(prhs[7]);
    c = (mwSize)mxGetScalar(prhs[8]);
    
    N = (mwSize)mxGetN(prhs[0]);
    if(N+1>500){
        mexErrMsgIdAndTxt("lazyEnviReadcMex:fpath","Too long.");
    }
    mxGetString(prhs[0],fpath,N+1);
    
    N = (mwSize)mxGetN(prhs[6]);
    if(N+1>5){
        mexErrMsgIdAndTxt("lazyEnviReadcMex:fpath","Too long.");
    }
    mxGetString(prhs[6],interleave,N+1);
    
    if(c>samples){
         mexErrMsgIdAndTxt("lazyEnviReadcMex:c","Too big.");
    }

    
/* check the variables */
//     printf("samples: %d\n",samples);
//     printf("lines: %d\n",lines);
//     printf("bands: %d\n",bands);
//     printf("header_offset: %d\n",header_offset);
//     printf("interleave: %s\n",interleave);
//     printf("data_type: %d\n",data_type);
//     printf("fpath: %s\n",fpath);
//     printf("c: %d\n",c);



/* read the image file */
    if(data_type==12)
    {
        plhs[0] = mxCreateNumericMatrix(bands, lines, mxUINT16_CLASS, mxREAL);
        s = sizeof(unsigned short);
//         printf("s:%d\n",s);
    }
    else{
        mexErrMsgIdAndTxt("lazyEnviReadcMex:data_type","uint16 type is required.");
    }
    
    imc = mxGetData(plhs[0]);
    
    if(data_type==12)
    {
        readimageUint16(fpath,samples,lines,bands,header_offset,interleave,byte_order,c,s,imc);
    }

}

    


