/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- symbol maintenance.
 * FILE:	  sym.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 22, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Sym_Init    	    Initialize symbols for a patient
 *	Sym_Lookup  	    Look for a symbol by name or path
 *	Sym_LookupInScope   Look for a symbol by name in a scope
 *	Sym_LookupAddr	    Look for a symbol given a GeosAddr-equivalent
 *	Sym_Class   	    Return class of symbol
 *	Sym_Scope	    Return enclosing scope of symbol
 *	Sym_ForEach	    Iterate over all symbols in a scope
 *	Sym_Name	    Return name of symbol
 *	Sym_FullName	    Return full pathname of symbol
 *	Sym_GetVarData	    Retrieve data for SYM_VAR symbol
 *	Sym_GetTypeData	    Retrieve type description for SYM_TYPE symbol
 *	Sym_GetFuncData	    Retrieve data for SYM_FUNCTION symbol
 *	Sym_IsFar	    See if symbol is a FAR label/function
 *	Sym_IsWeird 	    See if stack frame for function is weird
 *	Sym_GetOnStackData  Retrieve list of registers, etc., on stack after
 *			    given SYM_ONSTACK label
 *	Sym_GetEnumData	    Retrieve same
 *	Sym_GetAbsData	    Get value of an absolute symbol
 *	Sym_GetFieldData    Get base type for structure field
 *	Sym_Patient 	    Get the patient for a symbol
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/22/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This module is responsible for the maintenance of symbols in all
 *	patients, including the kernel/loader.
 *
 *	This module is somewhat twisted, dealing with both symbols created
 *	in local memory and those found in symbol files for the various
 *	patients.
 *
 *	The outside world (read: the rest of Swat) deals only with Sym tokens
 * 	and talks to us to get info about symbols. We, however, manipulate
 *	SymToken structures. These things contain a (file,block,offset) triple
 *	in the case of file-resident symbols. For memory-resident symbols,
 *	the block is 0 and the file is pointer to the in-core symbol,
 *	whose type is one of the structures detailed below.
 *
 *	Since symbols can only be defined w/in modules (code or data),
 *	they are grouped into trees based on the module in which they
 *	reside. The SYM_MODULE symbols are in turn children of a single
 *	SYM_GLOBAL that exists for each patient. SYM_MODULE symbols have
 *	no enclosing scope. If a symbol is sought by name for a patient and
 *	cannot be found in the current module, the search begins from the
 *	SYM_GLOBAL symbol and works down. The SYM_GLOBAL lists the module
 *	symbols from
 *	    - the patient
 *	    - all the libraries the patient uses and
 *	    - the kernel
 *	    - the loader
 *	as its subscopes.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: sym.c,v 4.39 97/04/18 16:45:37 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "hash.h"
#include "private.h"
#include "sym.h"
#include "type.h"
#include "ui.h"
#include "vector.h"
#include "vmsym.h"
#include "rpc.h"
#include "expr.h"
#include "var.h"
#include <compat/stdlib.h>
#include <compat/file.h>

#define size_t whifflesize_t
#include <stddef.h>
#undef size_t
#include <ctype.h>

#if defined(_MSDOS) || defined(_WIN32)
# include <share.h>
# ifndef __WATCOMC__
# include <dir.h>
# endif
#endif

extern char const gym_ext[];
extern int  gymResources;
extern char wrongNumArgsString[];
extern Sym  	Sym_LookupAddrExact (Handle handle, Address addr, int class);
extern Sym  	SymLookupAddr (Handle handle, Address addr, int class, int wantExact);

 	/* a place to cache the address of a class::msg lookup if the
	 * sym returned from Sym_LookupAddr is to some previous routine,
	 * this happens with gym files on non-exported methods
	 */
GeosAddr    cachedMethod;

/*
 * Mapping of symbol types into classes for quick reference during searching.
 */
static const struct {
    int	    	class;	    	/* Symbol classification (for narrowing
				 * searches) */
    char    	*name;	    	/* ASCII version of type */
}	symMap[] = {
    {0,	    	    	    	    	""}, 	    /* Nothing of type 0 */
    {SYM_TYPE,	    	    	    	"typedef"},  /* OSYM_TYPEDEF */
    {SYM_TYPE|SYM_SCOPE,	    	"struct"},   /* OSYM_STRUCT */
    {SYM_TYPE|SYM_SCOPE,	    	"record"},   /* OSYM_RECORD */
    {SYM_TYPE|SYM_SCOPE,	    	"etype"},    /* OSYM_ETYPE */
    {SYM_FIELD,	    	    	    	"field"},    /* OSYM_FIELD */
    {SYM_FIELD,	    	    	    	"bitfield"}, /* OSYM_BITFIELD */
    {SYM_ENUM,	    	    	    	"enum"},	    /* OSYM_ENUM */
    {SYM_ENUM,	    	    	    	"method"},   /* OSYM_METHOD */
    {SYM_ABS,	    	    	    	"const"},    /* OSYM_CONST */
    {SYM_VAR,	    	    	    	"var"},	    /* OSYM_VAR */
    {SYM_VAR,	    	    	    	"chunk"},    /* OSYM_CHUNK */
    {SYM_SCOPE|SYM_FUNCTION|SYM_LABEL,  "proc"},	    /* OSYM_PROC */
    {SYM_LABEL,	    	    	    	"label"},    /* OSYM_LABEL */
    {SYM_LABEL,	    	    	    	"loclabel"}, /* OSYM_LOCLABEL */
    {SYM_LOCALVAR,    	    	    	"locvar"},   /* OSYM_LOCVAR */
    {SYM_ONSTACK,    	    	    	"onstack"},  /* OSYM_ONSTACK */
    {SYM_SCOPE,	    	    	    	"blockstart"},/* OSYM_BLOCKSTART */
    {0,	    	    	    	    	"blockend"},/*OSYM_BLOCKEND No findee*/
    {SYM_TYPE,	    	    	    	"exttype"},  /* OSYM_EXTTYPE */
    {SYM_VAR,	    	    	    	"class"},    /* OSYM_CLASS */
    {0,	    	    	    	    	""}, 	    /* Nothing of type 21 */
    {SYM_VAR,	    	    	    	"masterclass"}, /* OSYM_MASTER_CLASS */
    {SYM_VAR,	    	    	    	"variantclass"},/*OSYM_VARIANT_CLASS */
    {0,	    	    	    	    	"binding"},/* OSYM_BINDING No findee */
    {SYM_SCOPE|SYM_MODULE,    	    	"module"},   /* OSYM_MODULE */
    {SYM_TYPE|SYM_SCOPE,	    	"union"},    /* OSYM_UNION */
    {SYM_LOCALVAR,   	    	    	"regvar"},   /* OSYM_REGVAR */
    {SYM_PROFILE,    	    	    	"profile"},  /* OSYM_PROFILE_MARK not
						      * supported yet */
    {0,	    	    	    	    	"rettype"},  /* OSYM_RETURN_TYPE no
	 					      * findee */
    {SYM_LOCALVAR,   	    	    	"locstatic"},/* OSYM_LOCAL_STATIC */
    {SYM_ENUM,	    	    	    	"vardata"},  /* OSYM_VARDATA */
};

extern	word	kernelInternalSymbols[];
extern	word	kcodeResID;

#define FIRST_INTERNAL_WITH_END 20
#define LAST_INTERNAL_WITH_END 48
static	char *kernelInternalSymbolNames[] = {
    	    	"kernelHasTable",
    	    	"tableSize",
		"currentThread",
		"geodeListPtr",
		"threadListPtr",
		"biosLock",
		"heapSem",
		"DebugLoadResource",
		"DebugMemory",
		"DebugProcess",
		"MemLock",
		"EndGeos",
		"BlockOnLongQueue",
		"FileReadFar",
		"FilePosFar",
		"sysECBlock",
		"sysECChecksum",
		"sysECLevel",
    	    	"systemCounter",
    	    	"errorFlag",
    	    	"ResourceCallInt",
    	    	"ResourceCallInt_end",
    	    	"FatalError",
    	    	"FatalError_end",
    	    	"SendMessage",
    	    	"SendMessage_end",
    	    	"CallFixed",
    	    	"CallFixed_end",
    	    	"ObjCallMethodTable",
    	    	"ObjCallMethodTable_end",
    	    	"CallMethodCommonLoadESDI",
    	    	"CallMethodCommonLoadESDI_end",
    	    	"ObjCallMethodTableSaveBXSI",
    	    	"ObjCallMethodTableSaveBXSI_end",
    	    	"CallMethodCommon",
    	    	"CallMethodCommon_end",
    	    	"MessageDispatchDefaultCallBack",
    	    	"MessageDispatchDefaultCallBack_end",
    	    	"MessageProcess",
    	    	"MessageProcess_end",
    	    	"OCCC_callInstanceCommon",
    	    	"OCCC_callInstanceCommon_end",
    	    	"OCCC_no_save_no_test",
    	    	"OCCC_no_save_no_test_end",
    	    	"OCCC_save_no_test",
    	    	"OCCC_save_no_test_end",
		"Idle",
		"Idle_end",
		"curXIPPage",
		"MapXIPPageFar",
		"", 	    	    /* constants here */
		"", 	    	    /* constants here */
    	    	""
};

static Boolean 	inLoader = FALSE;
static Event	resetEvent = NullEvent;

#if defined(__HIGHC__) || defined(__BORLANDC__) || defined(__WATCOMC__)
/*
 * High C doesn't have in-line structure constructors, so...
 */
Sym	NullSym = {0,0};
#endif

/***********************************************************************
 *
 *	    	    Utility/Maintenance Routines
 *
 ***********************************************************************/

/*********************************************************************
 *			SymbolKernelInternalCmd
 *********************************************************************
 * SYNOPSIS: 	    get at internal symbnols of kernel
 * CALLED BY:	    global
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/12/93		Initial version
 *
 *********************************************************************/
DEFCMD(symbol-kernel-internal,SymbolKernelInternal,TCL_EXACT,NULL,swat_prog,
"Usage: symbol-kernel-internal <address> \n\n\
Synopsis: returns the name of an internal kernel routine that contain the \n\
          address if there is one, otherwise it returns {}\n\
")
{
    GeosAddr	addr;

    if (argc != 2)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }

    if ((kernel != NullPatient) &&
	Expr_Eval(argv[1], NullFrame, &addr, (Type *)NULL, TRUE))
    {
	if (addr.handle == kernel->resources[kcodeResID].handle)
	{
	    Tcl_Return(interp,
		       (char *)Sym_IsKernelInternalRoutine((word)addr.offset),
		       TCL_STATIC);
	    return TCL_OK;
	}
    }
    Tcl_Return(interp, "", TCL_STATIC);
    return TCL_OK;
}

/*********************************************************************
 *			Sym_IsInternalWeird
 *********************************************************************
 * SYNOPSIS: 	check for weird internal kernel routine
 * CALLED BY:	Ibm86NextFrame
 * RETURN:  	true if it is an internal weird routine
 * SIDE EFFECTS:
 * STRATEGY:	HACK for backtracing with gym files
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/12/93	Initial version
 *
 *********************************************************************/
Boolean
Sym_IsInternalWeird(Handle   handle, word offset)
{
    /* if the kernel is null we are doing the loader which shouldn't
     * have anything weird going on
     */
    if (kernel == NullPatient)
    {
	return 0;
    }
    /* right now the only one I check for ResourceCallInt */
    return ((handle == kernel->resources[kcodeResID].handle) &&
	    (offset == Sym_KernelInternalNameToOffset("ResourceCallInt")));
}

/*********************************************************************
 *			SymbolKernelInternalCmd
 *********************************************************************
 * SYNOPSIS: 	    get at internal symbnols of kernel
 * CALLED BY:	    global
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/12/93		Initial version
 *
 *********************************************************************/
DEFCMD(kernel-has-table,KernelHasTable,TCL_EXACT,NULL,swat_prog,
"Usage: kernel-has-table\n\n\
Synopsis: returns 1 if the kernel has its own internal symbol table\n\
")
{
    int    hasTable;
    char    result[8];

    if (kernel == NullPatient)
    {
	Tcl_RetPrintf(interp, "Kernel not yet loaded");
	return TCL_ERROR;
    }

    hasTable = kernelInternalSymbols[0];
    sprintf(result, "%1d", hasTable);

    Tcl_Return(interp, result, TCL_VOLATILE);
    return TCL_OK;
}

/*********************************************************************
 *			SymbolKernelInternalCmd
 *********************************************************************
 * SYNOPSIS: 	    get at internal symbnols of kernel
 * CALLED BY:	    global
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/12/93		Initial version
 *
 *********************************************************************/
DEFCMD(address-kernel-internal,AddressKernelInternal,TCL_EXACT,NULL,swat_prog,
"Usage: symbol-kernel-internal <address> \n\n\
Synopsis: returns the name of an internal kernel routine that contain the \n\
          address if there is one, otherwise it returns {}\n\
")
{
    word    offset;
    char    addr[16];


    if (argc != 2)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }

    if (kernel == NullPatient)
    {
	Tcl_RetPrintf(interp, "Kernel not yet loaded");
	return TCL_ERROR;
    }

    offset = Sym_KernelInternalNameToOffset(argv[1]);
    if (offset == (word)-1)
    {
	Tcl_Return(interp, "", TCL_STATIC);
	return TCL_OK;
    }

    if (argv[1][0] >= 'A' && argv[1][0] <= 'Z')
    {
    /* if the thing starts with a capital letter then its a routine
     * name so put it with kcode
     */
	sprintf(addr, "%05xh:%05xh",
		(unsigned int)
		     Handle_Address(kernel->resources[kcodeResID].handle)>>4,
		offset);
    }
    else
    {
    /* if the thing starts with a lower case letter then its a variable
     * name so put it with kdata
     */
	sprintf(addr, "%05xh:%05xh",
		(unsigned int)Handle_Address(kernel->resources[1].handle)>>4,
		offset);
    }

    Tcl_Return(interp, addr, TCL_VOLATILE);
    return TCL_OK;
}

/*********************************************************************
 *			Sym_KernelInternalNameToOffset
 *********************************************************************
 * SYNOPSIS: 	    get the offset of an internal symbol of the kernel
 * CALLED BY:	    global
 * RETURN:  	    offset or -1 if not known
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/13/93		Initial version
 *
 *********************************************************************/
word
Sym_KernelInternalNameToOffset(char *name)
{
    int i;

    for (i = 0; kernelInternalSymbolNames[i] != NULL; i++)
    {
	if (!strcmp(name, kernelInternalSymbolNames[i]))
	{
	    return kernelInternalSymbols[i];
	}
    }
    return -1;
}

/*********************************************************************
 *			Sym_IsKernelInternalRoutine
 *********************************************************************
 * SYNOPSIS: 	return string of internal symbol that contains an address
 * CALLED BY:	sym faddr
 * RETURN:  	name of kernel symbol that contains address or NULL if none
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/11/93		Initial version
 *
 *********************************************************************/
char *
Sym_IsKernelInternalRoutine(word  offset)
{
    int	i;

    /* start from middle of table */
    for (i = FIRST_INTERNAL_WITH_END;
	 i <= LAST_INTERNAL_WITH_END && i <= kernelInternalSymbols[1];
	 i+=2)
    {
	if ((offset >= kernelInternalSymbols[i]) &&
	    (offset <= kernelInternalSymbols[i+1]))
	{
	    return kernelInternalSymbolNames[i];
	}
    }
    return NULL;
}


/***********************************************************************
 *				SymLock
 ***********************************************************************
 * SYNOPSIS:	    Lock down a symbol given its Sym token
 * CALLED BY:	    INTERNAL
 * RETURN:	    ObjSym  * for the symbol.
 * SIDE EFFECTS:    block may be brought into memory
 *
 * STRATEGY:	    None, really. It's all pretty ad hoc from here on out
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/24/90		Initial Revision
 *
 ***********************************************************************/
ObjSym *
SymLock(Sym sym)
{
    SymToken	    *s = (SymToken *)&sym;
    ObjSymHeader    *osh;

    osh = (ObjSymHeader *)VMLock(s->file, s->block, (MemHandle *)NULL);

    assert(s->offset < osh->num * sizeof(ObjSym) + sizeof(ObjSymHeader));

    return ((ObjSym *)((genptr)osh + s->offset));
}

#ifndef VMUnlock
/* If VMUnlock becomes a real function, it will be taking a real argument --
 * the memory handle for the thing, not the file and block handle */

/***********************************************************************
 *				SymUnlock
 ***********************************************************************
 * SYNOPSIS:	    Unlock a symbol given its Sym token
 * CALLED BY:	    INTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    foo
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/24/90		Initial Revision
 *
 ***********************************************************************/
void
SymUnlock(Sym sym)
{
    SymToken	    *s = (SymToken *)&sym;
    MemHandle	    mem;

    VMInfo(s->file, s->block, (word *)NULL, &mem, (VMID *)NULL);
    VMUnlock(mem);
}
#endif


/***********************************************************************
 *				SymSearchLocal
 ***********************************************************************
 * SYNOPSIS:	    Search through the local symbols for a procedure or
 *	    	    block scope for one of the proper name and class
 * CALLED BY:	    SymLookup
 * RETURN:	    Sym (NullSym if not found)
 * SIDE EFFECTS:    The scope's block is unlocked to make life easier
 *	    	    for the caller.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/24/90		Initial Revision
 *
 ***********************************************************************/
static Sym
SymSearchLocal(Sym  	scope,	    /* Scope in which we're searching (locked)*/
	       word 	loff,	    /* Offset of first local symbol in same
				     * block as scope */
	       ID   	id, 	    /* ID of symbol for which we search */
	       int  	class)	    /* Acceptable symbol classes */
{
    ObjSymHeader	*osh;
    MemHandle   	mem;
    ObjSym	    	*lsym;
    SymToken    	fsym = {(VMHandle)NULL, 0, 0};

    VMInfo(SymFile(scope), SymBlock(scope), (word *)NULL, &mem, (VMID *)NULL);
    MemInfo(mem, (genptr *)&osh, (word *)NULL);

    while (loff != 0 && loff != SymOffset(scope)) {
	assert(loff >= sizeof(ObjSymHeader) &&
	       loff < sizeof(ObjSymHeader) + (osh->num*sizeof(ObjSym)));
	lsym = (ObjSym *)((genptr)osh + loff);

	if (lsym->name == id) {
	    if (symMap[lsym->type].class & class) {
		fsym.file = SymFile(scope);
		fsym.block = SymBlock(scope);
		fsym.offset = loff;
		break;
	    } else {
		break;
	    }
	} else {
	    	/* if the local scope ends at the end of aprocedure then
		 * there is no block end for the block, it just points
		 * back to the procedure, so if we hit a procedure then
		 * we should end our search
		 */
	    	if (lsym->type == OSYM_PROC) {
		    break;
		}
	}
	loff=lsym->u.procLocal.next;
    }

    SymUnlock(scope);

    return (*(Sym *)&fsym);
}

