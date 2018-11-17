/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	FrontEnd/type1.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: type1.h,v 1.1 97/04/18 11:45:08 newdeal Exp $
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
 
/*************************** P S _ Q E M . H *********************************
 *                                                                           *
 * This is the standard definition file for PS QEM 2.0                       *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 *
 * Revision 28.24  93/03/15  13:12:36  roberte
 * Release
 * 
 * Revision 28.10  93/01/21  11:43:33  roberte
 * Added numerous new style function prototypes for most public functions.
 * 
 * Revision 28.9  93/01/12  11:42:09  roberte
 * Added structure definitions of azone_t, stem_snap_t and i_stem_snap_t
 * originally in tr_trans.c
 * 
 * Revision 28.8  92/12/02  11:52:13  laurar
 * add prototypes for get_byte and dynamic_load.  For DLL,
 * redefine calls to these functions through a function pointer.
 * 
 * Revision 28.7  92/11/19  15:36:33  weili
 * Release
 * 
 * Revision 26.4  92/11/16  18:31:54  laurar
 * Define STACKFAR and WDECL if they aren't already.
 * 
 * Revision 26.3  92/10/19  09:35:40  davidw
 * Removed zero_bbox flag from font_data structure, not needed.
 * 
 * Revision 26.2  92/10/16  15:25:51  davidw
 * Added zero_bbox flag to fontbbox_t struct
 * 
 * Revision 26.1  92/06/26  10:27:01  leeann
 * Release
 * 
 * Revision 25.2  92/06/26  10:13:27  leeann
 * make  BASELINE_IMPROVE as implemented in tr_trans.c the default
 * 
 * Revision 25.1  92/04/06  11:43:24  leeann
 * Release
 * 
 * Revision 24.1  92/03/23  14:11:43  leeann
 * Release
 * 
 * Revision 23.1  92/01/29  17:02:57  leeann
 * Release
 * 
 * Revision 22.1  92/01/20  13:34:22  leeann
 * Release
 * 
 * Revision 21.1  91/10/28  16:46:42  leeann
 * Release
 * 
 * Revision 20.1  91/10/28  15:30:24  leeann
 * Release
 * 
 * Revision 18.1  91/10/17  11:41:56  leeann
 * Release
 * 
 * Revision 17.2  91/09/24  16:47:20  leeann
 * initialize PROTOTYPE to be 0
 * 
 * Revision 17.1  91/06/13  10:46:42  leeann
 * Release
 * 
 * Revision 16.1  91/06/04  15:37:11  leeann
 * Release
 * 
 * Revision 15.1  91/05/08  18:09:19  leeann
 * Release
 * 
 * Revision 14.1  91/05/07  16:31:14  leeann
 * Release
 * 
 * Revision 13.1  91/04/30  17:05:54  leeann
 * Release
 * 
 * Revision 12.1  91/04/29  14:56:14  leeann
 * Release
 * 
 * Revision 11.4  91/04/24  17:48:00  leeann
 * define OSUBR_CALLOUT to be 0 by default
 * 
 * Revision 11.3  91/04/23  10:40:35  leeann
 * put in LOW_RES default
 * 
 * Revision 11.2  91/04/10  13:15:00  leeann
 * support character names as structures
 * 
 * Revision 11.1  91/04/04  11:00:09  leeann
 * Release
 * 
 * Revision 10.1  91/03/14  14:32:52  leeann
 * Release
 * 
 * Revision 9.1  91/03/14  10:07:33  leeann
 * Release
 * 
 * Revision 8.1  91/01/30  19:04:25  leeann
 * Release
 * 
 * Revision 7.1  91/01/22  14:28:58  leeann
 * Release
 * 
 * Revision 6.1  91/01/16  10:54:35  leeann
 * Release
 * 
 * Revision 5.1  90/12/12  17:21:08  leeann
 * Release
 * 
 * Revision 4.1  90/12/12  14:47:01  leeann
 * Release
 * 
 * Revision 3.2  90/12/11  17:20:47  leeann
 * fix syntax error in out_strk_info_t
 * 
 * Revision 3.1  90/12/06  10:29:22  leeann
 * Release
 * 
 * Revision 2.1  90/12/03  12:58:06  mark
 * Release
 * 
 * Revision 1.1  90/11/30  11:28:49  joyce
 * Initial revision
 * 
 * Revision 1.1  90/09/26  11:00:36  joyce
 * Initial revision
 * 
 * Revision 1.3  90/09/17  17:07:57  roger
 * changed to comply with RCS
 * 
 * Revision 1.2  90/09/11  11:07:25  roger
 * put in definition of stack_item for use in mk_chr_a.c
 * 
 * Revision 1.1  90/08/13  15:29:45  arg
 * Initial revision
 * 
 *                                                                           *
 *  1) 15 Mar 90  jsc  Created                                               *
 *                                                                           *
 ****************************************************************************/

