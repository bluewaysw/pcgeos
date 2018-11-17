/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  glue
 * FILE:	  library.h
 *
 * AUTHOR:  	  Tim Bradley: Jun 20, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	6/20/96   	Initial version
 *
 * DESCRIPTION:
 *	prototypes for library.c file
 *
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _LIBRARY_H_
#define _LIBRARY_H_

#include "geo.h"

extern void              Library_AddDir                   (char *dir);
extern void              Library_ExportAs                 (char *name,
                                                           char *alias,
							   Boolean
							     mustBeDefined);
extern ID                Library_TackPrependPublishedToID (VMHandle vmHandle,
                                                           VMBlockHandle table,
                                                           ID id);
extern ID                Library_ForceTackPrependPublishedToID
                                                          (VMHandle vmHandle,
							   VMBlockHandle table,
							   ID id);
extern void              Library_MarkPublished            (char *name);
extern void              Library_Publish                  (VMHandle fh,
                                                           VMBlockHandle
							     dataBlock,
		                                           VMBlockHandle
							     relBlock,
		                                           word procOffset,
		                                           word bytes,
		                                           ID symID);
extern void              Library_ProtoMinor               (char 	*name);
extern void              Library_Skip                     (int    	n);
extern void              Library_SkipUntilNumber          (int n);
extern void              Library_SkipUntilConstant        (char *name);
extern LibraryLinkValues Library_Link                     (char *name,
	                                                   LibraryLoadTypes
							     loadType,
	                                                   word attrs);
extern void              Library_LoadPublished            (void);
extern void              Library_WriteLDF                 (void);
extern void              Library_CheckForMissingLibraries (void);
extern int               Library_Find                     (ID name,
                                                           word *entryNum);
extern void              Library_IncMinor                 (void);
extern int               Library_UseEntry                 (SegDesc *libSeg,
		                                           const ObjSym *os,
		                                           int doInc,
		                                           int errorIfPlatformViolated);
extern void              Library_ReadPlatformFile         (char   *name);
extern void              Library_ReadShipFile             (char   *name);
extern void              Library_ExemptLibrary            (char   *name);

#endif /* _LIBRARY_H_ */
