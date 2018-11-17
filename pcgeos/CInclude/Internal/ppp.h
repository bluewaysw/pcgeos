/***********************************************************************
 *
 *	Copyright (c) GlobalPC 1994 -- All Rights Reserved
 *
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  
 * FILE:	  
 *
 * AUTHOR:  	  Mingzhe Zhu
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *      11/28/98  mzhu      initial version
 *
 * DESCRIPTION:
 *
 *      Define the special functions for the internet dialup application and
 *      (maybe) other applications to use. See ppp.def
 *
 * 	$Id: $
 *
 ***********************************************************************/
#ifndef _PPP_H_
#define _PPP_H_

#define SOCKET_DR_FIRST_SPEC_FUNC 0x4000
typedef enum {
  PPP_ID_GET_BAUD_RATE = SOCKET_DR_FIRST_SPEC_FUNC,
  PPP_ID_GET_BYTES_SENT = SOCKET_DR_FIRST_SPEC_FUNC + 2,
  PPP_ID_GET_BYTES_RECEIVED = SOCKET_DR_FIRST_SPEC_FUNC + 4,
  PPP_ID_REGISTER = SOCKET_DR_FIRST_SPEC_FUNC + 6,
  PPP_ID_UNREGISTER = SOCKET_DR_FIRST_SPEC_FUNC + 8,
  PPP_ID_FORCE_DISCONNECT = SOCKET_DR_FIRST_SPEC_FUNC + 10,
} PPPIDDriverFunc;


typedef enum {
  PPP_STATUS_OPENING = 0x0000,
  PPP_STATUS_DIALING = 0x2000,
  PPP_STATUS_CONNECTING = 0x4000,
  PPP_STATUS_OPEN = 0x6000,
  PPP_STATUS_CLOSING = 0x8000,
  PPP_STATUS_CLOSED = 0xa000,
  PPP_STATUS_ACCPNT = 0xc000
} PPPStatus;

#define PPPErrorBits 0x1fff
#define PPPStatusBits 0xe000

#endif
