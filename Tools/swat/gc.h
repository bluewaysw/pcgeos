/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Garbage Collection
 * FILE:	  gc.h
 *
 * AUTHOR:  	  Daniel Baumann: May  6, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	DB	5/ 6/96   	Initial version
 *
 * DESCRIPTION:
 *	Header file for a simple garbage collector.
 *
 * 	$Id: gc.h,v 1.1 96/05/20 18:46:04 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _GC_H_
#define _GC_H_

extern void GC_RegisterType(Type type);
extern void GC_UnregisterType(Type type);
extern void GC_Init(void);

#endif /* _GC_H_ */
