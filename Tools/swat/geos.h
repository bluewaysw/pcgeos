/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- GEOS-specific definitions.
 * FILE:	  geos.h
 *
 * AUTHOR:  	  Adam de Boor: Aug 16, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/16/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for GEOS version of Swat
 *
 *
* 	$Id: geos.h,v 4.1 92/04/13 00:17:05 adam Exp $
 *
 ***********************************************************************/
#ifndef _GEOS_H_
#define _GEOS_H_

#include    "table.h"
#include    "ibm.h"

/*
 * Constants from PC GEOS
 *
 * Handle Flags
 */
#define FIXED	  	0x80	    /* Block may not move */
#define SHARABLE	0x40	    /* Block is shared between threads */
#define DISCARDABLE  	0x20	    /* Block may be discarded at any time */
#define SWAPABLE	0x10	    /* Block may be swapped */
#define LMEM	    	0x08	    /* Block managed by LMem */
#define DEBUG	    	0x04	    /* Block being debugged */
#define DISCARDED    	0x02	    /* Block has been discarded. If address
				     * is 0 and DISCARDED is clear, block
				     * has been swapped */
#define MEM_SWAP    	0x01	    /* Block has been swapped to extended
				     * memory */

#define SIG_NON_MEM 	0xf000
#define SIG_GSEG    	0xff00	    /* Han_addr for gseg handles */
#define SIG_THREAD  	0xfe00	    /* Han_addr for thread handles */
#define SIG_FILE    	0xfd00	    /* Han_addr for file handles */
#define SIG_VM	    	0xfc00	    /* Han_addr for vm handles */
#define SIG_VM_HDR  	0xfb00	    /* Han_addr for vm header block */
#define SIG_SAVED_BLOCK	0xfa00	    /* Han_addr for "saved" block */
#define SIG_EVENT_REG	0xf900	    /* Han_addr of regular (i.e. non-stack)
				     * event handle */
#define SIG_EVENT_STACK	0xf800	    /* Han_addr of event handle w/stack data */
#define SIG_EVENT_DATA	0xf700	    /* Han_addr of data for event */
#define SIG_TIMER   	0xf600	    /* Han_addr of handle with timer info */

#include    <geode.h>

/*
 * This is a small piece of the GeodeHeader structure defined in <geode.h>.
 * It is used by Ibm_NewGeode() to fetch the name and type of a new
 * geode so its .geo file may be located on UNIX. The version and coreSize
 * fields aren't actually used, but I want to get the thing in one chunk.
 */
typedef struct {
    word    	fileType;
    word	release[4];
    word	protocol[2];
    word    	serial;
    char    	name[GEODE_NAME_SIZE];
    char    	ext[GEODE_NAME_EXT_SIZE];
}	GeodeName;

#endif _GEOS_H_
