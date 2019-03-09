/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Value fetching and storage.
 * FILE:	  value.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functional interface of the Value module.
 *
 *
* 	$Id: value.h,v 4.2 96/05/20 18:55:04 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _VALUE_H
#define _VALUE_H

extern Boolean  Value_HistoryFetch (int number, Handle *handlePtr,
				      Address *offsetPtr, Type *typePtr);
extern int      Value_HistoryStore (Handle handle, Address offset, Type type);

extern char 	*Value_ConvertToString(Type type, Opaque value);
extern Opaque	Value_ConvertFromString(Type type, const char *str);
extern void     Value_Init(void);
#endif /* _VALUE_H */
