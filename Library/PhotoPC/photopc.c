/*
	Copyright (c) 1997-1999 Eugene G. Crosser
	Copyright (c) 1998,1999 Bruce D. Lightner (DOS/Windows support)

	You may distribute and/or use for any purpose modified or unmodified
	copies of this software if you preserve the copyright notice above.

	THIS SOFTWARE IS PROVIDED AS IS AND COME WITH NO WARRANTY OF ANY
	KIND, EITHER EXPRESSED OR IMPLIED.  IN NO EVENT WILL THE
	COPYRIGHT HOLDER BE LIABLE FOR ANY DAMAGES RESULTING FROM THE
	USE OF THIS SOFTWARE.
*/

#include "config.h"
#include <Ansi/stdio.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>

#include "eph_io.h"

static unsigned long filesize=0L;
static PPCFrame G_frame;

#ifdef DEBUG
static int debug=2;
static FileHandle debug_file = NullHandle;

void printf(const char *format, ...)
{
     char buf[256];
     va_list vargs;

     va_start(vargs, format);
     vsprintf(buf, format, vargs);
     
     if (debug_file)
     {
          FileWrite(debug_file, buf, strlen(buf), FALSE);
     }
}
#else
#define debug 0
#endif

 /***********************************************************************
 *
 * FUNCTION:	init (eph_iob *iob)
 *
 * CALLED BY:  PPCOpen
 *
 * STRATEGY:   Appears to be some initialization stuff...
 *					Reads camera reg 1 (resolution) but doesn't seem to
 *             do anything with it (&ret).
 *             Then sends null to reg 83 (resetting folder system?)
 *
 *					returns TRUE on failure
 *
 *             I'm going to assume here that Dave determined that these
 *             two things needed to happen to get things going.
 *
 *
 ***********************************************************************/
int init(eph_iob *iob)
{
 long ret;


	/* read the value of camera register 1 (resolution) */
	if (eph_getint(iob, 1, &ret)) return -1;

/*#if 0
	/* jfh - Dave must have tried this IAW the protocol but found it
		unnecessary
	(void)eph_setint(iob,77,1L);
	(void)eph_setint(iob,82,60L);
/*#endif */

   /* send null to camera reg 83 */
	(void) eph_setnullint(iob, 83);

	return 0;
}

 /***********************************************************************
 *
 * FUNCTION:	running (dword count)
 *
 * CALLED BY:  PPCOpen
 *
 * STRATEGY:
 *
 *
 ***********************************************************************/
void running(dword count)
{
	if (filesize)
	{
#ifdef DEBUG
		printf("%lu: %lu of %lu\r\n",(unsigned long)G_frame,
				(unsigned long)count,(unsigned long)filesize);
#endif
	}
}

/***********************************************************************
 *				PPCOpen
 ***********************************************************************
 *
 * SYNOPSIS:	    Open the camera.
 * CALLED BY:	    GLOBAL
 *
 * PARAMETERS:		piob - pointer to void * to hold library context
 *						device - serial port to which camera is attached
 *						runcb - routine called during file xfer
 *								NULL is acceptable
 *						errorcb - routine called on any error in subsequent
 *								calls (if library is compiled with error strings)
 *								NULL is acceptable
 *						speed - port speed set in PicAlbum
 *		NOTE: runcb & errorcb are null when PPCOpen is called from
 *				PACameraRetrieve in PicAlbum app
 *
 * RETURN:	    zero on success, non-zero on error
 *
 * STRATEGY:	    
 *		Create a new iob structure
 *		Open the debug file
 *		Open the camera port and negotiate speed
 *		Do some camera initialization
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 * jfh		9/26/03		commenting code so I can try to understand it
 *          10/24/03		added speed parameter
 *
 ***********************************************************************/
