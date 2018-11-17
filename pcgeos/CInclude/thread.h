/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	thread.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines thread structures and routines.
 *
 *	$Id: thread.h,v 1.1 97/04/04 15:58:40 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__THREAD_H
#define __THREAD_H

#include <object.h>	/* ClassStruct */

extern void	/*XXX*/
    _pascal ThreadDestroy(word errorCode, optr ackObject, word ackData);

/***/

extern ThreadHandle	/*XXX*/
    _pascal ThreadCreate(word priority,
		 word valueToPass,
		 word (*startRoutine)(word valuePassed),
		 word stackSize,
		 GeodeHandle owner);

/***/

#define TGI_PRIORITY(val)	 	((byte) (val))
#define TGI_RECENT_CPU_USAGE(val) 	((byte) ((val) >> 8))

typedef enum /* word */ {
    TGIT_PRIORITY_AND_USAGE=0,	/* use TGI_PRIORITY and TGI_RECENT_CPU_USAGE */
    TGIT_THREAD_HANDLE=2,
    TGIT_QUEUE_HANDLE=4
} ThreadGetInfoType;

extern word	/*XXX*/
    _pascal ThreadGetInfo(ThreadHandle th, ThreadGetInfoType info);

/***/

typedef ByteFlags ThreadModifyFlags;
#define TMF_BASE_PRIO	0x80
#define TMF_ZERO_USAGE	0x40

extern void	/*XXX*/
    _pascal ThreadModify(ThreadHandle th,
		 word newBasePriority,
		 ThreadModifyFlags flags);

/***/

extern void	/*XXX*/
    _pascal ThreadAttachToQueue(QueueHandle qh, ClassStruct *class);

/***/

extern word	/*XXX*/
    _pascal ThreadPrivAlloc(word wordsRequested, GeodeHandle owner);

/***/

extern void	/*XXX*/
    _pascal ThreadPrivFree(word range, word wordsRequested);

/***/

typedef enum /* word */ {
    TE_DIVIDE_BY_ZERO=0,
    TE_OVERFLOW=4,
    TE_BOUND=8,
    TE_FPU_EXCEPTION=12,
    TE_SINGLE_STEP=16,
    TE_BREAKPOINT=20
} ThreadException;

extern void	/*XXX*/
    _pascal ThreadHandleException(ThreadHandle th,
			  ThreadException exception,
			  PCB(void, handler, (void)));

/*
 *	Constants for thread priorities
 */

typedef ByteEnum ThreadPriority;
#define PRIORITY_TIME_CRITICAL	0
#define PRIORITY_HIGH		64
#define PRIORITY_UI		96
#define PRIORITY_FOCUS		128
#define PRIORITY_STANDARD	160
#define PRIORITY_LOW		192
#define PRIORITY_LOWEST		254
#define PRIORITY_IDLE		255 /* Will never run until system is idle */

#ifdef __HIGHC__
pragma Alias(ThreadDestroy, "THREADDESTROY");
pragma Alias(ThreadCreate, "THREADCREATE");
pragma Alias(ThreadGetInfo, "THREADGETINFO");
pragma Alias(ThreadModify, "THREADMODIFY");
pragma Alias(ThreadAttachToQueue, "THREADATTACHTOQUEUE");
pragma Alias(ThreadPrivAlloc, "THREADPRIVALLOC");
pragma Alias(ThreadPrivFree, "THREADPRIVFREE");
pragma Alias(ThreadHandleException, "THREADHANDLEEXCEPTION");
#endif

#endif
