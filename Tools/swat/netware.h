/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1994 -- All Rights Reserved
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  netware.h
 *
 * AUTHOR:  	  Adam de Boor: Feb 27, 1994
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	ardeb	  2/27/94	    Initial version
 *
 * DESCRIPTION:
 *	Interface to UNIX netware support (and possibly DOS netware
 *	support, eventually)
 *
 *
 * 	$Id: netware.h,v 1.1 94/03/15 11:19:10 adam Exp $
 *
 ***********************************************************************/
#ifndef _NETWARE_H_
#define _NETWARE_H_

extern int NetWare_Init(char *addr);
extern int NetWare_WriteV(int fd, struct iovec *iov, int iov_len);
extern int NetWare_Read(int fd, void *buf, int bufSize);

#endif /* _NETWARE_H_ */