/***********************************************************************
 *				Sym_SearchTable
 ***********************************************************************
 * SYNOPSIS:	    Search a vm hash table for an entry with the given
 *	    	    ID.
 * CALLED BY:	    SymLookup, SrcFindLine
 * RETURN:	    TRUE if entry found.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/18/91		Initial Revision
 *
 ***********************************************************************/
Boolean
Sym_SearchTable(VMHandle    	file,
		VMBlockHandle	table,
		ID  	    	id,
		VMBlockHandle	*blockPtr,
		word	    	*offsetPtr,
		word	    	symFileType)
{
    int 	    	index;
    VMBlockHandle	cur;
    VMBlockHandle	next;
    ObjHashHeader	*hdr;

    if (symFileType == SYMFILE_FORMAT_OLD) {
	index = ST_Index(file, id) % OBJ_HASH_CHAINS;
    } else {
	index = ST_Index(file, id) % OBJ_HASH_CHAINS_NEW_FORMAT;
    }
    /*
     * Lock down the table header first.
     */
    hdr = (ObjHashHeader *)VMLock(file, table, (MemHandle *)NULL);

    /*
     * Now search all the blocks of the proper chain for a symbol whose
     * name matches the given one.
     */
    for (cur = hdr->chains[index]; cur != 0; cur = next) {
	ObjHashBlock    	*hb;
	ObjHashEntry    	*he;

	hb = (ObjHashBlock *)VMLock(file, cur, (MemHandle *)NULL);
	next = hb->next;

	for (he = hb->entries; he < &hb->entries[hb->nextEnt]; he++) {
	    if (he->name == id) {
		*blockPtr = he->block;
		*offsetPtr = he->offset;

		/*
		 * For now, there's only one entry per name in this table.
		 * If this changes, we'll want to provide a callback function
		 * to make sure the right thing's been found...
		 */
		VMUnlock(file, cur);
		return(TRUE);
	    }
	}
	VMUnlock(file, cur);
    }

    return(FALSE);
}


/*-
 *-----------------------------------------------------------------------
 * SymLookup --
 *	Look for a symbol in a given scope without doing any mapping.
 *
 * Results:
 *	The Symbol or NULL if not there.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Sym
SymLookup(ID   	    	id,	    /* Identifier of symbol to find */
	  int		class,	    /* Acceptable classes */
	  Sym	    	scope)	    /* Scope in which to look */
{
    ObjSym  	    *ssym;
    VMHandle	    file;


    file = SymFile(scope);
    ssym = SymLock(scope);

    if (id == NullID) {
	return NullSym;
    }

    switch (ssym->type) {
	case OSYM_MODULE:
	{
	    /*
	     * If scope is a module symbol, we need to look in the module's
	     * hash table, as stored in the VM file.
	     */
	    SymToken	fsym;
	    Patient 	symPat;

	    /*
	     * If module has no symbol table, symbol can't be here...
	     */
	    if (ssym->u.module.table == 0) {
		return NullSym;
	    }

	    symPat = Sym_Patient(scope);
	    if (Sym_SearchTable(file, ssym->u.module.table, id,
				&fsym.block, &fsym.offset,
		    	    	symPat->symfileFormat))
	    {
		ObjSym	    *s;

		fsym.file = file;
		SymUnlock(scope);

		/*
		 * Now lock down the symbol and make sure it's in one
		 * of the requested classes.
		 */
		s = SymLock(SymCast(fsym));
		if (symMap[s->type].class & class) {
		    SymUnlock(SymCast(fsym));
		    return (SymCast(fsym));
		} else {
		    /*
		     * Not the right class, so return "null" after
		     * unlocking the symbol. If we allow symbols of
		     * different classes to have the same name, we'd
		     * just continue here after unlocking the symbol
		     * block...
		     */
		    SymUnlock(*(Sym *)&fsym);
		    return(NullSym);
		}
	    }

	    SymUnlock(scope);
	    return(NullSym);
	}
	case OSYM_PROC:
	    /*
	     * Look through the symbols local to the procedure for something
	     * that matches.
	     */
	    return SymSearchLocal(scope, ssym->u.proc.local, id, class);
	case OSYM_BLOCKSTART:
	    /*
	     * Look through the symbols local to the block for something that
	     * matches.
	     */
	    return SymSearchLocal(scope, ssym->u.blockStart.local, id, class);
	case OSYM_STRUCT:
	case OSYM_UNION:
	case OSYM_ETYPE:
	case OSYM_RECORD:
	{
	    ObjSymHeader    *osh;
	    ObjSym	    *lsym;
	    SymToken        fsym = {(VMHandle)NULL, 0, 0};
	    word    	    loff;

	    osh = (ObjSymHeader *)((genptr)ssym - SymOffset(scope));
	    loff = ssym->u.sType.first;

	    /*
	     * Make sure the type isn't empty (loff != 0) before looping
	     * through the entire list.
	     */
	    if (loff != 0) {
		while (loff != SymOffset(scope)) {
		    assert(loff<sizeof(ObjSymHeader) +
			   (osh->num*sizeof(ObjSym)));
		    assert(loff>sizeof(ObjSymHeader));
		    lsym = (ObjSym *)((genptr)osh + loff);

		    if (lsym->name == id) {
			if (symMap[lsym->type].class & class) {
			    fsym.file = SymFile(scope);
			    fsym.block = SymBlock(scope);
			    fsym.offset = loff;
			    break;
			} else {
			    break;
			}
		    }
		    loff = lsym->u.tField.next;
		}
	    }

	    SymUnlock(scope);
	    return (SymCast(fsym));
	}
	default:
	    /*
	     * Not a valid scope. What the fuck is going on here?
	     */
	    assert(0);
	    return NullSym;
    }
}


/***********************************************************************
 *				SymRealLookupInPatient
 ***********************************************************************
 * SYNOPSIS:	    Real recursive routine to lookup a symbol in a
 *	    	    patient, making sure we've not looked in this patient
 *	    	    for this symbol before.
 * CALLED BY:	    SymLookupInPatientLen, self
 * RETURN:	    Sym, if found, NullSym if not...
 * SIDE EFFECTS:    current patient is added to the vector
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 1/92		Initial Revision
 *
 ***********************************************************************/
static Sym
SymRealLookupInPatient(const Patient	patient,
		       const char   	*name,
		       const int    	len,
		       const int    	class,
		       Vector	    	patientsScanned)
{
    int	    	i;  	    /* Counter for resources/libraries */
    ID	    	id;
    Sym	    	sym;	    /* Result of search */
    Patient    	*libraryPtr;

    sym = NullSym;		/* Initialize... */

    /*
     * See if we've scanned this patient before, and return NullSym if we
     * have, since we obviously didn't find it before.
     */
    for (i = Vector_Length(patientsScanned),
	 libraryPtr = (Patient *)Vector_Data(patientsScanned);

	 i > 0;

	 i--, libraryPtr++)
    {
	if (*libraryPtr == patient) {
	    return(sym);
	}
    }

    /*
     * Not scanned this patient yet, so add it to the end of the vector.
     */
    Vector_Add(patientsScanned, VECTOR_END, (void *)&patient);

    if (patient->symFile != NULL) {
	/*
	 * First map the string into an ID for the patient's symbol file. If
	 * there's no mapping, the thing can't possibly be here.
	 */
	id = SymLookupIDLen(name, len, patient->global);

	if (id != NullID)
	{
	    /*
	     * Well, it's in the thing's string table, but that doesn't mean
	     * it's here. Run through all the module symbols recorded in the
	     * first block of the global module's table (this also makes us
	     * search the global scope first...)
	     */
	    for (i = 0; i < patient->numRes; i++)
	    {
		if (!Sym_IsNull(patient->resources[i].sym))
		{
		    sym = SymLookup(id, class, patient->resources[i].sym);
		    if (!Sym_IsNull(sym))
		    {
			return (sym);
		    }
		}
	    }
	}
    }

    if (patient->libraries == NULL) {
	assert(patient->numLibs == 0);
    } else {
	/*
	 * Then the libraries
	 */
	for (i = patient->numLibs, libraryPtr = patient->libraries;
	     (i > 0) && Sym_IsNull(sym);
	     libraryPtr++, i--)
	{
	    sym = SymRealLookupInPatient(*libraryPtr, name, len, class,
					 patientsScanned);
	}
    }

    return(sym);
}

/***********************************************************************
 *				SymLookupInPatient
 ***********************************************************************
 * SYNOPSIS:	    Look up a null-terminated name in all scopes of a
 *	    	    patient.
 * CALLED BY:	    INTERNAL
 * RETURN:	    Sym for the thing or NullSym if not found
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 2/90		Initial Revision
 *
 ***********************************************************************/
#define SymLookupInPatient(p,n,c) SymLookupInPatientLen((p),(n),strlen(n),(c))


/***********************************************************************
 *				SymLookupInPatientLen
 ***********************************************************************
 * SYNOPSIS:	    Lookup a symbol in all scopes of a patient
 * CALLED BY:	    Sym_Lookup
 * RETURN:	    The Symbol of the proper class, or NullSymbol if
 *		    none found.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *	Since symbols are found only in resource segments, we look in
 *	all the SYM_MODULE symbols listed in the Patient's resources
 *	list. If we don't find it there, we go down the list of libraries
 *	the Patient uses, recursing on each one. If still not there, we
 *	recurse on the Kernel/Loader.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/27/88	Initial Revision
 *
 ***********************************************************************/
static Sym
SymLookupInPatientLen(Patient  	patient,	    /* Patient to examine */
		      const char *name,  	    /* Name desired */
		      int   	len,	    	    /* Length of name */
		      int	class)  	    /* Classes that are OK */
{
    Vector  	patientsScanned;
    Sym	    	sym;

    patientsScanned = Vector_Create(sizeof(Patient), ADJUST_ADD, 5, 5);

    sym = SymRealLookupInPatient(patient, name, len, class, patientsScanned);

    /*
     * If didn't find it, then look in the one patient that shouldn't be
     * a library, but that contains important information: the kernel (1.X)
     * or the loader (2.0).
     */
    if (Sym_IsNull(sym) && (patient != loader))
    {
	sym = SymRealLookupInPatient(loader,
				     name,
				     len,
				     class,
				     patientsScanned);
    }

    Vector_Destroy(patientsScanned);

    return(sym);
}


/***********************************************************************
 *				SymResetHandler
 ***********************************************************************
 * SYNOPSIS:	    Handler for RESET event to make sure inLoader
 *	    	    gets reset to FALSE on ^\
 * CALLED BY:	    EVENT_RESET
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    inLoader = FALSE
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/24/90		Initial Revision
 *
 ***********************************************************************/
static int
SymResetHandler(Event	event,
		Opaque	callData,
		Opaque	clientData)
{
    inLoader = FALSE;
    return(EVENT_HANDLED);
}


/***********************************************************************
 *				Sym_Init
 ***********************************************************************
 * SYNOPSIS:	    Read the symbol table for a patient.
 * CALLED BY:	    Ibm_NewGeode, Ibm_Init, IbmAttachCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The symbol table is filled in.
 *
 * STRATEGY:
 *	The .sym file should have been opened for us, but we need to
 *	fill in the resource descriptors for the patient based on the
 *	map block and the first block of the global segment's symbol
 *	chain.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/28/88	Initial Revision
 *
 ***********************************************************************/
void
Sym_Init(Patient patient)   	/* Patient being initialized */
{
    VMBlockHandle   map;
    ObjHeader	    *hdr;
    int	    	    i;
    SymToken	    fsym;
    ObjSegment	    *s;
    ObjSym  	    *os;
    word    	    numRes;

    fsym.file = (VMHandle)patient->symFile;
    map = VMGetMapBlock(fsym.file);

    hdr = (ObjHeader *)VMLock(fsym.file, map, (MemHandle *)NULL);
    s = (ObjSegment *)(hdr+1);
    fsym.block = s->syms;
    fsym.offset = sizeof(ObjSymHeader);

    patient->global = *(Sym *)&fsym;

    /* if its a gym file, see how many resources the gym file has by looking
     * at the user notes field of the header
     */
    numRes = patient->numRes;
    if (!strcmp(rindex(patient->path, '.'), gym_ext))
    {
	/* if a generic symbol file is being used and the number of resources
	 * it knows about is less than the number of resources in the geode
	 * then just use the number we know about in the gym file
	 */
	if (gymResources > 0 && gymResources < numRes)
	{
	    numRes = gymResources;
	}
	gymResources = 0;
    }

    for (i = 0; i < numRes;) {
	patient->resources[i].sym = *(Sym *)&fsym;
	/*
	 * There can be library segments in the table stuck between resource
	 * segments, so we need to skip s forward until we find the right
	 * one. XXX: doesn't handle bogus .sym file that's mis-ordered....
	 */
	os = SymLock(SymCast(fsym));
	while (s->name != os->name) {
	    s++;
	}
	SymUnlock(SymCast(fsym));

	if (patient == loader || patient->dos || s->type != SEG_ABSOLUTE) {
	    /*
	     * Don't count absolute segments as resources unless this is the
	     * loader. They don't have handles allocated for them by the
	     * kernel b/c they're not in the resource tables put in the
	     * executable by Glue, so...
	     */
	    patient->resources[i].size = s->size;
	    i++;
	}
	fsym.offset += sizeof(ObjSym);
    }
    VMUnlock(fsym.file, map);

    if (resetEvent == NullEvent) {
	resetEvent = Event_Handle(EVENT_RESET, 0, SymResetHandler,
				  NullOpaque);
    }
}

/***********************************************************************
 *				Sym_Copy
 ***********************************************************************
 * SYNOPSIS:	    Duplicate the symbol table from one patient into
 *	    	    another
 * CALLED BY:	    Ibm_NewGeode
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The table is copied, the otherInfo field for
 *	    	    non-shared resource handles is filled with the
 *	    	    symbol appropriate to this patient.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/88	Initial Revision
 *
 ***********************************************************************/
void
Sym_Copy(Patient    from,
	 Patient    to)
{
    int	    	i;

    to->global = from->global;
    to->symFile = from->symFile;

    /*
     * Set up the sym fields of the ResourceRec's for the new patient.
     */
    for (i = 0; i < from->numRes; i++) {
	to->resources[i].sym = from->resources[i].sym;
    }
}


/***********************************************************************
 *				SymbolMatch
 ***********************************************************************
 * SYNOPSIS:	    Look for symbols of a class and pattern in a scope
 * CALLED BY:	    SymbolMatchInPatient
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Block/offset pairs (in a long word) are appended to
 *	    	    the list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/13/88	Initial Revision
 *
 ***********************************************************************/
static void
SymbolMatch(char    	*pattern,
	    int	    	class,
	    Sym  	scope,
	    Vector    	result)
{
    ObjSym  	    *ssym;
    VMHandle	    file;

    file = SymFile(scope);
    ssym = SymLock(scope);

    if (ssym->type == OSYM_MODULE) {
	/*
	 * If scope is a module symbol, we need to look through the module's
	 * symbol list, as stored in the VM file.
	 */
	VMBlockHandle	cur, next;

	/*
	 * If module has no symbol table, can't be a match...
	 */
	if (ssym->u.module.table == 0) {
	    return;
	}

	for (cur = ssym->u.module.syms; cur != 0; cur = next) {
	    int 	    	i;
	    ObjSymHeader	*osh;
	    ObjSym  	    	*os;

	    osh = (ObjSymHeader *)VMLock(file, cur, (MemHandle *)NULL);
	    for (i = osh->num, os = (ObjSym *)(osh+1); i > 0; i--, os++) {
		if ((symMap[os->type].class & class) && (os->name != NullID)) {
		    char    	*name = ST_Lock(file, os->name);

		    if (Tcl_StringMatch(name, pattern)) {
			SymToken    fsym; /* = {file, cur,
					   *    (genptr)os-(genptr)osh};
					   * xxxDan */
			fsym.file = file;
			fsym.block = cur;
			fsym.offset = (genptr)os - (genptr)osh;

			Vector_Add(result, VECTOR_END, &fsym);
		    }
		    ST_Unlock(file, os->name);
		}
	    }
	    next = osh->next;
	    VMUnlock(file, cur);
	}
	SymUnlock(scope);
    } else {
	word	    	loff;
	ObjSymHeader	*osh;
	ObjSym	    	*lsym;

	if (ssym->type == OSYM_PROC) {
	    /*
	     * Look through the symbols local to the procedure for something
	     * that matches.
	     */
	    loff = ssym->u.proc.local;
	} else if (ssym->type == OSYM_BLOCKSTART) {
	    loff = ssym->u.blockStart.local;
	} else {
	    /*
	     * Not a valid scope. What the fuck is going on here?
	     */
	    assert(0);
	    return;
	}

	osh = (ObjSymHeader *)((genptr)ssym - SymOffset(scope));

	while (loff != 0 && loff != SymOffset(scope)) {
	    char    	*name;

	    assert(loff >= sizeof(ObjSymHeader) &&
		   loff < sizeof(ObjSymHeader) + (osh->num*sizeof(ObjSym)));
	    lsym = (ObjSym *)((genptr)osh + loff);

	    if (symMap[lsym->type].class & class) {
		name = ST_Lock(file, lsym->name);
		if (Tcl_StringMatch(name, pattern)) {
		    SymToken	fsym; /* = { file, SymBlock(scope), loff};
				       * xxxDDD*/
		    fsym.file = file;
		    fsym.block = SymBlock(scope);
		    fsym.offset = loff;

		    Vector_Add(result, VECTOR_END, &fsym);
		}
		ST_Unlock(file, lsym->name);
	    }
	    loff = lsym->u.procLocal.next;
	}
	SymUnlock(scope);
    }
}

/***********************************************************************
 *				SymbolMatchInPatient
 ***********************************************************************
 * SYNOPSIS:	    Look for symbols of a given pattern in a patient.
 * CALLED BY:	    SymbolCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Symbol tokens are placed at the end of the list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/13/88	Initial Revision
 *
 ***********************************************************************/
