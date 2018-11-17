/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Include
FILE:		streamC.h

AUTHOR:		John D. Mitchell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.
	JDM	93.07.25	Mask/offset value switch.

DESCRIPTION:
	This file contains all of the interface information for using the
	GEOS C Stream Driver library.

	$Id: streamC.h,v 1.1 97/04/04 15:57:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef _STREAMC_H_
#define _STREAMC_H_

#include <serialDr.h>		/* serial specific definitions */
#include <parallDr.h>		/* parallel specific definitions */


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Stream Types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * StreamRoles indicates which side of the connection one is interested in.
 */
typedef	enum
{
	STREAM_ROLES_WRITER	= 0,
	STREAM_ROLES_READER	= -1,
	STREAM_ROLES_BOTH	= -2
} StreamRoles;	


/*
 * StreamBlocker indicates whether the read/write should block or not.
 */
typedef	enum
{
	STREAM_BLOCK	= 2,
	STREAM_NO_BLOCK	= 0
} StreamBlocker;


typedef enum
{
    	STREAM_DISCARD = 0,
	STREAM_LINGER = -1
} StreamLingerMode;


/*
 * StreamError indicates the nature of errors common to all stream drivers.
 * This is the error returned from most all Stream*, Serial* & Parallel*
 * routines.  Note that this will not indicate device-specific errors. Use
 * StreamGetError/SerialGetError/ParallelGetErorr for this purpose.
 */
typedef	enum
{
	STREAM_NOT_IMPLEMENTED = -1,
	/* Used only in functions not implemented */

	STREAM_NO_ERROR = 0,
	/* Returned if no StreamError */

	STREAM_WOULD_BLOCK	= 1,
	/* Operation would block when  no blocking is allowed. This
	   is only returned if no part of the request could be
	   satisfied. */

	STREAM_CLOSING		= 2,
	/* Cannot write -- stream is being closed */

	STREAM_CANNOT_ALLOC	= 3,
	/* Cannot create -- unable to allocate buffer */

	STREAM_BUFFER_TOO_LARGE	= 4,
	/* Cannot create -- buffer size is too large (32K max) */

	STREAM_CLOSED		= 5,
	/* Cannot access -- stream is not open */

	STREAM_SHORT_READ_WRITE = 6,
	/* Read or write with STREAM_BLOCK and stream closed before
	   operation could complete.  */

	STREAM_NO_DEVICE 	= 7,
	 /* Attempting to open a device-based stream (e.g. parallel
	    or serial port) when the device requested doesn't exist.  */

	STREAM_DEVICE_IN_USE 	= 8,
	/* SOF_NOBLOCK or SOF_TIMEOUT given and device is in-use.  */

	STREAM_POWER_ERROR 	= 9
	/* Tried to open the requested port, but couldn't due to
	   some error in the power driver */
	 
} StreamError;

#define STREAM_FIRST_DEV_ERROR     256	/* Start of range stream-based drivers
					   can use for their StreamErrors */


/*
 * StreamToken identifies a stream.
 */
typedef	Handle	StreamToken;


/*
 * StreamOpenFlags indicate the manner in which the stream should be
 * opened.
 */
typedef	enum
{
	STREAM_OPEN_NO_BLOCK	= 0x02,
	STREAM_OPEN_TIMEOUT	= 0x01
} StreamOpenFlags;


/*
 * StreamNotifyMode indicates the way of notification.
 */
typedef	enum
{
	STREAM_MODE_NONE,
	STREAM_MODE_ROUTINE,
	STREAM_MODE_MESSAGE	/* This is *not* supported in C.	*/
} StreamNotifyMode;


/*
 * StreamNotifyEvent specifies which notifications we're interested in.
 */
typedef	enum
{
	STREAM_EVENT_ERROR,
	STREAM_EVENT_DATA,
	SERIAL_EVENT_MODEM
} StreamNotifyEvent;


/*
 * StreamNotifyType is how we tell the driver all about what notifications
 * we're interested in.
 */
typedef	ByteFlags StreamNotifyType;
#define	STREAM_TYPE_READER_OFFSET	(5)
#define	STREAM_TYPE_READER		(0x01 << STREAM_TYPE_READER_OFFSET)

