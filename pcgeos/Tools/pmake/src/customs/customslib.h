/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  pmake
 * FILE:	  customslib.h
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
 * 	$Id: customslib.h,v 1.2 1996/09/27 22:54:55 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _CUSTOMSLIB_H_
#define _CUSTOMSLIB_H_

#if defined(unix)

#include    "customs.h"
#include    <sys/time.h>
#include    <netdb.h>
#include    "rpc.h"

extern Rpc_Stat Customs_Ping         (void);
extern Rpc_Stat Customs_Host         (short flags, ExportPermit *permitPtr);
extern Rpc_Stat Customs_AvailInterval(struct timeval *interval);
extern Rpc_Stat Customs_Master       (struct sockaddr_in *masterAddrPtr);
extern Rpc_Stat Customs_SetAvail     (Avail_Data *criteria);
extern Rpc_Stat Customs_Info         (struct sockaddr_in *masterAddrPtr,
                                      char buf[]);

extern int      Customs_MakeWayBill  (ExportPermit *permitPtr, char *cwd,
				      char *file, char **argv, char **environ,
				      unsigned short port, char *buf);
extern int      Customs_RawExport    (char *file, char **argv, char *cwd,
                                      int flags, int *retSockPtr,
				      ExportPermit *permitPtr);

extern void     Customs_PError       (char* msg);

#endif /* defined(unix) */
#endif /* _CUSTOMSLIB_H_ */

