/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Compiler/Runtime
FILE:		fformat.h

AUTHOR:		dubois, Sep 29, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/29/95	Initial version.

DESCRIPTION:
	Definitions and structs for the .bc file format

	$Id: fformat.h,v 1.1 97/12/05 12:15:55 gene Exp $
	$Revision: 1.1 $

	Liberty version control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FFORMAT_H_
#define _FFORMAT_H_

/* -- File format shme.  Should this stay here? */

/* A var table entry, as it appears in a module header */
typedef struct
{
    byte	HVTE_type;	/* actually a LegosType */
    word	HVTE_offset;
/*    word	HVTE_runSize;*/
} HVTabEntry;

#ifdef LIBERTY
typedef word PageMarker;
#define PM_FUNC  	0x000c		/* FuncHeader */
#define PM_STRING_FUNC  0x000d		/* StringHeader */
#define PM_STRING_CONST 0x000e		/* StringHeader */
#define PM_EXPORT	0x000f		/* StringHeader */
#define PM_STRUCT_INFO	0x0010		/* Only found in header */
#define PM_PAD_BYTE	0x0011		/* Only found before PM_STRING_CONST,
					   one byte (0xcc) of padding follows
					   this page marker to align DBCS
					   strings to 2-byte boundaries */
#define PM_HEADER_END	0xeeee		/* End of header */
#define PM_END 		0xffff		/* EOF */

#else	/* GEOS version below */

typedef enum
{
    PM_FUNC = 0xc,		/* FuncHeader */
    PM_STRING_FUNC,		/* StringHeader */
    PM_STRING_CONST,		/* StringHeader */
    PM_EXPORT,			/* StringHeader */
    PM_STRUCT_INFO,		/* Only found in header */
    PM_PAD_BYTE,		/* One byte of padding follows this marker */
    PM_HEADER_END = 0xeeee,	/* End of header */
    PM_END = 0xffff		/* EOF */
} PageMarker;
#endif

/* Simple scheme for revision of code files
 * Inc major if changes are not backward-compatible
 */

/* initial definition dubois 2/13/96 */
#define BC_MAJOR_REV	4
#define BC_MINOR_REV	0

/* After a StringHeader:
 *	ASCIIZ string
 *	[...]	(SH_numStrings times)
 */
typedef struct
{
    PageMarker	SH_marker;
    word	SH_numStrings;
} StringHeader;

/* After a FuncHeader:
 *	word	size;
 *	<size> bytes of pcode
 *	[...]	(FH_numSegs times)
 */
typedef struct
{
    PageMarker	FH_marker;
    word	FH_funcNumber;
    byte	FH_numSegs;
    word    	FH_numLocals;
} FuncHeader;

typedef struct
{
    word	numFields;
    word	size;
} BCLVTab;


/* NOTE: because on unix this data structure's fields get word aligned
 * it shouldn't actually be used as on the GEOS side it doesn't get
 * aligned
 */
typedef struct
{
    byte	type;
    byte	structType;	/* this field only occurs in files with
				 * proto 1.2 and above */
/*    word	offset; */
} BCLVTabEntry;

#endif /* _FFORMAT_H_ */
