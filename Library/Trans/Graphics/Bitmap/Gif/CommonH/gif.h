/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		gif.h				     */
/*								     */
/*	AUTHOR:		jimmy lefkowitz				     */
/*								     */
/*	REVISION HISTORY:					     */
/*								     */
/*	Name	Date		Description			     */
/*	----	----		-----------			     */
/*	jimmy	2/ 5/92		Initial version			     */
/*								     */
/*	DESCRIPTION:						     */
/*								     */
/*	$Id: gif.h,v 1.1 97/04/07 11:27:11 newdeal Exp $
/*							   	     */
/*********************************************************************/



// global variables

#define BFT_BITMAP 0x4d42   /* 'BM' */

// function prototypes

/***
HSI_ERROR_CODE EXPORT  HSILoadGIF      (LPSTR,LPSTR,LPCNVOPTION);
***/
extern HSI_ERROR_CODE         LoadGIFImage    (int, long * );
extern HSI_ERROR_CODE         DecodeGIFData         (WORD linewidth );

extern HSI_ERROR_CODE FAR PASCAL HSILoadGIF(FILE *,FILE *,LPCNVOPTION);

extern BOOL ParseCmdLine(int argc, char **argv);

extern WORD       getbytes    ( FILE * Infile );
extern void       chkunexp    ( int *unexpected, int determiner );
extern int        extninfo    ( long *file_byte_cnt );
extern int        out_line    ( BYTE FAR *pixels, int linelen );
extern int        SaveTo8     ( LPSTR, int );
extern int        SaveTo4     ( LPSTR, int );
extern int        SaveTo1     ( LPSTR, int );
extern int        LoadColorMap( int times, long *file_byte_cnt);





