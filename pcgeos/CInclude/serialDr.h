/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  GEOS
 * MODULE:	  CInclude
 * FILE:	  serialDr.h
 *
 * AUTHOR:  	  Jenny Greenwood: Aug 31, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jenny	8/31/93   	Initial version
 *	doug	1/27/94		Moved all serial constants here from StreamC,
 *				so as to mirror original definition files
 *
 * DESCRIPTION:
 *	Header for users of the serial port driver.
 *
 * 	$Id: serialDr.h,v 1.1 97/04/04 15:57:46 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SERIALDR_H_
#define _SERIALDR_H_

/*
 * Serial driver only StreamError:  Attempting to  define a new port, but
 * the driver has no room in its internal tables to keep track of it.
 */
#define	STREAM_NO_FREE_PORTS = STREAM_FIRST_DEV_ERROR


/*
 * SerialError indicates the nature of serial device-specific errors.
 * This is the "errorCode" returned by SerialGetError.
 */
typedef WordFlags SerialError;

/* Break condition detected on line */
#define	SERIAL_ERROR_BREAK_OFFSET	(4)
#define	SERIAL_ERROR_BREAK		(0x01 <<	\
					 SERIAL_ERROR_BREAK_OFFSET)

/* Framing error (improper # stop bits, e.g.) */
#define	SERIAL_ERROR_FRAME_OFFSET	(3)
#define	SERIAL_ERROR_FRAME		(0x01 <<	\
					 SERIAL_ERROR_FRAME_OFFSET)

/* Parity error received in character (may be garbage) */
#define	SERIAL_ERROR_PARITY_OFFSET	(2)
#define	SERIAL_ERROR_PARITY		(0x01 <<	\
					 SERIAL_ERROR_PARITY_OFFSET)

/* New byte received before old byte read -- old byte discarded. */
#define	SERIAL_ERROR_OVERRUN_OFFSET	(1)
#define	SERIAL_ERROR_OVERRUN		(0x01 <<	\
					 SERIAL_ERROR_OVERRUN_OFFSET)


/*
 * Constant for SerialDefinePort
 */
#define SERIAL_PORT_DOES_NOT_EXIST	-1

/*
 * Constants for DR_STREAM_OPEN and everyone else.
 */
typedef enum /* word */ {
    SERIAL_COM1         = 0,
    SERIAL_COM2 	= 2,
    SERIAL_COM3	        = 4,
    SERIAL_COM4 	= 6,
    SERIAL_COM5 	= 8,	/* only on exceptional systems */
    SERIAL_COM6 	= 10,	/* only on exceptional systems */
    SERIAL_COM7 	= 12,	/* only on exceptional systems */
    SERIAL_COM8 	= 14	/* only on exceptional systems */
} SerialPortNum;

typedef SerialPortNum SerialUnit;

/*
 * Definitions for DR_SERIAL_SET_FORMAT and DR_SERIAL_GET_FORMAT
 */

/*
 * SerialParity describes the parity settings.
 */
typedef	enum
{
	SERIAL_PARITY_NONE	= 0,
	SERIAL_PARITY_ODD	= 1,
	SERIAL_PARITY_EVEN	= 3,
	SERIAL_PARITY_ONE	= 5,
	SERIAL_PARITY_MARK	= 5,
	SERIAL_PARITY_ZERO	= 7,
	SERIAL_PARITY_SPACE	= 7
} SerialParity;

/*
 * SerialLength specifies the number of data bits per frame.
 */
typedef	enum
{
	SERIAL_LENGTH_5,
	SERIAL_LENGTH_6,
	SERIAL_LENGTH_7,
	SERIAL_LENGTH_8
} SerialLength;


/*
 * SerialExtraStopBits specifies the number of additional stop bits per
 * frame.
 */
typedef enum
{
	SERIAL_XSTOP_NONE	= 0,
	SERIAL_XSTOP_HALF	= 1,	/* iff SerialLength == 5.	*/
	SERIAL_XSTOP_ONE	= 1	/* iff SerialLength == 6,7,8.	*/
} SerialExtraStopBits;


