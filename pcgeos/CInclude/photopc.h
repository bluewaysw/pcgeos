/***********************************************************************
 *
 *	Copyright (c) MyTurn.com 2000.  All rights reserved.
 *	MYTURN.COM CONFIDENTIAL
 *
 * PROJECT:	  GlobalPC
 * MODULE:	  PhotoPC
 * FILE:	  photopc.h
 *
 * AUTHOR:  	  David Hunter: Nov 08, 2000
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/08/00   	Initial version
 *
 * DESCRIPTION:
 *
 *	Header file for the PhotoPC library
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _PHOTOPC_H_
#define _PHOTOPC_H_

typedef unsigned long PPCFrame;

typedef enum {
    PPCR_LO = 1,		/* Low resolution  */
    PPCR_HI = 2,		/* High resolution */
    PPCR_EXT1 = 3,		/* Extended resolution #1 */
    PPCR_EXT2 = 4		/* Extended resolution #2 */
} PPCResolution;

typedef enum {
    PPCF_AUTO = 0,		/* Automatic flash */
    PPCF_FORCE = 1,		/* Fill flash */
    PPCF_OFF = 2,		/* No flash */
    PPCF_ANTIREDEYE = 3,	/* Red eye reduction */
    PPCF_SLOWSYNC = 4		/* (?) */
} PPCFlash;

typedef enum {
    PPCFT_THUMBNAIL,			/* thumbnail */
    PPCFT_IMAGE				/* whole image */
} PPCFileType;

typedef void (PPC_runcb)(dword count);
typedef void (PPC_errorcb)(int errcode,char *errstr);

/***********************************************************************
 *				PPCOpen
 ***********************************************************************
 *
 * SYNOPSIS:	    Open the camera.
 * CALLED BY:	    GLOBAL
 *
 * PARAMETERS:	    piob - pointer to void * to hold library context
 *		    device - serial port to which camera is attached
 *		    runcb - routine called during file xfer
 *		        NULL is acceptable
 *		    errorcb - routine called on any error in subsequent
 *			calls (if library is compiled with error strings)
 *		        NULL is acceptable
 *
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCOpen(void **piob, SerialPortNum device, PPC_runcb *runcb, 
		    PPC_errorcb *errorcb, word speed);

/***********************************************************************
 *				PPCSetResolution
 ***********************************************************************
 *
 * SYNOPSIS:	    Set the camera resolution.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    res - resolution mode
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCSetResolution(void *iob, PPCResolution);

/***********************************************************************
 *				PPCSetFlash
 ***********************************************************************
 *
 * SYNOPSIS:	    Set the camera flash mode.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    flash - flash mode
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCSetFlash(void *iob, PPCFlash);

/***********************************************************************
 *				PPCSnapShot
 ***********************************************************************
 *
 * SYNOPSIS:	    Take a picture.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCSnapShot(void *iob);

/***********************************************************************
 *				PPCErase
 ***********************************************************************
 *
 * SYNOPSIS:	    Erase a frame.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    frame - frame to erase
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCErase(void *iob, PPCFrame frame);

/***********************************************************************
 *				PPCEraseAll
 ***********************************************************************
 *
 * SYNOPSIS:	    Erase all frames.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCEraseAll(void *iob);

typedef WordFlags PPCQueryFlags;
#define PPCQF_RESOLUTION	0x0001
#define PPCQF_FLASH		0x0002
#define PPCQF_FRAMES_TAKEN	0x0004
#define PPCQF_FRAMES_LEFT	0x0008
#define PPCQF_FREE_MEMORY	0x0010

typedef struct {
    PPCQueryFlags PPCQ_flags;		/* indicate which fields set */
    PPCResolution PPCQ_resolution; 	/* resolution */
    PPCFlash PPCQ_flash;		/* flash */
    PPCFrame PPCQ_framesTaken;		/* frames taken */
    PPCFrame PPCQ_framesLeft;		/* frames left */
    PPCFrame PPCQ_freeMemory;		/* free memory */
} PPCQueryStruct;

/***********************************************************************
 *				PPCQuery
 ***********************************************************************
 *
 * SYNOPSIS:	    Get camera status data.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    pqs - query structure to fill with status
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCQuery(void *iob, PPCQueryStruct *pqs);

/***********************************************************************
 *				PPCCount
 ***********************************************************************
 *
 * SYNOPSIS:	    Get the number of frames stored on the camera.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    pNumFrames - pointer to PPCFrame to set to frame count
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCCount(void *iob, PPCFrame *pNumFrames);

/***********************************************************************
 *				PPCGetFile
 ***********************************************************************
 *
 * SYNOPSIS:	    Transfer a frame from the camera to the PC.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    frame - frame to transfer
 *		    datatype - type of data to receive
 *		        PPCFT_IMAGE for full-sized image
 *			PPCFT_THUMBNAIL for smaller image
 *		    filenm - name of file to which to write image
 *			May be full path or relative to current path
 *		    
 * RETURN:	    zero on success, non-zero on error
 *
 ***********************************************************************/
int _export PPCGetFile(void *iob, PPCFrame frame, PPCFileType type, 
		       const char *filename);

/***********************************************************************
 *				PPCClose
 ***********************************************************************
 *
 * SYNOPSIS:	    Close the camera port.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    bPowerOff - TRUE to send close command to camera
 *			This seems to want to always be TRUE
 * RETURN:	    nothing
 * SIDE EFFECTS:    iob is invalid upon return
 *
 ***********************************************************************/
void _export PPCClose(void *iob, Boolean bPowerOff);

#endif /* _PHOTOPC_H_ */