#ifndef ps_qem_h
#define ps_qem_h

#ifndef  BASELINE_IMPROVE
#define BASELINE_IMPROVE 1
#endif



#ifndef		STACKFAR
#define		STACKFAR
#endif

#ifndef		WDECL
#define		WDECL
#endif

/***** OUTPUT FLAG CONSTANTS *****/
#define AUTOCLOSEPATH 0X0001  /* Enable automatic closepath                */
#define CLOCKWISE     0X0002  /* Set fill to expect clockwise contours     */
#define ANTICLOCKWISE 0X0004  /* Set fill to expect anticlockwise contours */
#define EOFILL        0X0008  /* Set fill module to eofill mode            */
#define FILLSTROKE    0X0010  /* Route stroke module output to fill module */

#define MAXSECTIONS    10      /* Maximum number of font sections supported */
#define MAXPATHSIZE  1500      /* Max number of elements in current path    */

/* Path element types */
#define MOVETO     0
#define LINETO     1
#define CURVETO    2
#define CLOSEPATH  3

#ifndef NAME_STRUCT         /* characternames can be structures or strings */
#define NAME_STRUCT 0       /* default to strings */
#endif

#ifndef RESTRICTED_ENVIRON  /* Bitsteam use only */
#define RESTRICTED_ENVIRON 0
#endif

#ifndef INCL_PFB
#define INCL_PFB 0          /* don't include type1 PFB file format support */
#endif

#ifndef LOW_RES
#define LOW_RES 1	    /* default to low res for hybrid fonts */
#endif

#ifndef OSUBR_CALLOUT
#define OSUBR_CALLOUT 0     /* default is to use the hardcoded othersubrs */
#endif

#if NAME_STRUCT             /* support character names as structures */
typedef struct { fix15 count;        /* number of chars in name*/
                 unsigned char *char_name;   /* ascii name */
	       } CHARACTERNAME;
#define STRCMP ns_strcmp
#define STRCPY ns_strcpy
#define STRLEN ns_strlen
#define STRcpy ns_string_to_struct
static fix15 ns_strlen();
static void ns_strcpy();
static fix15 ns_strcmp();
static void ns_string_to_struct();
#else
typedef unsigned char CHARACTERNAME; /* support character names as strings */
#define STRCMP strcmp
#define STRCPY strcpy
#define STRLEN strlen
#define STRcpy strcpy
#endif


typedef struct {
    real   xmin;                 
    real   ymin;
    real   xmax;
    real   ymax;
    }
fbbox_t;                       /* Font bounding box data */

typedef struct 		       /* defines member of stack in mk_chr_a.c */
    {
    real r_value;
    fix31 i_value;
    } 
stack_item;

typedef
struct
    {
    int   painttype;
    real  linewidth;
    int   linejoin;
    real  miterlimit;
    int   linecap;
    int   dasharraysize;
    real *dasharray;
    real  dashoffset;
    } 
strokespecs_t;                 /* Stroke specifications */

typedef
struct
    {
    real a;
    real b;
    real c;
    real d;
    }
trans_t;                       /* Transformation coeffs for stroke output module */

typedef
struct
    {
    ufix32 flags;
    strokespecs_t strokespecs;
    trans_t trans;
    }
out_strk_info_t;               /* Stroke output module info structure */

typedef
struct
    {
    fix31 x;
    fix31 y;
    }
path_element_t;               /* Path element structure */

typedef struct {
	fix15           top_orus;
	fix15           bottom_orus;
	fix31           pix;
}               azone_t;	/* Entry in alignment zone table */

typedef struct {
	real            min_orus;
	real            max_orus;
	real            pix;
}               stem_snap_t;	/* Entry in stem snap table */

typedef struct {
	fix15           min_orus;
	fix15           max_orus;
	fix31           pix;
}               i_stem_snap_t;	/* Entry in stem snap table */

