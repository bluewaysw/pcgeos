/*-
 * log.h --
 *	Header file for programs that use the log facilities of the
 *	customs daemon.
 *
 * Copyright (c) 1988, 1989 by the Regents of the University of California
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any non-commercial purpose
 * and without fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California,
 * Berkeley Softworks and Adam de Boor make no representations about
 * the suitability of this software for any purpose.  It is provided
 * "as is" without express or implied warranty.
 *
 *	"$Id: log.h,v 1.4 89/11/14 13:46:29 adam Exp $ SPRITE (Berkeley)"
 */
#ifndef _LOG_H_
#define _LOG_H_

/*
 * XDR functions are used in the communication between customs and a loggin
 * process to obviate any byte-ordering differences.
 */
#include    <rpc/types.h>
#include    <rpc/xdr.h>

enum {
    LOG_START,	  	/* Job started */
    LOG_FINISH,	  	/* Job finished */
    LOG_STOPPED,  	/* Job stopped */
    LOG_NEWAGENT, 	/* New agent registered */
    LOG_NEWMASTER,	/* New master elected */
    LOG_ACCESS,	  	/* Illegal access attempted */
    LOG_EVICT,	  	/* You are dead meat */
    LOG_KILL,	  	/* Job was killed */
    LOG_EXITFAIL, 	/* Couldn't send EXIT */
} Log_Procs;

extern bool_t	  xdr_exportpermit();
extern bool_t	  xdr_in_addr();
extern bool_t	  xdr_sockaddr_in();
extern bool_t	  xdr_strvec();

#endif _LOG_H_