static void
SymbolMatchInPatient(char   	*pattern,   /* Pattern to match */
		     int    	class,	    /* Class(es) desired */
		     Patient	patient,    /* Patient to search */
		     Vector    	result,	    /* Vector in which to place the
					     * matching symbols */
		     int    	libs)	    /* Non-zero if should descend to
					     * libraries too */
{
    int	    	i;  	    /* Counter for resources/libraries */
    Patient    *libraryPtr;

    /*
     * First the resource segments
     */
    for (i = 0; i < patient->numRes; i++) {
	SymbolMatch(pattern, class, patient->resources[i].sym, result);
    }

    if (libs) {
	/*
	 * Then the libraries
	 */
	for (i = patient->numLibs, libraryPtr = patient->libraries;
	     (i > 0);
	     libraryPtr++, i--)
	{
	    SymbolMatchInPatient(pattern, class, *libraryPtr, result, 0);
	}
    }
}

static const struct {
    int 	class;
    char	*name;
}	    symclasses[] = {
    {SYM_VAR,    	"var"},
    {SYM_FUNCTION,	"proc"},
    {SYM_FUNCTION,	"func"},
    {SYM_TYPE,   	"type"},
    {SYM_MODULE, 	"module"},
    {SYM_ENUM,   	"enum"},
    {SYM_ABS,    	"const"},
    {SYM_ABS,    	"abs"},
    {SYM_LABEL,  	"label"},
    {SYM_FIELD,  	"field"},
    {SYM_LOCALVAR,   	"locvar"},
    {SYM_SCOPE,	    	"scope"},
    {SYM_ONSTACK,    	"onstack"},
    {SYM_PROFILE,    	"profile"},
    {SYM_ANY,	    	"any"}
};

/***********************************************************************
 *				SymParseClass
 ***********************************************************************
 * SYNOPSIS:	    Parse a symbol class specification
 * CALLED BY:	    SymbolCmd
 * RETURN:	    TCL_ERROR if error, TCL_OK if none.
 * SIDE EFFECTS:    *classPtr is set to the parsed class.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
static int
SymParseClass(Tcl_Interp    *interp,
	      char  	    *str,
	      int	    *classPtr)
{
    int	    class;
    char    **argv;
    int	    argc;
    int	    i, j;

    if (Tcl_SplitList(interp, str, &argc, &argv) != TCL_OK) {
	return(TCL_ERROR);
    }

    class = 0;
    for (i = 0; i < argc; i++) {
	for (j = 0; j < Number(symclasses); j++) {
	    if (strcmp(argv[i], symclasses[j].name) == 0) {
		class |= symclasses[j].class;
		break;
	    }
	}
	if (j == Number(symclasses)) {
	    Tcl_RetPrintf(interp, "Unknown symbol class: %s", argv[i]);
	    free((char *)argv);
	    return(TCL_ERROR);
	}
    }

    free((char *)argv);
    *classPtr = class;
    return(TCL_OK);
}

/***********************************************************************
 *				Sym_IsNull
 ***********************************************************************
 * SYNOPSIS:	    See if a Sym token is NULL
 * CALLED BY:	    EXTERNAL
 * RETURN:	    TRUE if Sym is NullSym.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/27/90		Initial Revision
 *
 ***********************************************************************/
Boolean
Sym_IsNull(Sym	sym)
{
    return (SymFile(sym) == (VMHandle)0);
}

/***********************************************************************
 *				Sym_Equal
 ***********************************************************************
 * SYNOPSIS:	    See if two symbol tokens refer to the same symbol
 * CALLED BY:	    EXTERNAL
 * RETURN:	    True if so.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
Boolean
Sym_Equal(Sym	sym1,
	  Sym 	sym2)
{
    return((SymFile(sym1) == SymFile(sym2)) &&
	   (SymBlock(sym1) == SymBlock(sym2)) &&
	   (SymOffset(sym1) == SymOffset(sym2)));
}

/***********************************************************************
 *				Sym_ToToken
 ***********************************************************************
 * SYNOPSIS:	    Convert an ASCII symbol token to its internal form
 * CALLED BY:	    SymbolCmd, EXTERNAL
 * RETURN:	    Sym for the symbol.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    A TCL-level Sym token is a 3-list
 *	    	    	{<file> <block> <offset>}
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/27/90		Initial Revision
 *
 ***********************************************************************/
Sym
Sym_ToToken(char    *token)
{
    SymToken	    fsym;
    int	    	    argc;
    char    	    **argv;

    if (Tcl_SplitList(interp, token, &argc, &argv) != TCL_OK) {
	return NullSym;
    }
    if (argc != 3) {
	Tcl_Return(interp, "malformed symbol token", TCL_STATIC);
	free((char *)argv);
	return NullSym;
    }
    fsym.file = (VMHandle)atoi(argv[0]);
    fsym.block = (VMBlockHandle)atoi(argv[1]);
    fsym.offset = (word)atoi(argv[2]);
    free((char *)argv);

    /*
     * None of these fields may be zero in a valid symbol token (file obviously
     * may not be zero, block may not be zero as the header has to be in there
     * somewhere.
     */
    if ((fsym.file == NULL) || !VALIDTPTR(fsym.file, TAG_VMFILE) ||
	(fsym.block == 0) || (fsym.offset == 0))
    {
	return NullSym;
    }

    /*
     * Make sure the block refers to a symbol block, returning NullSym if not.
     */
    if (fsym.block != 0) {
	VMID	id;

	VMInfo(fsym.file, fsym.block, (word *)NULL, (MemHandle *)NULL, &id);
	if (id != OID_SYM_BLOCK) {
	    return NullSym;
	}
    }

    return (*(Sym *)&fsym);
}


/***********************************************************************
 *				Sym_ToAscii
 ***********************************************************************
 * SYNOPSIS:	    Convert an internal Sym token to an ascii string
 *	    	    suitable for return to TCL.
 * CALLED BY:	    SymbolCmd, EXTERNAL
 * RETURN:	    Address of a *static* buffer containing the necessary
 *	    	    3-list
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/27/90		Initial Revision
 *
 ***********************************************************************/
char *
Sym_ToAscii(Sym	sym)
{
    static char	token[32];

    if (Sym_IsNull(sym)) {
	strcpy(token, "nil");
    } else {
	sprintf(token, "%d %d %d", (int)SymFile(sym), SymBlock(sym),
		SymOffset(sym));
    }

    return(token);
}

/***********************************************************************
 *				SymGetType
 ***********************************************************************
 * SYNOPSIS:	    Extract a type token for a symbol.
 * CALLED BY:	    INTERNAL
 * RETURN:	    proper Type token
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/29/90		Initial Revision
 *
 ***********************************************************************/
static Type
SymGetType(Sym	sym)
{
    SymToken	    fsym = *(SymToken *)&sym;
    ObjSymHeader    *osh;
    SymToken	    ftype;
    ObjSym  	    *os;

    ftype.file = fsym.file;

    osh = (ObjSymHeader *)VMLock(fsym.file, fsym.block, (MemHandle *)NULL);
    ftype.block = osh->types;

    os = (ObjSym *)((genptr)osh + fsym.offset);
    switch(os->type) {
	case OSYM_TYPEDEF:
	    ftype.offset = os->u.typeDef.type;
	    break;
	case OSYM_STRUCT:
	case OSYM_UNION:
	case OSYM_RECORD:
	case OSYM_ETYPE:
	    /*
	     * These things are their own type.
	     */
	    ftype.block = fsym.block;
	    ftype.offset = fsym.offset;
	    break;
	case OSYM_FIELD:
	    ftype.offset = os->u.sField.type;
	    break;
	case OSYM_BITFIELD:
	    if (os->u.bField.type == (OTYPE_BITFIELD|OTYPE_SPECIAL)) {
		ftype.offset =
		    (OTYPE_BITFIELD|OTYPE_SPECIAL|
		     (os->u.bField.width << OTYPE_BF_WIDTH_SHIFT)|
		     (os->u.bField.offset << OTYPE_BF_OFFSET_SHIFT));
	    } else {
		ftype.offset = os->u.bField.type;
	    }
	    break;
	case OSYM_VARDATA:
	    ftype.offset = os->u.varData.type;
	    break;
	case OSYM_ENUM:
	    /*
	     * Return the containing type for an ENUM (why not?)
	     */
	    while (os->type == OSYM_ENUM) {
		os = (ObjSym *)((genptr)osh+os->u.eField.next);
	    }
	    ftype.block = fsym.block;
	    ftype.offset = (genptr)os - (genptr)osh;
	    break;
	case OSYM_METHOD:
	    /*
	     * Return the containing type for a METHOD (why not?)
	     */
	    while (os->type == OSYM_METHOD) {
		os = (ObjSym *)((genptr)osh+os->u.method.next);
	    }
	    ftype.block = fsym.block;
	    ftype.offset = (genptr)os - (genptr)osh;
	    break;
	case OSYM_CONST:
	    /*
	     * These are always words...for now
	     */
	    ftype.offset = OTYPE_SPECIAL|OTYPE_INT|(2<<1);
	    break;
	case OSYM_VAR:
	    ftype.offset = os->u.variable.type;
	    break;
	case OSYM_CHUNK:
	{
	    Type    type;

	    ftype.offset = os->u.chunk.type;
	    type = Type_CreatePointer(TypeCast(ftype), TYPE_PTR_NEAR);
	    TypeCast(ftype) = type;
	    break;
	}
	case OSYM_PROC:
	    ftype.offset = OTYPE_SPECIAL|((os->u.proc.flags & OSYM_NEAR) ?
					  OTYPE_NEAR : OTYPE_FAR);
	    break;
	case OSYM_LABEL:
	    ftype.offset = OTYPE_SPECIAL|(os->u.label.near ?
					  OTYPE_NEAR : OTYPE_FAR);
	    break;
	case OSYM_LOCLABEL:
	    ftype.offset = OTYPE_SPECIAL|OTYPE_NEAR;
	    break;
	case OSYM_REGVAR:
	case OSYM_LOCVAR:
	    ftype.offset = os->u.localVar.type;
	    break;
        case OSYM_PROFILE_MARK:
	case OSYM_ONSTACK:
	case OSYM_BLOCKSTART:
	case OSYM_BLOCKEND:
	case OSYM_MODULE:
	case OSYM_BINDING:
	    ftype.offset = OTYPE_SPECIAL|OTYPE_VOID;
	    break;
	case OSYM_CLASS:
	case OSYM_VARIANT_CLASS:
	case OSYM_MASTER_CLASS:
	{
	    Sym	    type;

	    assert(kernel != NULL);

	    type = Sym_Lookup("ClassStruct", SYM_TYPE,
				kernel->global);

	    assert(!Sym_IsNull(type));

	    ftype.file = SymFile(type);
	    ftype.block = SymBlock(type);
	    ftype.offset = SymOffset(type);
	    break;
	}
	case OSYM_LOCAL_STATIC:
	{
	    SymToken	vsym;

	    vsym.file = fsym.file;
	    vsym.block = os->u.localStatic.symBlock;
	    vsym.offset = os->u.localStatic.symOff;

	    VMUnlock(fsym.file, fsym.block);
	    return(SymGetType(SymCast(vsym)));
	}
	default:
	    assert(0);
    }
    VMUnlock(fsym.file, fsym.block);

    return (*(Type *)&ftype);
}


/***********************************************************************
 *				SymLockID
 ***********************************************************************
 * SYNOPSIS:	    Lock down an identifier using a symbol as a point-
 *	    	    of-reference. The identifier should be in the same
 *	    	    file as the symbol.
 * CALLED BY:	    INTERNAL
 * RETURN:	    char * pointing to the string.
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/29/90		Initial Revision
 *
 ***********************************************************************/
char *
SymLockID(Sym	sym,
	  ID	id)
{
    return(ST_Lock(SymFile(sym), id));
}

/***********************************************************************
 *				SymUnlockID
 ***********************************************************************
 * SYNOPSIS:	    Release an identifier, using a symbol as a point-
 *	    	    of-reference. The identifier should be in the same
 *	    	    file as the symbol.
 * CALLED BY:	    INTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/29/90		Initial Revision
 *
 ***********************************************************************/
void
SymUnlockID(Sym	sym,
	    ID	id)
{
    ST_Unlock(SymFile(sym), id);
}

/***********************************************************************
 *				SymLookupID
 ***********************************************************************
 * SYNOPSIS:	    Map a string to an ID w.r.t. a symbol.
 * CALLED BY:	    INTERNAL
 * RETURN:	    ID for the file from which the symbol comes
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/29/90		Initial Revision
 *
 ***********************************************************************/
ID
SymLookupID(const char *name,
	    Sym	    sym)
{
    return SymLookupIDLen(name, strlen(name), sym);
}


/***********************************************************************
 *				SymLookupIDLen
 ***********************************************************************
 * SYNOPSIS:	    Map a string to an ID w.r.t. a symbol. Length of
 *	    	    string must be passed.
 * CALLED BY:	    INTERNAL
 * RETURN:	    ID for the file from which the symbol comes
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/29/90		Initial Revision
 *
 ***********************************************************************/
ID
SymLookupIDLen(const char *name,
	       int  len,
	       Sym  sym)
{
    VMBlockHandle   map;
    ObjHeader	    *hdr;
    ID	    	    result;

    /*
     * Lock down the file's map block so we can find the string table.
     */
    map = VMGetMapBlock(SymFile(sym));
    hdr = (ObjHeader *)VMLock(SymFile(sym), map, (MemHandle *)NULL);

    /*
     * Attempt to map the string to an ID with the file's string table
     */
    result = ST_Lookup(SymFile(sym), hdr->strings, name, len);

    if (result == NullID) {
	/*
	 * Try it with an underscore first (C convention).
	 */
	char	*newname = (char *)malloc(len+2);

	newname[0] = '_';
	bcopy((char *)name, (char *)newname+1, len);
	result = ST_Lookup(SymFile(sym), hdr->strings, newname, len+1);

	if (result == NullID) {
	    /*
	     * Not there with an underscore, so try all uppercase (Pascal
	     * convention).
	     */
	    const char  *old;
	    char    	*new;
	    int	    	i;

	    for (i = len, old = name, new = newname; i > 0; old++, i--) {
		if (islower(*old)) {
		    *new++ = toupper(*old);
		} else {
		    *new++ = *old;
		}
	    }
	    *new = '\0';

	    result = ST_Lookup(SymFile(sym), hdr->strings, newname, len);
	}

	if (result == NullID) {
	    /*
	     * Not there with an underscore or all upper-case, so try with a
	     * leading @  (fastcall convention).
	     */
	    newname[0] = '@';
	    bcopy((char *)name, (char *)newname+1, len);
	    result = ST_Lookup(SymFile(sym), hdr->strings, newname, len+1);
	}
	free((malloc_t)newname);
    }

    /*
     * Release the map block and return any ID we found.
     */
    VMUnlock(SymFile(sym), map);
    return(result);
}


/***********************************************************************
 *				SymForeachCmdCallback
 ***********************************************************************
 * SYNOPSIS:	Call the TCL callback function for "symbol foreach" back
 *	    	with the next symbol.
 * CALLED BY:	SymbolCmd via Sym_ForEach
 * RETURN:	0 to continue, non-zero to stop iteration
 * SIDE EFFECTS:none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 9/91		Initial Revision
 *
 ***********************************************************************/
static Boolean
SymForeachCmdCallback(Sym   	sym,	    /* Symbol to process */
		      Opaque	data)	    /* Symbol command's argv */
{
    char    	*cmd;
    char    	*cmdArgv[3];
    int	    	cmdArgc;
    char    	**symbolArgv = (char **)data;
    Boolean 	retval;

    cmdArgc = 0;
    cmdArgv[cmdArgc++] = symbolArgv[4];
    cmdArgv[cmdArgc++] = Sym_ToAscii(sym);
    if (symbolArgv[5] != NULL) {
	cmdArgv[cmdArgc++] = symbolArgv[5];
    }
    cmd = Tcl_Merge(cmdArgc, cmdArgv);

    if (Tcl_Eval(interp, cmd, 0, (const char **)NULL) != TCL_OK) {
	/*
	 * Stop iterating on error.
	 */
	retval = TRUE;
    } else if (interp->result[0] == '\0') {
	retval = FALSE;
    } else if (isdigit(interp->result[0])) {
	/*
	 * Return whatever callback returned.
	 */
	retval = atoi(interp->result);
    } else {
	/*
	 * Non-numeric result => stop iterating.
	 */
	retval = TRUE;
    }

    free(cmd);
    return(retval);
}

/***********************************************************************
 *				SymbolCmd
 ***********************************************************************
 * SYNOPSIS:	    Access/create a symbol.
 * CALLED BY:	    Tcl
 * RETURN:	    an integer in ASCII
 * SIDE EFFECTS:    A symbol may be created
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/3/88	    	Initial Revision
 *
 ***********************************************************************/
