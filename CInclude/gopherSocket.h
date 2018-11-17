/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:       Gopher Client	  
 * MODULE:	  Gopher Library -- socket testing
 * FILE:	  gopherSocket.h
 *
 * AUTHOR:  	  Alvin Cham: Dec  2, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	AC	12/ 2/94   	Initial version
 *
 * DESCRIPTION:
 *	This file contains some definitions for the GopherSocketClass.
 *
 * 	$Id: gopherSocket.h,v 1.1 97/04/04 16:00:14 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _GOPHERSOCKET_H_
#define _GOPHERSOCKET_H_

#include <geos.h>
#include <library.h>
#include <driver.h>


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*---------------------------------------------------------------------
 * 
 * IMPORTANT:
 * ----------
 * 
 * The following constants would have to match exactly with the ones that
 * are defined in the application "socketTest" because we will be running
 * that application when we are testing the socket library.  That application
 * will provide the server side of the socket, and the Gopher client itself
 * will provide the client side.
 *
 ---------------------------------------------------------------------*/

#define	SEND_SIZE	256
#define BUFFER_SIZE	256
#define NUM_OF_PENDING_CONNECTIONS	5
#define MAX_ADDRESS_SIZE 5
#define TCP_DOMAIN "TCPIP"
#define IRLAP_DOMAIN "IRLAP"
#define LOOPBACK_DOMAIN "LOOPBACK"

#endif /* _GOPHERSOCKET_H_ */