typedef ByteFlags SerialFormat;
#define	   SF_DLAB	0x80	/* FOR INTERNAL USE ONLY (MUST BE ZERO) */
#define	   SF_BREAK    	0x40	/* If set, causes a BREAK condition to be
			    	 *  asserted on the line. The bit must be cleared
			    	 *  again to return to normal function. */
#define	   SF_PARITY   	0x38    /* SerialParity: parity to expect on receive
				 *  and use on transmit */
#define    SF_EXTRA_STOP 0x04	/* Set if should generate an extra stop bit. One
				 *  stop bit is always generated. If this bit is
				 *  set, however, an extra 1/2 bit is generated
				 *  when the word-length is 5 bits, while a whole
				 *  extra stop bit is generated when the word-
				 *  length is 6, 7 or 8 */

#define SF_LENGTH   	0x03	/* SerialLength: Word-length specifier */


/* Duplicate defintions, but slightly different names */
typedef	ByteFlags SerialFormat;
#define	SERIAL_FORMAT_DLAB_OFFSET	(7)
#define	SERIAL_FORMAT_DLAB		(0x01 << SERIAL_FORMAT_DLAB_OFFSET)

#define	SERIAL_FORMAT_BREAK_OFFSET	(6)
#define	SERIAL_FORMAT_BREAK		(0x01 << SERIAL_FORMAT_BREAK_OFFSET)

#define	SERIAL_FORMAT_PARITY_OFFSET	(3)
#define	SERIAL_FORMAT_PARITY		(0x07 << SERIAL_FORMAT_PARITY_OFFSET)

#define	SERIAL_FORMAT_EXTRA_STOP_OFFSET	(2)
#define	SERIAL_FORMAT_EXTRA_STOP	(0x01 <<	\
					 SERIAL_FORMAT_EXTRA_STOP_OFFSET)

#define	SERIAL_FORMAT_LENGTH_OFFSET	(0)
#define	SERIAL_FORMAT_LENGTH		(0x03 << SERIAL_FORMAT_LENGTH_OFFSET)


typedef ByteEnum SerialMode;
#define    SM_RAW	0	/* Pass input through untouched */
#define    SM_RARE	1	/* Ditto, but obey XON/XOFF flow-control
 		    		 *  and use it on input */
#define    SM_COOKED	2	/* Flow-control, 7-bit input bytes. */

typedef enum /* word */ {
    SB_115200   = 1,
    SB_57600    = 2,
    SB_38400 	= 3,
    SB_19200	= 6,
    SB_14400	= 8,
    SB_9600	= 12,
    SB_7200	= 16,
    SB_4800	= 24,
    SB_3600	= 32,
    SB_2400	= 48,
    SB_2000	= 58,
    SB_1800	= 64,
    SB_1200	= 96,
    SB_600	= 192,
    SB_300	= 384
} SerialBaud;


/* Duplicate defintions, but slightly different names */
#define SERIAL_BAUD_115200  	SB_115200
#define SERIAL_BAUD_57600   	SB_57600
#define SERIAL_BAUD_38400   	SB_38400
#define SERIAL_BAUD_19200   	SB_19200 
#define SERIAL_BAUD_14400   	SB_14400 
#define SERIAL_BAUD_9600    	SB_9600
#define SERIAL_BAUD_7200    	SB_7200
#define SERIAL_BAUD_4800	SB_4800
#define SERIAL_BAUD_2400	SB_2400
#define SERIAL_BAUD_1800	SB_1800
#define SERIAL_BAUD_1200	SB_1200
#define SERIAL_BAUD_600	    	SB_600 
#define SERIAL_BAUD_300	    	SB_300

#define SERIAL_MODE_RAW	    	SM_RAW
#define SERIAL_MODE_RARE    	SM_RARE
#define SERIAL_MODE_COOKED    	SM_COOKED


/*
 * Parameter for DR_SERIAL_SET_MODEM/DR_SERIAL_GET_MODEM
 */
typedef ByteFlags SerialModem;
#define    SMC_OUT2 	0x08	/* INTERNAL TO DRIVER */
#define    SMC_OUT1 	0x04	/* INTERNAL TO DRIVER */
#define    SMC_RTS  	0x02	/* Request-To-Send (1 asserts it) */
#define    SMC_DTR  	0x01	/* Data-Terminal Ready (1 asserts it) */

