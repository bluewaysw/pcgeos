/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Object File Reading
 * FILE:	  obj.h
 *
 * AUTHOR:  	  Adam de Boor: Oct  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/ 2/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header for users of the Obj function(s)
 *
 *
 * 	$Id: obj.h,v 2.10 95/05/17 09:08:04 adam Exp $
 *
 ***********************************************************************/
#ifndef _OBJ_H_
#define _OBJ_H_

#include    <objfmt.h>

/*
 * Typedef of procedure to load an object file during pass1 or pass2
 */
typedef void ObjLoadProc(const char *file, genptr handle);

typedef enum {
    OBJ_VM, 	/* Standard VM file object */
    OBJ_MS, 	/* Microsoft object file */
    OBJ_MSL,	/* Microsoft library */
} ObjFileType;

extern ObjLoadProc  Pass1VM_Load;
extern ObjLoadProc  Pass2VM_Load;
extern ObjLoadProc  Pass1MS_Load, Pass2MS_Load;
extern ObjLoadProc  Pass1MSL_Load, Pass2MSL_Load;
extern Boolean	Pass1VM_FileIsNeeded(const char *file, void *handle);

/*
 * Open an object file. Returns a VMHandle if OBJ_VM or a FILE * if OBJ_MS.
 *
 * XXX: This won't work on the PC (VMHandle will be a word, after all).
 */
extern VMHandle	Obj_Open(const char *file,
		  short  	*statusPtr,
		  ObjFileType	*typePtr,
		  int	    	justChecking);

/*
 * Compare two PC/GEOS type descriptions for equality.
 */
extern int Obj_TypeEqual(VMHandle   f1,	    /* VM file containing any IDs for
					     * type1 */
			 void  	    *t1Base,/* Base of block containing first
					     * type */
			 word  	    t1,     /* Type descriptor 1 */
			 VMHandle   f2,	    /* VM file containing any IDs for
					     * type2 */
			 void  	    *t2Base,/* Base of block containing second
					     * type */
			 word  	    t2);    /* Type descriptor 2 */

extern SegDesc *Obj_FindFrameVM(const char    *file,  /* File name (for PRIVATE
					     * segments) */
			 VMHandle   fh,	    /* Object file */
			 ObjHeader  *hdr,   /* Header for same */
			 word	    offset);/* Offset of descriptor w/in header
					     * block */
extern void 	Obj_PrintType(FILE	    *stream,
		   VMHandle file,
		   void     *base,
		   word     type);

extern unsigned Obj_TypeSize(word type, void *base, int mayBeUndefined);
extern int  	Obj_EnterTypeSyms(const char *file,   	/* File name */
				  VMHandle fh,      	/* Object file handle */
				  SegDesc *sd,      	/* Internal segment
							 * descriptor */
				  VMBlockHandle	next,	/* First block in chain
							 * of type/undefined
							 * symbols */
				  int flags);	    	/* TRUE to enter all
							 * symbols, FALSE to
							 * enter only top-level
							 * symbols (i.e. not
							 * structure fields) */
#define OETS_TOP_LEVEL_ONLY 	    0x0001  /* Enter top-level symbols only;
					     * this doesn't include structure
					     * fields */
#define OETS_RETAIN_ORIGINAL	    0x0002  /* Retain all the memory in
					     * the chain of symbols */

extern int  	Obj_IsAddrSym(ObjSym *os);

/*
 * The segments are related if:
 *	- s2 is subsumed segment and s1 is either a full-fledged segment or
 *	  is also a subsumed segment and the two segments are in the same
 *    group (this handles both two segments subsumed by the same group
 *	  and having s2 be subsumed by a group whose name was then changed
 *	  to correspond to one of the group's segments, as is done for
 *	  geodes and all three groups in the kernel)
 *	- s1 is actually a group descriptor of which s2 is a part
 *	- the name of s2's group matches s1's name (this again handles the
 *	  case where a promoted group changes its name to match one of its
 *	  constituent segments).
 *	- both s1 and s2 are part of the same unpromoted group
 */
#define Obj_CheckRelated(s1, s2)  \
    ((((((SegDesc *)(s1))->type == S_SEGMENT) || \
       (((SegDesc *)(s1))->type == S_SUBSEGMENT)) && \
      (((SegDesc *)(s2))->type == S_SUBSEGMENT) && \
      (((SegDesc *)(s1))->group == ((SegDesc *)(s2))->group)) || \
     (((SegDesc *)(s2))->group == (GroupDesc *)((SegDesc *)(s1))) || \
     (((SegDesc *)(s2))->type != S_GROUP && \
      ((SegDesc *)(s2))->group && \
      (((SegDesc *)(s2))->group->name == ((SegDesc *)(s1))->name)) || \
     ((((SegDesc *)(s1))->type != S_GROUP) && \
      ((SegDesc *)(s1))->group && \
      (((SegDesc *)(s1))->group->type == S_GROUP) && \
      (((SegDesc *)(s1))->group == ((SegDesc *)(s2))->group)) || \
     (((SegDesc *)(s1)) == ((SegDesc *)(s2))))

#endif /* _OBJ_H_ */