DEFCMDNOPROC(symbol-types,junk,0,0,swat_prog,
"There are 30 symbol types that can be manipulated by the \"symbol\" command.\n\
They are divided into 12 groups for purposes of searching for them and\n\
manipulating them. The types and their groups are as follows:\n\
\n\
    Type (groups)		Description\n\
    -------------		-----------\n\
    binding (none)  	    	Defines the name of a procedure that will\n\
				handle the receipt of a particular message by\n\
				an object class.\n\
\n\
    bitfield (field)	    	A member of a record.\n\
\n\
    blockstart (scope)	    	The beginning of a lexical block within a\n\
				procedure that has symbols local to it. For\n\
				example, when you declare a variable in the\n\
				body of an \"if\", a symbol of this type will be\n\
				created for the start of the \"if\" body. The\n\
				symbol has an address, and can be searched for\n\
				symbols within it, and that is all.\n\
\n\
    blockend (none) 	    	This is placeholder that you will probably\n\
				never encounter, but it holds the address of\n\
				the end of a lexical block, so Swat can\n\
				determine when a variable local to the block\n\
				is no longer valid.\n\
\n\
    chunk (var)	    	    	A statically-defined variable stored in a\n\
				local memory chunk, as defined by the CHUNK\n\
				directive in Esp. There is no equivalent in C.\n\
\n\
    class (var)	    	    	An object class that is neither a master\n\
				class, nor a variant class.\n\
\n\
    const (abs)			A constant, as defined by the EQU directive in\n\
				Esp. There is no equivalent in most versions\n\
				of C.\n\
\n\
    enum (enum)	    	    	A member of an enumerated type.\n\
\n\
    etype (type, scope)		An enumerated type, as defined by the ETYPE\n\
				directive in Esp, or enum in C. The members of\n\
				the enumerated type can be looked up by name\n\
				(\"symbol lookup\") or enumerated (\"symbol\n\
				foreach\") by passing this etype symbol as the\n\
				scope in which to search. Symbols of this type\n\
				may also be manipulated by the \"type\" command.\n\
\n\
    exttype (type)  	    	This exists only for historical reasons. It\n\
				used to describe a type that was defined\n\
				external to the geode (e.g. in a library the\n\
				geode used), but is no longer needed.\n\
\n\
    field (field)   	    	A member of a structure or union.\n\
\n\
    label (label)		A label that is external to any procedure, as\n\
				defined by the LABEL directive in Esp.\n\
\n\
    loclabel (label)	    	A label that is local to a procedure, as\n\
				defined by the : directive in Esp. C doesn't\n\
				usually have local labels, except for the\n\
				??START label created by Glue to mark the end\n\
				of the function prologue, and hence the start\n\
				of the actual procedure,  created by the C\n\
				compiler.\n\
\n\
    locstatic (locvar)	    	A variable local to a procedure, but not stored\n\
				on the stack. This is (so far) the only type\n\
				of symbol whose lexical scope does not match\n\
				its physical scope.\n\
\n\
    locvar (locvar) 	    	A variable local to a procedure, as defined by\n\
				the LOCAL directive in Esp, or in the usual\n\
				manner in C. Procedure arguments are also\n\
				considered to be locvars, as are static\n\
				variables declared within a procedure.\n\
\n\
    masterclass (var)	    	An object class that is a master class, but\n\
				not a variant class.\n\
\n\
    method (enum)   	    	A member of the enumerated type holding the\n\
				messages that may be sent to an object of a\n\
				particular class.\n\
\n\
    module (scope, module)  	A segment, as defined by the SEGMENT directive\n\
				in Esp, or implicitly by the C compiler (or\n\
				via various pragmas that vary from compiler to\n\
				compiler).\n\
\n\
    onstack (onstack)		A stack-layout descriptor for use by Swat, as\n\
				defined by the ON_STACK directive in Esp.\n\
\n\
    proc (scope, func, label)	A procedure, as defined by the PROC directive\n\
				in Esp, or the usual manner in C. As a scope,\n\
				a procedure contains its local variables,\n\
				arguments, and top-level lexical blocks (for\n\
				C). These symbols can be looked up by giving\n\
				the procedure symbol as the scope in which to\n\
				search.\n\
\n\
    profile (profile)  	    	The location of code used for profiling.\n\
\n\
    record (type, scope)	A collection of bitfields defined by the\n\
				RECORD directive in Esp. There is no\n\
				equivalent in C. The fields in the record are\n\
				of type \"bitfield\" and can be looked up by\n\
				name (\"symbol lookup\") or enumerated (\"symbol\n\
				foreach\") by passing this record symbol as the\n\
				scope in which to search. Symbols of this type\n\
				may also be manipulated by the \"type\" command.\n\
\n\
    regvar (locvar) 	    	A variable local to a procedure that is stored\n\
				in a register, rather than on the stack.\n\
				Created only for C.\n\
\n\
    rettype (none)  	    	A \"local variable\" that contains the return\n\
				type for a procedure. Accessible only with the\n\
				\"symbol get\" command when applied to a\n\
				procedure symbol.\n\
    struct (type, scope)	A structure, as defined by the STRUC directive\n\
				in Esp, or struct in C. The fields of the\n\
				structure are of type \"field\" or \"bitfield\"\n\
				and can be looked up by name (\"symbol lookup\")\n\
				or enumerated (\"symbol foreach\") by passing this\n\
				struct symbol as the scope in which to search.\n\
				Symbols of this type may also be manipulated\n\
				by the \"type\" command.\n\
\n\
    typedef (type)		Any named type built up from other types, e.g.\n\
				using the TYPE directive in Esp, or typedef in\n\
				C.\n\
\n\
    union (type, scope)	    	Like a struct symbol, but defined by the UNION\n\
				directive in both Esp and C.\n\
\n\
    var (var)			A statically-defined variable.\n\
\n\
    vardata (enum)  	    	A member of the enumerated type holding the\n\
				ObjVarData tags for an object class.\n\
\n\
    variantclass (var)	    	An object class that is a variant master\n\
				class.\n\
\n\
")

#define SYMBOL_FIND 	(ClientData)0
#define SYMBOL_FADDR	(ClientData)1
#define SYMBOL_MATCH	(ClientData)2
#define SYMBOL_SCOPE	(ClientData)3
#define SYMBOL_NAME 	(ClientData)4
#define SYMBOL_FULLNAME	(ClientData)5
#define SYMBOL_CLASS	(ClientData)6
#define SYMBOL_TYPE 	(ClientData)7
#define SYMBOL_GET  	(ClientData)8
#define SYMBOL_PATIENT	(ClientData)9
#define SYMBOL_TGET 	(ClientData)10
#define SYMBOL_ADDR 	(ClientData)11
#define SYMBOL_FOREACH	(ClientData)12
static const CmdSubRec symbolCmds[] = {
    {"find", 	SYMBOL_FIND,	2, 3, "{(type|func|label|var|module|enum|abs|field|any)+} <name> [<scope>]"},
    {"faddr",	SYMBOL_FADDR,	2, 2, "{(func|label|var|module|scope|any)+} <address>"},
    {"match",	SYMBOL_MATCH,	2, 3, "{(type|func|label|var|module|enum|abs|field|any)+} <pattern> [<scope>]"},
    {"scope",	SYMBOL_SCOPE,	1, 2, "<symbol> [<lexical>]"},
    {"name", 	SYMBOL_NAME,	1, 1, "<symbol>"},
    {"fullname",SYMBOL_FULLNAME,1, 2, "<symbol> [<with-patient>]"},
    {"class",	SYMBOL_CLASS,	1, 1, "<symbol>"},
    {"type",	SYMBOL_TYPE,	1, 1, "<symbol>"},
    {"get",  	SYMBOL_GET, 	1, 1, "<symbol>"},
    {"patient",	SYMBOL_PATIENT,	1, 1, "<symbol>"},
    {"tget", 	SYMBOL_TGET,	1, 1, "<symbol>"},
    {"addr", 	SYMBOL_ADDR,	1, 1, "<symbol>"},
    {"foreach",	SYMBOL_FOREACH,	3, 4, "<scope> <class> <callback> [<data>]"},
    {NULL,	(ClientData)NULL,		0, 0, NULL}
};

