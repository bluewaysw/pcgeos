/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clp.h

AUTHOR:		Maryann Simmons, May 14, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/14/92   	Initial version.

DESCRIPTION:
	

	$Id: clp.h,v 1.1 97/04/07 11:26:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#define SIZEOFCLPHDR        40
#define SIZEOFCLP30FILEHDR   4
#define SIZEOFCLP30HDR      89
// header for Windows 2.x clipboard format 


typedef struct 
   {
	BYTE	byte1, byte2;
	WORD	w1, w2, w3, w4;
	WORD	width, height;
	WORD	w5, w6;
	WORD	width1, height1, widthbyte;
	BYTE	bitspixel;
	BYTE	planes;
	WORD	w7, w8;
	WORD	id;
	BYTE	filler[8];
	} CLPHDR;


// header for Windows 3.0 clipboard format

typedef struct
   {
   WORD    fileid;     // must be CLP_ID
   WORD    count;      // number of clipboard formats
   } CLP30FILEHDR;

typedef struct
   {
   WORD    fmtid;      // format ID, must be Bitmap or DIB
   DWORD   length;     // length of data in bytes
   DWORD   offset;     // offset to data byte
   char    name[79];   // format name
   } CLP30HDR;
      

#define CLP_ID     0xc350

/*
 This doesnt WORK- Cant declare 2x****
CLPHDR         *clphdr;
CLP30FILEHDR   *pclp30, clp30filehdr;
CLP30HDR       clp30hdr;
moved these into clpload and clpsave
**********************************/

#ifndef CF_DIB
#define CF_DIB                        8
#endif

#ifndef CF_BITMAP
#define CF_BITMAP          2
#endif

#ifndef CF_PALETTE
#define CF_PALETTE                9
#endif




































