/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Command utilities
 * FILE:	  cmd.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 17, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Cmd_PrintSym	    Print out info on a symbol
 *	Cmd_Init    	    Store the various commands that have no Init
 *			    function to store them.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/17/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Command utilities.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: cmd.c,v 4.13 97/04/18 14:54:19 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "break.h"
#include "cmd.h"
#include "event.h"
#include "expr.h"
#include "private.h"
#include "sym.h"
#include "type.h"
#include "value.h"
#include "ui.h"
#include <buf.h>
#include <ctype.h>

/**********************************************************************
 *
 *	    	  UTILITY SUBROUTINES FOR COMMANDS
 *
 *********************************************************************/

/*-
 *-----------------------------------------------------------------------
 * Cmd_PrintArg --
 * 	Print the name of the given argument symbol. Callback function
 *	for Sym_ForEachFuncArg when called from CmdPrintSym. The clientData
 *	for Sym_ForEachFuncArg should point to an integer that is
 *	initialized to 1.
 *
 * Results:
 *	=== 0.
 *
 * Side Effects:
 *	The name for sym is printed and *firstPtr is set to 0.
 *
 *-----------------------------------------------------------------------
 */
int
Cmd_PrintArg(Sym	sym,
	     int	*firstPtr)
{
    if (!*firstPtr) {
	Message(", %s", Sym_Name(sym));
    } else {
	Message("%s", Sym_Name(sym));
	*firstPtr = 0;
    }
    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * Cmd_PrintSym --
 *	Print out a single symbol. Callback function for Sym_ForEach from
 *	CmdDumpScope and for CmdWhatIs.
 *
 * Results:
 *	0 if not yet interrupted. non-zero if interrupted.
 *
 * Side Effects:
 *	A description of the symbol is printed.
 *
 *-----------------------------------------------------------------------
 */
int
Cmd_PrintSym(Sym    	sym,
	     ClientData	clientData)
{
    Type    	    t;
    int	    	    offset = (int)clientData;
    int	    	    class = Sym_Class(sym);

    if (class & (SYM_VAR|SYM_LOCALVAR)) {
	StorageClass	sClass;
	Address	    	addr;
	char	    	*name;
	    
	Sym_GetVarData(sym, &t, &sClass, &addr);
	    
	if (Type_IsNull(t)) {
	    Message("%*s%s, ", offset, "", Sym_Name(sym));
	} else {
	    name = Type_Name(t, Sym_Name(sym), FALSE);
	    Message("%*s%s, ", offset, "", name);
	    free(name);
	}
	switch(sClass) {
	    case SC_Register:
		Message("register %d\n", addr); break;
	    case SC_Parameter:
		Message("parameter %d from ap\n", addr); break;
	    case SC_Local:
		Message("local %d from fp\n", addr); break;
	    case SC_Static:
		Message("at %xh\n", addr); break;
	    default:
		Message("*** Unknown Storage Class ***\n"); break;
	}
    } else if (class & SYM_MODULE) {
	ResourcePtr	rp;
	int	    	i;
	Patient 	patient;
	
	patient = Sym_Patient(sym);
	for (i = patient->numRes, rp = patient->resources; i > 0; i--,rp++)
	{
	    if (Sym_Equal(rp->sym,sym)) {
		break;
	    }
	}
	if (i == 0) {
	    Message("%*smodule %s: NO HANDLE?\n", offset, "",
		    Sym_Name(sym));
	} else {
	    Message("%*smodule %s: handle %04xh (at %04xh:0)\n",
		    offset, "", Sym_Name(sym),
		    Handle_ID(rp->handle), Handle_Segment(rp->handle));
	}
    } else if (class & SYM_FUNCTION) {
	char	*name;
	char	*rname;
	Address	address;
	Boolean	isFar;
	Type	retType;
	
	name = Sym_FullName(sym);
	Sym_GetFuncData(sym, &isFar, &address, &retType);
	rname = Type_Name(retType, "", FALSE);
	Message("%*s%s %s %s() at %04xh\n", offset, "",
		rname, isFar ? "_far" : "_near",
		name, address);
	free(rname);
	free(name);
    } else if (class & SYM_LABEL) {
	char	*name;
	Address	address;
	Boolean 	isFar;
	
	name = Sym_FullName(sym);
	Sym_GetFuncData(sym, &isFar, &address, (Type *)NULL);
	Message("%*s%s %s at %xh\n", offset, "", isFar ? "_far" : "_near",
		name, address);
	free(name);
    } else if (class & SYM_TYPE) {
	char	*name;
		
	name = Type_Name(sym, Sym_Name(sym), TRUE);
	Message("%*stypedef %s;\n", offset, "", name);
	free(name);
    } else if (class & SYM_FIELD) {
	char    *name;
	int	    foffset, flength;
	Type    ftype;
	char    *fname;
	
	Sym_GetFieldData(sym, &foffset, &flength, &ftype, &t);
	name = Type_Name(t, "", FALSE);
	
	fname = Type_Name(ftype, Sym_Name(sym), TRUE);
	
	if (foffset & 7) {
	    Message("%*sfield %s at offset %d.%d (%d bits wide) in %s\n",
		    offset, "", fname, foffset/8, foffset & 7,
		    flength, name);
	} else {
	    Message("%*sfield %s at offset %d (%d bits wide) in %s\n",
		offset, "", fname, foffset/8, flength, name);
	}
	
	free(fname);
	free(name);
    } else if (class & SYM_ENUM) {
	int	    value;
	char    *name;
	
	Sym_GetEnumData(sym, &value, &t);
	name = Type_Name(t, "", FALSE);
	Message("%*senum %s, value %d in %s\n", offset, "", Sym_Name(sym),
		value, name);
	free(name);
    } else if (class & SYM_ABS) {
	Message("%*sabsolute %s = %d\n", offset, "", Sym_Name(sym),
		Sym_GetAbsData(sym));
    } else {
	Message("%*sclass unknown %s\n", offset, "", Sym_Name(sym));
    }
    return(Ui_CheckInterrupt());
}

#if 0
/*-
 *-----------------------------------------------------------------------
 * Cmd_PrintArgValue --
 *	Print the value of an argument.
 *
 * Results:
 *	=== 0.
 *
 * Side Effects:
 *	The value and name of the symbol are printed.
 *
 *-----------------------------------------------------------------------
 */
int
Cmd_PrintArgValue(Sym	    	sym,
		  ClientData 	clientData)
{
    register Boolean  	*firstPtr = (Boolean *)clientData;
    Address 	  	address;
    Address  	  	value;
    StorageClass  	sClass;
    Type		type;
    int			size;
    RegType		regType = REG_MACHINE;
    char		*string;


    if (!*firstPtr) {
	Message(", ");
    } else {
	*firstPtr = FALSE;
    }

    Sym_GetVarData(sym, &type, &sClass, &address);
    size = Type_Sizeof(type);
    switch(sClass) {
    case SC_Parameter:
	address = curPatient->frame->fp + address;
	Var_FetchAlloc(type, curPatient->core, address, &value);
	break;
    case SC_RegParam:
    case SC_Register:
    {
	word    reg;
	    
	MD_GetFrameRegister(curPatient->frame, regType,
					 (int)address, &reg);
	Type_Cast(&value, type_Word, type);
	break;
    }
    default:
	Warning("Unsupported storage class for %s", Sym_Name(sym));
	return(0);
    }
    string = Value_Format(value, type, (char *)NULL, FALSE);
    Message("%s = %s", Sym_Name(sym), string);

    free(string);
    free((char *)value);

    return(0);
}
#endif

/***********************************************************************
 *
 *			 FRONT END FUNCTIONS
 *
 **********************************************************************/
/***********************************************************************
 *
 *	    	  	INITIALIZATION
 *
 **********************************************************************/
extern const Tcl_CommandRec 
			    AddrParseCmdRec, AliasCmdRec,
			    AllocCmdRec, AutoloadCmdRec,
			    BrkTakenCmdRec,
			    CacheCmdRec,
			    DbgMeCmdRec,
			    DefacommandCmdRec, DefcommandCmdRec, DefhelpCmdRec,
			    DefvarCmdRec, DbgCmdRec,
			    ExplodeCmdRec, ExprDebugCmdRec,
			    FrameCmdRec,
			    GetenvCmdRec,
			    MapCmdRec, MapConcatCmdRec,
			    NullCmdRec,
			    PIDCmdRec,
			    RequireCmdRec,
			    ScopeCmdRec, SleepCmdRec, SortCmdRec,
			    StreamCmdRec, SymbolCmdRec,
			    TableCmdRec,
			    UnaliasCmdRec, UnassembleCmdRec,
			    WaitCmdRec, SymbolKernelInternalCmdRec,
 	    	    	    AddressKernelInternalCmdRec, KernelHasTableCmdRec;

static const Tcl_CommandRec *commands[] = {
    &AddrParseCmdRec,
    &AliasCmdRec,
    &AllocCmdRec,
    &AutoloadCmdRec,
    &BrkTakenCmdRec,
    &CacheCmdRec,
    &DbgCmdRec,
    &DbgMeCmdRec,
    &DefacommandCmdRec,
    &DefcommandCmdRec,
    &DefhelpCmdRec,
    &DefvarCmdRec,
    &ExplodeCmdRec,
    &ExprDebugCmdRec,
    &FrameCmdRec,
    &GetenvCmdRec,
    &MapCmdRec,
    &MapConcatCmdRec,
    &NullCmdRec,
    &PIDCmdRec,
    &RequireCmdRec,
    &ScopeCmdRec,
    &SleepCmdRec,
    &SortCmdRec,
    &StreamCmdRec,
    &SymbolCmdRec,
    &TableCmdRec,
    &UnaliasCmdRec,
    &UnassembleCmdRec,
    &WaitCmdRec,
    &SymbolKernelInternalCmdRec,
    &AddressKernelInternalCmdRec,
    &KernelHasTableCmdRec,
};

/*-
 *-----------------------------------------------------------------------
 * Cmd_Init --
 *	Install the commands defined in this module into the main
 *	interpreter.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Commands are stored in the interpreter.
 *
 *-----------------------------------------------------------------------
 */
void
Cmd_Init(void)
{
    int	    	  	i;

    for(i = 0; i < Number(commands); i++) {
	Tcl_CreateCommandByRec(interp, commands[i]);
    }
}