#define	STREAM_TYPE_EVENT_OFFSET	(2)
#define	STREAM_TYPE_EVENT		(0x07 << STREAM_TYPE_EVENT_OFFSET)

#define	STREAM_TYPE_HOW_OFFSET		(0)
#define	STREAM_TYPE_HOW			(0x01 << STREAM_TYPE_HOW_OFFSET)



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Driver Types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * DriverPassParams is used to pass arguments into DriverCallEntryPoint.
 */
typedef	struct
{
	word	ax;
	word	bx;
	word	cx;
	word	dx;
	word	si;
	word	bp;
	word	ds;
	word	es;
} DriverPassParams;

/*
 * DriverPassParams is used to return results from DriverCallEntryPoint.
 */
typedef	struct
{
	word	ax;
	word	bx;
	word	cx;
	word	dx;
	word	si;
	word	di;
	word	bp;
	word	ds;
	word	es;
	CPUFlags	flags;
} DriverReturnParams;


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Prototypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * Generic Driver routines.
 */
extern	void
	_pascal DriverCallEntryPoint (Handle driver,
				      word func,
				      DriverPassParams *passParams,
				      DriverReturnParams *returnParams);

/*
 * Stream Driver routines.
 *
 * NOTE:  StreamError == 0 indicates that no StreamError has occurred.
 *
 */
extern	StreamError
	_pascal StreamGetDeviceMap (Handle driver, word *retInfo);

extern	StreamError
	_pascal StreamOpen (Handle driver,
			    word buffSize,
			    GeodeHandle owner,
			    HeapFlags heapFlags,
			    StreamToken *stream);

extern	StreamError
	_pascal StreamClose (Handle driver,
			     StreamToken stream,
			     StreamLingerMode linger);

extern	StreamError	/* NOT implemented.	*/
	_pascal StreamSetNotify (Handle driver,
			     	 StreamToken stream,
				 word *status);

extern  StreamError
       	_pascal StreamSetMessageNotify (Handle driver,
				        StreamToken stream,
					StreamNotifyType type,
					Message msg,
					optr destination);
	 /* Message should be defined as follows:

	    STREAM_EVENT_DATA:
	    @message void NAME(word numAvail = cx, StreamToken stream = dx,
			       StreamRoles side = bp);

	    STREAM_EVENT_ERROR:
	    @message void NAME(ErrorType error = cx, StreamToken stream = dx);

	    SERIAL_EVENT_MODEM:
	    @message void NAME(SerialModemStatus status = cx,
	                       StreamToken stream = dx);

	    Note that "stream" will *not* be the unit number for the parallel
	    or serial drivers.
	  */


/*
 * Prototype for the notification routine to be passed to StreamSetRoutineNotify
 * for the SNE_ERROR, SNE_MODEM, SNE_PASSIVE events, and the SNE_DATA event
 * when the notification threshold is any value other than 1. For all events,
 * the "data" parameter is the same as the "data" parameter passed to
 * StreamSetRoutineNotify. The cxValue and bpValue parameters are as follows:
 *
 *	SNE_DATA:   	cxValue = # bytes available for reading or writing
 *		    	bpValue = STREAM_READ or STREAM_WRITE
 *	SNE_ERROR:  	cxValue = the error word (driver-specific)
 *	       	    	bpValue = undefined
 *	SNE_PASSIVE:	cxValue	= SerialPassiveNotificationStatus
 *	    	    	bpValue	= the port number
 *	SNE_MODEM:  	cxValue	= SerialModemStatus
 *	    	    	bpValue = undefined
 */
typedef void _pascal StreamGeneralNotifyRoutine(word data,
						word cxValue,
						word bpValue);

/*
 * Prototype for the notification routine to be passed to StreamSetRoutineNotify
 * for the SNE_DATA event when the notification threshold is 1. In this case,
 * the routine acts as an extension of the interrupt code, allowing it to see
 * each byte as it's received, or to fill each byte in the stream as space
 * becomes available.
 *
 * For the reading side:
 *	    cxValue = the byte just read
 *	    bpValue = STREAM_READ
 *	    return  = non-zero if the byte was consumed, 0 if the byte should
 *		      be placed into the input stream
 * For the writing side:
 *	    cxValue = undefined
 *	    bpValue = STREAM_WRITE
 *	    return  = formed using the STREAM_SPECIAL_WRITE_VALUE indicating
 *		      whether a byte to be written is being returned.
 */