DEFCMD(symbol,Symbol,0,symbolCmds,swat_prog,
"Usage:\n\
    symbol find <class> <name> [<scope>]\n\
    symbol faddr <class> <addr>\n\
    symbol match <class> <pattern>\n\
    symbol scope <symbol> [<lexical>]\n\
    symbol name <symbol>\n\
    symbol fullname <symbol> [<with-patient>]\n\
    symbol class <symbol>\n\
    symbol type <symbol>\n\
    symbol get <symbol>\n\
    symbol patient <symbol>\n\
    symbol tget <symbol>\n\
    symbol addr <symbol>\n\
    symbol foreach <scope> <class> <callback> [<data>]\n\
\n\
Examples:\n\
    \"symbol find type LMemType\"	Locate a type definition named\n\
					LMemType\n\
    \"symbol faddr proc cs:ip\"		Locate the procedure in which cs:ip\n\
					lies.\n\
    \"symbol faddr {proc label} cs:ip\"	Locate the procedure or label just\n\
					before cs:ip\n\
    \"symbol fullname $sym\"		Fetch the full name of the symbol\n\
					whose token is in the $sym variable.\n\
    \"symbol scope $sym\"			Fetch the token of the scope containing\n\
					the passed symbol. This will give the\n\
					structure containing a structure field,\n\
					or the procedure containing a local\n\
					variable, for example.\n\
\n\
Synopsis:\n\
    Provides information on the symbols for all currently-loaded patients.\n\
    Like many of Swat's commands, this operates by using a lookup function\n\
    (the \"find\", \"faddr\", \"match\", or \"foreach\" subcommands) to obtain a\n\
    token for a piece of data that's internal to Swat. Given this token, you\n\
    then use the other subcommands (such as \"name\" or \"get\") to obtain\n\
    information about the symbol you looked up.\n\
\n\
Notes:\n\
    * There are 30 types of symbols that have been grouped into 12 classes\n\
      that may be manipulated with this command. For a list of the symbol\n\
      types and their meaning, type \"help symbol-types\". The type of a symbol\n\
      can be obtained with the \"symbol type\" command.\n\
\n\
    * The 12 symbol classes are as follows:\n\
	type    describes any structured type: typedef, struct, record, etype,\n\
		union. Symbols of this class may also be used in place of type\n\
		tokens (see the \"type\" command).\n\
	field   describes a field in a structured type: field, bitfield.\n\
	enum    describes a member of an enumerated type: enum, method,\n\
		vardata.\n\
	const   a constant defined with EQU: const.\n\
	var     describes any non-local variable symbol: var, chunk, class,\n\
		masterclass, variantclass.\n\
	locvar	describes any local variable symbol: locvar, locstatic.\n\
	scope   describes any symbol that holds other symbols within it: module,\n\
		proc, blockstart, struct, union, record, etype.\n\
	proc    describes only proc symbols.\n\
	label   describes any code-related symbol: label, proc, loclabel.\n\
	onstack describes only symbols created by the ON_STACK directive.\n\
	module	describes only segment/group symbols.\n\
	profile	describes a symbol that marks where profiling code was\n\
		inserted by a compiler or assembler.\n\
\n\
    * The <class> argument for the \"find\", \"faddr\" and \"match\" subcommands may\n\
      be a single class, or a space-separated list of classes. For example,\n\
      \"symbol faddr {proc label} cs:ip\" would find the symbol closest to cs:ip\n\
      (but whose address is still below or equal to cs:ip) that is either a\n\
      procedure or a label.\n\
\n\
    * The \"symbol find\" command locates a symbol given its name (which may be\n\
      a symbol path).\n\
\n\
    * The \"symbol faddr\" command locates a symbol that is closest to the\n\
      passed address.\n\
\n\
    * A symbol's \"fullname\" is the symbol path, from the current patient, that\n\
      uniquely identifies the symbol. Thus if a procedure-local variable \n\
      belongs to the current patient, the fullname would be\n\
	<segment>::<procedure>::<name>\n\
      where <segment> is the segment holding the <procedure>, which is the\n\
      procedure for which the local variable named <name> is defined.\n\
\n\
    * You can force the prepending of the owning patient to the fullname by\n\
      passing <with-patient> as a non-empty argument (\"yes\" or \"1\" are\n\
      both fine arguments, as is \"with-patient\").\n\
\n\
    * The \"symbol get\" command provides different data for each symbol class,\n\
      as follows:\n\
	var, locvar, chunk:  {<addr> <sclass> <type>}\n\
	    <addr> is the symbol's address as for the \"addr\"\n\
	    subcommand, <sclass> is the storage class of the variable\n\
	    and is one of static (a statically allocated variable),\n\
	    lmem (an lmem chunk), local (a local variable below the\n\
	    frame pointer), param (a local variable above the frame\n\
	    pointer), or reg (a register variable; address is the\n\
	    machine register number -- and index into the list\n\
	    returned by the \"current-registers\" command).\n\
	object class: {<addr> <sclass> <type> <flag> <super>}\n\
	    first three elements same as for other variables. <flag>\n\
	    is \"variant\" if the class is a variant class, \"master\"\n\
	    if the class is a master class, or empty if the class is\n\
	    nothing special. <super> is the symbol token of the\n\
	    class's superclass.\n\
	proc: {<addr> (near|far) <return-type>}\n\
	    <addr> is the symbol's address as for the \"addr\"\n\
	    subcommand. The second element is \"near\" or \"far\"\n\
	    depending on the type of procedure involved. <return-type> is the\n\
	    token for the type of data returned by the procedure.\n\
	label-class: {<addr> (near|far)}\n\
	    <addr> is the symbol's address as for the \"addr\"\n\
	    subcommand. The second element is \"near\" or \"far\"\n\
	    depending on the type of label involved.\n\
	field-class: {<bit-offset> <bit-width> <field-type> <struct-type>}\n\
	    <bit-offset> is the offset of the field from the\n\
	    structure/union/record's base expressed in bits.\n\
	    <bit-width> is the width of the field, in bits.\n\
	    <field-type> is the type for the field itself, while\n\
	    <struct-type> is the token for the containing structured\n\
	    type.\n\
	const: {<value>}\n\
	    <value> is just the symbol's value.\n\
	vardata: {<value> <etype> <type>}\n\
	    <value> is the symbol's value. <etype> is the containing enumerated\n\
	    type's symbol. <type> is the type of data stored with the vardata\n\
	    tag.\n\
	enum-class: {<value> <etype>}\n\
	    <value> is the symbol's value. <etype> is the containing enumerated\n\
	    type's symbol.\n\
	blockstart, blockend: {<addr>}\n\
	    <addr> is the address bound to the symbol.\n\
	onstack: {<addr> <data>}\n\
	    <addr> is the address at which the ON_STACK was declared.\n\
	    <data> is the arguments given to the ON_STACK directive.\n\
	module: {<patient>}\n\
	    <patient> is the token for the patient owning the module.\n\
	profile: {<addr> <ptype>}\n\
	    <addr> is the address of the marker, while <ptype> indicates the\n\
	    type of profiling code present. 1 is for basic-block start put\n\
	    in by Esp. If the byte at <addr> is 0xc9, the basic block has been\n\
	    executed. 2 is for routine execution counting. Its format is not\n\
	    yet defined.\n\
\n\
    * A related command, \"symbol tget\" will fetch the type token for symbols\n\
      that have data types (var-, field- and enum-class symbols). For vardata\n\
      symbols, the type returned will be that of the data stored with the\n\
      vardata tag, not the containing enumerated type, for all that vardata\n\
      falls in the enum class.\n\
\n\
    * \"symbol addr\" can be used to obtain the address of symbols that actually\n\
      have one (var-, locvar- and label-class symbols). For locvar symbols,\n\
      the address is an offset from the frame pointer (positive or negative).\n\
      For var- and label-class symbols (remember that a procedure is a\n\
      label-class symbols), the returned integer is the offset of the symbol\n\
      within its segment.\n\
\n\
    * \"symbol patient\" returns the token of the patient to which the symbol\n\
      belongs.\n\
\n\
    * \"symbol foreach\" will call the <callback> procedure for each symbol in\n\
      <scope> (a symbol token) that is in one of the classes given in the list\n\
      <class>. The first argument will be the symbol token itself, while the\n\
      second argument will be <data>, if given. If <data> wasn't provided,\n\
      <callback> will receive only 1 argument. <callback> should return 0\n\
      to continue iterating, or non-zero to stop. A non-integer return is\n\
      assumed to mean stop. \"symbol foreach\" returns whatever the last call\n\
      to <callback> returned.\n\
\n\
    * By default, \"symbol scope\" will return the physical scope of the symbol.\n\
      The physical scope of a symbol is the symbol for the segment in which\n\
      the symbol lies, in contrast to the lexical scope of a symbol, which is\n\
      where the name of the symbol lies. The two scopes correspond for all\n\
      symbols but static variables local to a procedure. To obtain the lexical\n\
      scope of a symbol, pass <lexical> as a non-zero number.\n\
\n\
See also:\n\
    symbol-types, type\n\
")
{
    Sym	    sym;    	/* Generic symbol */
    int	    i;  	/* Index into symclasses or vclasses */

    if (clientData >= SYMBOL_SCOPE) {
	/*
	 * Decode the symbol argument for all those commands that use it.
	 */
	sym = Sym_ToToken(argv[2]);
	if (Sym_IsNull(sym)) {
	    Tcl_Return(interp, "invalid symbol", TCL_STATIC);
	    return(TCL_ERROR);
	}
    }

    switch((int)clientData) {
    case SYMBOL_SCOPE:
	if (argc == 4) {
	    Tcl_Return(interp, Sym_ToAscii(Sym_Scope(sym, atoi(argv[3]))),
		       TCL_VOLATILE);
	} else {
	    Tcl_Return(interp, Sym_ToAscii(Sym_Scope(sym, FALSE)),
		       TCL_VOLATILE);
	}
	break;
    case SYMBOL_NAME:
	Tcl_Return(interp, Sym_Name(sym), /* TCL_DYNAMIC */ TCL_STATIC);
	break;
    case SYMBOL_FULLNAME:
	if (argc == 4) {
	    Tcl_Return(interp, Sym_FullNameWithPatient(sym), TCL_DYNAMIC);
	} else {
	    Tcl_Return(interp, Sym_FullName(sym), TCL_DYNAMIC);
	}
	break;
    case SYMBOL_CLASS:
    {
	/*
	 * Return only the first class that's applicable.
	 */
	ObjSym	*s = SymLock(sym);
	int 	class = symMap[s->type].class;

	for (i = 0; i < Number(symclasses); i++) {
	    if (class & symclasses[i].class) {
		Tcl_Return(interp, symclasses[i].name, TCL_STATIC);
		break;
	    }
	}
	assert(i >= 0);
	SymUnlock(sym);
	break;
    }
    case SYMBOL_GET:
    {
	ObjSym	*s = SymLock(sym);
	char	*retav[5];
	char	val1[32], val2[32], val3[32];
	int 	retac;


	switch(s->type) {
	    case OSYM_CHUNK:
		sprintf(val1, "%d", s->u.addrSym.address);
		retav[0] = val1;
		retav[1] = "lmem";
		retav[2] = Type_ToAscii(SymGetType(sym));
		retac = 3;
		break;
	    case OSYM_CLASS:
	    case OSYM_MASTER_CLASS:
	    case OSYM_VARIANT_CLASS:
	    {
		ID  	superID = OBJ_FETCH_SID(s->u.class.super);
		char	*superName;
		Sym 	super;

		if (superID == NullID) {
		    super = NullSym;
		} else {
		    superName = SymLockID(sym, superID);

		    super = SymLookupInPatient(Sym_Patient(sym),
					       superName,
					       SYM_VAR);
		    SymUnlockID(sym, superID);
		}

		sprintf(val1, "%d", s->u.addrSym.address);
		retav[0] = val1;
		retav[1] = "static";
		retav[2] = Type_ToAscii(SymGetType(sym));
		retav[3] = ((s->type == OSYM_VARIANT_CLASS) ? "variant" :
			    (s->type == OSYM_MASTER_CLASS) ? "master" : "");
		retav[4] = Sym_ToAscii(super);
		retac = 5;

		break;
	    }
	    case OSYM_LOCAL_STATIC:
	    {
		Sym vsym;

		/*
		 * Redirect sym to the variable to which we point and do this
		 * again
		 */
		SymFile(vsym) = SymFile(sym);
		SymBlock(vsym) = s->u.localStatic.symBlock;
		SymOffset(vsym) = s->u.localStatic.symOff;

		SymUnlock(sym);
		sym = vsym;
		s = SymLock(sym);
		/*FALLTHRU*/
	    }
	    case OSYM_VAR:
		sprintf(val1, "%d", s->u.addrSym.address);
		retav[0] = val1;
		retav[1] = "static";
		retav[2] = Type_ToAscii(SymGetType(sym));
		retac = 3;
		break;
	    case OSYM_LOCVAR:
		sprintf(val1, "%d", s->u.localVar.offset);
		retav[0] = val1;
		retav[1] = (s->u.localVar.offset < 0) ? "local" : "param";
		retav[2] = Type_ToAscii(SymGetType(sym));
		retac = 3;
		break;
	    case OSYM_REGVAR:
		sprintf(val1, "%d", s->u.localVar.offset);
		retav[0] = val1;
		retav[1] = "reg";
		retav[2] = Type_ToAscii(SymGetType(sym));
		retac = 3;
		break;
	    case OSYM_PROFILE_MARK:
		sprintf(val1, "%d", s->u.profMark.address);
		sprintf(val2, "%d", s->u.profMark.markType);
		retav[0] = val1;
		retav[1] = val2;
		retac = 2;
		break;
	    case OSYM_LABEL:
	    case OSYM_LOCLABEL:
		sprintf(val1, "%d", s->u.addrSym.address);
		retav[0] = val1;
		retav[1] = (s->u.label.near ? "near" : "far");
		retac = 2;
		break;
	    case OSYM_PROC:
	    {
		Boolean	isFar;
		Address	addr;
		Type	retType;

		Sym_GetFuncData(sym, &isFar, &addr, &retType);

		sprintf(val1, "%d", (int)addr);
		retav[0] = val1;
		retav[1] = (isFar ? "far" : "near");
		retav[2] = Type_ToAscii(retType);
		retac = 3;
		break;
	    }
	    case OSYM_FIELD:
	    {
		Type	    ftype;
		genptr	    base;
		ObjSym	    *ns;
		SymToken    fsym;

		ftype = SymGetType(sym);
		sprintf(val1, "%d", s->u.sField.offset * 8);
		sprintf(val2, "%d", Type_Sizeof(ftype) * 8);
		strcpy(val3, Type_ToAscii(ftype));

		base = (genptr)s - SymOffset(sym);
		for (ns = (ObjSym *)(base + s->u.sField.next);
		     ns->type == OSYM_FIELD;
		     ns = (ObjSym *)(base + ns->u.sField.next))
		{
		    ;
		}
		fsym.file = SymFile(sym);
		fsym.block = SymBlock(sym);
		fsym.offset = (genptr)ns - base;

		retav[0] = val1;
		retav[1] = val2;
		retav[2] = val3;
		retav[3] = Sym_ToAscii(*(Sym *)&fsym);
		retac = 4;
		break;
	    }
	    case OSYM_BITFIELD:
	    {
		Type	    ftype;
		genptr	    base;
		ObjSym	    *ns;
		SymToken    fsym;

		ftype = SymGetType(sym);
		sprintf(val1, "%d", s->u.bField.offset);
		sprintf(val2, "%d", s->u.bField.width);
		strcpy(val3, Type_ToAscii(ftype));

		base = (genptr)s - SymOffset(sym);
		for (ns = (ObjSym *)(base + s->u.bField.next);
		     ns->type == OSYM_BITFIELD;
		     ns = (ObjSym *)(base + ns->u.bField.next))
		{
		    ;
		}
		fsym.file = SymFile(sym);
		fsym.block = SymBlock(sym);
		fsym.offset = (genptr)ns - base;

		retav[0] = val1;
		retav[1] = val2;
		retav[2] = val3;
		retav[3] = Sym_ToAscii(*(Sym *)&fsym);
		retac = 4;
		break;
	    }
	    case OSYM_VARDATA:
	    {
                genptr      base;
                ObjSym      *ns;
                SymToken    fsym;

                sprintf(val1, "%d", s->u.varData.value);

		/* find containing etype */
                base = (genptr)s - SymOffset(sym);
                for (ns = (ObjSym *)(base + s->u.varData.next);
                     ns->type == OSYM_VARDATA;
                     ns = (ObjSym *)(base + ns->u.varData.next))
                {
                    ;
                }
                fsym.file = SymFile(sym);
                fsym.block = SymBlock(sym);
                fsym.offset = (genptr)ns - base;

		retav[0] = val1;
		retav[1] = Sym_ToAscii(*(Sym *)&fsym);
		retav[2] = Type_ToAscii(SymGetType(sym));
		retac = 3;
		break;
	    }
	    case OSYM_ENUM:
		sprintf(val1, "%d", s->u.eField.value);

		retav[0] = val1;
		retav[1] = Type_ToAscii(SymGetType(sym));
		retac = 2;
		break;
	    case OSYM_METHOD:
		sprintf(val1, "%d", s->u.method.value);

		retav[0] = val1;
		retav[1] = Type_ToAscii(SymGetType(sym));
		retac = 2;
		break;
	    case OSYM_CONST:
		sprintf(val1, "%d", s->u.constant.value);
		retav[0] = val1;
		retac = 1;
		break;
	    case OSYM_BLOCKSTART:
	    case OSYM_BLOCKEND:
		sprintf(val1, "%d", s->u.addrSym.address);

		retav[0] = val1;
		retac = 1;
		break;
	    case OSYM_MODULE:
		sprintf(val1, "%d", (int)(Sym_Patient(sym)));

		retav[0] = val1;
		retac = 1;
		break;
	    case OSYM_ONSTACK:
	    {
		char	*data = SymLockID(sym,
					  OBJ_FETCH_SID(s->u.onStack.desc));

		sprintf(val1, "%d", s->u.onStack.address);

		retav[0] = val1;
		retav[1] = (char *)malloc(strlen(data)+1);
		retac = 2;

		strcpy(retav[1], data);
		SymUnlockID(sym, OBJ_FETCH_SID(s->u.onStack.desc));

		Tcl_Return(interp, Tcl_Merge(retac, retav), TCL_DYNAMIC);

		free((malloc_t)retav[1]);
		SymUnlock(sym);
		return(TCL_OK);
	    }
	    default:
		assert(0);
	}
	Tcl_Return(interp, Tcl_Merge(retac, retav), TCL_DYNAMIC);
	SymUnlock(sym);
	break;
    }
    case SYMBOL_TGET:
	Tcl_Return(interp, Type_ToAscii(SymGetType(sym)), TCL_STATIC);
	break;
    case SYMBOL_FIND:
    {
	/*
	 * Find a symbol of a given class in the current scope.
	 */
	int 	class;

	if (SymParseClass(interp, argv[2], &class) == TCL_ERROR) {
	    return(TCL_ERROR);
	}

	if (argc == 5) {
	    Sym	scope = Sym_ToToken(argv[4]);
	    ID	id;

	    if (Sym_IsNull(scope)) {
		Tcl_Error(interp, "invalid scope for sym find");
	    }
	    id = SymLookupID(argv[3], scope);
	    sym = SymLookup(id, class, scope);
	} else {
	    sym = Sym_Lookup(argv[3], class, curPatient->global);
	}

	Tcl_Return(interp, Sym_ToAscii(sym), TCL_VOLATILE);
	break;
    }
    case SYMBOL_FADDR:
    {
	/*
	 * Find a symbol of a given class closest to the given address
	 */
	int 	    class;
	GeosAddr    addr;

	if (SymParseClass(interp, argv[2], &class) == TCL_ERROR) {
	    return(TCL_ERROR);
	}
	if (Expr_Eval(argv[3], NullFrame, &addr, (Type *)NULL, TRUE)) {
	    sym = Sym_LookupAddr(addr.handle, addr.offset, class);
	} else {
	    sym = NullSym;
	}

	Tcl_Return(interp, Sym_ToAscii(sym), TCL_VOLATILE);
	break;
    }
    case SYMBOL_MATCH:
    {
	/*
	 * Find all symbols of the given class that match the given pattern.
	 */
	int 	    class;
	Vector 	    result;

	if (SymParseClass(interp, argv[2], &class) == TCL_ERROR) {
	    return(TCL_ERROR);
	}

	/*
	 * Look for matches in all patients linked to this one, placing the
	 * resulting Syms in result.
	 */
	result = Vector_Create(sizeof(Sym), ADJUST_ADD, 10, 10);
	if (argc == 5) {
	    /*
	     * Match just within a scope.
	     */
	    Sym	    scope = Sym_ToToken(argv[4]);

	    if (Sym_IsNull(scope)) {
		Tcl_Error(interp, "invalid symbol for scope");
	    }
	    SymbolMatch(argv[3], class, scope, result);
	} else {
	    /*
	     * Match everywhere.
	     */
	    SymbolMatchInPatient(argv[3], class, curPatient, result, 1);

	    if (curPatient != loader)
	    {
		/*
		 * Finally, the Kernel/loader
		 */
		SymbolMatchInPatient(argv[3], class, loader, result, 1);
	    }

	    /*
	     * Look in the default patient if not the same as the current.
	     */
	    if (VALIDTPTR(defaultPatient,TAG_PATIENT) &&
		(curPatient != defaultPatient))
	    {
		SymbolMatchInPatient(argv[3], class, defaultPatient,
				     result, 0);
	    }
	}

	if (Vector_Length(result) != 0) {
	    /*
	     * Not empty -- print the symbol tokens into an array. We allocate
	     * 32 bytes for each token, just to be on the safe side. During
	     * the loop we build up a vector pointing into the buffer that we
	     * then pass to Tcl_Merge to handle creating a list of the things,
	     * with associated curly braces etc.
	     */
	    char    *cp;
	    Sym	    *symp;
	    int	    retargc = Vector_Length(result);
	    char    **retargv;
	    int	    i;
	    char    *retbuf;

	    retargv = (char **)calloc(retargc, sizeof(char *));

	    cp = retbuf = (char *)malloc_tagged(retargc * 32, TAG_ETC);

	    for (i = 0, symp = (Sym *)Vector_Data(result);
		 i < retargc;
		 i++, symp++)
	    {
		strcpy(cp, Sym_ToAscii(*symp));
		retargv[i] = cp;
		cp += strlen(cp) + 1;
	    }
	    Tcl_Return(interp, Tcl_Merge(retargc, retargv), TCL_DYNAMIC);
	    free((malloc_t)retargv);
	    free(retbuf);
	} else {
	    /*
	     * Return empty
	     */
	    Tcl_Return(interp, NULL, TCL_STATIC);
	}
	Vector_Destroy(result);
	break;
    }
    case SYMBOL_ADDR:
    {
	ObjSym	    *s = SymLock(sym);

	switch(s->type) {
	    case OSYM_VAR:
	    case OSYM_CHUNK:
	    case OSYM_PROC:
	    case OSYM_LABEL:
	    case OSYM_LOCLABEL:
	    case OSYM_BLOCKSTART:
	    case OSYM_BLOCKEND:
	    case OSYM_CLASS:
	    case OSYM_MASTER_CLASS:
	    case OSYM_VARIANT_CLASS:
	    case OSYM_PROFILE_MARK:
	    {
		if (s->flags & OSYM_ENTRY)
		{
		    Rpc_IndexToOffset(Sym_Patient(sym),
						 (word)s->u.addrSym.address,
						s);
		}
		Tcl_RetPrintf(interp, "%d", s->u.addrSym.address);
		break;
	    }
	    case OSYM_LOCVAR:
	    case OSYM_REGVAR:
		Tcl_RetPrintf(interp, "%d", s->u.localVar.offset);
		break;
	    default:
		SymUnlock(sym);
		Tcl_Error(interp, "symbol has no address");
	}
	SymUnlock(sym);
	break;
    }
    case SYMBOL_PATIENT:
	Tcl_RetPrintf(interp, "%d", Sym_Patient(sym));
	break;
    case SYMBOL_TYPE:
	Tcl_Return(interp, symMap[Sym_Type(sym)].name, TCL_STATIC);
	break;
    case SYMBOL_FOREACH:
    {
	int 	class;

	if (SymParseClass(interp, argv[3], &class) == TCL_ERROR) {
	    return(TCL_ERROR);
	}

	Sym_ForEach(sym, class, SymForeachCmdCallback, (Opaque)argv);
	break;
    }
    }
    return(TCL_OK);
}

#define CHECK_CLASS(rS, c, dt, f, r) assert (symMap[(rS)->type].class & (c))

#define COND_ASSIGN(ptr, var) if (ptr) { *ptr = var; }

/***********************************************************************
 *				Sym_Patient
 ***********************************************************************
 * SYNOPSIS:	    Figure out the patient for a symbol.
 * CALLED BY:	    INTERNAL/EXTERNAL
 * RETURN:	    Patient for the symbol
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	We base our choice on the file handle contained in the symbol
 *	token, searching for the patient whose symFile field matches it.
 *	Note that we need to first check the current patient and see if
 *	the symbol belongs to it, or we'll ascribe all symbols for multiple
 *	instances of an application to the first instance, which causes
 *	problems.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/30/90		Initial Revision
 *
 ***********************************************************************/
Patient
Sym_Patient(Sym	    sym)
{
    VMHandle	    file = SymFile(sym);

    if ((curPatient != NullPatient) && (curPatient->symFile == file)) {
	return (curPatient);
    } else {
	LstNode	    ln;
	Patient	    patient;
	extern Lst  dead;   	/* List of dead patients. We can get symbols
				 * from these things upon occasion, so we need
				 * to look there */

	for (ln = Lst_First(patients); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    patient = (Patient)Lst_Datum(ln);

	    if (patient->symFile == file) {
		return(patient);
	    }
	}
	/* XXX: THIS MAY BE DANGEROUS */
	for (ln = Lst_First(dead); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    patient = (Patient)Lst_Datum(ln);

	    if (patient->symFile == file) {
		return(patient);
	    }
	}
    }
    assert(0);			/* Should never happen */
    return(NullPatient);
}

/***********************************************************************
 *				Sym_ToAddr
 ***********************************************************************
 * SYNOPSIS:	    Convert from an address-bearing symbol to a GeosAddr
 * CALLED BY:	    (EXTERNAL/INTERNAL)
 * RETURN:	    *addrPtr filled in.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/26/93		Initial Revision
 *
 ***********************************************************************/
void
Sym_ToAddr(Sym	    sym,
	   GeosAddr  *addrPtr)
{
    Sym	    module;
    Patient patient;
    int	    i;

    /*
     * First locate the module in which the thing resides.
     */
    for (module = sym;
	 !(Sym_Class(module) & SYM_MODULE);
	 module = Sym_Scope(module, FALSE))
    {
	;
    }

    /*
     * Now map that to the resource descriptor for the module's patient,
     * recording the handle of the resource.
     */
    patient = Sym_Patient(module);
    for (i = 0; i < patient->numRes; i++) {
	if (Sym_Equal(module, patient->resources[i].sym)) {
	    addrPtr->handle = patient->resources[i].handle;
	    break;
	}
    }

    assert(i != patient->numRes);

    /*
     * Now fetch the offset for the symbol itself.
     */
    if (Sym_Class(sym) & SYM_VAR) {
	Sym_GetVarData(sym, (Type *)NULL, (StorageClass *)NULL,
		       &addrPtr->offset);
    } else {
	Sym_GetFuncData(sym, (Boolean *)NULL, &addrPtr->offset,
			(Type *)NULL);
    }
}



/***********************************************************************
 *				SymProcessPossibleMethodPath
 ***********************************************************************
 * SYNOPSIS:	    Deal with specification of method as class::message,
 *	    	    with appropriate abbreviations for class (minus the
 *		    trailing Class) and message (minus the leading MSG_)
 * CALLED BY:	    (INTERNAL) Sym_Lookup
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	if {[null $s]} {
 *	    var colon [string first :: $args]
 *	    if {$colon >= 0} {
 *	    	var class [range $args 0 [expr $colon-1] char]
 *		var msg [range $args [expr $colon+2] end char]
 *
 *    	    	var cs [symbol find var $class]
 *		[if {[null $cs] ||
 *		     [type name [index [symbol get $cs] 2] {} 0] !=
 *                                                     {struct ClassStruct}}
 *    	    	{
 *		    var cs [symbol find var ${class}Class]
 *		    if {[null $cs]} {
 *			error [format {neither %s nor %sClass is a
 *                                                            defined class}
 *			    	$class $class]
 *		    }
 *    	    	}]
 *
 *		var ms [symbol find enum $msg]
 *		if {[null $ms]} {
 *		    var ms [symbol find enum MSG_${msg}]
 *
 *		    if {[null $ms]} {
 *		    	error [format {neither %s nor MSG_%s is a
 *                                                           defined message}
 *			    	    $msg $msg]
 *    	    	    }
 *    	    	}
 *
 *		var s [obj-find-method [index [symbol get $ms] 0]
 *		    	    [symbol fullname $cs] 1]
 *    	    }
 *    	}
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/27/93		Initial Revision
 *
 ***********************************************************************/
