/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  msobj.h
 * FILE:	  msobj.h
 *
 * AUTHOR:  	  Adam de Boor: Feb 21, 1991
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	2/21/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions relating to microsoft-format object files.
 *
 *
 * 	$Id: msobj.h,v 1.15 96/07/08 17:28:45 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _MSOBJ_H_
#define _MSOBJ_H_

#include    "vector.h"

/******************************************************************************
 *
 *		     DEFINED OBJECT RECORD TYPES.
 *
 ******************************************************************************/

#define MO_HEADER_SIZE	3   	/* Number of bytes in an object record header */

/*
 * Bad record. No data. Internal use only (not actually in a file)
 */
#define MO_ERROR    0x00

/*
 * Start of module. Followed by:
 *	- record length (word)
 *	- module name (counted ascii)
 *	- checksum (byte)
 */
#define MO_THEADR   0x80

/*
 * Comment. Followed by:
 *	- record length (word)
 *	- comment attributes (byte)
 *	- comment class (byte)
 *	- variable-length data (length implied by overall record length)
 *	- checksum (byte)
 */
#define MO_COMENT   0x88

/* Comment attributes */
#define CA_NO_PURGE 	0x80	/* Don't ever delete this record */
#define CA_NO_LIST  	0x40	/* Don't list this record's contents */

/* Comment classes */
#define CC_TRANSLATOR	0x00	/* data is name of translator that produced
				 * the object module */
#define CC_COPYRIGHT	0x01	/* data is copyright notice */
#define CC_DOS_VERSION	0x9c	/* data is word holding DOS version under which
				 * object file was created. */
#define CC_MODEL    	0x9d	/* data is memory model of module: s, c, m, l,
				 * or h */
#define CC_DOSSEG   	0x9e	/* enable DOS segment ordering */
#define CC_LIBRARY  	0x9f	/* data is name of library to be searched
				 * to resolve external references. */
#define CC_MSOFT_EXT  	0xa1	/* indicates that Microsoft extensions to
				 * the Intel object spec are used. */


/*
 * End of module. Followed by:
 *	- record length (word)
 *	- module type (byte)
 *	- entry point fixup, if module contains the entry.
 *	- checksum (byte)
 */
#define MO_MODEND   0x8a

/* Module types */
#define MT_IS_MAIN 	0x80	/* Set in modtype if it's a main program module,
				 * whatever that means. */
#define MT_HAS_START	0x40	/* Set in modtype if the module holds the
				 * entry point for the program */

/*
 * Definition of external undefined symbols. Followed by:
 *	- record length (word)
 *	- one or more records (number determined by overall record length) of
 *	  the form:
 *	    - external symbol name (counted ascii)
 *	    - type index (byte) referring to nth entry from preceding TYPDEF
 *	      records. If 0, then no type defined for the beast.
 *	- checksum (byte)
 */
#define MO_EXTDEF   0x8c

/*
 * Definition of simple types in a not-so-simple manner. Followed by:
 * 	- length (word)
 *	- name (counted ascii, always null)
 *	- one or more records of the form:
 *	    - a 0 byte
 *	    - a 62h byte, if the type can be referenced "near", followed by:
 *	    	- the variable type (byte)
 *	    	- the size of the type in bits. If < 128, this is a byte.
 *	    	  if the size requires two bytes, it is stored after a byte
 *	    	  containing 81h; if it requires 3, it is stored after a byte
 *	    	  containing 84h; if it requires 4, it is stored after a byte
 *		  containing 88h
 *
 *	    - or a 61h byte, if the type can be referenced "far", followed by:
 *	    	- the variable type (byte). it must be an array
 *	    	- the number of elements in the array, in the same format as
 *		  the length-in-bits field for a "near" type.
 *	    	- a type index for the element type.
 */
#define MO_TYPDEF   0x8e

/* type classes */
#define TC_NEAR	    	0x62
#define TC_FAR	    	0x61

