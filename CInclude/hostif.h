/***********************************************************************
 *
 *	Copyright (c) blueway.Softworks -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	hostif.h
 * AUTHOR:	Falk Rehwagen: December, 2023
 *
 * DESCRIPTION:
 *	C version of hostif.def
 *
 *	$Id: cell.h,v 1.1 97/04/04 15:58:05 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__HOSTIF_H
#define __HOSTIF_H

#include <geos.h>

typedef WordFlags HostIfFunctions;
#define HIF_CHECK			1
#define HIF_SET_RECEIVE_HANDLE		2
#define HIF_SET_SSL_CALLBACK		3
	
#define HIF_NETWORKING_BASE		1000
#define HIF_NC_RESOLVE_ADDR		HIF_NETWORKING_BASE
#define HIF_NC_ALLOC_CONNECTION		HIF_NETWORKING_BASE+1
#define HIF_NC_CONNECT_REQUEST		HIF_NETWORKING_BASE+2
#define HIF_NC_SEND_DATA		HIF_NETWORKING_BASE+3
#define HIF_NC_NEXT_RECV_SIZE		HIF_NETWORKING_BASE+4
#define HIF_NC_RECV_NEXT		HIF_NETWORKING_BASE+5
#define HIF_NC_RECV_NEXT_CLOSE		HIF_NETWORKING_BASE+6
#define HIF_NC_CLOSE			HIF_NETWORKING_BASE+7
#define HIF_NC_DISCONNECT		HIF_NETWORKING_BASE+8
#define HIF_NETWORKING_END		1199
	
#define HIF_SSL_BASE			1200
#define HIF_SSL_V2_GET_CLIENT_METHOD	HIF_SSL_BASE
#define HIF_SSL_SSLEAY_ADD_SSL_ALGO	HIF_SSL_BASE+1
#define HIF_SSL_CTX_NEW			HIF_SSL_BASE+2
#define HIF_SSL_CTX_FREE		HIF_SSL_BASE+3
#define HIF_SSL_NEW			HIF_SSL_BASE+4
#define HIF_SSL_FREE			HIF_SSL_BASE+5
#define HIF_SSL_SET_FD			HIF_SSL_BASE+6
#define HIF_SSL_CONNECT			HIF_SSL_BASE+7
#define HIF_SSL_SHUTDOWN		HIF_SSL_BASE+8
#define HIF_SSL_READ			HIF_SSL_BASE+9
#define HIF_SSL_WRITE			HIF_SSL_BASE+10
#define HIF_SSL_V23_CLIENT_METHOD	HIF_SSL_BASE+11
#define HIF_SSL_V3_CLIENT_METHOD	HIF_SSL_BASE+12
#define HIF_SSL_GET_SSL_METHOD		HIF_SSL_BASE+13
#define HIF_SSL_SET_CALLBACK		HIF_SSL_BASE+14
#define HIF_SSL_SET_TLSEXT_HOST_NAME	HIF_SSL_BASE+15
#define HIF_SSL_END			1299

#ifdef  __cplusplus
extern "C" {
#endif

extern word _pascal HostIfDetect();
extern dword _pascal HostIfCall(HostIfFunctions func, 
					dword data1, dword data2, word data3);

#ifdef  __cplusplus
}
#endif

#ifdef __HIGHC__
pragma Alias(HostIfDetect, "HOSTIFDETECT");
pragma Alias(HostIfCall, "HOSTIFCALL");
#endif

#endif
