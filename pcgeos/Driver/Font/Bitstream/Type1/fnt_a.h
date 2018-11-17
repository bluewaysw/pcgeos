/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/fnt_a.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fnt_a.h,v 1.1 97/04/18 11:45:17 newdeal Exp $
 *
 ***********************************************************************/

/*****************************************************************************
*                                                                            *
*  Copyright 1990 as an unpublished work by Bitstream Inc., Cambridge, MA    *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/
 
/****************************  F N T _ A . H *********************************
 *                                                                           *
 * This is the header file for the Type 1 font loader and interpreter        *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 * $Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/fnt_a.h,v 1.1 97/04/18 11:45:17 newdeal Exp $
 *
 * $Log:	fnt_a.h,v $
 * Revision 1.1  97/04/18  11:45:17  newdeal
 * Initial revision
 * 
 * Revision 1.1.10.1  97/03/29  07:05:50  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:18:31  brianc
 * support Type1
 * 
 * Revision 28.24  93/03/15  13:05:21  roberte
 * Release
 * 
 * Revision 28.9  93/01/21  11:42:17  roberte
 * Added prototype (new style) for tr_get_font_hints().
 * 
 * Revision 28.8  93/01/12  11:42:55  roberte
 * Added a comment on last #endif
 * 
 * Revision 28.7  92/11/19  15:24:04  weili
 * Release
 * 
 * Revision 26.3  92/11/16  18:23:09  laurar
 * Add STACKFAR for Windows.
 * 
 * Revision 26.2  92/09/28  16:19:57  roberte
 * In process of renaming fnt.h to fnt_a.h
 * 
 * Revision 26.1  92/06/26  10:22:42  leeann
 * Release
 * 
 * Revision 25.1  92/04/06  11:39:26  leeann
 * Release
 * 
 * Revision 24.1  92/03/23  14:06:54  leeann
 * Release
 * 
 * Revision 23.1  92/01/29  16:58:12  leeann
 * Release
 * 
 * Revision 22.1  92/01/20  13:29:29  leeann
 * Release
 * 
 * Revision 21.1  91/10/28  16:41:51  leeann
 * Release
 * 
 * Revision 20.1  91/10/28  15:25:37  leeann
 * Release
 * 
 * Revision 18.1  91/10/17  11:37:12  leeann
 * Release
 * 
 * Revision 17.1  91/06/13  10:41:42  leeann
 * Release
 * 
 * Revision 16.1  91/06/04  15:32:24  leeann
 * Release
 * 
 * Revision 15.1  91/05/08  18:04:51  leeann
 * Release
 * 
 * Revision 14.1  91/05/07  16:26:04  leeann
 * Release
 * 
 * Revision 13.1  91/04/30  17:00:32  leeann
 * Release
 * 
 * Revision 12.1  91/04/29  14:51:30  leeann
 * Release
 * 
 * Revision 11.1  91/04/04  10:54:35  leeann
 * Release
 * 
 * Revision 10.1  91/03/14  14:25:19  leeann
 * Release
 * 
 * Revision 9.1  91/03/14  10:03:14  leeann
 * Release
 * 
 * Revision 8.1  91/01/30  19:00:00  leeann
 * Release
 * 
 * Revision 7.2  91/01/30  18:51:42  leeann
 * correct size of hint variables
 * 
 * Revision 7.1  91/01/22  14:23:51  leeann
 * Release
 * 
 * Revision 6.1  91/01/16  10:50:30  leeann
 * Release
 * 
 * Revision 5.2  91/01/07  19:51:19  leeann
 * change data definitions to stdef types
 * 
 * Revision 5.1  90/12/12  17:17:17  leeann
 * Release
 * 
 * Revision 4.1  90/12/12  14:42:58  leeann
 * Release
 * 
 * Revision 3.1  90/12/06  10:25:27  leeann
 * Release
 * 
 * Revision 2.1  90/12/03  12:54:06  mark
 * Release
 * 
 * Revision 1.1  90/11/30  11:28:37  joyce
 * Initial revision
 * 
 * Revision 1.1  90/09/26  10:59:49  joyce
 * Initial revision
 * 
 * Revision 1.2  90/09/17  17:06:54  roger
 * changed to comply with RCS
 * 
 * Revision 1.1  90/08/13  15:26:33  arg
 * Initial revision
 * 
 *                                                                           *
 *  1) 30 Apr 90  jsc  Created                                               *
 *                                                                           *
 ****************************************************************************/

#ifndef fnt_a_h
#define fnt_a_h


#define MAXBLUEVALUES      14 /* Max number of entries in BlueValues array */
#define MAXOTHERBLUES      10 /* Max number of entries in OtherBlues array */
#define MAXFAMBLUES        14 /* Max number of entries in FamilyBlues array */
#define MAXFAMOTHERBLUES   10 /* Max number of entries in FamilyOtherBlues array */
#define MAXSTEMSNAPH       12 /* Max number of entries in StemSnapH array */
#define MAXSTEMSNAPV       12 /* Max number of entries in StemSnapV array */

#define MAXSUBRDEPTH       10 /* Max subr call depth */
#define MAXOTHERARGS       20 /* Max number of args for othersubr */
#define MAXSTEMZONES       10 /* Max number of stem hint zones in any dimension */
#define MAXTOPZONES         6 /* Max number of top alignment zones */
#define MAXBOTTOMZONES      6 /* Max number of bottom alignment zones */

typedef
struct
    {
    fix31  unique_id;          /* Unique ID */
    fix31  STACKFAR*pblue_values;       /* Pointer to blue values array */
    fix31  STACKFAR*pother_blues;       /* Pointer to other blues array */
    fix31  STACKFAR*pfam_blues;         /* Pointer to family blues array */
    fix31  STACKFAR*pfam_other_blues;   /* Pointer to family other blues array */
    real   blue_scale;         /* Point size for overshoot suppression */
    fix31  blue_shift;         /* Blue shift value (default 7) */
    fix31  blue_fuzz;          /* Blue fuzz value (default 1) */
    real   stdhw;              /* Standard horiz stroke width */
    real   stdvw;              /* Standard vert stroke width */
    real   STACKFAR*pstem_snap_h;       /* Pointer to horiz stem widths array */
    real   STACKFAR*pstem_snap_v;       /* Pointer to vert stem widths array */
    boolean force_bold;       /* Control to force bold at small sizes */
    fix31   language_group;     /* Language group: 
                                  0: Latin (default)
                                  1: Ideographic                      */
    fix15   no_blue_values;     /* Number of blue values (0 - 14 even) */
    fix15   no_other_blues;     /* Number of other blues (0 - 10 even) */
    fix15   no_fam_blues;       /* Number of family blues (0 - 14 even) */
    fix15   no_fam_other_blues; /* Number of family other blues (0 - 10 even) */
    fix15   no_stem_snap_h;     /* Number of horiz stem widths (0 - 12) */
    fix15   no_stem_snap_v;     /* Number of vert stem widths (0 - 12) */
    } 
font_hints_t;                 /* Font-level hint specifications */

/* prototype dependent on font_hints_t being defined: */
font_hints_t STACKFAR* tr_get_font_hints PROTO((PROTO_DECL1));

#endif /* ifndef fnt_a_h */