/* type types */
#define TT_ARRAY    	0x77
#define TT_STRUCT   	0x79
#define TT_SCALAR   	0x7b

/* type sizes */
#define TS_TWO_BYTE    	0x81
#define TS_THREE_BYTE	0x84
#define TS_FOUR_BYTE	0x88

/*
 * Definition of symbols exported from this module. Followed by:
 *	- length (word)
 *	- public base:
 *	    - group index (0 => no associated group) referring to previous
 *	      GRPDEF record.
 *	    - segment index (0 => absolute frame) referring to previous
 *	      SEGDEF record.
 *	    - if group & segment indices are both zero, a word holding the
 *	      absolute segment of the reference. A segment of 0 probably
 *	      means the beast's a constant.
 *	- one or more records of the form:
 *	    - name (counted ascii)
 *	    - offset of symbol (word)
 *	    - type index (0 => symbol is untyped)
 *	- checksum (byte)
 */

/**
 * Reference: http://www.fileformat.info/format/ms-obj/corion.htm
 *
 * Watcom uses LPUBDEF1 for NEAR modules instead of PUBDEF. The specification
 * defines b6 and b7 as both LPUBDEF but doesn't state the difference so we'll
 * just treat them both as real symbols for now - mcasadevall
 */

#define MO_LPUBDEF1 0xb6
#define MO_LPUBDEF2 0xb7
#define MO_PUBDEF   0x90

/*
 * Line number mapping. Followed by:
 *	- length (word)
 *	- line number base:
 *	    - group index (always a 0 byte)
 *	    - segment index (byte or word) to which the line numbers pertain
 *	- one or more records of the form:
 *	    - line number (word) All line numbers refer to the source file
 *	      given in the THEADR record.
 *	    - starting offset (word)
 *	- checksum (byte)
 */
#define MO_LINNUM   0x94

/*
 * List of names to be referenced by later records. Followed by:
 *	- length (word)
 *	- one or more names (counted ascii)
 *	- checksum (byte)
 */
#define MO_LNAMES   0x96

/*
 * Segment definition. Followed by:
 *	- length (word)
 *	- segment attributes:
 *	    - ACBP byte:
 *	    	- b0	= Page-resident (unused)
 *	    	- b1	= Big (exactly 64K, so segment length is 0)
 *	    	- b2:4	= Combine type:
 *	    	    	  0 = private
 *			  1 = unused
 *			  2 = public
 *			  3 = unused
 *			  4 = public ("same as C = 2")
 *			  5 = stack
 *			  6 = common
 *			  7 = public ("same as C = 2")
 *	    	- b5:7	= Alignment
 *	    	    	  0 = absolute
 *			  1 = byte-aligned
 *			  2 = word-aligned
 *			  3 = para-aligned
 *			  4 = page-aligned
 *	    - frame number if segment is absolute (word)
 *	    - offset if segment is absolute (byte). always < 0x10
 *	- segment length (word)
 *	- segment name index (index)
 *	- class name index (index)
 *	- overlay name index (index)
 *	- checksum (byte)
 */
#define MO_SEGDEF   0x98

#define SA_PAGE_RESIDENT    0x01
#define SA_BIG	    	    0x02
#define SA_COMBINE  	    0x1c
#define SA_ALIGN    	    0xe0

#define SA_COMBINE_SHIFT    2
#define SA_ALIGN_SHIFT	    5

/*
 * 32-bit Segment definition. Followed by:
 *	- length (word)
 *	- segment attributes:
 *	    - ACBP byte:
 *	    	- b0	= USE32
 *	    	- b1	= Big (exactly 64K, so segment length is 0)
 *	    	- b2:4	= Combine type:
 *	    	    	  0 = private
 *			  1 = unused
 *			  2 = public
 *			  3 = unused
 *			  4 = public ("same as C = 2")
 *			  5 = stack
 *			  6 = common
 *			  7 = public ("same as C = 2")
 *	    	- b5:7	= Alignment
 *	    	    	  0 = absolute
 *			  1 = byte-aligned
 *			  2 = word-aligned
 *			  3 = para-aligned
 *			  4 = page-aligned
 *	    	    	  5 = dword-aligned
 *	    - frame number if segment is absolute (word)
 *	    - offset if segment is absolute (byte). always < 0x10
 *	- segment length (dword)
 *	- segment name index (index)
 *	- class name index (index)
 *	- overlay name index (index)
 *	- checksum (byte)
 */