typedef word _pascal StreamSpecialDataNotifyRoutine(word data,
						    word cxValue,
						    word bpValue);

#define STREAM_SPECIAL_WRITE_VALUE(addByte, value) \
	    ((((addByte)&0xff)<<8) | ((value) & 0xff))

extern  StreamError
       	_pascal StreamSetRoutineNotify (Handle driver,
				        StreamToken stream,
					StreamNotifyType type,
					word data,
					StreamGeneralNotifyRoutine *callback);

extern	StreamError
	_pascal StreamSetDataRoutineNotify (Handle driver,
					    StreamToken stream,
					    StreamNotifyType type,
					    word data,
					    StreamGeneralNotifyRoutine *callback,
					    word threshold);

extern  StreamError
       	_pascal StreamSetNoNotify (Handle driver,
				   StreamToken stream,
				   StreamNotifyType type);



extern	StreamError
	_pascal StreamGetError (Handle driver,
				StreamToken stream,
				StreamRoles roles,
				word *errorCode);
	/* NOTE:  errorCode is a device-specific code, such as SerialError
	   or ParallelError */

extern	StreamError
	_pascal StreamSetError (Handle driver,
				StreamToken stream,
				StreamRoles roles,
				word errorCode);
	/* NOTE:  errorCode is a device-specific code, such as SerialError
	   or ParallelError */

extern	StreamError
	_pascal StreamFlush (Handle driver,
			     StreamToken stream);

extern	StreamError
	_pascal StreamSetThreshold (Handle driver,
				    StreamToken stream,
				    StreamRoles roles,
				    word threshold);

extern	StreamError
	_pascal StreamRead (Handle driver,
			    StreamToken stream,
			    StreamBlocker blocker,
			    word buffSize,
			    byte *buffer,
			    word *numBytesRead);

extern	StreamError
	_pascal StreamReadByte (Handle driver,
				StreamToken stream,
				StreamBlocker blocker,
				byte *dataByte);

extern	StreamError
	_pascal StreamWrite (Handle driver,
			     StreamToken stream,
			     StreamBlocker blocker,
			     word buffSize,
			     byte *buffer,
			     word *numBytesWritten);

extern	StreamError
	_pascal StreamWriteByte (Handle driver,
				 StreamToken stream,
				 StreamBlocker blocker,
				 byte dataByte);

extern	StreamError
	_pascal StreamQuery (Handle driver,
			     StreamToken stream,
			     StreamRoles role,
			     word *bytesAvailable);

extern	StreamError
	_pascal StreamEscLoadOptions (Handle driver,
				      const char *category);

/*
 * Serial Driver routines.
 *
 * NOTE:  StreamError == 0 indicates that no StreamError has occurred.
 */
extern	Handle
	_pascal SerialLoadDriver(void);

#define SerialGetDeviceMap(driver, retInfo) \
	    StreamGetDeviceMap((driver), (retInfo))

extern	StreamError
	_pascal SerialOpen (Handle driver,
			    SerialUnit unit,
			    StreamOpenFlags flags,
			    word inBuffSize,
			    word outBuffSize,
    			    word timeout);

extern	StreamError
	_pascal SerialClose (Handle driver,
			     SerialUnit unit,
			     StreamLingerMode linger);

extern	StreamError
	_pascal SerialSetNotify (Handle driver,
			     	 StreamToken stream,
				 SerialModemStatus *status);

#define SerialGetError(driver, unit, roles, errorCode) \
	    StreamGetError((driver), (unit), (roles), (errorCode))

#define SerialSetError(driver, unit, roles, errorCode) \
	    StreamSetError((driver), (unit), (roles), (errorCode))

extern	StreamError
	_pascal SerialFlush (Handle driver,
			     SerialUnit unit,
			     StreamRoles roles);

#define SerialSetThreshold(driver, unit, roles, threshold) \
	    StreamSetThreshold((driver), (unit), (roles), (threshold))

#define SerialRead(driver, unit, blocker, buffSize, buffer, numBytesRead) \
	    StreamRead((driver), (unit), (blocker), (buffSize), (buffer), \
	    	    	(numBytesRead))

#define SerialReadByte(driver, unit, blocker, dataByte) \
	    StreamReadByte((driver), (unit), (blocker), (dataByte))