/* For DCE role: */
#define SMC_RI		0x08	/* Ring Indicator */
#define SMC_DCD		0x04	/* Data-Carrier Detect */
#define SMC_CTS		0x02	/* Clear-to-send */
#define SMC_DSR		0x01	/* Data-Set Ready */

/* Duplicate defintions, but slightly different names */
#define	SERIAL_MODEM_OUT2_OFFSET	(3)
#define	SERIAL_MODEM_OUT2		(0x01 << SERIAL_MODEM_OUT2_OFFSET)

#define	SERIAL_MODEM_OUT1_OFFSET	(2)
#define	SERIAL_MODEM_OUT1		(0x01 << SERIAL_MODEM_OUT1_OFFSET)

#define SERIAL_MODEM_RTS_OFFSET		(1)
#define SERIAL_MODEM_RTS		(0x01 << SERIAL_MODEM_RTS_OFFSET)

#define SERIAL_MODEM_DTR_OFFSET		(0)
#define SERIAL_MODEM_DTR		(0x01 << SERIAL_MODEM_DTR_OFFSET)

/* For DCE role: */
#define	SERIAL_MODEM_RI_OFFSET	        (3)
#define	SERIAL_MODEM_RI                 (0x01 << SERIAL_MODEM_RI_OFFSET)

#define	SERIAL_MODEM_DCD_OFFSET	        (2)
#define	SERIAL_MODEM_DCD		(0x01 << SERIAL_MODEM_DCD_OFFSET)

#define SERIAL_MODEM_CTS_OFFSET		(1)
#define SERIAL_MODEM_CTS		(0x01 << SERIAL_MODEM_CTS_OFFSET)

#define SERIAL_MODEM_DSR_OFFSET		(0)
#define SERIAL_MODEM_DSR		(0x01 << SERIAL_MODEM_DSR_OFFSET)

/*
 * Additional StreamNotifyEvent defined for the serial driver.
 * May be passed in a StreamNotifyType record to DR_STREAM_SET_NOTIFY.
 */
#define	SNE_MODEM	2	    	/* Notify when modem input
				    	 * signals change. */
typedef ByteFlags SerialModemStatus;	/* Passed in CX when SNE_MODEM
    	    	    	    	    	 * notifier is triggered. */
    /*
     * Current state of signals
     */
#define    SMS_DCD 	0x80		/* Carrier Detect */
#define    SMS_RING	0x40		/* Ring Detect */
#define    SMS_DSR 	0x20		/* Data-Set Ready (modem is happy) */
#define    SMS_CTS 	0x10		/* Clear to send (modem will accept
    	    	    	    	    	 * data) */
    /*
     * Signal-change indicators. Notification will occur whenever one of these
     * becomes set. They are set when the corresponding signal has changed since
     * the last notification.
     */
#define    SMS_DCD_CHANGED 	0x08	/* Carrier Detect changed */
#define    SMS_RING_CHANGED	0x04	/* Activated only when the SMS_RING
    			   	    	 * indicator changes from active to
			   	    	 * inactive (signals the end of a RING
    	    	    	    	    	 * signal on the incoming phone line)*/
#define    SMS_DSR_CHANGED 	0x02	/* Data-Set Ready changed */
#define    SMS_CTS_CHANGED 	0x01	/* Clear to send changed */

/* For DCE role: */
#define SMS_DTR		0x20
#define SMS_RTS		0x10
#define SMS_DTR_CHANGED	0x02
#define SMS_RTS_CHANGED	0x01

/*
 * SerialFlowControl specifies the type of flow control for the stream.
 */
typedef ByteFlags SerialFlowControl;
#define    SFC_SOFTWARE	    0x02    /* If set, obey XON/XOFF characters */
#define    SFC_HARDWARE	    0x01    /* If set, obey hardware signals passed
    	    	    	    	     * in cl and ch */

/* Duplicate defintions, but slightly different names */
typedef	ByteFlags SerialFlowControl;
#define	SERIAL_FLOW_SOFTWARE_OFFSET	(1)
#define	SERIAL_FLOW_SOFTWARE		(0x01 << SERIAL_FLOW_SOFTWARE_OFFSET)