#define MO_SEGDEF32 0x99

#define SA_USE32    0x01
/* Other SA_ constants apply here, too */

/*
 * Group definition. Followed by:
 *	- length (word)
 *	- group name (index)
 *	- one or more records of the following form:
 *	    - member type (byte). always 0xff == segment index
 *	    - segment (index)
 *	- checksum (byte)
 */
#define MO_GRPDEF   0x9a

/*
 * Fixup list. Applies to the immediately-preceding LEDATA or LIDATA record.
 * Followed by:
 *	- length (word)
 *	- zero or more thread records:
 *	    - thread data (byte)
 *	    - segment/group index or absolute frame (index/word)
 *	- zero or more fixup records:
 *	    - location (word)
 *	    - fixup data (byte)
 *	    - frame data (index/word/absent)
 *	    - target data (index/word/absent)
 *	    - target displacement (word/absent)
 *	- checksum (byte)
 *
 * A fixup is specified in terms of (TARGET, FRAME, LOCATION) triples, where:
 *	TARGET	    the thing whose address was unknown at compile-time
 *	FRAME	    the frame w.r.t. which the target's address is to be
 *		    determined
 *	LOCATION    the address to be affected by the fixup.
 *
 * A fixup record can contain eight "threads", four to specify a TARGET and
 * four to specify a FRAME. These threads can be used to reduce the number
 * of bytes in a FIXUPP record, as the thread number can be placed in the
 * fixup data byte, rather than requiring an extra byte or two for the
 * index.
 */
#define MO_FIXUPP   0x9c

/* Fields of thread data */
#define TD_IS_FRAME 	0x40	/* Set if thread is for a frame. Clear if
				 * thread is for a target */
#define TD_METHOD   	0x1c	/* Fixup method */
#define TD_METHOD_SHIFT	2
#define TD_THREAD_NUM	0x03	/* Thread number */

#define TD_METHOD_SHIFT	2

/* Frame fixup methods */
#define FFM_SEGMENT 	0x00	/* Frame is a segment index */
#define FFM_GROUP   	0x01	/* Frame is a group index */
#define FFM_EXTERNAL	0x02	/* Frame is the segment/group of an external
				 * symbol whose index is given */
#define FFM_ABSOLUTE	0x03	/* Frame is an absolute segment */
#define FFM_SELF    	0x04	/* Frame is the LOCATION's own segment */
#define FFM_TARGET  	0x05	/* Frame is the same as the target */

/* Target Fixup Methods */
#define TFM_SEGMENT 	0x00	/* Target is a segment index */
#define TFM_GROUP   	0x01	/* Target is a group index */
#define TFM_EXTERNAL	0x02	/* Target is an external symbol index */
#define TFM_ABSOLUTE	0x03	/* Target is an absolute segment */
#define TFM_SELF    	0x04	/* Target is the LOCATION's own segment (MSC7
				 * EXTENSION) */

/* Fixup Location High-byte */
#define FLH_IS_FIXUP 	0x80	/* Set to indicate fixup, not thread */
#define FLH_SEG_REL  	0x40	/* Clear if fixup is pc-relative */
#define FLH_LOC_TYPE	0x1c	/* Location type */
#define FLH_LOC_TYPE_SHIFT 2
#define FLH_OFFSET_HIGH	0x03	/* High two bits of fixup location offset.
				 * Low 8 bits are in following byte */

