/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  npipe.h
 *
 * AUTHOR:  	  Dan Baumann: Sep 10, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial version
 *
 * DESCRIPTION:
 *
 *	Interface to WIN32 Named Pipes
 *
 * 	$Id: npipe.h,v 1.1 97/04/18 16:21:18 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _NPIPE_H_
#define _NPIPE_H_

extern int NPipe_ServerInit(char *addr, HANDLE *pipe, LPOVERLAPPED ovlpR,
			    LPOVERLAPPED ovlpW);
extern int NPipe_ServerConnect(HANDLE pipe, int *madeConnection, 
			       LPOVERLAPPED ovlp);
extern int NPipe_ClientInit(char *addr, HANDLE *pipe, LPOVERLAPPED ovlpR,
			    LPOVERLAPPED ovlpW);
extern int NPipe_Read(HANDLE pipe, void *buf, int bufSize, 
		      LPOVERLAPPED ovlp, BOOL block);
extern int NPipe_PrimeForWait(HANDLE pipe, LPOVERLAPPED ovlp);
extern int NPipe_Write(HANDLE pipe, void *buf, int bufSize, 
		       LPOVERLAPPED ovlp);
extern int NPipe_WriteV(HANDLE pipe, struct iovec *iov, int iov_len, 
			LPOVERLAPPED ovlp);
extern int NPipe_Check(HANDLE pipe, LPOVERLAPPED ovlp);
extern void NPipe_ServerExit(HANDLE *pipe, LPOVERLAPPED ovlpR,
			     LPOVERLAPPED ovlpW);
extern void NPipe_ClientExit(HANDLE *pipe, LPOVERLAPPED ovlpR,
			     LPOVERLAPPED ovlpW);

#endif /* _NPIPE_H_ */