#define	SERIAL_FLOW_HARDWARE_OFFSET	(0)
#define	SERIAL_FLOW_HARDWARE		(0x01 << SERIAL_FLOW_HARDWARE_OFFSET)


/*
 * SerialDeviceMap is the serial driver attribute mask returned by
 * SerialGetDeviceMap.
 */
typedef	WordFlags SerialDeviceMap;
#define	SERIAL_DEVICE_COM8_OFFSET	(14)
#define	SERIAL_DEVICE_COM8		(0x01 << SERIAL_DEVICE_COM8_OFFSET)

#define	SERIAL_DEVICE_COM7_OFFSET	(12)
#define	SERIAL_DEVICE_COM7		(0x01 << SERIAL_DEVICE_COM7_OFFSET)

#define	SERIAL_DEVICE_COM6_OFFSET	(10)
#define	SERIAL_DEVICE_COM6		(0x01 << SERIAL_DEVICE_COM6_OFFSET)

#define	SERIAL_DEVICE_COM5_OFFSET	(8)
#define	SERIAL_DEVICE_COM5		(0x01 << SERIAL_DEVICE_COM5_OFFSET)

#define	SERIAL_DEVICE_COM4_OFFSET	(6)
#define	SERIAL_DEVICE_COM4		(0x01 << SERIAL_DEVICE_COM4_OFFSET)

#define	SERIAL_DEVICE_COM3_OFFSET	(4)
#define	SERIAL_DEVICE_COM3		(0x01 << SERIAL_DEVICE_COM3_OFFSET)

#define	SERIAL_DEVICE_COM2_OFFSET	(2)
#define	SERIAL_DEVICE_COM2		(0x01 << SERIAL_DEVICE_COM2_OFFSET)

#define	SERIAL_DEVICE_COM1_OFFSET	(0)
#define	SERIAL_DEVICE_COM1		(0x01 << SERIAL_DEVICE_COM1_OFFSET)


#define	STREAM_STATUS_UNKNOWN_OFFSET	(15)
#define	STREAM_STATUS_UNKNOWN		(0x01 << STREAM_STATUS_UNKNOWN_OFFSET)

#define	SERIAL_STATUS_DCD_OFFSET	(7)
#define	SERIAL_STATUS_DCD		(0x01 << SERIAL_STATUS_DCD_OFFSET)

#define	SERIAL_STATUS_RING_OFFSET	(6)
#define	SERIAL_STATUS_RING		(0x01 << SERIAL_STATUS_RING_OFFSET)

#define	SERIAL_STATUS_DSR_OFFSET	(5)
#define	SERIAL_STATUS_DSR		(0x01 << SERIAL_STATUS_DSR_OFFSET)

#define	SERIAL_STATUS_CTS_OFFSET	(4)
#define	SERIAL_STATUS_CTS		(0x01 << SERIAL_STATUS_CTS_OFFSET)

#define	SERIAL_STATUS_DCD_CHANGED_OFFSET	(3)
#define	SERIAL_STATUS_DCD_CHANGED	(0x01 <<	\
					 SERIAL_STATUS_DCD_CHANGED_OFFSET)

#define	SERIAL_STATUS_RING_CHANGED_OFFSET	(2)
#define	SERIAL_STATUS_RING_CHANGED	(0x01 <<	\
					 SERIAL_STATUS_RING_CHANGED_OFFSET)

#define	SERIAL_STATUS_DSR_CHANGED_OFFSET	(1)
#define	SERIAL_STATUS_DSR_CHANGED	(0x01 <<	\
					 SERIAL_STATUS_DSR_CHANGED_OFFSET)

#define	SERIAL_STATUS_CTS_CHANGED_OFFSET	(0)
#define	SERIAL_STATUS_CTS_CHANGED	(0x01 <<	\
					 SERIAL_STATUS_CTS_CHANGED_OFFSET)

typedef ByteEnum SerialRole;
#define    SR_DTE	0	/* computer; transmit on 2 receive on 3 */
#define    SR_DCE	1	/* modem; transmit on 3 receive on 2 */

#endif /* _SERIALDR_H_ */
