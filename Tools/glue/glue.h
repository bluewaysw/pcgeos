/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools/Glue -- Common definitions
 * FILE:	  glue.h
 *
 * AUTHOR:  	  Adam de Boor: Sep 27, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/27/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Common definitions for all parts of Glue.
 *
 *
 * 	$Id: glue.h,v 3.25 95/11/08 18:13:40 adam Exp $
 *
 ***********************************************************************/
#ifndef _GLUE_H_
#define _GLUE_H_

#include    <config.h>
#include    <assert.h>

#include    <st.h>
#include    <stdio.h>
#include    <stdarg.h>
#include    <compat/string.h>

#include    <os90.h>

#include    <objfmt.h>
#include    <malloc.h>
typedef int 	Boolean;
#ifndef FALSE
#define FALSE (0)
#define TRUE (!FALSE)
#endif

#define TEST_NRELS 0

#define DEFCOPYRIGHT   "Copyright GeoWorks 1991"
#define COPYRIGHT_SIZE	32  /* Maximum length of a copyright notice (dictated
			     * by the GFH_reserved field of the GEOS file
			     * header */
extern char    	copyright[];	/* Copyright notice to use, where appropriate */

extern int  	discardableDgroup;  	/* Flag to give an error if a segment
					 * or call relocation to dgroup is
					 * encountered. */
extern int    	mapSharableRelocations;	/* Flag to map relocations
					 * from shared to non-shared
					 * resources to be mapped
					 * to resource IDs */
extern int  	noLMemLineNumbers;  	/* Flag to not output line numbers for
					 * lmem segments, thus reducing the
					 * number of blocks required for a
					 * symbol file */

extern int  	geosRelease;	/* Major number of PC/GEOS release for which
				 * we're linking */

extern	int 	dbcsRelease;	/* non-zero if DBCS release */

#include <compat/stdlib.h>

#ifndef TRUE
#define FALSE	0
#define TRUE	(!FALSE)
#endif

#if defined(sparc) || defined(mc68000)
/*
 * Swap a word or longword in-place. May be used with post-increment.
 */
#define swapsp(p) { unsigned char *_cp = (unsigned char *)(p), _c; \
		     _c = *_cp++; _cp[-1] = *_cp; *_cp = _c; }
#define swaplp(p) { unsigned char *_cp = (unsigned char *)(p), _c; \
		     c = _cp[3]; _cp[3] = _cp[0]; _cp[0] = c; \
		     c = _cp[2]; _cp[2] = _cp[1]; _cp[1] = c; }

/*
 * Swap a word or longword as a value, returning the value swapped.
 */
#define swaps(s)    ((((s) << 8) | (((unsigned short)(s)) >> 8)) & 0xffff)
#define swapl(l)    (((l) << 24) | \
		     (((l) & 0xff00) << 8) | \
		     (((l) >> 8) & 0xff00) | \
		     (((unsigned long)(l)) >> 24))
#define DOSWAP

#else
#define swapsp(p) (*(p))
#define swaplp(p) (*(p))
#define swaps(s) (s)
#define swapl(l) (l)
#endif

typedef enum {
    S_GROUP,	    /* Descriptor actually a GroupDesc */
    S_SEGMENT,	    /* Descriptor for full-fledged segment */
    S_SUBSEGMENT    /* Descriptor for subsumed segment */
} SegType;

/*
 * Internal data kept for each group. foff and offset are for exe and com
 * relocation's sake.
 */
typedef struct {
    ID	    	    name;   	/* Group name */
    SegType 	    type;
    long    	    foff;   	/* Offset of first-segment data in output
				 * file */
    int	    	    offset; 	/* Offset of first-Segment descriptor in map
				 * block */
    int	    	    flags;  	/* Flags from object file/resource allocation
				 * flags */
    union {
	int 	    	resid;	    /* Resource ID if groups didn't subsume
				     * their segments in a geode */
	int	    	frame;      /* Frame number (exe) of group */
	VMBlockHandle	block;	    /* VM Handle (vm) */
    }	    	    pdata;

    int	    	    numSegs;	/* Number of segments in the group */
    struct _SegDesc **segs; 	/* Descriptors for same */
} GroupDesc;

