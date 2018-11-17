/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Speedo/reset.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: reset.c,v 1.1 97/04/18 11:45:14 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("SetupCode")

/*****************************************************************************
*                                                                            *
*  Copyright 1989, as an unpublished work by Bitstream Inc., Cambridge, MA   *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/
/********************* Revision Control Information **********************************
*                                                                                    *
*                                                                                    *
*       Revision 28.37  93/03/15  12:48:09  roberte
*       Release
*       
*       Revision 28.9  93/01/29  15:46:44  roberte
*       Changed references to specs_valid to reflect change to common area of SPEEDO_GLOBALS.
*       Changed references to specs_valid to reflect change to common area of SPEEDO_GLOBALS.
*       
*       Revision 28.8  93/01/04  16:23:53  roberte
*       Changed all references to new union fields of SPEEDO_GLOBALS to sp_globals.processor.speedo prefix.
*       
*       Revision 28.7  92/12/30  17:49:45  roberte
*       Functions no longer renamed in spdo_prv.h now declared with "sp_"
*       Use PARAMS1&2 macros throughout.
*       
*       Revision 28.6  92/11/24  10:55:16  laurar
*       include fino.h
*       
*       Revision 28.5  92/11/19  15:18:08  roberte
*       Release
*       
*       Revision 28.1  92/06/25  13:41:56  leeann
*       Release
*       
*       Revision 27.1  92/03/23  14:01:38  leeann
*       Release
*       
*       Revision 26.1  92/01/30  17:01:11  leeann
*       Release
*       
*       Revision 25.1  91/07/10  11:06:50  leeann
*       Release
*       
*       Revision 24.1  91/07/10  10:40:24  leeann
*       Release
*       
*       Revision 23.1  91/07/09  18:01:23  leeann
*       Release
*       
*       Revision 22.1  91/01/23  17:20:45  leeann
*       Release
*       
*       Revision 21.2  91/01/21  18:05:59  leeann
*       make hdr2_org pointer a FONTFAR
*       
*       Revision 21.1  90/11/20  14:40:16  leeann
*       Release
*       
*       Revision 20.1  90/11/12  09:35:58  leeann
*       Release
*       
*       Revision 19.1  90/11/08  10:25:15  leeann
*       Release
*       
*       Revision 18.1  90/09/24  10:16:28  mark
*       Release
*       
*       Revision 17.1  90/09/13  16:01:40  mark
*       Release name rel0913
*       
*       Revision 16.1  90/09/11  13:22:02  mark
*       Release
*       
*       Revision 15.1  90/08/29  10:05:29  mark
*       Release name rel0829
*       
*       Revision 14.1  90/07/13  10:42:14  mark
*       Release name rel071390
*       
*       Revision 13.1  90/07/02  10:41:18  mark
*       Release name REL2070290
*       
*       Revision 12.1  90/04/23  12:14:00  mark
*       Release name REL20
*       
*       Revision 11.1  90/04/23  10:14:14  mark
*       Release name REV2
*       
*       Revision 10.5  90/04/23  10:05:39  mark
*       call read_word_u, not sp_read_word_u so that
*       reentrant mode works
*       
*       Revision 10.4  90/04/23  09:40:35  mark
*       balance #if/endif statements (fatal error is
*       normal compilers)
*       
*       Revision 10.3  90/04/21  10:49:58  mark
*       initialize device set flags for multi device support option
*       
*       Revision 10.2  90/04/12  13:45:09  mark
*       add sp_get_cust_no function
*       
*       Revision 10.1  89/07/28  18:12:33  mark
*       Release name PRODUCT
*       
*       Revision 9.1  89/07/27  10:25:57  mark
*       Release name PRODUCT
*       
*       Revision 8.1  89/07/13  18:21:54  mark
*       Release name Product
*       
*       Revision 7.1  89/07/11  09:04:26  mark
*       Release name PRODUCT
*       
*       Revision 6.1  89/06/19  08:37:24  mark
*       Release name prod
*       
*       Revision 5.1  89/05/01  17:56:38  mark
*       Release name Beta
*       
*       Revision 4.1  89/04/27  12:19:21  mark
*       Release name Beta
*       
*       Revision 3.1  89/04/25  08:32:31  mark
*       Release name beta
*       
*       Revision 2.1  89/04/04  13:38:34  mark
*       Release name EVAL
*       
*       Revision 1.7  89/04/04  13:26:31  mark
*       Update copyright text
*       
*       Revision 1.6  89/03/31  14:45:03  mark
*       change speedo.h to spdo_prv.h
*       change comments from fontware to speedo
*       
*       Revision 1.5  89/03/31  12:15:24  john
*       modified to use new NEXT_WORD macro.
*       
*       Revision 1.4  89/03/30  17:53:50  john
*       Decryption data simplified.
*       
*       Revision 1.3  89/03/29  16:12:18  mark
*       changes for slot independence and dynamic/reentrant
*       data allocation
*       
*       Revision 1.2  89/03/21  13:32:26  mark
*       change name from oemfw.h to speedo.h
*       
*       Revision 1.1  89/03/15  12:35:40  mark
*       Initial revision
*                                                                                 *
*                                                                                    *
*************************************************************************************/