/*******-------------- Function Prototypes: ---------------*******/
/* tr_mkchr.c */
void tr_init PROTO((PROTO_DECL1));
boolean tr_set_specs PROTO((PROTO_DECL2 ufix32 specs_flags,real STACKFAR*matrix,ufix8 STACKFAR*font_ptr));
#if RESTRICTED_ENVIRON
boolean tr_make_char PROTO((PROTO_DECL2 ufix8 STACKFAR*font_ptr,CHARACTERNAME STACKFAR*charname));
#else
boolean tr_make_char PROTO((PROTO_DECL2 CHARACTERNAME *charname));
#endif
void curve_fill PROTO((PROTO_DECL2 point_t P1,point_t P2,point_t P3,fix15 depth));
void scan_curve_fill PROTO((PROTO_DECL2 fix31 X0,fix31 Y0,fix31 X1,fix31 Y1,fix31 X2,fix31 Y2,fix31 X3,fix31 Y3));
#if RESTRICTED_ENVIRON
real tr_get_char_width PROTO((PROTO_DECL2 ufix8 STACKFAR*font_ptr,CHARACTERNAME STACKFAR*charname));
#else
real tr_get_char_width PROTO((PROTO_DECL2 CHARACTERNAME *charname));
#endif

/* tr_trans.c */
void init_trans_a PROTO((PROTO_DECL2 real STACKFAR*matrix, fbbox_t STACKFAR*font_bbox));
void clear_constraints PROTO((PROTO_DECL1));
void do_hstem PROTO((PROTO_DECL2 fix31 sby,fix31 y,fix31 dy));
void do_hstem3 PROTO((PROTO_DECL2 fix31 sby,fix31 y0,fix31 dy0,fix31 y1,fix31 dy1,fix31 y2,fix31 dy2));
void do_vstem PROTO((PROTO_DECL2 fix31 sbx,fix31 x,fix31 dx));
void do_vstem3 PROTO((PROTO_DECL2 fix31 sbx,fix31 x0,fix31 dx0,fix31 x1,fix31 dx1,fix31 x2,fix31 dx2));
void hint_sort3 PROTO((fix31 STACKFAR*px0,fix31 STACKFAR*pdx0,fix31 STACKFAR*px1,
		fix31 STACKFAR*pdx1,fix31 STACKFAR*px2,fix31 STACKFAR*pdx2));
void hint_sort2 PROTO((fix31 STACKFAR*px0,fix31 STACKFAR*pdx0,
		fix31 STACKFAR*px1,fix31 STACKFAR*pdx1));
void do_trans_a PROTO((PROTO_DECL2 fix31 STACKFAR*pX,fix31 STACKFAR*pY));
fix15 set_shift_const PROTO((PROTO_DECL1));
void set_mode_flags PROTO((PROTO_DECL2 fbbox_t STACKFAR *font_bbox));

/* tr_ldfnt.c */
char  STACKFAR* tr_get_font_name PROTO((PROTO_DECL1));
void tr_get_font_matrix PROTO((PROTO_DECL2 real STACKFAR*matrix));
fbbox_t STACKFAR* tr_get_font_bbox PROTO((PROTO_DECL1));
fix15 tr_get_paint_type PROTO((PROTO_DECL1));
CHARACTERNAME STACKFAR* tr_encode PROTO((PROTO_DECL2 int i));
unsigned char STACKFAR* tr_get_subr PROTO((PROTO_DECL2 int i));
unsigned char STACKFAR* tr_get_chardef PROTO((PROTO_DECL2 CHARACTERNAME  STACKFAR*charname));
#if RESTRICTED_ENVIRON
boolean tr_set_encode PROTO((PROTO_DECL2 ufix8 STACKFAR*font_ptr,char STACKFAR*set_array[256]));
char STACKFAR*STACKFAR* WDECL tr_get_encode PROTO((PROTO_DECL2 ufix8 STACKFAR*font_ptr));
#else
int tr_set_encode PROTO((PROTO_DECL2 CHARACTERNAME STACKFAR*set_array[256]));
CHARACTERNAME **tr_get_encode PROTO((PROTO_DECL1));
#endif
boolean get_tag_string PROTO((ufix8 STACKFAR*tag_string));
fix15 tr_get_leniv PROTO((PROTO_DECL1));
short compstr PROTO((ufix8 STACKFAR*buff, ufix8 STACKFAR*string));

#if   WINDOWS_4IN1
/* prototypes */
extern boolean WDECL get_byte(char STACKFAR *next_char);
extern unsigned char  STACKFAR* WDECL dynamic_load(unsigned long file_position, short num_bytes, unsigned char success);

#ifndef     DEFINE_TYPE1_CALLS  /* in module in which these functions are */
                           /* declared, must define this constant so that the */
                        /* macros that follow will not be executed. */
/* reference function through a pointer */
#define     get_byte(next_char)  (*callback_ptrs.get_byte)(next_char)
#define     dynamic_load(file_position, num_bytes, success)    (*callback_ptrs.dynamic_load)(file_position, num_bytes, success)
#endif
#endif

#ifndef PROTOTYPE
#define PROTOTYPE 0
#endif
#endif /* ps_qem_h */
