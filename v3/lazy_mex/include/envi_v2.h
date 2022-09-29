/* envi.h */
#ifndef ENVI_V2_H
#define ENVI_V2_H

#include <stdint.h>
#include <stdbool.h>
#include <string.h> 
#include "mex.h"
#include "matrix.h"

typedef enum EnviHeaderInterleave {
    BSQ,BIP,BIL
} EnviHeaderInterleave ;

typedef struct EnviHeader {
    int32_T samples;
    int32_T lines;
    int32_T bands;
    int32_T data_type;
    int32_T byte_order;
    int32_T header_offset;
    EnviHeaderInterleave interleave;
    char* file_type;
    double data_ignore_value;
} EnviHeader ;

EnviHeader mxGetEnviHeader(const mxArray *pm);
extern bool isComputerLSBF(void);

/* function : swapFloat_shuffle 
 *  swap the bytes of the input float variable into the reverse direction 
 *  for resolving endian issues using byte shuffling.  
 *  Input Parameters
 *    float inFolat: input float before swapped 
 *  Returns
 *    float retVal : output float after swapped */
extern float swapFloat_shuffle( float inFloat );

/* function : swapFloat 
 *  swap the bytes of the input float variable into the reverse direction 
 *  for resolving endian issues using bit shifts. 
 *  Input Parameters
 *    float inFolat: input float before swapped 
 *  Returns
 *    float retVal : output float after swapped */
extern float swapFloat( const float inFloat );

extern int lazyenvireadRectx_multBand(char *imgpath, EnviHeader hdr, 
        long int* smpl_skipszlist, size_t* smpl_readszlist, 
        size_t N_smpl_skipread, long int smpl_skip_last,
        long int* line_skipszlist, size_t* line_readszlist,
        size_t N_line_skipread, long int line_skip_last,
        long int* band_skipszlist, size_t* band_readszlist,
        size_t N_band_skipread, long int band_skip_last,
        void *subimg, size_t *dims_subimg, size_t sz);

extern int image_byteswapFloat(float* img, size_t *dims_img, int32_t byte_order);
extern int image_byteswapInt16(int16_t* img, size_t *dims_img, int32_t byte_order);
extern int image_byteswapUint16(uint16_t* img, size_t *dims_img, int32_t byte_order);

#endif
