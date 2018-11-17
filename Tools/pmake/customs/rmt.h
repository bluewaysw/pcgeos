/***********************************************************************
 *
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  pmake
 * FILE:	  rmt.h
 *
 * AUTHOR:  	  Tim Bradley: Jun 12, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	6/12/96   	Initial version
 *
 * DESCRIPTION:
 *	Prototypes for the rmt.c file
 *
 *
 * 	$Id: rmt.h,v 1.3 1996/09/27 22:55:00 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _RMT_H_
#define _RMT_H_
#if defined(unix)

#include "pmjob.h"
#include "rpc.h"
#include "customs.h"

extern void    Rmt_Init      (void);
extern void    Rmt_AddServer (char *name);
extern void    Rmt_Exec      (char *file, char **args, Boolean traceMe);
extern void    Rmt_Done      (int id);
extern void    Rmt_Watch     (int stream, RpcWatchCallback proc, char *data);
extern void    Rmt_Ignore    (int stream);
extern void    Rmt_Wait      (void);

extern int     Rmt_LastID    (int pid);
extern int     Rmt_Signal    (Job *job, int signo);

extern Boolean Rmt_Begin     (char *file, char **argv, GNode *gn);
extern Boolean Rmt_Export    (char *file, char **argv, Job *job);
extern Boolean Rmt_ReExport  (int pid);

#endif /* defined(unix) */
#endif /* _RMT_H_ */