static Sym
SymProcessPossibleMethodPath(const char *name,
			     int    	class,
			     Sym    	scope,
			     Boolean	lookEverywhere,
			     const char	**endPtr)
{
    static int      superClassOff,  /* Offset of superclass ptr w/in class */
		    methodCountOff, /* Offset of methodCount w/in class */
		    methodTableOff; /* Offset of method table w/in class */
    Sym	    	    result; 	    /* The method we found. */
    Boolean 	    found = FALSE;  /* Loop control */
    const char	    *colon; 	    /* End of the component being parsed */
    char    	    *className;	    /* Temp variable holding the name of
				     * the class, possibly with "Class" tacked
				     * on */
    const char	    *msgStart;	    /* Start of the message name */
    char    	    *msgName;	    /* Temp variable holding the name of the
				     * message, possibly with "MSG_" prepended
				     */
    Sym	    	    msgSym; 	    /* Symbol for the message */
    ObjSym    	    *msg;   	    /* Locked version of same */
    Sym	    	    classSym;	    /* Symbol for the class */
    word    	    msgnum; 	    /* Number of the message whose method is
				     * being sought */
    GeosAddr	    classAddr;	    /* Address of the class being searched */


    /*
     * Locate the offsets for the various parts of a class structure
     * once during a session.
     */
    if (methodTableOff == 0) {
	static const struct {
	    const char 	*name;
	    int	    	*offVar;
	}   	fields[] = {
	    {"Class_superClass", &superClassOff},
	    {"Class_methodCount", &methodCountOff},
	    {"Class_methodTable", &methodTableOff}
	};
	Sym 	sym;
	int 	i;

	if (kernel == NullPatient) {
	    return(NullSym);
	}

	for (i = 0; i < sizeof(fields)/sizeof(fields[0]); i++) {
	    sym = Sym_Lookup(fields[i].name, SYM_FIELD, kernel->global);
	    if (Sym_IsNull(sym)) {
		return(NullSym);
	    }
	    Sym_GetFieldData(sym, fields[i].offVar, (int *)NULL, (Type *)NULL,
			     (Type *)NULL);

	    /*
	     * Convert from bit-offset to byte-offset.
	     */
	    *fields[i].offVar /= 8;
	}
    }

    /*
     * First locate the end of the class name.
     */
    colon = index(name, ':');
    if (colon == NULL) {
	return NullSym;
    }

    /*
     * Allocate a buffer large enough to hold it and the "Class" that we
     * might have to tack onto the end, should we not find the thing under
     * this name.
     */
    className = (char *)malloc(colon - name + 5 + 1);
    bcopy((char *)name, (char *)className, colon - name);
    className[colon - name] = '\0';

    if (lookEverywhere) {
	/*
	 * If no components in the symbol path before this one, call Sym_Lookup
	 * back again asking it to find us a variable of the name anywhere it
	 * can.
	 */
	classSym = Sym_Lookup(className, SYM_VAR, scope);
    } else {
	/*
	 * Look only in the given scope
	 * XXX: need to deal with scope being the global one..
	 */
	classSym = Sym_LookupInScope(className, SYM_VAR, scope);
    }

    if (!Sym_IsNull(classSym)) {
	/*
	 * Make sure it's a class, not just a variable whose name is
	 * the abbreviated name of the class.
	 */
	switch (Sym_Type(classSym)) {
	case OSYM_VAR:
	{
	    char *typeName = Type_Name(SymGetType(classSym), "", FALSE);
	    if (strcmp(typeName, "struct ClassStruct") != 0) {
		classSym = NullSym;
	    }
	    free ((malloc_t)typeName);
	    break;
	}
	case OSYM_CLASS:
	case OSYM_MASTER_CLASS:
	case OSYM_VARIANT_CLASS:
	    break;
	default:
	    classSym = NullSym;
	    break;
	}
    }

    if (Sym_IsNull(classSym)) {
	/*
	 * Couldn't find it by that name, but a rose by any other... I digress.
	 * Tack "Class" onto the end and perform a search as before.
	 */
	strcat(className, "Class");

	if (lookEverywhere) {
	    classSym = Sym_Lookup(className, SYM_VAR, scope);
	} else {
	    classSym = Sym_LookupInScope(className, SYM_VAR, scope);
	}

	if (Sym_IsNull(classSym)) {
	    free((malloc_t)className);
	    return NullSym;
	}
    }

    free((malloc_t)className);

    /*
     * Find the start of the message name, immediately following the colon
     * (or double colon, as appropriate).
     */
    if (colon[1] == ':') {
	msgStart = colon+2;
    } else {
	msgStart= colon+1;
    }
    colon = index(msgStart, ':');

    if (colon == NULL) {
	/*
	 * Message name extends to the end of the string.
	 */
	colon = msgStart + strlen(msgStart);
    }

    /*
     * Allocate room for the given name, plus room for prepending "MSG_"
     */
    msgName = (char *)malloc(4 + colon - msgStart + 1);
    bcopy((char *)msgStart, (char *)msgName, colon - msgStart);
    msgName[colon - msgStart] = '\0';

    /*
     * Perform global search using passed scope, regardless of whether there
     * were components before this convoluted thing in the symbol path, as
     * messages are almost always in the global scope.
     */
    msgSym = Sym_Lookup(msgName, SYM_ENUM, scope);
    if (Sym_IsNull(msgSym)) {
	/*
	 * Not there. Try it with MSG_ prepended.
	 */
	bcopy("MSG_", msgName, 4);
	bcopy((char *)msgStart, (char *)msgName+4, colon - msgStart);
	msgName[colon - msgStart + 4] = '\0';

	msgSym = Sym_Lookup(msgName, SYM_ENUM, scope);
	if (Sym_IsNull(msgSym)) {
	    free((malloc_t)msgName);
	    return NullSym;
	}
    }

    free((malloc_t)msgName);

    msg = SymLock(msgSym);
    msgnum = msg->u.eField.value;
    SymUnlock(msgSym);

    /*
     * Now look for the method for the beast. First compute the handle and
     * offset of the starting class.
     */
    Sym_ToAddr(classSym, &classAddr);

    while (!found) {
	word	count;
	int 	i;

	/*
	 * Fetch the number of methods implemented by this class.
	 */
	Var_FetchInt(2, classAddr.handle, classAddr.offset + methodCountOff,
		     (genptr)&count);

	/*
	 * Loop through the table of message numbers looking for the one we've
	 * got.
	 */
	for (i = 0; i < count; i++) {
	    word    thismsg;

	    Var_FetchInt(2, classAddr.handle,
			 classAddr.offset + methodTableOff + 2 * i,
			 (genptr)&thismsg);
	    if (thismsg == msgnum) {
		break;
	    }
	}

	if (i != count) {
	    /*
	     * Found our target message in the table. Fetch and decode the
	     * virtual far pointer to the method itself.
	     */
	    dword   method;

	    found = TRUE;	/* Stop looping whether we can obtain a symbol
				 * for the method or not. */

	    Var_FetchInt(4, classAddr.handle,
			 classAddr.offset + methodTableOff + 2 * count + 4 * i,
			 (genptr)&method);

	    /* Offset always in low word */
	    classAddr.offset = (Address)(method & 0xffff);

	    if ((method & 0xf0000000) == 0xf0000000) {
		/*
		 * Movable memory.
		 */
		classAddr.handle = Handle_Lookup((word)((method >> 12) & 0xfff0));
	    } else {
		/*
		 * Fixed memory.
		 */
		classAddr.handle =
		    Handle_Find((Address)((method >> 12) & 0xffff0));
	    }
	    /*
	     * Now lookup the method itself, as that's the goal of this whole
	     * exercise. If the lookup fails, the whole thing fails.
	     */
	    result = /*(Sym)*/Sym_LookupAddrExact(classAddr.handle,
				    classAddr.offset,
				    SYM_FUNCTION);
	    break;
	} else {
	    /*
	     * Not implemented at this level, so advance to the superclass.
	     */
	    dword   super;

	    Var_FetchInt(4, classAddr.handle,
			 classAddr.offset + superClassOff,
			 (genptr)&super);

	    if (((super & 0xffff0000) == 0x00010000) || (super == 0)) {
		/*
		 * Variant or meta, so can't go higher.
		 */
		result = NullSym;
		found = TRUE;
	    } else {
		/*
		 * Decompose the far pointer to get the address of the super
		 * class.
		 */

		classAddr.handle =
		    Handle_Find((Address)((super >> 12) & 0xffff0));
		classAddr.offset = (Address)(super & 0xffff);

		if (classAddr.handle == NullHandle) {
		    /*
		     * If we can't locate the block in which the superclass
		     * resides, we're not going to get very far with its
		     * method, so we might as well stop now.
		     */
		    result = NullSym;
		    found = TRUE;
		}
	    }
	}
    }

    /*
     * Point *endPtr after the stuff we used (on the colon, if there is one,
     * or before the null, so the caller knows there's nothing more and will
     * believe the thing ended with ::).
     */
    if (*colon == ':') {
	*endPtr = colon;
    } else {
	*endPtr = colon-1;
    }
    return result;
}


/*-
 *-----------------------------------------------------------------------
 * Sym_LookupInScope --
 *	Examine the given scope for a symbol of the given name and class.
 *
 * Results:
 *	The Symbol, if found, NULL if not found.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Sym
Sym_LookupInScope(const char	*name,	    /* Symbol to find */
		  int	    	class,	    /* Classes desired */
		  Sym	    	scope)	    /* Scope to check */
{
    if (!Sym_IsNull(scope)) {
	return(SymLookup(SymLookupID(name, scope), class, scope));
    } else {
	return (NullSym);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Sym_Lookup --
 *	Find a symbol in the given context by name.
 *
 * Results:
 *	The token for the symbol, or NullSym if it can't be found.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Sym
Sym_Lookup(const char  	*name,	    /* Name to search for */
	   int	    	class,	    /* Acceptable classes */
	   Sym	    	scope)	    /* Scope from which to start */
{
    Sym	    	    	sym;
    char    	    	*cp;

    /* mark the chached method a null */
    cachedMethod.handle = 0;
    if (Sym_IsNull(scope)) {
	return NullSym;
    }

    /*
     * Symbols we are passed may look like
     *	patient::module::proc::block::symbol
     * patient, module, proc and block are optional (e.g. patient::symbol is
     * permitted). patient should be the <name> field of an existing patient.
     * If the name contains a colon, perform this mapping and return the
     * result -- there is no searching through libraries or the kernel/loader.
     */
    cp = index(name, ':');
    if (cp != (char *)NULL) {
	const char *start = name;
	ID  	id;
	Boolean	checkPatient = TRUE;	/* Set if we should see if the
					 * current component might be a
					 * patient name. */
	Boolean checkEverywhere = TRUE;	/* Set if we should look for the
					 * current component everywhere
					 * within the patient that owns
					 * the passed scope, and in the
					 * default patient, if that's set
					 * and the component is nowhere
					 * in the current patient */
	sym = NullSym;

	while (cp != (char *)NULL) {
	    id = SymLookupIDLen(start, cp - start, scope);

	    if (id != NullID) {
		sym = SymLookup(id, SYM_SCOPE, scope);
	    }
	    if (Sym_IsNull(sym) || (Sym_Class(sym)&SYM_TYPE)) {
		/*
		 * scope not found in current scope/ID not found in
		 * current file/symbol found is actually a structured type
		 * masquerading as a scope...
		 */
		if ((start == name) || checkPatient || checkEverywhere) {
		    /*
		     * This is the first component of the whole thing. We're
		     * more lenient here as we're still trying to get our
		     * bearings. First see if the current scope is within
		     * some other scope. If so, we just loop back to look
		     * for the current component in the parent scope.
		     */
		    Sym	newscope;

		    newscope = Sym_Scope(scope, TRUE);
		    if (!Sym_IsNull(newscope)) {
			/*
			 * More to check -- do so without advancing to next
			 * component, since haven't processed this one yet...
			 */
			scope = newscope;
			continue;
		    }
		    if (checkPatient) {
			/*
			 * Well, that went over like a watermelon. See if
			 * the thing is a patient. Note we copy the component
			 * to a separate array rather than forcibly null-
			 * terminating it as that tends to have bad effects if
			 * the name we were given is a string constant
			 * that was allocated in text space.
			 */
			char    *pname;
			Patient patient;

			pname = (char *)malloc(cp-start+1);

			bcopy((char *)start, (char *)pname, cp-start);
			pname[cp-start] = '\0';
			patient = Patient_ByName(pname);
			free((malloc_t)pname);

			if (patient != NullPatient) {
			    newscope = patient->global;
			    checkPatient = FALSE;
			    checkEverywhere = TRUE;
			}
		    }
		    if (Sym_IsNull(newscope)) {
			if (checkEverywhere) {
			    /*
			     * Penultimate try -- look through all scopes
			     * available to this patient for the thing. We
			     * do this last as it will cause blocks to come
			     * in from all over the place.
			     */
			    newscope =
				SymLookupInPatientLen(Sym_Patient(scope),
						      start, cp-start,
						      SYM_SCOPE);
			    /*
			     * Really the last straw -- if there's a default
			     * patient that's not the same as we just examined,
			     * try looking there for the first element of the
			     * path...
			     */
			    if (Sym_IsNull(newscope) &&
				(Sym_Patient(scope) != defaultPatient) &&
				VALIDTPTR(defaultPatient,TAG_PATIENT))
			    {
				newscope =
				    SymLookupInPatientLen(defaultPatient,
							  start,
							  cp-start,
							  SYM_SCOPE);
			    }
			}
			if (Sym_IsNull(newscope)) {
			    newscope =
				SymProcessPossibleMethodPath(start,
							     class,
							     scope,
							     checkEverywhere,
							   (const char **)&cp);
			    if (Sym_IsNull(newscope)) {
				return NullSym;
			    }
			}
			checkEverywhere = checkPatient = FALSE;
		    }
		    scope = newscope;
		} else {
		    /*
		     * Any other non-existent scope along the path is
		     * grounds for divorce...
		     */
		    scope =
			SymProcessPossibleMethodPath(start,
						     class,
						     scope,
						     checkEverywhere,
						     (const char **)&cp);
		    if (Sym_IsNull(scope)) {
			return NullSym;
		    }
		}
	    } else {
		checkPatient = checkEverywhere = FALSE;
		scope = sym;
	    }
	    /*
	     * scope should now contain the proper symbol for this most
	     * recent component, so advance "start" past it. We allow either
	     * single or double colons, just to be nice.
	     */
	    start = cp+1;
	    if (*start == ':') {
		start++;
	    }
	    /*
	     * See if there's another component to be found...
	     */
	    cp = index(start, ':');
	}

	if (*start == '\0') {
	    /*
	     * Path terminated in a :: => caller wants just the scope itself,
	     * if that fits the desired class...
	     */
	    if (Sym_Class(scope) & class) {
		return(scope);
	    } else {
		return NullSym;
	    }
	}

	/*
	 * Now have the exact scope in which the symbol is expected to be...
	 * unless the string contained only a patient name, but we'll get to
	 * that in a moment.
	 */
	id = SymLookupID(start, scope);
	if (id == NullID) {
	    return NullSym;
	}
	sym = SymLookup(id, class, scope);
	if (Sym_IsNull(sym)) {
	    /*
	     * Handle patient::symbol case by performing a SymLookupInPatient
	     * for the scope's patient if the scope in which we just searched
	     * is the global scope for the patient, as reflected by its
	     * having a name of NULL.
	     */
	    ObjSym  *s = SymLock(scope);

	    id = s->name;
	    SymUnlock(scope);

	    if (id == NullID) {
		sym = SymLookupInPatient(Sym_Patient(scope), start, class);
	    }
	}
    } else {
	/*
	 * Seekez le in zis scope.
	 */
    	ID  id = SymLookupID(name, scope);
    	sym = SymLookup(id, class, scope);

	if (Sym_IsNull(sym)) {
	    /*
	     * Not found in this scope -- look for it everywhere. Note this
	     * will look in this scope again, but c'est la vie.
	     */
	    sym = SymLookupInPatient(Sym_Patient(scope), name, class);
	}

	/*
	 * Handle the defaultPatient here, rather than making everyone else
	 * do it.
	 * XXX: DOES THIS SCREW ANYONE UP?
	 */
	if (Sym_IsNull(sym) && (Sym_Patient(scope) != defaultPatient) &&
	    VALIDTPTR(defaultPatient,TAG_PATIENT))
	{
	    sym = SymLookupInPatient(defaultPatient, name, class);
	}
    }

    /*
     * Return the result, whatever it may be.
     */
    return (sym);
}


/*-
 *-----------------------------------------------------------------------
 * Sym_LookupAddr --
 *	Find a symbol of the given class that matches the given address.
 *	For SYM_SCOPE, this is the scope that most closely brackets the
 *	address. For everything else, this is the symbol whose value is
 *	closest to the address while still being below it.
 *
 * Results:
 *	A Sym fitting the above criteria.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Sym
Sym_LookupAddr(
	       Handle	handle,	    /* Handle in which address resides */
	       Address 	addr,	    /* Address to find */
	       int	class)	    /* Desired symbol class */
{
    return(SymLookupAddr(handle, addr, class, 0));
}

/*-
 *-----------------------------------------------------------------------
 * Sym_LookupAddrExact --
 *	Find a symbol of the given class that matches the given address.
 *	For SYM_SCOPE, this is the scope that most closely brackets the
 *	address. For everything else, this is the symbol whose value is
 *	AT the address while still being below it.
 *
 * Results:
 *	A Sym fitting the above criteria.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Sym
Sym_LookupAddrExact(
	       Handle	handle,	    /* Handle in which address resides */
	       Address 	addr,	    /* Address to find */
	       int	class)	    /* Desired symbol class */
{
    return(SymLookupAddr(handle, addr, class, 1));
}


/*********************************************************************
 *			Sym_GetCachedMethod
 *********************************************************************
 * SYNOPSIS: 	get the cached method
 * CALLED BY:	GLOBAL
 * RETURN:  	cached method
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/21/93		Initial version
 *
 *********************************************************************/
GeosAddr *
Sym_GetCachedMethod(void)
{
    return &cachedMethod;
}

