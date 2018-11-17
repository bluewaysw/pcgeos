/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/tr_fdata.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tr_fdata.h,v 1.1 97/04/18 11:45:17 newdeal Exp $
 *
 ***********************************************************************/

#undef INCL_PFB
#define INCL_PFB 1

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

/****************************  tr_fdata.h *********************************
 *                                                                           *
 * This is the header file for the Type 1 font loader and interpreter        *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 * $Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_fdata.h,v 1.1 97/04/18 11:45:17 newdeal Exp $
 *
 * $Log:	tr_fdata.h,v $
 * Revision 1.1  97/04/18  11:45:17  newdeal
 * Initial revision
 * 
 * Revision 1.1.10.1  97/03/29  07:05:47  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:18:25  brianc
 * support Type1
 * 
 * Revision 28.24  93/03/15  13:10:21  roberte
 * Release
 * 
 * Revision 28.9  93/02/01  12:43:08  roberte
 * Added #ifndef tr_fdata_h flags to allow re-inclusion of this file.
 * 
 * Revision 28.8  93/01/21  11:42:46  roberte
 * Added new style prototypes for tr_load_font(), standard_encoding() tr_unload_font() and tr_error().
 * 
 * Revision 28.7  92/11/19  15:35:04  weili
 * Release
 * 
 * Revision 26.3  92/10/16  15:25:25  davidw
 * beautified with indent
 * 
 * Revision 26.2  92/07/22  21:26:10  ruey
 * change FONTNAMESIZE from 32 to 100.
 * 
 * Revision 26.1  92/06/26  10:25:35  leeann
 * Release
 * 
 * Revision 25.1  92/04/06  11:42:02  leeann
 * Release
 * 
 * Revision 24.1  92/03/23  14:10:02  leeann
 * Release
 * 
 * Revision 23.1  92/01/29  17:01:16  leeann
 * Release
 * 
 * Revision 22.1  92/01/20  13:32:38  leeann
 * Release
 * 
 * Revision 21.2  91/12/02  10:22:42  leeann
 * make tag_bytes a fix31 field (rather than fix15) in RESTRICTED_ENVIRON
 * 
 * Revision 21.1  91/10/28  16:45:04  leeann
 * Release
 * 
 * Revision 20.1  91/10/28  15:28:46  leeann
 * Release
 * 
 * Revision 18.1  91/10/17  11:40:21  leeann
 * Release
 * 
 * Revision 17.1  91/06/13  10:44:59  leeann
 * Release
 * 
 * Revision 16.1  91/06/04  15:35:38  leeann
 * Release
 * 
 * Revision 15.1  91/05/08  18:07:47  leeann
 * Release
 * 
 * Revision 14.1  91/05/07  16:29:36  leeann
 * Release
 * 
 * Revision 13.1  91/04/30  17:04:16  leeann
 * Release
 * 
 * Revision 12.1  91/04/29  14:54:39  leeann
 * Release
 * 
 * Revision 11.3  91/04/24  17:46:49  leeann
 * make leniv a fix15
 * 
 * Revision 11.2  91/04/10  13:16:19  leeann
 *  support character names as structures
 * 
 * Revision 11.1  91/04/04  10:58:12  leeann
 * Release
 * 
 * Revision 10.1  91/03/14  14:30:27  leeann
 * Release
 * 
 * Revision 9.1  91/03/14  10:06:05  leeann
 * Release
 * 
 * Revision 8.3  91/03/13  17:30:03  leeann
 * for RESTRICTED_ENVIRON, add offsets from top and bottom
 * 
 * Revision 8.2  91/03/13  16:18:11  leeann
 * Support RESTRICTED_ENVIRON
 * 
 * Revision 8.1  91/01/30  19:03:00  leeann
 * Release
 * 
 * Revision 7.2  91/01/30  18:52:40  leeann
 * fix sizes of variables
 * 
 * Revision 7.1  91/01/22  14:27:09  leeann
 * Release
 * 
 * Revision 6.1  91/01/16  10:53:16  leeann
 * Release
 * 
 * Revision 1.2  91/01/10  11:23:18  leeann
 * add copyright and log messages
 * 
 */
#ifndef tr_fdata_h
#define tr_fdata_h

