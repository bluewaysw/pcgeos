/***********************************************************************
 *
 * PROJECT:       VConvert
 * FILE:          VConvert.h
 * DESCRIPTION:   Vector file converter common definitions
 *
 * AUTHOR:        Marcus Groeber
 *
 ***********************************************************************/

#include <meta.h>
#include "vconv_ui.h"

/*
 * useful macros
 */
#define NULL_HANDLE 0

/* Type-independent minimum, maximum, absolute value: */
#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))
#define abs(a)   (((a)>0)?(a):-(a))

/* Bytewise swapping of two areas of memory: */
#define memswap(d,s,n) { int _i; char t; for(_i=0;_i<(n);_i++)\
                         {t=((char *)(s))[_i];\
                          ((char *)(s))[_i]=((char *)(d))[_i];\
                          ((char *)(d))[_i]=t;} }

/* Check if value is inside a given interval [b1,b2]: */
#define _between(a,b1,b2) (((a)>=(b1) && (a)<=(b2)) || ((a)<=(b1) && (a)>=(b2)))

/* Test character for being valid part of a floating point number: */
#define isnum(c) (((c)>='0' && (c)<='9') || (c)=='.' || (c)=='-' || (c)=='+')


/* maximum number of points in a polyline */
#define MAX_POINTS 4096

/* result codes for converters */
#define ERR_NONE 0                      /* no problems encountered */
#define ERR_OPEN_FAILED 1               /* file could not be opened */
#define ERR_INVALID_FORMAT 2            /* file is not the type it should be */
#define ERR_UNSUPPORTED_VARIANT 3       /* file contains unsupported features */
#define ERR_OUT_OF_MEMORY 4             /* not enough memory */
#define ERR_ABORTED 255                 /* user aborted conversion */

/*
 * update Progress value and check if user requested stopping the operation
 */
Boolean UpdateProgressPct(word pct);

/*
 * Data block passed between TransGet???portOptions and Trans???port
 */
struct ie_uidata {
  word booleanOptions;
};

/*
 * prototypes for available import filters
 */
int ReadHPGL(FileHandle srcFile,word settings);
int ReadCGM(FileHandle srcFile,word settings);

void ExportGString(GStateHandle gs);

/*
 * "Wrappers" to pass parameters for MSG_GB_CREATE_*_TRANSFER_FORMAT
 */
VMBlockHandle _far _pascal
  My_GB_CreateGStringTransferFormat(optr body,VMFileHandle vmf,PointDWFixed *o);
VMBlockHandle _far _pascal
  My_GB_CreateGrObjTransferFormat(optr body,VMFileHandle vmf,PointDWFixed *o);