#define SerialWrite(driver, unit, blocker, buffSize, buffer, numWritten) \
	    StreamWrite((driver), (unit), (blocker), (buffSize), (buffer), \
			(numWritten))

#define SerialWriteByte(driver, unit, blocker, dataByte) \
	    StreamWriteByte((driver), (unit), (blocker), (dataByte))

#define SerialQuery(driver, unit, role, bytesAvailable) \
	    StreamQuery((driver), (unit), (role), (bytesAvailable))

#define SerialEscLoadOptions(driver, category) \
	    StreamEscLoadOptions((driver), (category))

extern	StreamError
	_pascal SerialSetFormat (Handle driver,
				 SerialUnit unit,
				 SerialFormat format,
				 SerialMode mode,
				 SerialBaud baud);

extern	StreamError
	_pascal SerialGetFormat (Handle driver,
				 SerialUnit unit,
				 SerialFormat *format,
				 SerialMode *mode,
				 SerialBaud *baud);

extern	StreamError
	_pascal SerialSetModem (Handle driver,
				SerialUnit unit,
				SerialModem modem);

extern	StreamError
	_pascal SerialGetModem (Handle driver,
				SerialUnit unit,
				SerialModem *modem);

extern	StreamError
	_pascal SerialOpenForDriver (Handle driver,
				     SerialUnit unit,
				     StreamOpenFlags flags,
				     word inBuffSize,
				     word outBuffSize,
				     word timeout,
				     GeodeHandle owner);

extern	StreamError
	_pascal SerialSetFlowControl (Handle driver,
				      SerialUnit unit,
				      SerialFlowControl flow,
				      SerialModem modem,
				      SerialModemStatus status);

extern	StreamError
	_pascal SerialDefinePort (Handle driver,
				  word basePort,
				  byte interruptLevel,
				  SerialUnit *unit);

extern	StreamError
	_pascal SerialStatPort (Handle driver,
				SerialUnit unit,
				word *interruptLevel,
				Boolean *portOpen);

extern	StreamError
	_pascal SerialCloseWithoutReset (Handle driver,
					 SerialUnit unit,
					 StreamLingerMode linger);

extern  StreamError
        _pascal SerialSetRole (Handle driver,
			       SerialUnit unit,
			       SerialRole role);

/*
 * Parallel Driver routines.
 *
 * NOTE:  StreamError == 0 indicates that no StreamError has occurred.
 *
 */
extern	Handle
	_pascal ParallelLoadDriver(void);

#define ParallelGetDeviceMap(driver, retInfo) \
	    StreamGetDeviceMap((driver), (retInfo))


extern	StreamError
	_pascal ParallelOpen (Handle driver,
			      ParallelUnit unit,
			      StreamOpenFlags flags,
			      word outBuffSize,
			      word timeout);

#define	ParallelClose(driver, unit, linger) \
	    StreamClose((driver), (unit), (linger))


#define	ParallelGetError(driver, unit, roles, errorCode) \
	    StreamGetError((driver), (unit), (roles), (errorCode))

extern	StreamError
	_pascal ParallelSetError (Handle driver,
				  ParallelUnit unit,
				  StreamRoles roles,
				  ParallelError errorCode);

#define	ParallelFlush(driver, unit, roles) SerialFlush((driver),(unit),(roles))

#define ParallelSetThreshold(driver, unit, roles, threshold) \
	    StreamSetThreshold((driver), (unit), (roles), (threshold))

#define ParallelWrite(driver, unit, blocker, buffSize, buffer, numWritten) \
	    StreamWrite((driver), (unit), (blocker), (buffSize), (buffer), \
	    	    	(numWritten))

#define ParallelWriteByte(driver, unit, blocker, dataByte) \
	    StreamWriteByte((driver), (unit), (blocker), (dataByte))

extern	StreamError
	_pascal ParallelQuery (Handle driver,
			       ParallelUnit unit,
			       Boolean *printerBusy);

#define ParallelEscLoadOptions(driver, category) \
	    StreamEscLoadOptions((driver), (category))

extern	StreamError
	_pascal ParallelMaskError (Handle driver,
				   ParallelUnit unit,
				   ParallelError errorMask);

extern	StreamError
	_pascal ParallelTimeout (Handle driver,
				 ParallelUnit unit,
				 word waitSeconds);

