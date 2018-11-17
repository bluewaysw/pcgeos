/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Fixup Data Definitions
 * FILE:	  fixup.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 12, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/12/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Description of internal fixup data
 *
 *
 * 	$Id: fixup.h,v 1.15 94/10/13 18:00:00 john Exp $
 *
 ***********************************************************************/
#ifndef _FIXUP_H_
#define _FIXUP_H_

#include    "expr.h"

/*
 * These first three must be first -- their order is used by Fix_Write
 */
#define FIX_LOW_OFFSET	0   /* Value is low part of symbol offset */
#define FIX_HIGH_OFFSET	1   /* Value is high part of symbol offset */
#define FIX_OFFSET  	2   /* Value is full symbol offset */
#define FIX_SEGMENT 	3   /* Value required is segment address of
			     * segment/group */
#define FIX_HANDLE  	4   /* Value required is handle ID of segment/group */
#define FIX_RESID   	5   /* Value required is resource ID of
			     * segment/group */
#define FIX_CALL    	6   /* Far call (deal with movable dest, etc) */
#define FIX_ENTRY   	7   /* Value required is entry point number */
#define FIX_METHCALL	8   /* Static method call to object of
			     * class given by symBlock:symOff */
#define FIX_SUPERCALL	9   /* Static method call, but class is
			     * superclass of that of the object */
#define FIX_PROTOMINOR  10  /* Far call (deal with movable dest, etc) */

#define FIX_BOGUS   	15  /* Data should not need fixing up... */

#define FIX_SIZE_BOGUS	-1
#define FIX_SIZE_BYTE	0
#define FIX_SIZE_WORD	1
#define FIX_SIZE_DWORD	2

typedef struct {
    unsigned 	type:4,	    /* One of the FIX constants, above */
		size:2,     /* Size of data being fixed (FIX_SIZE_foo) */
		pcrel:1,    /* Set if fixup's pc-relative (w.r.t. addr after
			     * value */
		fixed:1;    /* Set if target must be in fixed memory */
    SymbolPtr  	sym;	    /* Symbol with respect to which relocation is to be
			     * performed (segment/group for FIX_SEGMENT and
			     * FIX_HANDLE) */
    SymbolPtr  	frame;	    /* Frame of reference for relocation */
}	FixDesc;

typedef enum {
    FR_ERROR,	    /* Error in operands -- discard fixup */
    FR_UNDEF,	    /* Value returned by procedures during pass 1 if they
		     * find an undefined symbol in their operands */
    FR_DONE,	    /* Fixup complete -- don't call again */
    FR_OPTIM,	    /* Change fixup to be optimization only (undefineds
		     * resolved) */
    FR_FINAL,	    /* Change fixup to be FC_FINAL (call during pass 4 for
		     * error-checking purposes) */
} FixResult;

typedef FixResult   FixProc(int	    *dotPtr,	/* IN/OUT: Address of datum.
						 * Returns address after
						 * datum */
			    int	    prevSize,	/* Size from previous pass */
			    int	    pass,   	/* Current pass:
						 *  1 = source reading
						 *  2 = resolve undefined
						 *  3 = optimization
						 *  4 = final */
			    FExpr   expr1,  	/* Operand 1 */
			    FExpr   expr2,  	/* Operand 2 */
			    Opaque  data);  	/* Arbitrary datum */
			 
typedef enum {
    FC_UNDEF,	    /* Resolve on pass 2 */
    FC_OPTIM,	    /* For optimization only (passes 3 and 4) */
    FC_FINAL,	    /* Can't be optimized, but should be called during pass 4
		     * for error-checking purposes */
} FixClass;


/*
 * Fix_Register registers an internal fixup to be dealt with on a later pass.
 * expr1 and expr2 are copied to private storage and may be NULL if not needed.
 * data is an arbitrary piece of data that will be passed to the handling
 * function.
 *
 * The FixProc is expected to return a FixResult indicating what should happen
 * to the fixup. If the return is FR_ERROR, the fixup is discarded. If
 * the return is FR_DONE, the fixup is assumed handled, any size change is
 * duly noted and the FixProc isn't called again. If the return is FR_OPTIM,
 * a return only valid during pass 2, the fixup is promoted to be an FC_OPTIM
 * fixup and the function will be called during pass 3 and pass 4.
 *
 * During pass 3, the functions for all FC_OPTIM fixups are called repeatedly
 * until no fixup indicates a size change (or until a limit on the number of
 * passes is reached, in case of some pathological setup). During this pass,
 * the function should probably not store anything, just resize its data
 * to be correct (this is to avoid unnecessary stores, should the operand
 * symbols change so as to necessitate further changes).
 *
 * Pass 4 is the pass during which final values are to be stored for each
 * fixup. The fixup is not allowed to change size during this pass. Any attempt
 * to do so will cause Esp to abort. Errors may be signaled in the normal
 * manner, however, should the data not be able to fit in the size previously
 * returned.
 */
extern void Fix_Register(FixClass   class,  	/* Class of fixup */
			 FixProc    *func,  	/* Function to be called */
			 int 	    addr,   	/* Address of beginning of
						 * data to be fixed */
			 int	    size,   	/* Current size of data */
			 FExpr 	    expr1, 	/* Operand 1 */
			 FExpr 	    expr2, 	/* Operand 2 */
			 Opaque	    data);  	/* Arbitrary datum */

/*
 * Fix_Enter creates a fixup to be passed to the linker. The FixDesc in
 * result should be set up properly. addr is the offset within the current
 * segment for which the fixup is to be posted. ref is the "reference address"
 * of the relocation. For data, it is just the base of the datum. For
 * relocations in an instruction, however, it is the base of the instruction.
 * This allows us to determine what relocations are really affected by a change
 * in size by an instruction.
 */
extern void Fix_EnterSegment(SymbolPtr	seg,
			     FExprResult result,
			     int 	addr,
			     int    	ref);
#define Fix_Enter(result, addr, ref) Fix_EnterSegment(curSeg, (result), (addr), (ref))

/*
 * Initialize private data for the segment
 */
extern void Fix_Init(SymbolPtr	seg);

/*
 * Write fixups for a segment to the output file. Returns the block handle of
 * the first block in the chain of relocation blocks.
 */
extern VMBlockHandle Fix_Write(SymbolPtr	seg);

/*
 * Convert a single external fixup to an object-file relocation.
 */
extern int  Fix_OutputRel(SymbolPtr 	seg,
			  int	    	addr,
			  FixDesc   	*desc,
			  Opaque    	rel);

/*
 * Check to see if a fixup exists.
 * Returns 'TRUE' if the fixup exists, 'FALSE' otherwise.
 */
extern int  Fix_Find(FixProc	*func,	/* Callback for fixup */
		     int    	 addr,	/* Address of fixup */
		     int    	 size);	/* Size of the fixup */

extern void Fix_Adjust(SymbolPtr	sym, /* Segment needing adjustment */
		       int	    	addr, /* First affected address */
		       int	    	diff); /* Amount by which to adjust the fixups */

extern int Fix_Pass2(void);
extern int Fix_Pass3(void);
extern int Fix_Pass4(void);


#endif /* _FIXUP_H_ */
