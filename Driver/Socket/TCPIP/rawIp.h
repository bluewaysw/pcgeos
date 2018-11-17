/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  rawip.h
 * FILE:	  rawip.h
 *
 * AUTHOR:  	  Jennifer Wu: Oct 14, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/14/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for Raw Ip interface to TCP/IP driver.
 *
 * 	$Id: rawIp.h,v 1.1 97/04/18 11:57:14 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _RAWIP_H_
#define _RAWIP_H_


typedef byte RawIpFlags;
#define	RIF_IP_HEADER	0x01

extern 	word RawIpOutput(optr dataBuffer, word link);
extern  void RawIpInput	(optr dataBuffer, word hlen);
extern	void RawIpError (word code);

#endif /* _RAWIP_H_ */
