/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  serial.h
 * FILE:	  serial.h
 *
 * AUTHOR:  	  Adam de Boor: Jul 16, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/16/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definition of interface to serial port under DOS
 *
 *
 * 	$Id: serial.h,v 1.5 97/04/18 16:33:13 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _SERIAL_H_
#define _SERIAL_H_

typedef char *caddr_t;
struct iovec {
    caddr_t iov_base;
    int	    iov_len;
};

extern int  	Serial_WriteV(struct iovec *iov, int len);
extern int  	Serial_Read(void *buffer, int bufSize);
extern int  	Serial_Check(void);
extern int 	Serial_Init(const char *portDesc, int fullInit);
extern void 	Serial_Exit(void);

#if defined (_MSDOS)
extern void 	Serial_Rs(void); /* starts up the swat stub on the remote PC*/
extern void 	Serial_Rss(void); /* starts up the swat stub on the remote PC*/
extern void 	Serial_Rsn(void); /* starts up the swat stub on the remote PC*/
extern void 	Serial_Rssn(void);/* starts up the swat stub on the remote PC*/
#endif   /*  _MSDOS  */

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

#endif /* _SERIAL_H_ */
