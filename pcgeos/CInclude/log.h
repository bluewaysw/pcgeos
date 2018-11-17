/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 * PROJECT:	  GEOS
 * MODULE:	  logging utility
 * FILE:	  log.h
 *
 * AUTHOR:  	  Eric Weber: May 24, 1995
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	EW	5/24/95   	Initial version
 *
 * DESCRIPTION:
 *	definition file for log library
 *
 *
 * 	$Id: log.h,v 1.1 97/04/04 15:56:28 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _LOG_H_
#define _LOG_H_

#endif /* _LOG_H_ */

#ifndef _LOG_H_
#define _LOG_H_ 1

@deflib log

#define MAX_LOG_MODULE_NAME_LENGTH	(32)

/*
 *  identifier of a module user can control logging for
 */
/* enum LogModuleID */
typedef enum {
    LMI_EMAIL = 0x0,
    LMI_SOCKET = 0x2,
    LMI_TCP = 0x4,
    LMI_PPP = 0x6,
    LMI_WWW = 0x8,
    LMI_MAIL_EDITOR = 0xa,
    LMI_MAIL_VIEWER = 0xc,
    LMI_RBUS = 0xe,
    LMI_SCM = 0x10,
    LMI_TEST_MANAGER = 0x12,
    LMI_TCP_ECHO = 0x14,
    LMI_TEST_SCRIPT = 0x16,
    LMI_SMS = 0x18,
    LMI_SMS_RECV = 0x1a,
    LMI_SMS_EDIT = 0x1c,
    LMI_B_CARD = 0x1e,
    LMI_SMSEND = 0x20
} LogModuleID;
	/* when adding things here, add them to		  */
	/* log.def, and to Library/Foam/Log/logStrings.ui */

/*
 *  severity of a log event
 * 
 */
typedef ByteEnum LogEventLevel;
#define LEL_NONE	0x0
#define LEL_INFO	0x1
#define LEL_WARNING	0x2
#define LEL_ERROR	0x3
#define LEL_FATAL	0x4


/*
 *  extended machine readable description of an event
 */
typedef DWordFlags LogEventMask;
#define LEM_level	(0xE0000000)   /* LogEventLevel */
#define LEM_level_OFFSET	29
#define LEM_counter	(0x10000000)   /* set to select counter info */
#define LEM_custom	(0x0FFFFFFF)
#define LEM_custom_OFFSET	0


/*
 *  information about an event to be logged
 */
typedef struct {
    LogModuleID	LEP_module;
    LogEventMask	LEP_mask;
    fptr.char	LEP_event;
    fptr.char	LEP_string1;
    fptr.char	LEP_string2;
} LogEventParams;

/*
 *  destination of log events
 */
typedef ByteFlags LogOutputType;
#define LOT_FILE	(0x80)
#define LOT_SERIAL	(0x40)
/* 6 bits unused */


extern void _pascal LogEvent(LogEventParams lep);
/*
 *  Add an event record to the log
 * 
 *  Pass:       lep - description of event to be logged
 *  Return:     nothing
 *
 *  string1 and string2 are substituted for ^A and ^B in LEP_event
 *  the strings can be discarded when LogEvent returns
 *
 *  The event will be logged if the level passed to LogEvent is not
 *  LEL_none and equals or exceeds the level in the mask set by
 *  LogSetModuleMask.  The event will also be logged if the custom
 *  masks supplied to LogEvent and LogSetModuleMask have any common
 *  set bits.
 *
 */

extern void _pascal IncrementCounters(LogModuleID lmi, long counters);
extern void _pascal DecrementCounters(LogModuleID lmi, long counters);
extern void _pascal ZeroCounters(LogModuleID lmi, long counters);
/*
 *  Increment/Decrement/Zero some of the counters for this module.
 * 
 *  Pass:	counters - mask of counters to increment/decrement/zero
 * 		lmi	 - module id requesting log
 * 
 *  Return:	nothing
 *
 *  Each module has access to 32 unsigned 32-bit counters.  At regular
 *  intervals, all of the counters for a module will be converted to
 *  hex and passed to LogEvent with a mask of LEM_counter.  Hence,
 *  they will be logged if and only if the LEM_counter bit is set in
 *  the module mask, irregardless of the LogEventLevel of the mask.
 *
 *  Increment and Decrement will not change the counter value if 
 *  doing so would cause it to go below zero or above maxint.
 */

extern  LogOutputType _pascal LogSetOutput(LogOutputType lot, 
					   SerialPortNum spn,
					   char *fname);
/*
 *  Direct the output of the log utility
 * 
 *  Pass:	lot     = outputs on which to log (0 to disable logging)
 * 		spn	= which serial port to use (if LOT_SERIAL is set)
 * 		ds:dx	= filename relative to SP_PRIVATE_DATA (if LOT_FILE)
 * 
 *  Return:	mask of sucessfully opened outputs
 */


extern Boolean _pascal LogSetCounterOutput(char *fname);
/* 
 * Direct the output of the counters
 * 
 * Pass:	fname  - filename relative to SP_PRIVATE_DATA
 * Return:	TRUE if unable to open file
 *
 * At fixed intervals, this file will be overwritten with the current 
 * counter data for all the modules.  The file will also be
 * overwritten immediately in order to detect any errors.
 */


extern int _pascal LogGetModuleName(LogModuleID lmi, char *namebuf)
/*
 *  Get the name of an app
 * 
 *  Pass:	lmi = module whose name should be fetched
 *              namebuf = buffer for null-terminated name
 *                        should be MAX_LOG_MODULE_NAME_LENGTH chars long
 * 
 *  Return:	size of name, sans null
 */

extern LogEventMask _pascal LogGetModuleMask(LogModuleID lmi);
/*
 *  Get the currently enabled logging for a module
 * 
 *  Pass:	lmi = module whose logging mask should be fetched
 *  Return:	LogEventMask assigned to lmi
 * 
 *  See LogEvent for an explanation of how the mask is used.
 */

extern	void _pascal LogSetModuleMask(LogModuleID lmi, LogEventMask lem);
/*
 *  Set the currently enabled logging for a module
 * 
 *  Pass:	lmi = module to modify
 * 		lem = new mask for lmi
 * 
 *  Return:	nothing
 * 
 *  See LogEvent for an explanation of how the mask is used.
 */

extern int _pascal LogGetLevelName(LogModuleID lmi, char *namebuf)
/*
 *  Get the level name.
 * 
 *  Pass:	lmi = module whose name should be fetched
 *              namebuf = buffer for null-terminated name
 *                        should be MAX_LOG_MODULE_NAME_LENGTH chars long
 * 
 *  Return:	size of name, sans null
 */

@endlib

#endif



