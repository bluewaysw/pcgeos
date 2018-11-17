/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Sun RPC Implementation
 * FILE:	  sunrpc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for Sun RPC implementation based on Customs RPC
 *	
 * 	Copyright (c) Berkeley Softworks 1989
 * 	Copyright (c) Adam de Boor 1989
 *
 * 	Permission to use, copy, modify, and distribute this
 * 	software and its documentation for any non-commercial purpose
 *	and without fee is hereby granted, provided that the above copyright
 * 	notice appears in all copies.  Neither Berkeley Softworks nor
 * 	Adam de Boor makes any representations about the suitability of this
 * 	software for any purpose.  It is provided "as is" without
 * 	express or implied warranty.
 *
 ***********************************************************************/

#ifndef _SUNRPC_H_
#define _SUNRPC_H_

extern void 	    	SunRpc_ServerCreate();
extern void 	    	SunRpc_ServerDelete();
extern enum clnt_stat	SunRpc_Call();
extern int  	    	SunRpc_MsgStream();
extern unsigned long	SunRpc_MsgProg();
extern unsigned long	SunRpc_MsgProc();
extern struct opaque_auth *SunRpc_MsgRawCred();
extern caddr_t	    	SunRpc_MsgCred();

/*
 * Code returned if server doesn't wish to respond to a call
 */
#define SUNRPC_DONTRESPOND	((enum clnt_stat)-1)

#endif /* _SUNRPC_H_ */
