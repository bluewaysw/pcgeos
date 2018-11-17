/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	PC SDK
 * MODULE:	Sample Library -- Mandelbrot Set Library
 * FILE:	msFatErr.h
 *
 * AUTHOR:  	  Tom Lester: Aug  9, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TL	8/ 9/93   	Initial version
 *
 * DESCRIPTION:
 *	Fatal errors for the mandelbrot set library.
 *
 *
 * 	$Id: msFatErr.h,v 1.1 97/04/07 10:43:39 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _MSFATERR_H_
#define _MSFATERR_H_

#include <ec.h>

typedef enum {
    /*
     * the color controler received a MSG_GEN_CONTROL_UPDATE_UI
     * with a bad Change Notification Type
     */
    ERROR_COLOR_CONTROL_INVALID_CHANGE_ID_IN_UPDATE_UI,

    /*
     * the precision controler received a MSG_GEN_CONTROL_UPDATE_UI
     * with a bad Change Notification Type
     */
    ERROR_PRECISION_CONTROL_INVALID_CHANGE_ID_IN_UPDATE_UI,

    /*
     * MSG_MSET_INITIALIZE was sent to an initialized MSet object
     */
    ERROR_ALREADY_INITIALIZED,

    /*
     * MSG_MSET_DRAW was asked to draw a line which doesn't seem to have
     * been calculated yet.
     */
    ERROR_MSET_DRAW_DRAWING_NULL_BLOCK_HANDLE,

    /*
     * MSG_MSET_ZOOM passed a point which is not in vis bounds
     */
    ERROR_MSET_ZOOM_POINT_OUT_OF_BOUNDS,
  
    /*
     *	redundant data fields which should always be identical aren't.
     */
    ERROR_REDUNDANT_DATA_NOT_IDENTICAL,
} FatalErrors;

typedef enum {
    /*
     * Tried to send a message to the calculation thread, but either the
     * thread hasn't been created yet, or it has been destroyed.
     */
    WARNING_MESSAGING_UNINITIALIZED_MSET,

    /*
     * Tried to zoom in on a pixel that's outside of the MSet's vis bounds.
     */
    WARNING_POINT_OUT_OF_BOUNDS,
} Warnings;

extern FatalErrors shme;
extern Warnings gribble;

#endif /* _MSFATERR_H_ */