extern	StreamError
	_pascal ParallelRestart (Handle driver,
				 ParallelUnit unit,
				 Boolean resendPending);

extern	StreamError
	_pascal ParallelVerify (Handle driver,
				ParallelUnit unit,
				ParallelError *error);

extern	StreamError
	_pascal ParallelSetInterrupt (Handle driver,
				      ParallelUnit unit,
				      ParallelInterrupt pInt);

extern	StreamError
	_pascal ParallelStatPort (Handle driver,
				  ParallelUnit unit,
				  byte *interruptLevel,
				  byte *portOpen);


#ifdef	__HIGHC__
pragma	Alias (DriverCallEntryPoint,	"DRIVERCALLENTRYPOINT");

pragma	Alias (StreamGetDeviceMap,	"STREAMGETDEVICEMAP");
pragma	Alias (StreamOpen,		"STREAMOPEN");
pragma	Alias (StreamClose,		"STREAMCLOSE");
pragma	Alias (StreamSetMessageNotify, 	"STREAMSETMESSAGENOTIFY");
pragma	Alias (StreamSetRoutineNotify, 	"STREAMSETROUTINENOTIFY");
pragma	Alias (StreamSetDataRoutineNotify, "STREAMSETDATAROUTINENOTIFY");
pragma	Alias (StreamSetNoNotify, 	"STREAMSETNONOTIFY");
pragma	Alias (StreamSetNotify,		"STREAMSETNOTIFY");
pragma	Alias (StreamGetError,		"STREAMGETERROR");
pragma	Alias (StreamSetError,		"STREAMSETERROR");
pragma	Alias (StreamFlush,		"STREAMFLUSH");
pragma	Alias (StreamSetThreshold,	"STREAMSETTHRESHOLD");
pragma	Alias (StreamRead,		"STREAMREAD");
pragma	Alias (StreamReadByte,		"STREAMREADBYTE");
pragma	Alias (StreamWrite,		"STREAMWRITE");
pragma	Alias (StreamWriteByte,		"STREAMWRITEBYTE");
pragma	Alias (StreamQuery,		"STREAMQUERY");
pragma	Alias (StreamEscLoadOptions,	"STREAMESCLOADOPTIONS");

pragma	Alias (SerialLoadDriver,    	"SERIALLOADDRIVER");
pragma	Alias (SerialOpen,		"SERIALOPEN");
pragma	Alias (SerialClose,		"SERIALCLOSE");
pragma	Alias (SerialSetNotify,		"SERIALSETNOTIFY");
pragma	Alias (SerialFlush,		"SERIALFLUSH");
pragma	Alias (SerialSetFormat,		"SERIALSETFORMAT");
pragma	Alias (SerialGetFormat,		"SERIALGETFORMAT");
pragma	Alias (SerialSetModem,		"SERIALSETMODEM");
pragma	Alias (SerialGetModem,		"SERIALGETMODEM");
pragma	Alias (SerialOpenForDriver,	"SERIALOPENFORDRIVER");
pragma	Alias (SerialSetFlowControl,	"SERIALSETFLOWCONTROL");
pragma	Alias (SerialDefinePort,	"SERIALDEFINEPORT");
pragma	Alias (SerialStatPort,		"SERIALSTATPORT");
pragma	Alias (SerialCloseWithoutReset,	"SERIALCLOSEWITHOUTRESET");
pragma  Alias (SerialSetRole,           "SERIALSETROLE");

pragma	Alias (ParallelLoadDriver,    	"PARALLELLOADDRIVER");
pragma	Alias (ParallelOpen,		"PARALLELOPEN");
pragma	Alias (ParallelQuery,		"PARALLELQUERY");
pragma	Alias (ParallelMaskError,	"PARALLELMASKERROR");
pragma	Alias (ParallelTimeout,		"PARALLELTIMEOUT");
pragma	Alias (ParallelRestart,		"PARALLELRESTART");
pragma	Alias (ParallelVerify,		"PARALLELVERIFY");
pragma	Alias (ParallelSetInterrupt,	"PARALLELSETINTERRUPT");
pragma	Alias (ParallelStatPort,	"PARALLELSTATPORT");
#endif /* __HIGHC__ */

#endif /* _STREAMC_H_ */
