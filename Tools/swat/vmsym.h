/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- VM-format symbol file thingamabobs
 * FILE:	  vmsym.h
 *
 * AUTHOR:  	  Adam de Boor: Jan 31, 1990
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/31/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Common definitions for things that read VM-format symbol files.
 *
 *
* 	$Id: vmsym.h,v 4.3 97/04/18 17:11:01 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _VMSYM_H_
#define _VMSYM_H_

#include    <objfmt.h>

extern ID   SymLookupIDLen(const char *, int, Sym);
extern ID   SymLookupID(const char *, Sym);
extern void SymUnlockID(Sym, ID);
extern char *SymLockID(Sym, ID);
extern ObjSym	*SymLock(Sym);

extern Boolean	Sym_SearchTable(VMHandle file, VMBlockHandle table,
				ID id, VMBlockHandle *blockPtr,
				word *offsetPtr, word symfileFormat);

#ifndef VMUnlock
extern void SymUnlock(Sym);
#else
#define SymUnlock(Sym)
#endif

typedef struct {
    VMHandle	    file;
    VMBlockHandle   block;
    word    	    offset;
} SymToken;

#define SymFile(sym)	(((SymToken *)&(sym))->file)
#define SymBlock(sym)	(((SymToken *)&(sym))->block)
#define SymOffset(sym)	(((SymToken *)&(sym))->offset)

#endif /* _VMSYM_H_ */
