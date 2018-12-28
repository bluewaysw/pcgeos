/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Symbol Definitions
 * FILE:	  sym.h
 *
 * AUTHOR:  	  Adam de Boor: Oct 21, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/21/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for things that play with symbols.
 *
 * 	$Id: sym.h,v 2.7 96/07/08 17:30:50 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _SYM_H_
#define _SYM_H_

#include    <objfmt.h>

#define	OSYM_UNKNOWN	0   /* ObjSym type to use if the type of symbol is
			     * unknown when the object file is read in */

extern VMBlockHandle	    Sym_Create(VMHandle file);
extern void 	    	    Sym_Close(VMHandle file, VMBlockHandle table);
extern void                 Sym_Destroy (VMHandle file, VMBlockHandle table);
extern void 	    	    Sym_Enter(VMHandle 	    file,
				      VMBlockHandle table,
				      ID    	    id,
				      VMBlockHandle symBlock,
				      word  	    symOff);
extern int  	    	    Sym_Find(VMHandle	    file,
				     VMBlockHandle  table,
				     ID	    	    id,
				     VMBlockHandle  *symBlockPtr,
				     word   	    *symOffPtr,
				     int    	    globalOnly);
extern int  	    	    Sym_FindWithFile(VMHandle	    file,
					     const char*    fileName,
				     	     VMBlockHandle  table,
				     	     ID	    	    id,
				     	     VMBlockHandle  *symBlockPtr,
				     	     word   	    *symOffPtr,
				     	     int    	    globalOnly);

extern int  	    	    Sym_FindWithSegment(VMHandle	file,
						ID	    	id,
						VMBlockHandle  	*symBlockPtr,
						word   	    	*symOffPtr,
						int    	    	globalOnly,
						SegDesc	    	**sdPtr);
extern void 	    	    Sym_EnterUndef(VMHandle file,
					   VMBlockHandle table,
					   ID id,
					   ObjSym *os,
					   word symOff,
					   VMHandle tfile,
					   VMBlockHandle types);

extern void 	    	    Sym_AllocCommon(SegDesc *sd);

/*
 * Chain of undefined symbols, exported for use by static-linked library readers
 */
typedef struct _SymUndef {
    struct _SymUndef   *next;  	/* Next undefined symbol */
    VMBlockHandle   table;  	/* Expected symbol table (error if not and
				 * table doesn't belong to global scope) */
    ObjSym  	    sym;    	/* Symbol itself */
    ObjType 	    types[LABEL_IN_STRUCT];
  				/* Start of any copied type descriptions */
} SymUndef;

extern SymUndef	*symUndefHead;

#endif /* _SYM_H_ */