/*-
 *-----------------------------------------------------------------------
 * SymLookupAddr --
 *	Find a symbol of the given class that matches the given address.
 *	For SYM_SCOPE, this is the scope that most closely brackets the
 *	address. For everything else, this is the symbol whose value is
 *	closest to the address while still being below it.
 *
 * Results:
 *	A Sym fitting the above criteria.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Sym
SymLookupAddr(Handle	handle,	    /* Handle in which address resides */
	      Address 	addr,	    /* Address to find */
	      int	class,	    /* Desired symbol class */
	      int   	wantExact)  /* is close enough ok, or not */
{
    Sym	    	    sym;

    sym = NullSym;

    class &= (SYM_NAMELESS|SYM_VAR|SYM_MODULE|SYM_FUNCTION|
	      SYM_LABEL|SYM_ONSTACK|SYM_SCOPE);

    if ((handle != NullHandle) && (Handle_State(handle) & (HANDLE_RESOURCE|
							   HANDLE_KERNEL))) {
	Sym    	    	module;	    /* Containing module */
	VMBlockHandle	map;	    /* Sym file's map block */
	ObjHeader   	*hdr;	    /* Locked version of same */
	ObjSym	    	*os;	    /* Current symbol */
	Patient	    	patient;    /* Patient to which handle belongs */
	ObjSegment  	*s; 	    /* Segment descriptor for getting
				     * address map */

	/*
	 * Find the patient and module symbol for the block
	 */
	patient = Handle_Patient(handle);
	module = patient->resources[(int)handle->otherInfo].sym;

	/*
	 * Lock down the symbol file's header and point s at the segment
	 * descriptor for the module so we can get to the address map.
	 */
	if (patient->symFile != (Opaque)NULL)
	{
	map = VMGetMapBlock(patient->symFile);
	hdr = (ObjHeader *)VMLock(patient->symFile, map, (MemHandle *)NULL);
	os = SymLock(module);
	s = (ObjSegment *)((genptr)hdr + os->u.module.offset);
	SymUnlock(module);

	if ((class != SYM_MODULE) && (s->addrMap != 0)) {
	    /*
	     * Segment actually has an address map. First find the likeliest
	     * block and begin searching backwards from there.
	     */
	    ObjAddrMapEntry	*oame;	    /* Current entry in the address
					     * map */
	    ObjAddrMapHeader	*oamh;	    /* Header for segment's map */
	    int	    	    	i;

	    oamh = (ObjAddrMapHeader *)VMLock(patient->symFile,
					      s->addrMap,
					      (MemHandle *)NULL);

	    /*
	     * Find the entry whose last address is *greater* than the offset
	     * to deal with weird cases that will probably never arise -- I'll
	     * let you figure it out.
	     */
	    for (i = oamh->numEntries, oame = (ObjAddrMapEntry *)(oamh+1);
		 i > 0;
		 i--, oame++)
	    {
		if (oame->last > (word)addr) {
		    break;
		}
	    }

	    /*
	     * Deal with falling off the end of the map by pre-decrementing
	     * oame to point it at a valid entry.
	     */
	    if (i == 0) {
		oame--;
		i++;
	    }


	    /*
	     * Now run through the list of address-symbol blocks looking
	     * for the first one of the indicated class(es) whose address
	     * is <= to the desired address. If there's not one in the
	     * block whose last address is just above the desired address,
	     * we just traverse the list in reverse order looking in
	     * each preceding block in the same manner until we find the
	     * thing we want or run out of blocks.

	     * I have changed this to run to the end of the current block
	     * rather than stopping once you get an address <= to addr because
	     * gym files aren't neccessarily in order, even this is a potential
	     * problem if the thing is in the wrong block, but since there
	     * are less symbols even kcode seems to fit in one block so
	     * hopefully this will be good enough, I am not sure how much
	     * slower this will make things...
	     */
	    while (i <= oamh->numEntries)
	    {
		ObjSymHeader	*osh;
		int 	    	j;
		ObjSym	    	*s = (ObjSym *)NULL;
		ObjSym	    	*lows = (ObjSym *)NULL;

		osh = (ObjSymHeader *)VMLock(patient->symFile,
					     oame->block,
					     (MemHandle *)NULL);
		os = &((ObjSym *)(osh+1))[osh->num];
		for (j = osh->num; j > 0; j--)
		{
		    os--;

		    if (os->flags & OSYM_ENTRY)
		    {
			Rpc_IndexToOffset(patient,
						(word)os->u.addrSym.address,
						    os);
		    }

		    /*
		     * Don't return symbols marked as NAMELESS unless
		     * specifically requested, so we deal nicely with ??START
		     * and things of that ilk.
		     */
		    if ((!(os->flags & OSYM_NAMELESS) ||
			 (class & SYM_NAMELESS)) &&
			(symMap[os->type].class & class) &&
			((word)os->u.addrSym.address <= (word)addr))
		    {

			if ((os->u.addrSym.address == (word)addr) ||
			    (s == (ObjSym *)NULL))
			{
			    /*
			     * Delay choice of symbol until next to deal
			     * with functions that begin with a local label.
			     * XXX: This doesn't handle functions that
			     * begin with more than one local label, but
			     * does give the proper result of using the local
			     * label, rather than the function, as the base for
			     * all things inside the function (up to the next
			     * local label, of course).
			     */
			    s = os;
			    if (lows == (ObjSym *)NULL ||
				(word)s->u.addrSym.address >
				(word)lows->u.addrSym.address)
			    {
				lows = s;
			    }
			    /*
			     * Give preference to procedure symbols. If we find
			     * one one these then no need to look further.
			     */
			    if (s->type == OSYM_PROC &&
				os->u.addrSym.address == (word)addr) {
				lows = s;
				break;
			    }

			}
			else
			{
			    if (lows == (ObjSym *)NULL ||
				(word)os->u.addrSym.address >
				(word)lows->u.addrSym.address)
			    {
				lows = os;
			    }
			    s = (ObjSym *)NULL;
			}
		    }
		}

		s = lows;
		if (((j != 0) || (s != (ObjSym *)NULL)) &&
		    !(wantExact &&
		     ((word)s->u.addrSym.address != (word)addr)))
		{
		    SymFile(sym) = patient->symFile;
		    SymBlock(sym) = oame->block;
		    SymOffset(sym) = (genptr)s - (genptr)osh;
		    VMUnlock(patient->symFile, oame->block);
		    break;
		}
		else
		{
		    /* if we found the thing, but its address was not
		     * exact, then we must be doing a class::msg lookup
		     * so just cache the address and return a null
		     */
		    if (wantExact && ((j != 0) || s != (ObjSym *)NULL))
		    {
			cachedMethod.handle = handle;
			cachedMethod.offset = addr;
		    }
		    VMUnlock(patient->symFile, oame->block);
		}
		oame--, i++;
	    }

	    VMUnlock(patient->symFile, s->addrMap);
	}
	VMUnlock(patient->symFile, map);
	}

	/*
	 * If we were searching for a module or a scope symbol and didn't
	 * find anything, just return the module symbol itself.
	 */
	if (Sym_IsNull(sym) && (class & (SYM_MODULE|SYM_SCOPE))) {
	    sym = module;
	}
    }
/*
    Message("LookupAddr: %04x:%04x = %s\n", Handle_ID(handle), addr,
            Sym_IsNull(sym) ? "NULL" : Sym_Name(sym));
*/
    return(sym);
}

/*-
 *-----------------------------------------------------------------------
 * Sym_Class --
 *	Return the class of the given symbol.
 *
 * Results:
 *	The class of the symbol.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Sym_Class(Sym	    sym)	    	/* Symbol to examine */
{
    ObjSym  	*s;
    int	    	class;

    assert(!Sym_IsNull(sym));

    s = SymLock(sym);
    class = symMap[s->type].class;
    SymUnlock(sym);

    return(class);
}

/*-
 *-----------------------------------------------------------------------
 * Sym_Scope --
 *	Find the containing lexical or physical scope of a symbol.
 *
 * Results:
 *	The Sym for the enclosing scope.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Sym
Sym_Scope(Sym	    sym,
	  Boolean   lexical)	/* TRUE if lexical scope desired (the one that
				 * contains the symbol's name), else physical
				 * scope desired (the one that contains the
				 * symbol's address). These are the same for
				 * (almost) all symbols except LOCAL_STATIC */
{
    ObjSym  	*s;

    s = SymLock(sym);

    switch(s->type) {
	case OSYM_FIELD:
	case OSYM_BITFIELD:
	{
	    /*
	     * Need to find the containing structure/union
	     */
	    genptr  	    base;
	    ObjSym  	    *os;

	    /*
	     * Point to the base of the symbol's block
	     */
	    base = ((genptr)s - SymOffset(sym));

	    for (os = (ObjSym *)(base + s->u.sField.next);
		 os->type == OSYM_FIELD || os->type == OSYM_BITFIELD;
		 os = (ObjSym *)(base + os->u.sField.next))
	    {
		;
	    }
	    SymOffset(sym) = (genptr)os-base;
	    SymUnlock(sym);
	    break;
	}
	case OSYM_TYPEDEF:
	case OSYM_STRUCT:
	case OSYM_RECORD:
	case OSYM_ETYPE:
	case OSYM_ENUM:
	case OSYM_METHOD:
	case OSYM_VARDATA:
	case OSYM_CONST:
	case OSYM_VAR:
	case OSYM_CHUNK:
	case OSYM_PROC:
	case OSYM_LABEL:
	case OSYM_ONSTACK:
	case OSYM_CLASS:
	case OSYM_MASTER_CLASS:
	case OSYM_VARIANT_CLASS:
	case OSYM_UNION:
        case OSYM_PROFILE_MARK:
	{
	    /*
	     * For all these things, we need to
	     *	1) get the segment descriptor offset from the header for
	     *	    the block
	     *	2) find the module symbol in the first block of the global
	     *	    segment's chain based on the segment's name.
	     */
	    ObjSymHeader    *osh;
	    VMBlockHandle   map;
	    ObjHeader	    *hdr;
	    ID	    	    id;
	    VMBlockHandle   modBlock;
	    int	    	    i;

	    /*
	     * Point to the base of the symbol's block
	     */
	    osh = (ObjSymHeader *)((genptr)s - SymOffset(sym));

	    /*
	     * Lock down the map block and extract the segment's name (ID) and
	     * the first symbol block in the global scope
	     */
	    map = VMGetMapBlock(SymFile(sym));
	    hdr = (ObjHeader *)VMLock(SymFile(sym), map, (MemHandle *)NULL);
	    id = ((ObjSegment *)((genptr)hdr + osh->seg))->name;
	    modBlock = ((ObjSegment *)(hdr+1))->syms;
	    VMUnlock(SymFile(sym), map);
	    /*
	     * Release the symbol so we can reuse osh, os and sym
	     */
	    SymUnlock(sym);
	    osh = (ObjSymHeader *)VMLock(SymFile(sym),
					 modBlock,
					 (MemHandle *)NULL);
	    for (i = osh->num, s = (ObjSym *)(osh+1); i > 0; i--, s++) {
		if (s->name == id) {
		    break;
		}
	    }
	    /*
	     * Adjust sym to be the module symbol. Of course, it's in the
	     * same file.
	     */
	    SymBlock(sym) = modBlock;
	    SymOffset(sym) = (genptr)s - (genptr)osh;
	    VMUnlock(SymFile(sym), modBlock);
	    break;
	}
	case OSYM_LOCAL_STATIC:
	    if (!lexical) {
		/*
		 * If lexical scope not desired, recurse to find the physical
		 * scope of the variable symbol to which we point.
		 */
		SymToken    vsym;

		vsym.file = SymFile(sym);
		vsym.block = s->u.localStatic.symBlock;
		vsym.offset = s->u.localStatic.symOff;

		SymUnlock(sym);

		sym = Sym_Scope(SymCast(vsym), lexical);
		break;
	    }
	    /*FALLTHRU*/
	case OSYM_LOCLABEL:
	case OSYM_BLOCKSTART:
	case OSYM_BLOCKEND:
	case OSYM_LOCVAR:
    	case OSYM_REGVAR:
	{
	    /*
	     * For these, we need to find the most-recent preceding
	     * blockstart or proc symbol in the current block.
	     */
	    genptr  base = (genptr)s-SymOffset(sym);
	    int	    nesting = 0;

	    while(--s >= (ObjSym *)(base+sizeof(ObjSymHeader))) {
		if (s->type == OSYM_BLOCKEND) {
		    nesting++;
		} else if (s->type == OSYM_BLOCKSTART) {
		    if (--nesting < 0) {
			break;
		    }
		} else if (s->type == OSYM_PROC) {
		    break;
		}
	    }
	    assert(s >= (ObjSym *)(base+sizeof(ObjSymHeader)));
	    SymOffset(sym) = (genptr)s - base;
	    SymUnlock(sym);
	    break;
	}
	case OSYM_MODULE:
	    /*
	     * All modules but the global one (aka the core block) are in
	     * the global scope. For the global scope itself we return Null
	     */
	    if (s->name != NullID) {
		SymUnlock(sym);
		sym = Sym_Patient(sym)->global;
	    } else {
		SymUnlock(sym);
		sym = NullSym;
	    }
	    break;
	default:
	    assert(0);
    }
    return (sym);
}

/***********************************************************************
 *				SymForEach
 ***********************************************************************
 * SYNOPSIS:	    Internal version of Sym_ForEach that actually
 *	    	    returns non-zero if callback function returned
 *	    	    non-zero, as required for exported message range
 *	    	    fun.
 * CALLED BY:	    Sym_ForEach, self
 * RETURN:	    non-zero if (*func)() returned non-zero to halt
 *	    	    processing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 8/91	Initial Revision
 *
 ***********************************************************************/
static int
SymForEach(ObjSym   	*ssym,	    	/* Locked scope symbol */
	   Sym	    	scope,	    	/* The original symbol itself */
	   int	    	class,	    /* Classes on which to call func */
	   Boolean    	(*func)(Sym sym, Opaque data),
	   Opaque	data) 	    /* Data to pass it */
{
    VMHandle	    file;

    file = SymFile(scope);
    switch(ssym->type) {
	case OSYM_MODULE:
	{
	    /*
	     * If scope is a module symbol, we need to look through the
	     * module's symbol list, as stored in the VM file.
	     */
	    VMBlockHandle	cur, next;

	    /*
	     * If module has no symbol table, can't be a match...
	     */
	    if (ssym->u.module.table == 0) {
		return(0);
	    }

	    for (cur = ssym->u.module.syms; cur != 0; cur = next) {
		int 	    	i;
		ObjSymHeader	*osh;
		ObjSym  	    	*os;
		SymToken	    	fsym; /*  = {file, cur,
					       *     sizeof(ObjSymHeader)};
					       * xxxDan */
		fsym.file = file;
		fsym.block = cur;
		fsym.offset = sizeof(ObjSymHeader);

		osh = (ObjSymHeader *)VMLock(file, cur, (MemHandle *)NULL);
		for (i = osh->num, os = (ObjSym *)(osh+1); i > 0; i--, os++) {
		    if (symMap[os->type].class & class) {
			int result = (*func)(*(Sym *)&fsym, data);

			if (result) {
			    VMUnlock(file, cur);
			    return(result);
			}
		    }
		    fsym.offset += sizeof(ObjSym);
		}
		next = osh->next;
		VMUnlock(file, cur);
	    }
	    break;
	}
	case OSYM_PROC:
	case OSYM_BLOCKSTART:
	{
	    word	    	loff;
	    ObjSymHeader	*osh;
	    ObjSym	    	*lsym;
	    SymToken    	fsym;

	    if (ssym->type == OSYM_PROC) {
		/*
		 * Look through the symbols local to the procedure for
		 * something that matches.
		 */
		loff = ssym->u.proc.local;
	    } else {
		loff = ssym->u.blockStart.local;
	    }

	    osh = (ObjSymHeader *)((genptr)ssym - SymOffset(scope));

	    fsym.file = SymFile(scope);
	    fsym.block = SymBlock(scope);

	    while (loff != 0 && loff != SymOffset(scope)) {
		assert(loff >= sizeof(ObjSymHeader) &&
		       loff < (sizeof(ObjSymHeader) +
			       (osh->num*sizeof(ObjSym))));
		lsym = (ObjSym *)((genptr)osh + loff);
		fsym.offset = loff;

		if (symMap[lsym->type].class & class) {
		    int	result = (*func)(*(Sym *)&fsym, data);

		    if (result) {
			return (result);
		    }
		}
		loff = lsym->u.procLocal.next;
	    }
	    break;
	}
	case OSYM_STRUCT:
	case OSYM_UNION:
	case OSYM_ETYPE:
	case OSYM_RECORD:
	{
	    ObjSymHeader    *osh;
	    ObjSym	    *lsym, *nsym;
	    SymToken        fsym;
	    word    	    loff;
	    int	    	    doCallback;	    /* Yes, I (tony) am a wimp.  The */
	    	    	    	    	    /* complexity of the expression */
	    	    	    	    	    /* drove me nuts */
	    int 	    result;

	    osh = (ObjSymHeader *)((genptr)ssym - SymOffset(scope));
	    loff = ssym->u.sType.first;

	    /*
	     * Make sure the type isn't empty (loff != 0) before looping
	     * through the entire list.
	     */
	    if (loff != 0) {
		fsym.file = SymFile(scope);
		fsym.block = SymBlock(scope);

		while (loff != SymOffset(scope)) {
		    assert(loff<sizeof(ObjSymHeader) +
			   (osh->num*sizeof(ObjSym)));
		    assert(loff>sizeof(ObjSymHeader));

		    result = 0;

		    lsym = (ObjSym *)((genptr)osh + loff);
		    fsym.offset = loff;

		    /*
		     * Note that labels in a structure are not passed off.
		     * This prevents evil swapping bugs and lets everyone
		     * else ignore distinguishing between a fake field and
		     * a real one. The field symbol itself is still
		     * available via Sym_LookupInScope
		     */

		    loff = lsym->u.tField.next;
		    nsym = (ObjSym *)((genptr)osh + loff);

		    if (symMap[lsym->type].class & class) {
		    	if (lsym->type == OSYM_FIELD &&
			    ssym->type == OSYM_STRUCT)
			{
			    if (nsym->type == OSYM_FIELD) {
				/*
				 * Next symbol is another field. Call the
				 * callback if the offsets don't match, taking
				 * bitfields into account.
				 */
			    	doCallback =
				    ((lsym->u.sField.offset !=
				      nsym->u.sField.offset) ||
				     (((lsym->u.sField.type & OTYPE_TYPE) ==
				       OTYPE_BITFIELD) &&
				      ((nsym->u.sField.type & OTYPE_TYPE) ==
				       OTYPE_BITFIELD) &&
				      ((lsym->u.sField.type&OTYPE_BF_OFFSET) !=
				       (nsym->u.sField.type&OTYPE_BF_OFFSET))
				     ));

			    } else {
				/*
				 * This is the last field. Call the callback
				 * only if this field has any size (i.e. the
				 * structure is bigger than the field's offset)
				 */
			    	doCallback = (lsym->u.sField.offset <
					      ssym->u.sType.size);
			    }
			} else if ((lsym->type == OSYM_METHOD) &&
				   (lsym->u.method.flags & OSYM_METH_RANGE))
			{
			    /*
			     * Exported message range here. Try and locate the
			     * enumerated type of the same name and enumerate
			     * it in place of this member of the enumerated
			     * type we were initially given. The only flaw
			     * here, as indicated by the XXX, is that if
			     * the callback returns non-zero in the recursive
			     * call, we won't know about it. Leave it for
			     * now, but at some point we'll need a SymForEach
			     * that returns non-zero if aborted prematurely...
			     */
			    Sym	    range;
			    char    *name = ST_Lock(fsym.file, lsym->name);

			    range = Sym_Lookup(name, SYM_TYPE,
					       curPatient->global);
			    ST_Unlock(fsym.file, lsym->name);

			    if (!Sym_IsNull(range)) {
				ObjSym	*rsym;

				rsym = SymLock(range);
				if (rsym->type == OSYM_ETYPE) {
				    result = SymForEach(rsym, range,
							class, func, data);
				}
				SymUnlock(range);
			    }
			    doCallback = 0;
		    	} else {
			    doCallback = 1;
		    	}
			if (doCallback) {
			    result = (*func)(SymCast(fsym), data);
		    	}
		    }
		    if (result) {
			return(result);
		    }
		}
	    }
	    break;
	}
	default:
	    /*
	     * Not a valid scope. What the fuck is going on here?
	     */
	    assert(/* invalid scope symbol type */ 0);
	    break;
    }

    /*
     * Signal traversal wasn't halted prematurely, as all those places where
     * it can be stopped will return whatever the callback function returns
     * when it returns non-zero.
     */
    return(0);
}


