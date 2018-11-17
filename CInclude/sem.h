/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	sem.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines semaphore structures and routines.
 *
 *	$Id: sem.h,v 1.1 97/04/04 15:58:10 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__SEM_H
#define __SEM_H

typedef enum /* word */ {
    SE_NO_ERROR,
    SE_TIMEOUT,
    SE_PREVIOUS_OWNER_DIED
} SemaphoreError;

extern SemaphoreHandle	/*XXX*/
    _pascal ThreadAllocSem(word value);

/***/

extern void	/*XXX*/
    _pascal ThreadFreeSem(SemaphoreHandle sem);

/***/

extern SemaphoreError	/*XXX*/
    _pascal ThreadPSem(SemaphoreHandle sem);

/***/

extern void	/*XXX*/
    _pascal ThreadVSem(SemaphoreHandle sem);

/***/

extern SemaphoreError	/*XXX*/
    _pascal ThreadPTimedSem(SemaphoreHandle sem, word timeout);

/***/

extern ThreadLockHandle	/*XXX*/
    _pascal ThreadAllocThreadLock(void);

/***/

extern void	/*XXX*/
    _pascal ThreadFreeThreadLock(ThreadLockHandle sem);

/***/

extern void	/*XXX*/
    _pascal ThreadGrabThreadLock(ThreadLockHandle sem);

/***/

extern void	/*XXX*/
    _pascal ThreadReleaseThreadLock(ThreadLockHandle sem);

#ifdef __HIGHC__
pragma Alias(ThreadAllocSem, "THREADALLOCSEM");
pragma Alias(ThreadFreeSem, "THREADFREESEM");
pragma Alias(ThreadPSem, "THREADPSEM");
pragma Alias(ThreadVSem, "THREADVSEM");
pragma Alias(ThreadPTimedSem, "THREADPTIMEDSEM");
pragma Alias(ThreadAllocThreadLock, "THREADALLOCTHREADLOCK");
pragma Alias(ThreadFreeThreadLock, "THREADFREETHREADLOCK");
pragma Alias(ThreadGrabThreadLock, "THREADGRABTHREADLOCK");
pragma Alias(ThreadReleaseThreadLock, "THREADRELEASETHREADLOCK");
#endif

#endif
