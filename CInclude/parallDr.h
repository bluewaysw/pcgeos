/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  GEOS
 * MODULE:	  CInclude
 * FILE:	  parallDr.h
 *
 * AUTHOR:  	  Jenny Greenwood: Aug 31, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jenny	8/31/93   	Initial version
 *	doug	1/27/94		Moved all parallel constants from StreamC here
 *				so as to mirror the original definition files
 *
 * DESCRIPTION:
 *	Header for users of the parallel port driver.
 *
 * 	$Id: parallDr.h,v 1.1 97/04/04 15:57:45 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _PARALLDR_H_
#define _PARALLDR_H_

/*
 * Parallel driver only StreamError:  Requested interrupt level is already
 * in-use by another port.
 */

#define STREAM_INTERRUPT_TAKEN = STREAM_FIRST_DEV_ERROR

/* 
 * Constants for DR_STREAM_OPEN.
 * ParallelPortNum and ParallelUnit identify serial ports.  The only reason
 * for two names for the same this is for consistency with the ASM
 * documentation.
 */
typedef	enum /* word */
{
	PARALLEL_LPT1	= 0,
	PARALLEL_LPT2	= 2,
	PARALLEL_LPT3	= 4,
	PARALLEL_LPT4	= 6,
} ParallelPortNum, ParallelUnit;


/*
 * ParallelDeviceMap is the serial driver attribute mask returned by
 * ParallelGetDeviceMap.
 */
typedef	WordFlags ParallelDeviceMap;
#define	PARALLEL_DEVICE_LPT4_OFFSET	(6)
#define	PARALLEL_DEVICE_LPT4		(0x01 << PARALLEL_DEVICE_LPT4_OFFSET)

#define	PARALLEL_DEVICE_LPT3_OFFSET	(4)
#define	PARALLEL_DEVICE_LPT3		(0x01 << PARALLEL_DEVICE_LPT3_OFFSET)

#define	PARALLEL_DEVICE_LPT2_OFFSET	(2)
#define	PARALLEL_DEVICE_LPT2		(0x01 << PARALLEL_DEVICE_LPT2_OFFSET)

#define	PARALLEL_DEVICE_LPT1_OFFSET	(0)
#define	PARALLEL_DEVICE_LPT1		(0x01 << PARALLEL_DEVICE_LPT1_OFFSET)


/*
 * ParallelError indicates the nature of parallel device-specific errors.
 * This is the "errorCode" returned by ParallelGetError.
 */
typedef	WordFlags ParallelError;
#define	PARALLEL_ERROR_FATAL_OFFSET	(9)
#define	PARALLEL_ERROR_FATAL		(0x01 <<	\
					 PARALLEL_ERROR_FATAL_OFFSET)

#define	PARALLEL_ERROR_TIMEOUT_OFFSET	(8)
#define	PARALLEL_ERROR_TIMEOUT		(0x01 <<	\
					 PARALLEL_ERROR_TIMEOUT_OFFSET)

#define	PARALLEL_ERROR_NOPAPER_OFFSET	(5)
#define	PARALLEL_ERROR_NOPAPER		(0x01 <<	\
					 PARALLEL_ERROR_PAPER_OFFSET)

#define	PARALLEL_ERROR_OFFLINE_OFFSET	(4)
#define	PARALLEL_ERROR_OFFLINE		(0x01 <<	\
					 PARALLEL_ERROR_OFFLINE_OFFSET)

#define	PARALLEL_ERROR_ERROR_OFFSET	(3)
#define	PARALLEL_ERROR_ERROR		(0x01 <<	\
					 PARALLEL_ERROR_ERROR_OFFSET)


typedef enum
{
	PARALLEL_INT_THREAD	= 0,
	PARALLEL_INT_NORMAL	= 7,
	PARALLEL_INT_ALTERNATE	= 5
} ParallelInterrupt;

#endif /* _PARALLDR_H_ */
