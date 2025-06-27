
#include "io64.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "envi_v2.h"

EnviHeader mxGetEnviHeader(const mxArray *pm){
    EnviHeader msldem_hdr;
    char *interleave_char;
    
    if(mxGetField(pm,0,"samples")!=NULL){
        msldem_hdr.samples = (int32_T) mxGetScalar(mxGetField(pm,0,"samples"));
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header (sample)");
    }
    if(mxGetField(pm,0,"lines")!=NULL){
        msldem_hdr.lines = (int32_T) mxGetScalar(mxGetField(pm,0,"lines"));
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header");
    }
    if(mxGetField(pm,0,"bands")!=NULL){
        msldem_hdr.bands = (int32_T) mxGetScalar(mxGetField(pm,0,"bands"));
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header");
    }
    if(mxGetField(pm,0,"interleave")!=NULL){
        interleave_char = mxArrayToString(mxGetField(pm,0,"interleave"));
        if(strcmp(interleave_char,"bil")==0){
            msldem_hdr.interleave = BIL;
        } else if(strcmp(interleave_char,"bsq")==0) {
            msldem_hdr.interleave = BSQ;
        } else if(strcmp(interleave_char,"bip")==0) {
            msldem_hdr.interleave = BIP;
        } else {
            mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Interleave is not valid");
        }
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header");
    }
    if(mxGetField(pm,0,"data_type")!=NULL){
        msldem_hdr.data_type = (int32_T) mxGetScalar(mxGetField(pm,0,"data_type"));
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header");
    }
    if(mxGetField(pm,0,"byte_order")!=NULL){
        msldem_hdr.byte_order = (int32_T) mxGetScalar(mxGetField(pm,0,"byte_order"));
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header");
    }
    if(mxGetField(pm,0,"header_offset")!=NULL){
        msldem_hdr.header_offset = (int32_T) mxGetScalar(mxGetField(pm,0,"header_offset"));
    }else{
        mexErrMsgIdAndTxt("envi:mexGetEnviHeader","Struct is not an envi header");
    }
    if(mxGetField(pm,0,"data_ignore_value")!=NULL){
        msldem_hdr.data_ignore_value = mxGetScalar(mxGetField(pm,0,"data_ignore_value"));
    }
    
    mxFree(interleave_char);
    return msldem_hdr;
    
}

bool isComputerLSBF(void){
    int i = 1;
    char *c = (char*)&i;
    
    if (*c) {
        /* little endian */
        return true;
    } else {
        /* big endian */
        return false;
    }
        
}

/* function : swapFloat_shuffle 
 *  swap the bytes of the input float variable into the reverse direction 
 *  for resolving endian issues using byte shuffling.  
 *  Input Parameters
 *    float inFolat: input float before swapped 
 *  Returns
 *    float retVal : output float after swapped */
float swapFloat_shuffle( float inFloat )
{
   float retVal;
   char *inFloat_char = (char*) &inFloat;
   char *retVal_char  = (char*) &retVal;
   
   // swap the bytes into a temporary buffer
   retVal_char[0] = inFloat_char[3];
   retVal_char[1] = inFloat_char[2];
   retVal_char[2] = inFloat_char[1];
   retVal_char[3] = inFloat_char[0];

   return retVal;
}

/* function : swapFloat 
 *  swap the bytes of the input float variable into the reverse direction 
 *  for resolving endian issues using bit shifts. 
 *  Input Parameters
 *    float inFolat: input float before swapped 
 *  Returns
 *    float retVal : output float after swapped */
float swapFloat( const float inFloat )
{
   float retVal;
   uint32_T *inFloat_int = (uint32_T*) &inFloat;
   uint32_T *retVal_int  = (uint32_T*) &retVal;
   
   *retVal_int = (*inFloat_int<<24) | ( (*inFloat_int<<8) & 0x00FF0000u )
                 | ( (*inFloat_int>>8) & 0x0000FF00u)
                 | ( (*inFloat_int>>24) & 0x000000FFu);
   
   return retVal;
}