#define FL_OFFSET ((FLH_OFFSET_HIGH << 8) | 0xff)
#define FL_LOC_TYPE (FLH_LOC_TYPE << 8)
#define FL_SEG_REL (FLH_SEG_REL << 8)
#define FL_IS_FIXUP (FLH_IS_FIXUP << 8)

/* Fixup Location Types */
#define FLT_LOW_BYTE	0x00	/* Location is low-order byte */
#define FLT_OFFSET  	0x01	/* Location is word-sized offset */
#define FLT_SEGMENT 	0x02	/* Location is word-sized segment */
#define FLT_FAR_PTR 	0x03	/* Location is far pointer */
#define FLT_HIGH_BYTE	0x04	/* Location is high-order byte */
#define FLT_LDRRES_OFF	0x05	/* Location is offset to be resolved by the
				 * run-time loader (same as FLT_OFFSET) */


/* Fixup Data byte */
#define FD_FRAME_IS_THREAD  0x80    /* Set => FD_FRAME is thread # */
#define FD_FRAME    	    0x70    /* Frame Fixup Method, or thread # */
#define FD_FRAME_SHIFT	    4
#define FD_TARG_IS_THREAD   0x08    /* Set => FD_TARGET is thread # */
#define FD_NO_TARG_DISP     0x04    /* Set if target displacement is 0 */
#define FD_TARGET   	    0x03    /* Target Fixup Method, or thread # */


/*
 * Binary (enumerated) data. Followed by:
 *	- length (word)
 *	- segment (index)
 *	- offset in segment of first byte of data (word)
 *	- data (variable)
 *	- checksum (byte)
 */
#define MO_LEDATA   0xa0

/*
 * Binary (enumerated) data in 32-bit segment. Followed by:
 *	- length (word)
 *	- segment (index)
 *	- offset in segment of first byte of data (dword)
 *	- data (variable)
 *	- checksum (byte)
 */
#define MO_LEDATA32 0xa1

/*
 * Binary (iterated) data. Followed by:
 *	- length (word)
 *	- segment (index)
 *	- offset in segment of first byte of data (word)
 *	- iterated data block:
 *	    - repeat count (word)
 *	    - # of iterated data blocks in this block (word) 0 =>
 *	      iterated data is raw bytes
 *	    - iterated data. If block count is non-zero, this is #block count
 *	      nested iterated data blocks. If block count is 0, this is
 *	      followed by:
 *	    	- # bytes of data (byte)
 *	    	- the data in the block (variable)
 *	- checksum (byte)
 */
#define MO_LIDATA   0xa2

/*
 * Binary (iterated) data in 32-bit segment. Followed by:
 *	- length (word)
 *	- segment (index)
 *	- offset in segment of first byte of data (dword)
 *	- iterated data block:
 *	    - repeat count (word)
 *	    - # of iterated data blocks in this block (word) 0 =>
 *	      iterated data is raw bytes
 *	    - iterated data. If block count is non-zero, this is #block count
 *	      nested iterated data blocks. If block count is 0, this is
 *	      followed by:
 *	    	- # bytes of data (byte)
 *	    	- the data in the block (variable)
 *	- checksum (byte)
 */
#define MO_LIDATA32 0xa3

/*
 * Definition of communal variables...but what the fuck do I do with them?
 * Followed by:
 *	- length (word)
 *	- one or more records:
 *	    - name (counted ascii)
 *	    - type index (CodeView type, if CV extensions being used)
 *	    - data segment type (byte):
 *	    	- 0x61: TC_FAR (FAR_BSS segment private para 'FAR_BSS')
 *	    	- 0x62: TC_NEAR (c_common segment in DGROUP)
 *	    - communal length (variable). If type near:
 *	    	- size of variable in bytes (1-5 bytes)
 *	      if type far:
 *	    	- number of elements (1-5 bytes)
 *	    	- size of element in  bytes (1-5 bytes)
 *	- checksum
 *
 * Sizes are same as in TYPDEF records (qv. TS_*)
 */
