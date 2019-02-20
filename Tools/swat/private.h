/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Private data support
 * FILE:	  private.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This is a fake module dating back to the days when patients were
 *	independent entities. There is a single table of private data
 *	into which things may be stored by anyone. The table is managed
 *	by the Table module, so the data are keyed by strings and have
 *	delete procedures, etc.
 *
* 	$Id: private.h,v 4.1 92/04/13 00:17:58 adam Exp $
 *
 ***********************************************************************/
#ifndef _PRIVATE_H
#define _PRIVATE_H

#ifndef NoDestroy
#define NoDestroy ((void (*)())NULL)
#endif /* NoDestroy */

extern Table	privateDataTable;

#define Private_Init() privateDataTable = Table_Create(16)

#define Private_Enter(name, data, destroyProc) \
        Table_Enter(privateDataTable, name, data, destroyProc)
#define Private_Delete(name) \
	Table_Delete(privateDataTable, name)
#define Private_GetData(name) \
	Table_Lookup(privateDataTable, name)

#endif /* _PRIVATE_H */

