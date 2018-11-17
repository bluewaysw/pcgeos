/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	HWR Library (Graffiti)
 * FILE:	grafhwr.h
 *
 *
 * REVISION HISTORY:
 *	
 *	Name	Date		Description
 *	----	----		-----------
 *	briacn	2/6/94		Initial revision
 *
 *
 * DESCRIPTION:
 *	Contains exported routines/structures for the HWR library (Graffiti).
 *		
 *	$Id: grafhwr.h,v 1.1 97/04/04 15:56:33 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__GRAFHWR_H
#define	__GRAFHWR_H

#include <hwr.h>		/* so apps don't need to */

#define HWRR_GET_BUFFER_PTRS (HWRR_LAST_RESERVED_ENTRY+1)
/*
 *	Fetches pointers to PalmPrint's internal buffers
 *
 *	PROTOTYPE:
 *	    void HWRGetBufferPtrs(pointsBuff, strokesBuff, multCharBuff,
 *	    	    	    	    	singleCharBuff);
 */

#define HWRR_DO_GRAFFITI_MULTIPLE_CHAR_RECOGNITION (HWRR_LAST_RESERVED_ENTRY+2)
/*
 *	This returns a null-terminated string that was recognized from the
 *	input.
 *
 *	Note: This function is not supported in the PalmPrint library.
 *
 *	PROTOTYPE:
 *	    MemHandle HWrDoGraffitiMultipleCharRecognition();
 */

#define HWRR_SET_LOCKED_SHIFT_CHANGE_CALLBACK (HWRR_LAST_RESERVED_ENTRY+3)
/*
 *	Do not use.
 */

#define HWRR_SET_TERMORARY_SHIFT_CHANGE_CALLBACK (HWRR_LAST_RESERVED_ENTRY+4)
/*
 *	Do not use.
 */

#define HWRR_SET_LOCKED_STATE (HWRR_LAST_RESERVED_ENTRY+5)
/*
 *	This allows the application to set the cap-lock and num-lock state
 *	of the library.
 *
 *	PROTOTYPE:
 *	    void HWRSetLockedState(HWRLockState lockState);
 */

#define HWRR_GET_LOCKED_STATE (HWRR_LAST_RESERVED_ENTRY+6)
/*
 *	This allows the application to get the cap-lock and num-lock state
 *	of the library.
 *
 *	PROTOTYPE:
 *	    HWRLockState HWRGetLockState();
 */

#define HWRR_GET_TEMPORARY_SHIFT_STATE (HWRR_LAST_RESERVED_ENTRY+7)
/*
 *	This allows the application to get the state of the punctuation
 *	shift, extended shift or case shift of the library.
 *
 *	PROTOTYPE:
 *	    HWRTemporaryShiftState HWRGetTemporaryShiftState();
 */

#define HWRR_SET_SHIFT_STATE (HWRR_LAST_RESERVED_ENTRY+8)
/*
 *	This allows setting the shift state.
 *
 *	PROTOTYPE:
 *	    void HWRSetShiftState(Boolean shifted);
 */

#endif