#ifdef RCSSTATUS
#endif




/******************************* R E S E T . C *******************************
 *                                                                           *
 * This module provides initialization functions.                            *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 *                                                                           *
 *  1) 15 Dec 88  jsc  Created                                               *
 *                                                                           *
 *  2) 23 Jan 89  jsc  Font decryption mechanism implemented                 *
 *                                                                           *
 *  3)  1 Mar 89  jsc  Font decryption mechanism updated.                    *
 *                                                                           *
 ****************************************************************************/

#include "spdo_prv.h"               /* General definitions for Speedo     */
#include "fino.h"
#include "keys.h"                /* Font decryption keys */

#define   DEBUG      0

#if DEBUG
#include <stdio.h>
#define SHOW(X) printf("X = %d\n", X)
#else
#define SHOW(X)
#endif

/***** GLOBAL VARIABLES *****/

/*****  GLOBAL FUNCTIONS *****/

/***** EXTERNAL VARIABLES *****/

/***** EXTERNAL FUNCTIONS *****/

/***** STATIC VARIABLES *****/

/***** STATIC FUNCTIONS *****/


FUNCTION void sp_reset(PARAMS1)
GDECL
/*
 * Called by the host software to intialize the Speedo mechanism
 */
{
sp_globals.specs_valid = FALSE;            /* Flag specs not valid */

/* Reset decryption key */
sp_globals.processor.speedo.key32 = (KEY3 << 8) | KEY2;
sp_globals.processor.speedo.key4 = KEY4;
sp_globals.processor.speedo.key6 = KEY6;
sp_globals.processor.speedo.key7 = KEY7;
sp_globals.processor.speedo.key8 = KEY8;

#if INCL_RULES
sp_globals.processor.speedo.constr.font_id_valid = FALSE;
#endif

#if INCL_MULTIDEV
#if INCL_BLACK || INCL_SCREEN || INCL_2D
sp_globals.processor.speedo.bitmap_device_set = FALSE;
#endif
#if INCL_OUTLINE
sp_globals.processor.speedo.outline_device_set = FALSE;
#endif
#endif
}

#if INCL_KEYS
FUNCTION void sp_set_key(PARAMS2 key)
GDECL
ufix8 key[];         /* Specified decryption key */
/*
 * Dynamically sets font decryption key.
 */
{
sp_globals.processor.speedo.key32 = ((ufix16)key[3] << 8) | key[2];
sp_globals.processor.speedo.key4 = key[4];
sp_globals.processor.speedo.key6 = key[6];
sp_globals.processor.speedo.key7 = key[7];
sp_globals.processor.speedo.key8 = key[8];
}
#endif



FUNCTION ufix16 sp_get_cust_no(PARAMS2 font_buff)
GDECL
buff_t font_buff;
/*
	returns customer number from font 
*/
{ 
ufix8 FONTFAR *hdr2_org;
ufix16 private_off;

private_off = sp_read_word_u(PARAMS2 font_buff.org + FH_HEDSZ);
if (private_off + FH_CUSNR > font_buff.no_bytes)
	{
	sp_report_error(PARAMS2 1);           /* Insufficient font data loaded */
    return FALSE;
    }

hdr2_org = font_buff.org + private_off;

return (sp_read_word_u(PARAMS2 hdr2_org + FH_CUSNR));
}

#pragma Code ()