/*
 * Internal data kept for each segment.
 */
typedef struct _SegDesc {
/* Data common with GroupDesc */
    ID	    	    name;   	/* Segment name */
    SegType 	    type;
    long    	    foff;   	/* Offset of segment data in output file */
    int	    	    offset; 	/* Offset of Segment descriptor in map block */
    int	    	    flags;  	/* Flags from object file/resource allocation
				 * flags */
    union {
	int	    	resid;      /* Resource ID (geode) */
	int 	    	frame;	    /* Frame number (exe) */
	VMBlockHandle	block;	    /* VM Handle (vm) */
	int	    	library;    /* Library record (geode if segment is
				     * for a library) */
    }	    	    pdata;  	/* Data "private" to file-output module */
/* Segment-specific data */
    int	    	    nodata; 	/* Set if segment doesn't actually have any
				 * room in the executable, we're just faking
				 * it for the sake of relocations and the
				 * like, where we need to know how much of
				 * nothing has made it into the executable
				 * before this object file is loaded */
    long    	    nextOff;	/* Offset of next segment piece */
    ID	    	    class;  	/* Segment class */
    int	    	    nrel;   	/* Number of run-time relocations necessary */
    long    	    roff;   	/* Offset of relocations for segment in output
				 * file */
    int	    	    combine;	/* Combine type */
    int	    	    alignment;	/* Required alignment for each piece */
    int	    	    size;   	/* Size so far */
    VMBlockHandle   lineMap;	/* Map block for the thing */
    VMBlockHandle   lineH;  	/* First block of line info */
    VMBlockHandle   lineT;  	/* Last block of line info */
    VMBlockHandle   addrH;  	/* First block of syms with addresses */
    VMBlockHandle   addrT;  	/* Last block of syms with addresses */
    VMBlockHandle   addrMap;	/* Map of addr syms created by InterPass */
    VMBlockHandle   symH;   	/* First block of other syms */
    VMBlockHandle   symT;   	/* Last block of other syms */
    int	    	    symTNext;	/* Offset of next slot to use in symT */
    int	    	    typeNext;	/* Offset into type block in symT of first
				 * available type slot. This is 0 if shouldn't
				 * use associated type block */
    VMBlockHandle   syms;   	/* Symbol table for segment (ID -> symbol
				 * mapping, as opposed to the chains of
				 * symbols, above) */
    GroupDesc	    *group; 	/* Containing group, if any */
    int	    	    grpOff; 	/* Offset of segment in group, if any */
    const char 	    *file;  	/* Object file name for PRIVATE segments */
    int	    	    doObjReloc:1,	/* Non-zero if should map segment
					 * relocations into object relocations
					 * within this segment */

		    isObjSeg:1,	    	/* Non-zero if this is the header
					 * segment of an lmem trio and it's
					 * for an object block, so doObjReloc
					 * should be set for the LMEM_HEAP
					 * segment of the triumverate */

		    hasProfileMark:1,	/* Non-zero if profile mark seen, so
					 * segment shouldn't be discardable */

		    isClassSeg:1;	/* Non-zero this segment shouldn't
					 * be merged with dgroup, since it's
					 * designed to contain things (like
					 * ClassStructs) that don't want to
					 * be in dgroup, for XIP's sake. */

/* add 16 elements at a time */
#define CALL_ARRAY_STEP 16
#define CALL_ARRAY_MASK 15
    word    	    *callArray;
    	    	    	    	    	/* an array of offsets where a 0x9a
					 * is found at the end of an object
					 * record */
} SegDesc;

typedef	struct	_segInfo 
{
    ID	    segID;  	    	/* used to order the segments correctly */
} SegInfo;