#define MO_COMDEF   0xb0

/*
 * "Back patch" record to perform fixups that a fixup record apparently can't.
 * For example, msc7 uses this to fill in the parameter passed to its stack-
 * checking routine.
 * Followed by:
 *	- length (word)
 *	- affected segment (index)
 *	- location type to be patched:
 *	    0 = 8-bit lobyte
 *	    1 = 16-bit offset
 *	    2 = 32-bit offset (MO_BACKPATCH32 only)
 *	- one or more records:
 *	    - offset to be patched (word, dword if MO_BACKPATCH32)
 *	    - value to add to location data (word, dword if MO_BACKPATCH32)
 *	- checksum
 */
#define MO_BACKPATCH	0xb2
#define MO_BACKPATCH32	0xb3

#define BPS_BYTE    0
#define BPS_WORD    1
#define BPS_DWORD   2

/*
 * Special EXTDEF record for use by fixups for CodeView symbols. Format is
 * same as for MO_EXTDEF with the symbols being stored in the "externals"
 * vector, but they are not actually external.
 */
#define MO_LEXTDEF    0xb4

/*
 * Special PUBDEF record for use by fixups for CodeView symbols. Format is
 * same as for MO_PUBDEF, but the symbols are not actually global. This is
 * used to provide the segment in which a symbol is stored.
 */
#define MO_CVPUB    0xb6

/*
 * Header for a library file. Followed by:
 *	- record length. This is the "page size" of the library, minus the
 *	  three bytes for the length and the opcode. All references within
 *	  the file are in terms of pages.
 *	- start of library dictionary (dword)
 *	- number of 512-byte blocks in the dictionary (word)
 *	- random stuff (length - 6 bytes) of no interest.
 */
#define MO_LHEADR   0xf0

/******************************************************************************
 *
 *		      OTHER EXTERNAL DEFINITIONS
 *
 ******************************************************************************/
extern Vector	segments,   /* SegDesc *'s for segment indices for this file */
#define MS_MIN_SEGMENT	((SegDesc *)256)
	    	groups,	    /* GroupDesc *'s for group indices for this file */
	    	names,	    /* ID's for name indices for this file */
	    	externals;  /* ObjSym vptr's for external symbols for file (pass
			     * 2) unless symbol is undefined, in which case it
			     * contains the ID with MO_EXT_UNDEFINED set.
			     * Contains ID's during pass 1, with
			     * MO_EXT_IN_LIB set if the external's from a
			     * library. */
extern Vector	segSizes;   /* Vector of long segment sizes, for pass 2 only */
extern ID   	msobj_CurFileName;
extern ID   	msobj_FirstFileName;

/*
 * Fixup thread info.
 */
typedef union {
    GroupDesc   *group; 	/* Group descriptor, if FFM_GROUP */
    SegDesc 	*segment;	/* Segment descriptor, if FFM_SEGMENT */
    VMPtr	external;	/* ObjSym in "symbols", if FFM_EXTERNAL */
    word	absolute;	/* Absolute segment, if FFM_ABSOLUTE */
} MSFixData;

/**************************************************************
  	these enums are used by the relocation module to
	know when to take floating point code and turn it into
	software interrupts
***************************************************************/
typedef enum	
{
    	FPED_FALSE,
	FPED_TRUE,
	FPED_FIARQQ,
	FPED_FISRQQ,
	FPED_FICRQQ,
	FPED_FIERQQ,
	FPED_FIDRQQ,
    	FPED_FJARQQ,
	FPED_FJSRQQ,
	FPED_FJCRQQ,
	FPED_FJERQQ,
	FPED_FIWRQQ
} FloatingPointExtDef;

typedef	struct _MSThread {
    byte    	fixup;	    /* Fixup data byte w/fields to merge into fixup
			     * using the thread */
    byte    	valid;      /* Bit MST_* non-zero if thread is valid for 
			     * frame/target */
    MSFixData	data[2];
} MSThread;

