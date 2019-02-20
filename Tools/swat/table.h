/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- String-keyed data table management
 * FILE:	  table.h
 *
 * AUTHOR:  	  Adam de Boor: Aug 15, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/15/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for users of the Table module.
 *
 *
* 	$Id: table.h,v 4.2 92/07/03 20:22:20 adam Exp $
 *
 ***********************************************************************/
#ifndef _TABLE_H_
#define _TABLE_H_

#include    "hash.h"

#define Table_Key(e) ((e)->key.name)

typedef Hash_Table	*Table;

#define NullTable 	((Table)NULL)
#define NullTEntry	((Opaque)NULL)

#ifndef NoDestroy
#define NoDestroy 	((void (*)())NULL)
#endif /* NoDestroy */

typedef void Table_DestroyProc(Opaque value, char *key);

extern Table	Table_Create (int initBuckets);
extern void	Table_Destroy (Table table, Boolean destroy);
extern void	Table_Enter (Table table, const char *key, Opaque value,
			     Table_DestroyProc *destroyProc);
extern Opaque	Table_Lookup (Table table, const char *key);
extern void	Table_Delete (Table table, const char *key);
				     
#endif /* _TABLE_H_ */