int _export PPCOpen(void **piob, SerialPortNum device,
						PPC_runcb *runcb, PPC_errorcb *errorcb, word speed)
{
 eph_iob *iob;


	if (runcb == NULL)
		/* we'll call the default routine defined above which does nothing
			except in DEBUG mode where it gives an output of frame, count and
         filesize */
		runcb = running;

	/* create a new iob structure in memory */
	iob = eph_new(runcb,	errorcb,	debug);

	/* Create a debug file in the temp camera folder.  The variable debug
		is set to 2 when the DEBUG compile switch is set, otherwise it is 0 */
#ifdef DEBUG
	if (debug) {
		debug_file = FileCreate("debug.txt", FCF_NATIVE |
				      FILE_CREATE_NO_TRUNCATE |
				      FILE_ACCESS_W | FILE_DENY_RW, 0);
		if (debug_file)
			FilePos(debug_file, 0L, FILE_POS_END);
		}
#endif

	if (!iob) {
#ifdef DEBUG
		printf("eph_new failed\r\n");
#endif
		return 1;
		}

	/* open the connection to the camera */
	if (eph_open(iob, device, (long)speed)) {
#ifdef DEBUG
		printf("eph_open failed\r\n");
#endif
		eph_free(iob);
		return 1;
		}

	/* initialize some stuff */
	if (init(iob)) {
#ifdef DEBUG
		printf("init failed\r\n");
#endif
		eph_close(iob, TRUE);
		eph_free(iob);
		return 1;
		}

	*(eph_iob **)piob = iob;
	return 0;  // success

}	/* End of PPCOpen.	*/


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
 * STRATEGY:	    Set register 1 to the passed value
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export
PPCSetResolution(void *iob, PPCResolution res)
{
	return eph_setint(iob,1,res);
}	/* End of PPCSetResolution.	*/


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
 * STRATEGY:	    Set register 7 to the passed value
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export
PPCSetFlash(void *iob, PPCFlash flash)
{
	if (flash > PPCF_SLOWSYNC) {
#ifdef DEBUG
		printf("bad flash mode `%d'\r\n",(int)flash);
#endif
		return -1;
	}

	return eph_setint(iob,7,flash);
}	/* End of PPCSetFlash.	*/