#define MS_MAX_THREADS	4   	/* Number of fixup "threads" allowed for in an
				 * object file... */

extern MSThread	    msThreads[MS_MAX_THREADS];
#define MST_FRAME   0
#define MST_TARGET  1

#define MO_EXT_IN_LIB	 0x00000001 /* Pass 1 -- externals entry is for a
				     * symbol in a library. */
#define MO_EXT_UNDEFINED 0x00000001 /* Pass 2 -- externals entry is ID of
				     * undefined symbol */

extern byte 	*msobjBuf;
extern unsigned	msobjBufSize;

extern byte 	MSObj_ReadRecord(FILE *stream, word *datalenPtr, int *recNoPtr);
extern void 	MSObj_Init(FILE *);

/*
 * Macros to extract words in Intel byte-order without running afoul of
 * compiler optimizers.
 */
#define MSObj_GetWordImm(bp) \
    ((bp) += 2, ((bp)[-2] | ((bp)[-1] << 8)))

#define MSObj_GetWord(var, bp) \
    (var) =  *(bp)++; (var) |= *(bp)++ << 8

#define MSObj_GetDWord(var, bp) \
    (var) = (bp)[0] | ((bp)[1] << 8) | ((bp)[2] << 16) | ((bp)[3] << 24); \
    (bp) += 4

/*
 * Extract an "index" field from an object record. bp is a pointer to the start
 * of the index field. Evaluates to the index, with bp advanced beyond the
 * field.
 */
#define MSObj_GetIndex(bp) \
    (((*(bp))&0x80) ? ((bp) += 2, ((((bp)[-2]&0x7f)<<8) | (bp)[-1])) : *(bp)++)

extern SegDesc	    *MSObj_GetSegment(byte **bufPtr);
extern GroupDesc    *MSObj_GetGroup(byte **bufPtr);
extern ID   	    MSObj_GetName(byte **bufPtr);
extern VMPtr	    MSObj_GetExternal(byte **bufPtr);
extern int  	    MSObj_DecodeFixup(const char *file,
				      SegDesc *sd,
				      byte **bpPtr,
				      word *fixLocPtr,
				      byte *fixDataPtr,
				      MSFixData *targetPtr,
				      MSFixData *framePtr);

extern void 	    MSObj_DecodeFrameOrTarget(byte fixupMethod,
					      byte **bpPtr,
					      MSFixData *dataPtr);
extern int 	    MSObj_DecodeSegDef(const char *file,
				       byte rectype,
				       byte *data,
				       int *typePtr,
				       int *alignPtr,
				       ID *namePtr,
				       ID *classPtr,
				       word *framePtr,
				       long *sizePtr);

extern ID   	    MSObj_MakeString(void);

extern void 	    MSObj_AddAnonStruct(ObjSym *os,
					VMBlockHandle typeBlock,
					int size,
					int nfields);

extern ObjType	    *MSObj_AllocType(VMBlockHandle, word *);
extern word 	    MSObj_CreateArrayType(VMBlockHandle typeBlock,
					  word base,
					  int alen);


/*
 * Functions for saving object records around until the whole file has been
 * processed.
 */
typedef struct _MSSaveRecLinks {
    struct  _MSSaveRec	*next;
    struct  _MSSaveRec 	*prev;
} MSSaveRecLinks;


typedef struct _MSSaveRec {
    MSSaveRecLinks  links;
    byte    	    type;   	/* Record type */
    word    	    len;    	/* Record length (excluding checksum, which
				 * isn't here anyway...) */
    byte    	    *data;  	/* Data for record */
} MSSaveRec;

typedef struct _MSSaveFixupRec {
    MSSaveRecLinks  links;
    dword    	    startOff;
    dword    	    endOff;
    MSThread	    threads[MS_MAX_THREADS];
    byte    	    data[LABEL_IN_STRUCT];
} MSSaveFixupRec;

extern MSSaveRecLinks pubHead;	    /* predefined list for saving PUBDEF
				     * records */

