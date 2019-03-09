/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Address Expression Definitions
 * FILE:	  expr.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Function definitions for the Expr module
 *
 *
* 	$Id: expr.h,v 4.4 97/04/18 15:13:59 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _EXPR_H
#define _EXPR_H

extern Boolean Expr_Eval(const char *expr, Frame *frame,
			 GeosAddr *addrPtr, Type *typePtr,
			 Boolean wantAddr);

extern Sym Expr_FindSym(Patient patient, const char *name);

extern int ustrcmp(char *s1, char *s2);

#endif /* _EXPR_H */
