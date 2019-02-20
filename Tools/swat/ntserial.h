/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  ntserial.h
 * FILE:	  ntserial.h
 *
 * AUTHOR:  	  Dan Baumann: Dec 02, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	12/02/96   	Initial version
 *
 * DESCRIPTION:
 *	Definition of interface to serial port under WIN32
 *	
 *
 * 	$Id: ntserial.h,v 1.1 97/04/18 16:21:35 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _NTSERIAL_H_
#define _NTSERIAL_H_

typedef char *caddr_t;
struct iovec {
    caddr_t iov_base;
    int	    iov_len;
};

extern int 	Ntserial_Init(HANDLE *comHandle, const char *portDesc, 
			      LPOVERLAPPED ovlpR, LPOVERLAPPED ovlpW);
extern int  	Ntserial_Read(HANDLE comHandle, void *buffer, int bufSize, 
			      LPOVERLAPPED ovlp, BOOL bBlock);
extern int	Ntserial_PrimeForWait(HANDLE comHandle, LPOVERLAPPED ovlp);
extern int  	Ntserial_WriteV(HANDLE comHandle, struct iovec *iov, 
				int len, LPOVERLAPPED ovlp);
extern int  	Ntserial_Check(HANDLE comHandle, LPOVERLAPPED ovlp);
extern void 	Ntserial_Exit(HANDLE *comHandle, LPOVERLAPPED ovlpR, 
			      LPOVERLAPPED ovlpW);

/* 
 * empty Ipx funtion definitions.  Makes the Borland linker happy for now.
 * Novell will not be supported initially
 */

int Ipx_Check(void);
void Ipx_Init(char *addr);
void Ipx_Exit(void);
void Ipx_CopyToSendBuffer(caddr_t a, int b, int c);
void Ipx_SendLow(int a);
int Ipx_CheckPacket(void);
int Ipx_ReadLow(void *buf, int bufSize);

#endif /* _NTSERIAL_H_ */
