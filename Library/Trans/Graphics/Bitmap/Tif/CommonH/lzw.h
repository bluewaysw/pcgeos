/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		lzw.h

AUTHOR:		Maryann Simmons, May  5, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: lzw.h,v 1.1 97/04/07 11:27:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* main LZW control structure
 *
 * the table is an array of DCTREENODEs, the first (1<<Bits) entries of
 * which represent the characters themselves.
 */

typedef struct {
    /* initialized at open time: */
    HANDLE        hTable;          /* the table */
    HANDLE        hOutStripBuf;    /* where we'll write the compressed output */
    HANDLE        h16Buf;          /* for storing 16-bit LZW codes temporarily */
    WORD        OutStripBufSize;
} LZWSTRUCT;


/* Decompression tree node structure.
 *
 * This is a funny "tree", with pointers pointing up but not down.
 */

typedef struct {
    BYTE    Suffix;        /* character to be added to the current string */
    BYTE    StringLength; /* # of characters in the string */
    WORD    Parent;        /* offset of parent treenode */
} DCTREENODE;

typedef DCTREENODE  FAR * DCLPTREENODE;

/* some LZW constants */

#define MAXCODEWIDTH     12                   /* maximum code width, in bits */
#define MAXTABENTRIES    (1<<MAXCODEWIDTH)    /* max # of table entries */
#define CLEARCODE        256
#define EOICODE          257
#define DBMSG(p)         (printf p )
#define SUCCESS          (HSI_ERROR_CODE)0
#define CHARBITS    8    /* bit depth; */
#define MAXWORD     ((WORD)(0xFFFF))

/******** Functions Declaration ******************************************/

HSI_ERROR_CODE        LzwCmStrip        ( PVOID, DWORD, LPBYTE, DWORD *);
// HSI_ERROR_CODE        LzwCmOpen         ( PVOID *, DWORD);
HSI_ERROR_CODE        LzwCmClose        ( PVOID );
int      LzwDeOpen       ( DWORD, DCLPTREENODE FAR *, LPSTR FAR *);
void     LzwDeClose      ( DCLPTREENODE, LPSTR);
int      LzwDecodeChunk  ( LPWORD,DCLPTREENODE,/*WORD,*/LPSTR,DWORD);
int      LzwDeChunk      ( LPSTR,DWORD,LPSTR,DCLPTREENODE,DWORD,LPSTR);
WORD  CalcMask         (WORD BitDepth);