/* segment.c */
extern SegDesc	    	*Seg_AddSegment(const char *file,
					ID name,
					ID class,
					int type,
					int align,
					int flags);
extern GroupDesc    	*Seg_AddGroup(const char *file,
				      ID name);
extern void 	    	Seg_EnterGroupMember(const char *file,
					     GroupDesc *gd,
					     SegDesc *sd);
extern SegDesc	    	*Seg_Find(const char *file, ID name, ID class);
extern GroupDesc    	*Seg_FindGroup(const char *file, ID name);
extern SegDesc	    	*Seg_FindPromotedGroup(SegDesc *sd);

extern int  	    	seg_NumSegs;
extern SegDesc	    	**seg_Segments;
extern SegInfo	    	*seg_Info;
extern int  	    	seg_NumGroups;
extern GroupDesc    	**seg_Groups;
extern int  	    	seg_NumSubSegs;
extern SegDesc	    	**seg_SubSegs;

extern SegDesc	    	*seg_FarCommon, *seg_NearCommon;

typedef struct _SegAlias {
    ID	    name;
    ID	    class;
    int	    aliasMask;
#define SA_NEWNAME	0x0001
#define SA_NEWCLASS    	0x0002
#define SA_NEWCOMBINE  	0x0004
#define SA_NEWALIGN 	0x0008
    ID	    newName;
    ID	    newClass;
    int	    newCombine;
    int	    newAlign;
} SegAlias;

extern SegAlias	    	*seg_Aliases;
extern int  	    	seg_NumAliases;
extern void 	    	Seg_AddAlias(SegAlias *);

/* main.c */
extern int  	    	isEC;       /* Non-zero if producing an error-checking
				     * geode */
extern int  	    	mustBeGeode;/* Set non-zero if output file must
				     * be a geode. Determined during first
				     * pass */

extern VMHandle	    	symbols;    /* File for symbol info */
extern VMBlockHandle	strings;    /* String table for sym file */

extern int  	    	entryGiven; /* TRUE if entry point has been given */

extern int  	    	numAddrSyms;/* Count of total number of symbols
				     * with addresses defined by program.
				     * Can be used to size sorting arrays
				     * for producing map files... */
extern SegDesc	    	*globalSeg; /* Descriptor for the nameless global
				     * segment. */

extern void AddSrcMapEntry(ID   fileName, SegDesc *sd,
			   int start, int end);

extern void RenameFileSrcMapEntry(ID   oldName, ID newName);

extern int ustrncmp(const char *s1, const char *s2, unsigned n);

/*
 * Error/warning notification.
 */
typedef enum {
    NOTIFY_ERROR, NOTIFY_PREFACE,
    NOTIFY_WARNING,
    NOTIFY_DEBUG,
} NotifyType;

    
extern void Notify(NotifyType why, char *fmt, ...);
extern void NotifyInt(NotifyType why, char *fmt, va_list args);
extern int  errors; 	    	    /* Count of errors so far */

extern void Pass2_RelocError(SegDesc *sd, int off, char *fmt, ...);
extern void Pass2_RelocWarning(SegDesc *sd, int off, char *fmt, ...);

/*
 * Special form of assert() for second pass. If the assertion fails, not
 * only are the file and line within glue printed, but also the file and line
 * within the program.
 *
 * sd is the SegDesc * for the segment in which the relocation is taking place.
 * off is the offset of the relocation within the segment *for the current
 * object file*, i.e. it has not itself been relocated.
 * COMMENT: the abort() was put into a comma expression so that the return
 * type is actually an int as HIGHC bitched otherwise....
 */
#define pass2_assert(expr, sd, off) \
	if (!(expr)) {\
	 Pass2_RelocError((sd), (off), \
			  "Failed assertion " \
			  #expr \
			  " at line %d of `" __FILE__ "'.", __LINE__); \
	  abort();}
#endif /* _GLUE_H_ */