#define FULLNAMESIZE  100
#define FONTNAMESIZE  100	/* Maximum font name size */
#if RESTRICTED_ENVIRON
typedef struct {
	ufix16          data_offset;	/* set to to zero if subr not in data
					 * block */
	fix15           subr_size;	/* number of bytes in subr */
}
                subrs_t;

typedef struct {
	ufix16          key_offset;	/* offset to character name string */
	ufix16          decryption_key;	/* decryption value to start */
	ufix32          file_position;	/* offset from start of file */
	ufix16          value_offset;	/* set to to zero if charstring not
					 * in data block */
	fix15           charstring_size;	/* number of bytes in
						 * charstring value */
#if INCL_PFB
	fix31           tag_bytes;	/* number of bytes to go in the file
					 * before a tag */
#endif
	fix15           file_bytes;	/* number of bytes in file for
					 * charstring */
	boolean         hex_mode;	/* is the data in hex or binary ? */
}
                charstrings_t;

typedef struct {
	real            font_matrix[6];
	char            full_name[FULLNAMESIZE + 1];
	char            font_name[FONTNAMESIZE + 1];
	fix31           paint_type;
	fbbox_t         font_bbox;

	ufix16          encoding_offset;	/* offset to Encoding vector */
	fix15           no_subrs;	/* Number of subrs */
	ufix16          subrs_offset;	/* offset to array of subrs */
	fix15           no_charstrings;	/* Number of characterstrings read */
	ufix16          charstrings_offset;	/* CharStrings array */
	fix15           leniv;	/* Value of lenIV field (default = 4) */

	/* Font-level hint storage */
	fix31           blue_values[MAXBLUEVALUES];
	fix31           other_blues[MAXOTHERBLUES];
	fix31           fam_blues[MAXFAMBLUES];
	fix31           fam_other_blues[MAXFAMOTHERBLUES];
	real            stem_snap_h[MAXSTEMSNAPH];
	real            stem_snap_v[MAXSTEMSNAPV];
	font_hints_t    font_hints;
#if INCL_PFB
	ufix16          font_file_type;
#endif
	ufix16          offset_from_top;
	ufix16          offset_from_bottom;
}
                font_data;

#else
typedef struct {
	ufix8          *value;	/* Pointer to subr string */
	fix15           size;	/* Number of bytes in subr string */
}
                subrs_t;	/* Element of subrs array */

typedef struct {
	CHARACTERNAME  *key;	/* Pointer to character name */
	ufix8          *value;	/* Pointer to character program string */
	fix15           size;	/* Number of bytes in character program stri
				 * ng */
}
                charstrings_t;	/* Element of charstrings array */

typedef struct {
	real            font_matrix[6];
	char            full_name[FULLNAMESIZE + 1];
	char            font_name[FONTNAMESIZE + 1];
	fix31           paint_type;
	fbbox_t         font_bbox;

	CHARACTERNAME **encoding;	/* Encoding vector */
	fix15           no_subrs;	/* Number of subrs */
	subrs_t        *subrs;	/* ptr to array of subrs */
	fix15           no_charstrings;	/* Number of characterstrings read */
	charstrings_t  *charstrings;	/* CharStrings array */
	fix15           leniv;	/* Value of lenIV field (default = 4) */

	/* Font-level hint storage */
	fix31           blue_values[MAXBLUEVALUES];
	fix31           other_blues[MAXOTHERBLUES];
	fix31           fam_blues[MAXFAMBLUES];
	fix31           fam_other_blues[MAXFAMOTHERBLUES];
	real            stem_snap_h[MAXSTEMSNAPH];
	real            stem_snap_v[MAXSTEMSNAPV];
	font_hints_t    font_hints;
}
                font_data;
#endif

/* prototypes dependent on font_data structure: */
#if RESTRICTED_ENVIRON
boolean WDECL tr_load_font PROTO((PROTO_DECL2 ufix8 STACKFAR*font_ptr,ufix16 buffer_size));
#else
boolean tr_load_font PROTO((PROTO_DECL2 font_data **font_ptr));
#endif
void standard_encoding PROTO((font_data STACKFAR*font_ptr));
void  WDECL tr_unload_font PROTO((font_data STACKFAR*font_ptr));
void tr_error PROTO((PROTO_DECL2 int errcode,font_data STACKFAR*font_ptr));

#endif /* tr_fdata_h */