/*-
 *-----------------------------------------------------------------------
 * Sym_ForEach --
 *	Iterate through all the symbols in a given scope, calling the
 *	given function:
 *	    (* func) (sym, data)
 *	Func should return 0 to continue iteration and non-zero to stop.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The passed function is called once per symbol.
 *
 *-----------------------------------------------------------------------
 */
void
Sym_ForEach(Sym	    	scope,	    /* Scope to traverse */
	    int	    	class,	    /* Classes on which to call func */
	    Boolean    	(*func)(Sym sym, Opaque data),
	    Opaque	data) 	    /* Data to pass it */
{
    ObjSym  	    *ssym;

    ssym = SymLock(scope);
    (void)SymForEach(ssym, scope, class, func, data);
    SymUnlock(scope);
}


/*-
 *-----------------------------------------------------------------------
 * Sym_Name --
 *	Return the name of the given symbol. The returned name MAY NOT
 *	BE MODIFIED.
 *
 *	XXX: THIS WILL NEED TO BE MODIFIED FOR THE PC VERSION, AS WE
 *	CANNOT GUARANTEE THE STRING'S ADDRESS LIKE THIS UNLESS THE THING
 *	IS LOCKED AND WE WILL NEED TO UNLOCK THE BEASTIE.
 *
 * Results:
 *	The symbol's name.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
char *
Sym_Name(Sym	sym)	    /* Symbol whose name is desired */
{
    char    *result;
    ObjSym  *s;

    s = SymLock(sym);
    if ((s->name == NullID) || (s->flags & OSYM_NAMELESS)) {
	result = "";
    } else {
	result = ST_Lock(SymFile(sym), s->name);
	/*
	 * Strip off leading underscore, please.
	 */
	if (s->flags & OSYM_MANGLED) {
	    result += 1;
	}
    }
    SymUnlock(sym);

    return (result);
}

/***********************************************************************
 *				SymFullName
 ***********************************************************************
 * SYNOPSIS:	    Internal routine called by the above two to do the
 *		    actual work.
 * CALLED BY:	    Sym_FullName, Sym_FullNameWithPatient
 * RETURN:	    the fully-qualified name
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static char *
SymFullName(Sym	    sym,
	    Boolean patientAlways)
{
    Sym	    	next, prev;
    int	    	length = -1;	/* Start at -1 to compensate for extra 2
				 * added in in the loop (the final component
				 * isn't followed by two colons, as the loop
				 * assumes...) */
    Patient 	patient;
    char    	*result;
    char    	*cp;

    /*
     * Figure out how many chars are needed for the entire thing by going up
     * the scopes until we get to one that has no scope (the global scope),
     * whose name we skip.
     */
    prev = sym;
    while (!Sym_IsNull(next = Sym_Scope(prev, TRUE))) {
	ObjSym	*s = SymLock(prev);

	if (s->name != NullID) {
	    char    *name = ST_Lock(SymFile(prev), s->name);

	    if (s->flags & OSYM_MANGLED) {
		name += 1;
	    }

	    length += strlen(name) + 2;

	    ST_Unlock(SymFile(prev), s->name);
	}
	SymUnlock(sym);

	prev = next;
    }

    /*
     * Add in the owning-patient's name if it's not the current one or
     * the symbol was the patient's global scope, where we want to produce
     * "patient::" instead of just "" or "::".
     */
    patient = Sym_Patient(sym);
    if (length < 0) {
	length = strlen(patient->name) + 2 + 1;
    } else if (patientAlways || (patient != curPatient)) {
	length += strlen(patient->name) + 2;
    }

    /*
     * Allocate the buffer and fill it in from the end after terminating
     * the thing.
     */
    result = (char *)malloc(length);
    cp = result+length;
    *--cp = '\0';

    prev = sym;
    while (!Sym_IsNull(next = Sym_Scope(prev, TRUE))) {
	ObjSym	*s;
	char	*name;

	s = SymLock(prev);
	if (s->name != NullID) {
	    name = ST_Lock(SymFile(prev), s->name);

	    if (s->flags & OSYM_MANGLED) {
		name += 1;
	    }

	    length = strlen(name);
	    if (*cp != '\0') {
		/*
		 * Not the final component, so stick in two colons first.
		 */
		*--cp = ':';
		*--cp = ':';
	    }

	    /*
	     * Copy the name in w/o its null-terminator
	     */
	    cp -= length;
	    bcopy(name, cp, length);
	    ST_Unlock(SymFile(prev), s->name);
	}
	SymUnlock(prev);

	prev = next;
    }

    if (patientAlways || (patient != curPatient) || (*cp == '\0')) {
	length = strlen(patient->name);
	*--cp = ':';
	*--cp = ':';
	cp -= length;
	bcopy(patient->name, cp, length);
    }

    return(result);
}

/*-
 *-----------------------------------------------------------------------
 * Sym_FullName --
 *	Returns the fully-qualified name of the given symbol in the
 *	given scope.
 *
 *	XXX: THIS ALSO NEEDS REWRITING FOR THE PC.
 *
 * Results:
 *	The fully-qualified name, as patient::module::proc::block::name
 *
 * Side Effects:
 *	The string is allocated and must be freed by the caller.
 *
 *-----------------------------------------------------------------------
 */
char *
Sym_FullName(Sym    sym)	    /* Symbol whose name is desired */
{
    return (SymFullName(sym, FALSE));
}


/***********************************************************************
 *				Sym_FullNameWithPatient
 ***********************************************************************
 * SYNOPSIS:	    Return the fully-qualified name of the given symbol
 *	    	    always prefaced by the patient name.
 * CALLED BY:	    GLOBAL
 * RETURN:	    dynamically-allocated fully-qualified name
 * SIDE EFFECTS:    the string must be freed by the caller
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
char *
Sym_FullNameWithPatient(Sym sym)
{
    return(SymFullName(sym, TRUE));
}


/*-
 *-----------------------------------------------------------------------
 * Sym_GetVarData --
 *	Find out about a variable.
 *
 * Results:
 *	The type, storage class and address data are stored through the
 *	appropriate arguments if they are non-null.
 *
 * Side Effects:
 *	Things overwritten....
 *
 *-----------------------------------------------------------------------
 */
void
Sym_GetVarData(Sym	    	sym,	    	/* Symbol to interrogate */
	       Type		*typePtr,	/* Place for type */
	       StorageClass	*sClassPtr,	/* Place for storage class */
	       Address		*addrPtr)	/* Place for address data */
{
    ObjSym  	*s = SymLock(sym);

    CHECK_CLASS(s, SYM_VAR|SYM_LOCALVAR, var, Sym_GetVarData, return);

    if (s->type == OSYM_LOCAL_STATIC) {
	SymToken	vsym;

	vsym.file = SymFile(sym);
	vsym.block = s->u.localStatic.symBlock;
	vsym.offset = s->u.localStatic.symOff;

	Sym_GetVarData(SymCast(vsym), typePtr, sClassPtr, addrPtr);
    } else {
	COND_ASSIGN(typePtr, SymGetType(sym));

	switch(s->type) {
	    case OSYM_CHUNK:
	    case OSYM_CLASS:
	    case OSYM_MASTER_CLASS:
	    case OSYM_VARIANT_CLASS:
	    case OSYM_VAR:
		COND_ASSIGN(sClassPtr, SC_Static);

		/* be sure to convert entry syms to normal syms if needed */
		if (s->flags & OSYM_ENTRY)
		{
		    COND_ASSIGN(addrPtr,
				(Address)Rpc_IndexToOffset(Sym_Patient(sym),
				           (word)s->u.addrSym.address, s));
		}
		else
		{
		    COND_ASSIGN(addrPtr, (Address)s->u.addrSym.address);
		}
		break;
	    case OSYM_LOCVAR:
		COND_ASSIGN(sClassPtr, s->u.localVar.offset < 0 ?
			    SC_Local : SC_Parameter);
		COND_ASSIGN(addrPtr, (Address)s->u.localVar.offset);
		break;
	    case OSYM_REGVAR:
		COND_ASSIGN(sClassPtr, SC_Register);
		COND_ASSIGN(addrPtr, (Address)s->u.localVar.offset);
		break;
	    default:
		assert(0);
	}
    }
    SymUnlock(sym);
}

/***********************************************************************
 *				Sym_IsFar
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/30/88	Initial Revision
 *
 ***********************************************************************/
Boolean
Sym_IsFar(Sym sym)
{
    ObjSym  	*s = SymLock(sym);
    Boolean 	result;

    if (s->type == OSYM_PROC) {
	result = (!(s->u.proc.flags & OSYM_NEAR));
    } else if (s->type == OSYM_LOCLABEL) {
	result = FALSE;
    } else if (s->type == OSYM_LABEL) {
	result = (!s->u.label.near);
    } else {
	result = FALSE;
    }

    SymUnlock(sym);

    return(result);
}

/***********************************************************************
 *				Sym_IsWeird
 ***********************************************************************
 * SYNOPSIS:	    See if a function is weird (i.e. has ON_STACKs in it)
 * CALLED BY:	    EXTERNAL
 * RETURN:	    TRUE if it is, FALSE if it ain't
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/88	Initial Revision
 *
 ***********************************************************************/
Boolean
Sym_IsWeird(Sym sym)
{
    ObjSym  	*s = SymLock(sym);
    Boolean 	result;

    if ((s->type == OSYM_PROC) && (s->u.proc.flags & OSYM_WEIRD)) {
	result = TRUE;
    } else {
	result = FALSE;
    }

    SymUnlock(sym);

    return(result);
}

/*-
 *-----------------------------------------------------------------------
 * Sym_GetFuncData --
 *	Get the data of a function symbol.
 *
 * Results:
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Sym_GetFuncData(Sym	sym,	    	/* Symbol to interrogate */
		Boolean	*isFarPtr,	/* Place for return type */
		Address	*addrPtr,   	/* Place for address */
		Type	*retTypePtr)	/* Place to store return type */
{
    ObjSym  	*s = SymLock(sym);
    SymToken	*symp = (SymToken *)&sym;

    CHECK_CLASS(s, (SYM_FUNCTION|SYM_LABEL), function, Sym_GetFuncData,
		return);

    if (s->type == OSYM_PROC) {
	COND_ASSIGN(isFarPtr, (s->u.proc.flags & OSYM_NEAR) ? FALSE : TRUE);
    } else {
	COND_ASSIGN(isFarPtr, !s->u.label.near);
    }

    /* if the symbol is an entry symbol then we must go to the stub for
     * actual offset
     */

    if (s->flags & OSYM_ENTRY)
    {
	COND_ASSIGN(addrPtr, (Address)Rpc_IndexToOffset(Sym_Patient(sym),
					 (word)s->u.addrSym.address, s));
    }
    else
    {
	COND_ASSIGN(addrPtr, (Address)s->u.addrSym.address);
    }

    if (retTypePtr != (Type *)NULL) {
	/*
	 * Look for an OSYM_RETURN_TYPE symbol in the procedure's scope.
	 */
	SymToken    retType;
	genptr      base = (genptr)s - symp->offset;
	Boolean	    found = FALSE;
	ObjSym      *local;

	found = FALSE;
	if (s->type == OSYM_PROC) {
	    for (local = (ObjSym *)(base + s->u.proc.local);
		 local != (ObjSym *)base && local != s;
		 local = (ObjSym *)(base + local->u.procLocal.next))
	    {
		if (local->type == OSYM_RETURN_TYPE) {
		    retType.file = symp->file;
		    retType.block = ((ObjSymHeader *)base)->types;
		    retType.offset = local->u.localVar.type;
		    found = TRUE;
		    break;
		}
	    }
	}
	if (!found) {
	    *retTypePtr = type_Void;
	} else {
	    *retTypePtr = *(Type *)&retType;
	}
    }

    SymUnlock(sym);
}

/*-
 *-----------------------------------------------------------------------
 * Sym_GetEnumData --
 *	Interrogate a symbolic constant for its value and source type.
 *
 * Results:
 *	The value and source type of the constant.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Sym_GetEnumData(Sym	sym,	    	/* Symbol to interrogate */
		int	*valuePtr,	/* Place for value */
		Type	*sourceTypePtr) /* Place for source type */
{
    ObjSym  	*s = SymLock(sym);

    CHECK_CLASS(s, SYM_ENUM, enum, Sym_GetEnumData, return);

    COND_ASSIGN(valuePtr, s->u.eField.value);
    COND_ASSIGN(sourceTypePtr, SymGetType(sym));

    SymUnlock(sym);
}

/***********************************************************************
 *				Sym_GetAbsData
 ***********************************************************************
 * SYNOPSIS:	    Get value of an absolute symbol
 * CALLED BY:	    GLOBAL
 * RETURN:	    The symbol's value
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/28/88	Initial Revision
 *
 ***********************************************************************/
int
Sym_GetAbsData(Sym  sym)
{
    ObjSym  	*s = SymLock(sym);
    int	    	result;

    CHECK_CLASS(s, SYM_ABS, abs, Sym_GetAbsData, return);

    result = s->u.constant.value;

    SymUnlock(sym);

    return(result);
}

/***********************************************************************
 *				Sym_GetOnStackData
 ***********************************************************************
 * SYNOPSIS:	    Return the data list for an ON_STACK symbol
 * CALLED BY:	    Ibm86 module.
 * RETURN:	    vector of args -- MUST BE FREED (just the vector)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/88	Initial Revision
 *
 ***********************************************************************/
char **
Sym_GetOnStackData(Sym 	sym,
		   int	*numPtr)
{
    ObjSym  	*s = SymLock(sym);
    char    	**result;
    char    	*data;

    CHECK_CLASS(s, SYM_ONSTACK, on-stack, Sym_GetOnStackData, return);

    data = ST_Lock(SymFile(sym), OBJ_FETCH_SID(s->u.onStack.desc));
    if (Tcl_SplitList(interp, data, numPtr, &result) != TCL_OK) {
	result = NULL;
    }
    ST_Unlock(SymFile(sym), OBJ_FETCH_SID(s->u.onStack.desc));
    SymUnlock(sym);

    return(result);
}

/***********************************************************************
 *				Sym_GetFieldData
 ***********************************************************************
 * SYNOPSIS:	    Get base type of a field symbol
 * CALLED BY:	    GLOBAL
 * RETURN:	    The symbol's base type
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/13/88	Initial Revision
 *
 ***********************************************************************/
void
Sym_GetFieldData(Sym  	sym,
		 int	*offsetPtr,
		 int	*lengthPtr,
		 Type	*fieldTypePtr,
		 Type	*sourceTypePtr)
{
    ObjSym  	*s = SymLock(sym);
    Type    	ftype;
    int	    	offset, length=0;
    word    	stype;

    CHECK_CLASS(s, SYM_FIELD, field, Sym_GetFieldData, return);

    if (lengthPtr || fieldTypePtr) {
	ftype = SymGetType(sym);
    }

    stype = s->u.sField.type;

    if (s->type == OSYM_BITFIELD) {
	/*
	 * Bitfield in a record -- just use the recorded offset and width.
	 */
	offset = s->u.bField.offset;
	length = s->u.bField.width;
    } else if ((stype & OTYPE_TYPE) == OTYPE_BITFIELD) {
	/*
	 * Bitfield in a structure or union. Fetch the length from the
	 * type word and calculate the offset from the field's base offset
	 * plus the offset encoded in the type word.
	 */
	length = (stype & OTYPE_BF_WIDTH) >> OTYPE_BF_WIDTH_SHIFT;
	offset = (s->u.sField.offset * 8) +
	    ((stype & OTYPE_BF_OFFSET) >> OTYPE_BF_OFFSET_SHIFT);
    } else {
	/*
	 * Regular field in a structure or union -- use the type of the field
	 * and the recorded offset to set length and offset, respectively.
	 */
	if (lengthPtr) {
	    length = Type_Sizeof(ftype) * 8;
	}
	offset = s->u.sField.offset * 8;
    }

    COND_ASSIGN(offsetPtr, offset);
    COND_ASSIGN(lengthPtr, length);
    COND_ASSIGN(fieldTypePtr, ftype);

    if (sourceTypePtr) {
	genptr 	base = (genptr)s - SymOffset(sym);
	ObjSym	*ns;

	if (s->type == OSYM_FIELD) {
	    for (ns = (ObjSym *)(base + s->u.sField.next);
		 ns->type == OSYM_FIELD;
		 ns = (ObjSym *)(base + ns->u.sField.next))
	    {
		;
	    }
	} else {
	    for (ns = (ObjSym *)(base + s->u.bField.next);
		 ns->type == OSYM_BITFIELD;
		 ns = (ObjSym *)(base + ns->u.bField.next))
	    {
		;
	    }
	}
	SymFile(*sourceTypePtr) = SymFile(sym);
	SymBlock(*sourceTypePtr) = SymBlock(sym);
	SymOffset(*sourceTypePtr) = (genptr)ns - base;
    }

    SymUnlock(sym);
}


/***********************************************************************
 *				Sym_Type
 ***********************************************************************
 * SYNOPSIS:	    Return the actual type of a symbol, not its class
 * CALLED BY:	    Type module, mostly
 * RETURN:	    one of the OSYM constants
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
int
Sym_Type(Sym	sym)
{
    ObjSym  	*s = SymLock(sym);
    int	    	result;

    result = s->type;
    if (result == OSYM_LOCAL_STATIC) {
	result = OSYM_VAR;
    }

    SymUnlock(sym);

    return(result);
}

/***********************************************************************
 *				Sym_GetTypeData
 ***********************************************************************
 * SYNOPSIS:	    Return the type for a typedef
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Type token for the sucker
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
Type
Sym_GetTypeData(Sym sym)
{
    return SymGetType(sym);
}
