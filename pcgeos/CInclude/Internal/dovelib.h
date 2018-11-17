/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Dove
 * MODULE:	  Hardware Library
 * FILE:	  dovelib.h
 *
 * AUTHOR:  	  Allen Yuen: Nov 30, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	allen	11/30/96   	Initial version
 *
 * DESCRIPTION:
 *
 *	Dove Hardware Library interface.
 *
 * 	$Id: dovelib.h,v 1.1 97/04/04 15:54:15 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _DOVELIB_H_
#define _DOVELIB_H_



/*
 * Register notification for the EARPHONE-MIC switch
 *
 * if notification routine
 *      msg     = 0
 *      dest    = fptr to handler (called from interrupt code):
 *                handler API: void (void)
 * if notification message
 *      msg     = notification message
 *      dest    = optr to receive message
 *                message API: void (void)
 */
extern void
    _pascal DoveSetEarphoneMicSwitchNotify(Message msg, dword dest);

/*
 * Unregister notification for the EARPHONE-MIC switch
 */
extern void
    _pascal DoveClearEarphoneMicSwitchNotify(void);

/*
 * Register notification for PDC MCPU reset
 *
 * if notification routine
 *      msg     = 0
 *      dest    = fptr to handler (called from interrupt code):
 *                handler API: void (void)
 * if notification message
 *      msg     = notification message
 *      dest    = optr to receive message
 *                message API: void (void)
 */
extern void
    _pascal DoveSetPdcResetNotify(Message msg, dword dest);

/*
 * Unregister notification for PDC MCPU reset
 */
extern void
    _pascal DoveClearPdcResetNotify(void);

/*
 * Register notification for sub-battery low
 *
 * if notification routine
 *      msg     = 0
 *      dest    = fptr to handler (called from interrupt code):
 *                handler API: void (void)
 * if notification message
 *      msg     = notification message
 *      dest    = optr to receive message
 *                message API: void (void)
 */
extern void
    _pascal DoveSetSubBatteryLowNotify(Message msg, dword dest);

/*
 * Unregister notification for sub-battery low
 */
extern void
    _pascal DoveClearSubBatteryLowNotify(void);

/*
 * Register notification for the SEND switch
 *
 * if notification routine
 *      msg     = 0
 *      dest    = fptr to handler (called from interrupt code):
 *                handler API: void (void)
 * if notification message
 *      msg     = notification message
 *      dest    = optr to receive message
 *                message API: void (void)
 */
extern void
    _pascal DoveSetSendSwitchNotify(Message msg, dword dest);

/*
 * Unregister notification for the SEND switch
 */
extern void
    _pascal DoveClearSendSwitchNotify(void);

/*
 * Register notification for the END switch
 *
 * if notification routine
 *      msg     = 0
 *      dest    = fptr to handler (called from interrupt code):
 *                handler API: void (void)
 * if notification message
 *      msg     = notification message
 *      dest    = optr to receive message
 *                message API: void (void)
 */
extern void
    _pascal DoveSetEndSwitchNotify(Message msg, dword dest);

/*
 * Unregister notification for the END switch
 */
extern void
    _pascal DoveClearEndSwitchNotify(void);



/*
 *                       UTILITY ROUTINES
 */

/*
 * Get a FileDate & FileTime record for some time in the
 * future by extending the current date & time by an amount
 *
 *      hour    = # hours in the future
 *      min     = # minutes in the future
 */
extern FileDateAndTime
    _pascal DoveGetFutureFileDateTime(byte hour, byte min);

/*
 * Block the current thread for the given amount of time
 *
 *      ms      = amount of time (in milliseconds) to block for
 */
extern void
    _pascal DoveTimerSleepMS(word ms);



#ifdef __HIGHC__

pragma Alias (DoveSetSendSwitchNotify, "DOVESETSENDSWITCHNOTIFY");
pragma Alias (DoveClearSendSwitchNotify, "DOVECLEARSENDSWITCHNOTIFY");
pragma Alias (DoveSetEndSwitchNotify, "DOVESETENDSWITCHNOTIFY");
pragma Alias (DoveClearEndSwitchNotify, "DOVECLEARENDSWITCHNOTIFY");
pragma Alias (DoveGetFutureFileDateTime, "DOVEGETFUTUREFILEDATETIME");
pragma Alias (DoveTimerSleepMS, "DOVETIMERSLEEPMS");

#endif /* __HIGHC__ */



#endif /* _DOVELIB_H_ */
