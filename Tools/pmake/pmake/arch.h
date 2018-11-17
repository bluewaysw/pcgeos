/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  pmake
 * FILE:	  arch.h
 *
 * AUTHOR:  	  Tim Bradley: Jun 24, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	6/24/96   	Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: arch.h,v 1.2 1996/10/23 19:22:22 jacob Exp $
 *
 ***********************************************************************/
#ifndef _ARCH_H_
#define _ARCH_H_
#if defined(unix)

#include    "make.h"

extern Boolean      Arch_LibOODate    (GNode *gn);

extern int          Arch_MTime        (GNode *gn);
extern int          Arch_MemMTime     (GNode *gn);

extern ReturnStatus Arch_ParseArchive (char **linePtr, Lst nodeLst,
                                       GNode *ctxt);

extern void         Arch_Touch        (GNode *gn);
extern void         Arch_TouchLib     (GNode *gn);
extern void         Arch_FindLib      (GNode *gn, Lst path);
extern void         Arch_Init         (void);

#endif /* defined(unix) */
#endif /* _ARCH_H_ */