int lazyenvireadRectx_multBand(char *imgpath, EnviHeader hdr, 
        long int* smpl_skipszlist, size_t* smpl_readszlist, 
        size_t N_smpl_skipread, long int smpl_skip_last,
        long int* line_skipszlist, size_t* line_readszlist,
        size_t N_line_skipread, long int line_skip_last,
        long int* band_skipszlist, size_t* band_readszlist,
        size_t N_band_skipread, long int band_skip_last,
        void *subimg, size_t *dims_subimg, size_t sz)
{
    size_t i,j,k, ii, jj,kk;
    long int skip_pri;
    void *buf;
    long int sz_li;
    FILE *fid;
    size_t ncpy;
    long int szfile,header_offset;
    
    long int d1, d2, d3;
    size_t *d1_readszlist, *d2_readszlist, *d3_readszlist;
    long int *d1_skipszlist, *d2_skipszlist, *d3_skipszlist;
    size_t N_d1_skipread, N_d2_skipread, N_d3_skipread;
    long int d1_skip_last, d2_skip_last, d3_skip_last;

    size_t N;
    size_t subimg_offset,curskip;

    sz_li = (long int) sz;

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
    if(szfile < (long int) hdr.samples * (long int) hdr.lines * (long int) hdr.bands * sz_li + header_offset){
        fclose(fid);
        return -2;
    }
    fseek(fid, header_offset, SEEK_SET);
    
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

    /* read the data from the file */
    N = d1*d2;
    ncpy = N * sz;
    buf = malloc(ncpy);
    subimg_offset = 0;
    for(i=0;i<N_d3_skipread;i++){
        // printf("i=%d\n",i);
        fseek(fid,d1*d2*d3_skipszlist[i]*sz_li,SEEK_CUR);
        for(ii=0;ii<d3_readszlist[i];ii++){
            fread(buf,sz,N,fid);
            curskip = 0;
            for(j=0;j<N_d2_skipread;j++){
                // printf("j=%d\n",j);
                curskip += d1*d2_skipszlist[j]*sz_li;
                for(jj=0;jj<d2_readszlist[j];jj++){
                    for(k=0;k<N_d1_skipread;k++){
                        // printf("k=%d\n",k);
                        curskip += d1_skipszlist[k]*sz_li;
                        memcpy(subimg+subimg_offset,buf+curskip,d1_readszlist[k]*sz);
                        subimg_offset += d1_readszlist[k]*sz;
                        curskip += d1_readszlist[k]*sz_li;
                        /* for(kk=0;kk<d1_readszlist[k];kk++){
                            *(subimg+subimg_offset) = *(buf+curskip);
                            subimg_offset++;
                            curskip++;
                        } */
                    }
                    curskip += d1_skip_last*sz_li;
                }
            }
        }
    }
    free(buf);
    fclose(fid);
    
    return 0;
}

int image_byteswapFloat(float *img, size_t *dims_img, int32_t byte_order)
{
    float swapped;
    bool computer_isLSBF;
    bool data_isLSBF;
    bool swap_necessary;
    size_t N,i;

    /* Evaluate the endians of the computer and image data. */
    computer_isLSBF = isComputerLSBF();
    data_isLSBF = !((bool) byte_order);
    swap_necessary = (computer_isLSBF != data_isLSBF);

    /* Swap bytes if necessary */
    if(swap_necessary){
        N = dims_img[0]*dims_img[1]*dims_img[2];
        for(i=0;i<N;i++){
            swapped = swapFloat(img[i]);
            img[i] = swapped;
        }
    }

    return 0;
}

int image_byteswapInt16(int16_t *img, size_t *dims_img, int32_t byte_order)
{
    int16_t swapped;
    bool computer_isLSBF;
    bool data_isLSBF;
    bool swap_necessary;
    size_t N,i;

    /* Evaluate the endians of the computer and image data. */
    computer_isLSBF = isComputerLSBF();
    data_isLSBF = !((bool) byte_order);
    swap_necessary = (computer_isLSBF != data_isLSBF);

    /* Swap bytes if necessary */
    if(swap_necessary){
        N = dims_img[0]*dims_img[1]*dims_img[2];
        for(i=0;i<N;i++){
            swapped = (img[i]<<8) | ((img[i]>>8) & 0xFF);
            img[i] = swapped;
        }
    }
    return 0;
}

int image_byteswapUint16(uint16_t *img, size_t *dims_img, int32_t byte_order)
{
    uint16_t swapped;
    bool computer_isLSBF;
    bool data_isLSBF;
    bool swap_necessary;
    size_t N,i;

    /* Evaluate the endians of the computer and image data. */
    computer_isLSBF = isComputerLSBF();
    data_isLSBF = !((bool) byte_order);
    swap_necessary = (computer_isLSBF != data_isLSBF);

    /* Swap bytes if necessary */
    if(swap_necessary){
        N = dims_img[0]*dims_img[1]*dims_img[2];
        for(i=0;i<N;i++){
            swapped = (img[i]<<8) | (img[i]>>8);
            img[i] = swapped;
        }
    }

    return 0;
}