/***********************************************************************
 *				PPCSnapShot
 ***********************************************************************
 *
 * SYNOPSIS:	    Take a picture.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 * RETURN:	    zero on success, non-zero on error
 *
 * STRATEGY:	    Do action code 2
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export
PPCSnapShot(void *iob)
{
	byte zero=0;

	if (eph_action(iob,2,&zero,1)) return -1;
	else return 0;
}


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
 * STRATEGY:	    Do action code 7
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export
PPCErase(void *iob, PPCFrame frame)
{
	byte zero=0;

	if (eph_setint(iob,4,frame)) return -1;
	if (eph_action(iob,7,&zero,1)) return -1;
	else return 0;
}



/***********************************************************************
 *				PPCEraseAll
 ***********************************************************************
 *
 * SYNOPSIS:	    Erase all frames.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 * RETURN:	    zero on success, non-zero on error
 *
 * STRATEGY:	    Do action code 1
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export
PPCEraseAll(void *iob)
{
	byte zero=0;

	if (eph_action(iob,1,&zero,1)) return -1;
	else return 0;
}



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
 * STRATEGY:	    Get each register and fill in the structure
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export
PPCQuery(void *iob, PPCQueryStruct *pqs)
{
	unsigned long result;
	int rc;

	pqs->PPCQ_flags = 0;	// assume everything will fail

	if ((rc=eph_getint(iob,1,&result)) == 0) {
		pqs->PPCQ_resolution = result;
		pqs->PPCQ_flags |= PPCQF_RESOLUTION;
	}
	else if (rc != DC1) return -1;

	if ((rc=eph_getint(iob,7,&result)) == 0) {
		pqs->PPCQ_flash = result;
		pqs->PPCQ_flags |= PPCQF_FLASH;
	}
	else if (rc != DC1) return -1;

	if ((rc=eph_getint(iob,10,&result)) == 0) {
		pqs->PPCQ_framesTaken = result;
		pqs->PPCQ_flags |= PPCQF_FRAMES_TAKEN;
	}
	else if (rc != DC1) return -1;

	if ((rc=eph_getint(iob,11,&result)) == 0) {
		pqs->PPCQ_framesLeft = result;
		pqs->PPCQ_flags |= PPCQF_FRAMES_LEFT;
	}
	else if (rc != DC1) return -1;

	if ((rc=eph_getint(iob,28,&result)) == 0) {
		pqs->PPCQ_freeMemory = result;
		pqs->PPCQ_flags |= PPCQF_FREE_MEMORY;
	}
	else if (rc != DC1) return -1;

	return 0;
}



/***********************************************************************
 *				PPCCount
 ***********************************************************************
 *
 * SYNOPSIS:	Get the number of frames stored on the camera.
 * CALLED BY:	GLOBAL
 * PARAMETERS:	iob - library context
 *					pNumFrames - pointer to PPCFrame to set to frame count
 * RETURN:		zero on success, non-zero on error
 *
 * STRATEGY:	Get the value of register 10
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
int _export PPCCount(void *iob, PPCFrame *pNumFrames)
{

	if (eph_getint(iob, 10, pNumFrames)) return -1;
	else return 0;

}


/***********************************************************************
 *				PPCGetFile
 ***********************************************************************
 *
 * SYNOPSIS:	    Transfer a frame from the camera to the PC.
 * CALLED BY:	    GLOBAL
 * PARAMETERS:	    iob - library context
 *		    frame - frame to transfer (not zero based)
 *		    datatype - type of data to receive
 *		        PPCFT_IMAGE for full-sized image
 *			PPCFT_THUMBNAIL for smaller image
 *		    filenm - name of file to which to write image
 *			May be full path or relative to current path
 *		    
 * RETURN:	    zero on success, non-zero on error
 *
 * STRATEGY:
 *		Get the length of the image/thumbnail data
 *		Open the file for write
 *		Get data from the image/thumbnail register
 *		Close the file
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 * jfh	11/4/03	Comment for clarity
 *
 ***********************************************************************/
int _export PPCGetFile(void *iob, PPCFrame frame, PPCFileType datatype,
								const char *filenm)
{
 long		ilength, tlength;
 dword	got = 0;
 int		dreg = 0;
 int		retval = 0;
 FileHandle		fh;


	G_frame = frame;

	/* set the current frame and get the image & thumbnail lengths */
	if (eph_setint(iob, 4, frame) ||
		 eph_getint(iob, 12, &ilength) ||
		 eph_setint(iob, 4, frame) ||
		 eph_getint(iob, 13, &tlength)) {
		/* bail if any of these bombed */
		return -1;
		}

	/* set the filesize global and the camera register for thumbnail or image */
	filesize = tlength;
	dreg = 15;  // current thumbnail data register
	if (datatype == PPCFT_IMAGE) {
		/* this is the only thing PicAlbum uses (PPCFT_IMAGE) */
		dreg = 14;  // current frame data register
		filesize = ilength;
		}

	/* open a file for the image */
	if ((fh = FileCreate(filenm, FCF_NATIVE | FILE_CREATE_TRUNCATE |
			FILE_ACCESS_W | FILE_DENY_RW, 0)) == NullHandle)
		return -1;
	/* get the image from the camera */
	if (eph_setint(iob, 4, frame) ||
		 eph_getvar(iob, dreg, NULL, &got, fh))
		retval = -1;
   /* close the image file */
	if (FileClose(fh, FALSE)) retval = -1;

	return retval;
}


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
 * STRATEGY:	    Close camera and port
 *		    Free iob
 *		    Close debug file
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	11/11/00   	Initial Revision
 *
 ***********************************************************************/
void _export
PPCClose(void *iob, Boolean bPowerOff)
{
    eph_close(iob, bPowerOff);
    eph_free(iob);

#ifdef DEBUG
	 if (debug_file) {
	    FileClose(debug_file, FALSE);
	    debug_file = NullHandle;
	 }
#endif
}
