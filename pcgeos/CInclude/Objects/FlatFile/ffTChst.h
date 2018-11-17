/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  ffTChst.h
 * FILE:	  ffTChst.h
 *
 * AUTHOR:  	  Jeremy Dashe: Mar 16, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/16/92	  jeremy    Initial version
 *	4/29/92	  jeremy    Moved definition of TCFieldChangeStatus to
 *	    	    	    ffUICtrl.goh
 *
 * DESCRIPTION:
 *	This file contains definitions for the flat file
 *	treasure chest UI controller.
 *	
 * 	$Id: ffTChst.h,v 1.1 97/04/04 15:50:45 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _FFTCHST_H_
#define _FFTCHST_H_

/***********************************************
	Controller features
***********************************************/
#define FFTC_FIELD_LISTS_FEATURE	0x0010
#define FFTC_FIELD_NOTES_FEATURE	0x0008
#define FFTC_CREATE_NEW_FIELD_FEATURE	0x0004
#define FFTC_EDIT_FIELD_FEATURE		0x0002
#define FFTC_DELETE_FIELD_FEATURE	0x0001

/*
 * Feature flags for different UI levels
 */
#define FFTC_DEFAULT_FEATURES           (FFTC_FIELD_LISTS_FEATURE | \
					 FFTC_FIELD_NOTES_FEATURE | \
					 FFTC_CREATE_NEW_FIELD_FEATURE | \
					 FFTC_EDIT_FIELD_FEATURE | \
					 FFTC_DELETE_FIELD_FEATURE)
#define FFTC_DEFAULT_TOOLBOX_FEATURES   0

#endif /* _FFTCHST_H_ */