extern void 	    MSObj_SaveRecord(byte   rectype,
				     word   reclen,
				     MSSaveRecLinks *head);

extern void 	    MSObj_FreeSaved(MSSaveRecLinks *head);

extern void 	    MSObj_SaveFixups(dword   startOff,
				     word   reclen,
				     word   datalen,
				     MSSaveRecLinks *head);

extern void 	    MSObj_FreeFixups(MSSaveRecLinks *head);

/*
 * Pre-processor function for object records. If returns TRUE, function
 * has completely handled the object record.
 */
typedef int 	    MSObjCheck(const char *file, byte rectype, word reclen,
			       byte *data, int pass);
typedef void	    MSObjFinish(const char *file, int happy, int pass);

extern MSObjCheck   *msobjCheck;
extern MSObjFinish  *msobjFinish;

extern MSObjCheck   CV_Check,
		    MSObj_DefCheck,
		    Borland_Check;

extern MSObjFinish  CV_Finish,
		    Pass1MS_Finish,
		    Pass2MS_Finish,
	    	    Borland_Finish;

extern unsigned Pass1MS_CountRels(const char *file,
				  byte	    rectype,
				  SegDesc   *sd,
				  word	    startOff,
				  word	    reclen,
				  byte	    *data);
extern void Pass1MS_EnterExternal(ID name);
extern void Pass1MS_ProcessObject(const char *file,
				  FILE	    *f);

extern void Pass2MS_ProcessObject(const char *file,
				  FILE	    *f);

#define DONT_RETURN_ORDER ((int *)NULL)

extern char *MSObj_DecodeLMemName(char *segName, int *order);

extern int MSObj_GetLMemSegOrder(SegDesc *seg);

#define LMEM_HEADER 	    0
#define LMEM_HANDLES	    1
#define LMEM_HEAP   	    2

#include    "lmem.h"

/*
 * To properly determine the actual size of the heap portion of an lmem troika,
 * we need to generate the handle table for the thing and re-layout the heap,
 * adding a size word before, and longword padding after each chunk. The
 * handle table, of course, comes in as a bunch of zeroes with relocations
 * to the appropriate places in the heap segment, so we have to save all the
 * fixup records for the handles segment as well. LMem segments are defined in
 * one object file only, and things in the handles segment refer exclusively
 * to things in the heap segment, so we can perform all necessary relocations
 * at the end of reading the object file to obtain at least the offsets of the
 * chunks in the heap segment, allowing us to calculate their size and layout
 * the heap properly.
 *
 * The array of pointer to MSObjLMemData structures persists from pass1 to pass2
 * so we know what the handle table looked like before we re-laid out the heap.
 */
typedef struct {
    SegDesc 	    *handles;	    /* Segment w/handle table */
    word    	    heapSize;	    /* Original heap size */
    MSSaveRecLinks  fixups;	    /* Chain of fixup records, in address
				     * order */
    word    	    handleData[LABEL_IN_STRUCT];
  				    /* Block holding the handle table, as
				     * read in from the object file */
} MSObjLMemData;

#define LMEM_SIZE_SIZE    2	    /* Size of the size word. This is applied
				     * to all relocations within the handles
				     * segment of an lmem troika */

extern Vector	lmemSegs;

extern Boolean MSObj_PerformRelocations(const char *file,
					byte *data,
					byte *bp,
					byte *endRecord,
					SegDesc *sd,
					word baseOff,
					int pass,
					byte **nextRelPtr);

extern word MSObj_CalcIDataSize(byte   **bufPtr);

extern void MSObj_ExpandIData(byte **dataPtr,	    /* Iterated data block */
			      byte **bufPtr);	    /* Destination buffer */

extern FloatingPointExtDef MSObj_IsFloatingPointExtDef(ID name);
extern Boolean MSObj_IsWatcomFloatingPoint(ID name);
#endif /* _MSOBJ_H_ */
