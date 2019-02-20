/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Header File for commands
 * FILE:	  cmd.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Declarations for Cmd module
 *
 *
* 	$Id: cmd.h,v 4.5 96/05/20 18:44:23 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _CMD_H
#define _CMD_H

#include    "sym.h"

#define CmdSubRec Tcl_SubCommandRec
#define CmdRec	Tcl_CommandRec

#define CMD_ANY	    TCL_CMD_ANY
#define CMD_NOCHECK TCL_CMD_NOCHECK

extern void Cmd_Init (void);

extern int Cmd_PrintArg (Sym sym, int *firstPtr);
extern int Cmd_PrintSym (Sym sym, ClientData clientData);
extern int Cmd_PrintArgValue (Sym sym, ClientData clientData);

#define Cmd_Create(cmdRec) Tcl_CreateCommandByRec(interp, cmdRec)

/*
 * DEFCMD is used to create a CmdRec for entering a command into the 
 * interpreter. It creates a function <FuncPref>Cmd to handle the command,
 * and <FuncPref>CmdRec whose address should be passed off to Cmd_Create to
 * install the command and its help string. The CmdRec isn't static so
 * certain commands whose modules don't have an initialization function
 * can be installed by Cmd_Init...
 *
 * cmdData should be NULL or the address of a CmdData record describing the
 * arguments the command expects.
 *
 * The helpString does not actually reside in Swat's memory. Rather, it is
 * extracted by the makedoc program and placed in the documentation file
 * in swat's library directory.
 *
 * XXX: HighC doesn't take to "static Tcl_CmdProc FuncPref##Cmd;", mistaking it
 * for a function definition, when it's actually a forward-reference sort of
 * thing. However, it also doesn't bitch if we declare the thing external and
 * then static, so...
 */
#if defined(__HIGHC__)
#define DEFCMD(string,FuncPref,flgs,cmdData,class,helpString) \
extern Tcl_CmdProc FuncPref##Cmd; \
const Tcl_CommandRec FuncPref##CmdRec = { #string, #class, FuncPref##Cmd, NoDelProc, cmdData, flgs }; \
static int \
FuncPref##Cmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
#else
#define DEFCMD(string,FuncPref,flgs,cmdData,class,helpString) \
static Tcl_CmdProc FuncPref##Cmd; \
const Tcl_CommandRec FuncPref##CmdRec = { #string, #class, FuncPref##Cmd, NoDelProc, cmdData, flgs }; \
static int \
FuncPref##Cmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)
#endif
/*
 * DEFCMDNOPROC is used to provide help that's not tied to any actual command.
 */
#define DEFCMDNOPROC(string,FuncPref,flgs,cmdData,class,helpString) 

#endif _CMD_H
