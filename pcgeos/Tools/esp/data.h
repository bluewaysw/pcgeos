/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Data Definition Definitions
 * FILE:	  data.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 26, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: data.h,v 1.9 91/04/26 12:25:00 adam Exp $
 *
 ***********************************************************************/
#ifndef _DATA_H_
#define _DATA_H_

extern int  Data_Enter(int *addrPtr, TypePtr type, Expr *expr, int maxElts);
extern void Data_EncodeRecord(SymbolPtr record, char *initStr);

#endif /* _DATA_H_ */
