/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	gstring.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines graphics string structures and routines.
 *
 *	$Id: gstring.h,v 1.1 97/04/04 15:57:20 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__GSTRING_H
#define __GSTRING_H

#include <graphics.h>

typedef void GString;

/***/

typedef WordFlags GSControl;
#define GSC_PARTIAL		0x0200
#define GSC_ONE			0x0100
#define GSC_MISC		0x0080
#define GSC_LABEL		0x0040
#define GSC_ESCAPE		0x0020
#define GSC_NEW_PAGE		0x0010
#define GSC_XFORM		0x0008
#define GSC_OUTPUT		0x0004
#define GSC_ATTR		0x0002
#define GSC_PATH		0x0001

typedef enum /* word */  {
GSRT_COMPLETE 	=0,
GSRT_ONE    	=1,
GSRT_MISC   	=2,
GSRT_LABEL   	=3,
GSRT_ESCAPE 	=4,
GSRT_NEW_PAGE 	=5,
GSRT_XFORM  	=6,
GSRT_OUTPUT 	=7,
GSRT_ATTR 	=8,
GSRT_PATH 	=9,
GSRT_FAULT 	=0xffff
} GSRetType;

/***/

extern GSRetType	/*XXX*/
    _pascal GrDrawGString(GStateHandle gstate, GStateHandle gstringToDraw, sword x,
		 sword y, GSControl flags, word *lastElement);

/***/

extern GSRetType	/*XXX*/
    _pascal GrDrawGStringAtCP(GStateHandle gstate, GStateHandle gstringToDraw,
		     GSControl flags, word *lastElement);

/***/

extern void	/*XXX*/
    _pascal GrParseGString(GStateHandle gstate, GStateHandle gstringToDraw,
		     GSControl flags, Boolean (*callback) /* TRUE to stop */
		    	    	      (void *element));

/***/

typedef ByteEnum GStringSetPosType;
#define GSSPT_SKIP_1 0
#define GSSPT_RELATIVE 1
#define GSSPT_BEGINNING 2
#define GSSPT_END 3

extern void	/*XXX*/
    _pascal GrSetGStringPos(GStateHandle gstate, GStringSetPosType type, word skip);

/***/

extern GSRetType	/*XXX*/
    _pascal GrCopyGString(GStateHandle source, GStateHandle dest, GSControl flags);

/***/

extern Boolean	/*XXX*/
    _pascal GrGetGStringBounds(Handle gstring, GStateHandle gstate, 
		       GSControl flags, Rectangle _far *bounds);

/***/

extern void 	/*XXX*/
    _pascal GrGetGStringBoundsDWord(Handle gstring, GStateHandle gstate, 
		       GSControl flags, RectDWord _far *bounds);

/***/

typedef ByteEnum GStringKillType;
#define GSKT_KILL_DATA 0
#define GSKT_LEAVE_DATA 1

extern void
    _pascal GrDestroyGString(GStateHandle gstring, GStateHandle gstate,
		     GStringKillType type);

/***/

typedef ByteEnum GStringType;
#define GST_CHUNK 0
#define GST_STREAM 1
#define GST_VMEM 2
#define GST_PTR 3
#define GST_PATH 4

extern GStateHandle	/*XXX*/
    _pascal GrLoadGString(Handle han, GStringType hanType, word vmBlock);

/***/

extern GStateHandle	/*XXX*/
    _pascal GrEditGString(Handle vmFile, word vmBlock);

/***/

extern GStateHandle	/*XXX*/
    _pascal GrCreateGString(Handle han, GStringType hanType, word _far *vmBlock);

/***/

extern GStringElement	/*XXX*/
    _pascal GrGetGStringElement(GStateHandle gstate, GStateHandle gstring, word bufSize, void *buffer, word *elSize);

/***/

extern void	/*XXX*/
    _pascal GrDeleteGStringElement(GStateHandle gstate, word count);

/***/

extern void	/*XXX*/
    _pascal GrLabel(GStateHandle gstate, word label);

/*
 *	Graphic String Constants
 */

#define GR_FIRST_SYSTEM_ESCAPE		0x0000
#define GR_LAST_SYSTEM_ESCAPE		0x3fff
#define GR_FIRST_GEOWORKS_ESCAPE		0x4000
#define GR_LAST_GEOWORKS_ESCAPE		0x7fff
#define GR_FIRST_APPLICATION_ESCAPE	0x8000
#define GR_LAST_APPLICATION_ESCAPE	0xffff

#ifdef __HIGHC__
pragma Alias(GrDrawGString, "GRDRAWGSTRING");
pragma Alias(GrDrawGStringAtCP, "GRDRAWGSTRINGATCP");
pragma Alias(GrSetGStringPos, "GRSETGSTRINGPOS");
pragma Alias(GrCopyGString, "GRCOPYGSTRING");
pragma Alias(GrDestroyGString, "GRDESTROYGSTRING");
pragma Alias(GrLoadGString, "GRLOADGSTRING");
pragma Alias(GrCreateGString, "GRCREATEGSTRING");
pragma Alias(GrEditGString, "GREDITGSTRING");
pragma Alias(GrGetGStringElement, "GRGETGSTRINGELEMENT");
pragma Alias(GrGetGStringBounds, "GRGETGSTRINGBOUNDS");
pragma Alias(GrGetGStringBoundsDWord, "GRGETGSTRINGBOUNDSDWORD");
pragma Alias(GrLabel, "GRLABEL");
pragma Alias(GrDeleteGStringElement, "GRDELETEGSTRINGELEMENT");
pragma Alias(GrParseGString, "GRPARSEGSTRING");
#endif


/* This is the first cut at the gstring macros.                        */
/* There are currently spurious warnings because several constants are */
/* redefined in decimal. This must be done because goc can't parse hex */

/* 
 * 	NOTE TO FOLKS MAKING CHANGES/FIXES  
 *
 * in general, if the macros generate too many or too few chars, the 
 * graphics system will crash. This will happen if the macros do not
 * format their args as they should (e.g. formatting a word as a char).
 * If the thing comes up, but is strange looking,
 * it is probably due to the data being formatted incorectly -- e.g.
 * two fields being reversed.
 */


#define GOC_OR(a,b) 	((a)|(b))
#define GOC_WORD(a)   	((a)&0xff),(((a)&0xff00)>>8)
#define GOC_SW(a)   	GOC_WORD(a)

/* to truncate the fractional part, cast the float to an int.             */
/* to get the fractional part's representation, multiply the float by 256 */

/* only used for track kerning.        			    *NOT_TESTED* */
#define GOC_BBF(a)  (((int)(((a)-(int)(a))*256))&0xff),(((int)(a))&0xff)

/* 8 bits fraction, 16 bits integer 		TESTED in GSSetFont*/

#define GOC_WBF(a) (((int)(((a)-(int)(a))*256))&0xff),GOC_WORD(((int)(a))&0xffff)

/* 16 bits fraction, 16 bits integer.    	TESTED in GSApplyRotation  */

#define GOC_WWF(a) GOC_WORD(((int)(((a)-(int)(a))*65536))&0xffff),GOC_WORD(((int)(a))&0xffff)

/* 32 bits fraction, 16 bits integer.	    	    	    	    */
#define GOC_DWF(a) GOC_WORD(((int)(((a)-(int)(a))*65536))&0xffff),GOC_WORD(((int)(a))&0xffff), GOC_WORD(((long)(a))>>16)

/* Two word quantity. 			TESTED for GSApplyTranslationDWord */
#define GOC_SDW(a) GOC_WORD((a)&0xffff),GOC_WORD(((long)(a)>>16)&0xffff) 

/* optr */        			               /*NOT_TESTED*/
#define GOC_OPTR(a) GOC_SDW(a)

#define GOC_PATTERN(a) GOC_WORD(a)

#define GOC_POINT(x,y) GOC_SW(x), GOC_SW(y)

/*  NOTE:  the gstring opcode structures defined below have 
           *NOT* been tested yet */

/* this opcode is null */

typedef struct {
	GStringElement	OEGS_opcode;	/* GR_END_GSTRING */
} OpEndGString;

#define GSEndString() 					/*TESTED*/ 	\
	GR_END_GSTRING

typedef struct {
	GStringElement	OP_opcode;	/* GR_LABEL */
} OpLabel;

#define GSLabel(w) 							\
  GR_LABEL,GOC_WORD(w)


typedef struct {
	GStringElement	OSS_opcode;	/* GR_SAVE_STATE */
} OpSaveState;

#define GSSaveState()  					/*TESTED*/	\
	GR_SAVE_STATE  

typedef struct {
	GStringElement	ORS_opcode;
} OpRestoreState;			/* GR_RESTORE_STATE */

#define GSRestoreState()				/*TESTED*/\
	GR_RESTORE_STATE

typedef struct {
	GStringElement	OST_opcode;	/* GR_SAVE_TRANSFORM */
} OpSaveTransform;

#define GSSaveTransform()						\
	GR_SAVE_TRANSFORM

typedef struct {
	GStringElement	ORT_opcode;	/* GR_RESTORE_TRANSFORM */
} OpRestoreTransform;

#define GSRestoreTransform() 						\
	GR_RESTORE_TRANSFORM

typedef struct {
	GStringElement	ONP_opcode;	/* GR_NEW_PAGE */
	PageEndCommand  ONP_pageEnd;
} OpNewPage;

#define GSNewPage(pageEndCommand)					\
	GR_NEW_PAGE,(pageEndCommand)

typedef struct {
	GStringElement	OE_opcode;	/* GR_ESCAPE */
	word            OE_escCode;
	word            OE_escSize;
} OpEscape;

#define GSEscape(esc_w,size_w)						\
	GR_ESCAPE,GOC_WORD(esc_w),GOC_WORD(size_w)

typedef struct {
	GStringElement	OC_opcode;	/* GR_COMMENT */
	word            OC_size;
} OpComment;

#define GSComment(size_b)						\
 	GR_COMMENT, GOC_WORD(size_b)

typedef struct {
	GStringElement	OSGSB_opcode;	/* GR_SET_GSTRING_BOUNDS */
	word            OSGSB_x1;
	word            OSGSB_y1;
	word            OSGSB_x2;
	word            OSGSB_y2;
} OpSetGStringBounds;

#define GSSetGStringBounds(x1_w,y1_w,x2_w,y2_w)				\
	GR_SET_GSTRING_BOUNDS,GOC_SW(x1_w),GOC_SW(y1_w),		\
	GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ONO_opcode;	/* GR_NULL_OP */
} OpNullOp;

#define GSNullOp() 					/*TESTED*/  	\
	 GR_NULL_OP   

typedef struct {
	GStringElement	OAR_opcode;	/* GR_APPLY_ROTATION */
	WWFixed         OAR_angle;
} OpApplyRotation;

#define GSApplyRotation(angle_f)			/*TESTED*/  	\
	GR_APPLY_ROTATION,GOC_WWF(angle_f)

typedef struct {
	GStringElement	OAS_opcode;	/* GR_APPLY_SCALE */
	WWFixed         OAS_xScale;
	WWFixed         OAS_yScale;
} OpApplyScale;

#define GSApplyScale(x_f,y_f)				/*TESTED*/  	\
            GR_APPLY_SCALE,GOC_WWF(x_f),GOC_WWF(y_f)

typedef struct {
	GStringElement	OAT_opcode;	/* GR_APPLY_TRANSLATION */
	WWFixed         OAT_x;
	WWFixed         OAT_y;
} OpApplyTranslation;

#define GSApplyTranslation(x_f,y_f)			/*TESTED*/  	\
	GR_APPLY_TRANSLATION,GOC_WWF(x_f),GOC_WWF(y_f)

typedef struct {
	GStringElement	OADT_opcode;	/* GR_APPLY_TRANSLATION_DWORD */
	sdword          OADT_x;
	sdword          OADT_y;
} OpApplyTranslationDWord;

#define GSApplyTranslationDWord(x_sdw,y_sdw)				\
	GR_APPLY_TRANSLATION_DWORD,GOC_SDW(x_sdw),			\
	GOC_SDW(y_sdw)

typedef struct {
	GStringElement	OST_opcode;	/* GR_SET_TRANSFORM */
	WWFixed         OST_elem11;
	WWFixed         OST_elem12;
	WWFixed         OST_elem21;
	WWFixed         OST_elem22;
	WWFixed         OST_elem31;
	WWFixed         OST_elem32;
} OpSetTransform;

#define GSSetTransform(e11_f,e12_f,e21_f,e22_f,e31_df,e32_df) 		\
	GR_SET_TRANSFORM,GOC_WWF(e11_f),				\
	GOC_WWF(e12_f),GOC_WWF(e21_f),					\
	GOC_WWF(e22_f),GOC_DWF(e31_df),GOC_DWF(e32_df)

typedef struct {
	GStringElement	OATr_opcode;	/* GR_APPLY_TRANSFORM */
	WWFixed         OATr_elem11;
	WWFixed         OATr_elem12;
	WWFixed         OATr_elem21;
	WWFixed         OATr_elem22;
	WWFixed         OATr_elem31;
	WWFixed         OATr_elem32;
} OpApplyTransform;

#define GSApplyTransform(e11_f,e12_f,e21_f,e22_f,e31_df,e32_df) 	\
	GR_APPLY_TRANSFORM,GOC_WWF(e11_f),GOC_WWF(e12_f),		\
	GOC_WWF(e21_f),GOC_WWF(e22_f), 					\
	GOC_DWF(e31_df), GOC_DWF(e32_df)
	
typedef struct {
	GStringElement	OSNT_opcode;	/* GR_SET_NULL_TRANSFORM */
} OpSetNullTransform;

#define GSSetNullTransform() 						\
	GR_SET_NULL_TRANSFORM

typedef struct {
	GStringElement	OSDT_opcode;	/* GR_SET_DEFAULT_TRANSFORM */
} OpSetDefaultTransform;

#define GSSetDefaultTransform()						\
	GR_SET_DEFAULT_TRANSFORM

typedef struct {
	GStringElement	OIDT_opcode;	/* GR_INIT_DEFAULT_TRANSFORM */
} OpInitDefaultTransform;

#define GSInitDefaultTransform()					\
	GR_INIT_DEFAULT_TRANSFORM

typedef struct {
	GStringElement	ODL_opcode;	/* GR_DRAW_LINE */
	word            ODL_x1;
	word            ODL_x2;
	word            ODL_y1;
	word            ODL_y2;
} OpDrawLine;

#define GSDrawLine(x1_w,y1_w,x2_w,y2_w)  				\
	GR_DRAW_LINE,GOC_SW(x1_w),GOC_SW(y1_w),			\
	GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODLT_opcode;	/* GR_DRAW_LINE_TO */
	word            ODLT_x2;
	word            ODLT_y2;
} OpDrawLineTo;

#define GSDrawLineTo(x2_w,y2_w) 					\
	GR_DRAW_LINE_TO,GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODR_opcode;	/* GR_DRAW_RECT */
	word            ODR_x1;
	word            ODR_y1;
	word            ODR_x2;
	word            ODR_y2;
} OpDrawRect;

#define GSDrawRect(x1_w,y1_w,x2_w,y2_w)  		/*TESTED*/ 	\
	GR_DRAW_RECT,GOC_SW(x1_w),GOC_SW(y1_w),			\
	GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODRT_opcode;	/* GR_DRAW_RECT_TO */
	word            ODRT_x2;
	word            ODRT_y2;
} OpDrawRectTo;

#define GSDrawRectTo(x2_w,y2_w)  			/*TESTED*/ 	\
	GR_DRAW_RECT_TO,GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODHL_opcode;	/* GR_DRAW_HLINE */
	word            ODHL_x1;
	word            ODHL_y1;
	word            ODHL_x2;
} OpDrawHLine;

#define GSDrawHLine(x1_w,y1_w,x2_w) 					\
	GR_DRAW_HLINE,GOC_SW(x1_w),					\
	GOC_SW(y1_w),GOC_SW(x2_w)

typedef struct {
	GStringElement	ODHLT_opcode;	/* GR_DRAW_HLINE_TO */
	word            ODHLT_x2;
} OpDrawHLineTo;

#define GSDrawHLineTo(x2_w) 						\
	GR_DRAW_HLINE_TO,GOC_SW(x2_w)

typedef struct {
	GStringElement	ODVL_opcode;	/* GR_DRAW_VLINE */
	word            ODVL_x1;
	word            ODVL_y1;
	word            ODVL_y2;
} OpDrawVLine;

#define GSDrawVLine(x1_w,y1_w,y2_w)					\
	GR_DRAW_VLINE,GOC_SW(x1_w),					\
	GOC_SW(y1_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODVLT_opcode;	/* GR_DRAW_VLINE_TO */
	word            ODVLT_y2;
} OpDrawVLineTo;

#define GSDrawVLineTo(y2_w) 						\
	GR_DRAW_VLINE_TO,GOC_SW(y2_w)

typedef struct {
	GStringElement	ODRR_opcode;	/* GR_DRAW_ROUND_RECT */
	word            ODRR_radius;
	word            ODRR_x1;
	word            ODRR_y1;
	word            ODRR_x2;
	word            ODRR_y2;
} OpDrawRoundRect;

#define GSDrawRoundRect(x1_w,y1_w,x2_w,y2_w,r_w) 			\
	GR_DRAW_ROUND_RECT,GOC_WORD(r_w),				\
	GOC_SW(x1_w),GOC_SW(y1_w),					\
	GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODRRT_opcode;	/* GR_DRAW_ROUND_RECT_TO */
	word            ODRRT_radius;
	word            ODRRT_x2;
	word            ODRRT_y2;
} OpDrawRoundRectTo;

#define GSDrawRoundRectTo(x2_w,y2_w,r_w) 				\
	GR_DRAW_ROUND_RECT_TO,GOC_WORD(r_w),				\
	GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODP_opcode;	/* GR_DRAW_POINT */
	word            ODP_x1;
	word            ODP_y1;
} OpDrawPoint;

#define GSDrawPoint(x1_w,y1_w) 						\
	GR_DRAW_POINT,GOC_SW(x1_w),GOC_SW(y1_w)

typedef struct {
	GStringElement	ODPCP_opcode;	/* GR_DRAW_POINT_CP */
} OpDrawPointAtCP;

#define GSDrawPointAtCP() 						\
	GR_DRAW_POINT_CP

typedef struct {
	GStringElement	ODB_opcode;	/* GR_DRAW_BITMAP */
	word            ODB_x;
	word            ODB_y;
	word            ODB_size;
} OpDrawBitmap;

typedef struct {
	GStringElement	OBS_opcode;	/* GSE_BITMAP_SLICE */
	word            OBS_size;
} OpBitmapSlice;

#define GSDrawBitmap(x_w,y_w,w_w) \
	GR_DRAW_BITMAP, GOC_SW(x_w), 					\
	GOC_SW(y_w), GOC_WORD(w_w)

#define GSDrawCBitmap(x_w,y_w,slice1size_w,totalSize) 			\
	GR_DRAW_BITMAP,GOC_SW(x_w), GOC_SW(y_w), 			\
	GOC_WORD(slice1size_w)

typedef struct {
	GStringElement	ODBCP_opcode;	/* GR_DRAW_BITMAP_CP */
	word            ODBCP_size;
} OpDrawBitmapAtCP;

#define GSDrawBitmapAtCP(bsize_w) 					\
	GR_DRAW_BITMAP_CP, GOC_WORD(bsize_w)

typedef struct {
	GStringElement	ODBP_opcode;	/* GR_DRAW_BITMAP_PTR */
	word            ODBP_x;
	word            ODBP_y;
	word            ODBP_ptr;
} OpDrawBitmapPtr;

/*NOT DONE-- PTR*/
#define GSDrawBitmapPtr(x_w,y_w,offptr) 				\
	GR_DRAW_BITMAP_PTR,GOC_SW(x_w),				\
	GOC_SW(y_w),GOC_PTR(offptr)

typedef struct {
	GStringElement	ODBOP_opcode;	/* GR_DRAW_BITMAP_OPTR */
	word		ODBOP_x;
	word		ODBOP_y;
	optr		ODBOP_bitmap;
} OpDrawBitmapOptr;

/* The GSDrawBitmapOptr macro will NOT work, since GOC cannot
   generate the high & low bytes of a segment */

#if 0
#define GSDrawBitmapOptr(x_w,y_w,o_ptr)  				\
	GR_DRAW_BITMAP_OPTR,GOC_SW(x_w),				\
	GOC_SW(y_w),GOC_OPTR(o_ptr)
#endif

typedef struct {
	GStringElement	OFB_opcode;	/* GR_FILL_BITMAP */
	word		OFB_x;
	word		OFB_y;
	word		OFB_size;
} OpFillBitmap;

#define GSFillBitmap(x_w,y_w,bsize_w) 					\
	GR_FILL_BITMAP,GOC_SW(x_w),					\
	GOC_SW(y_w),GOC_WORD(bsize_w)

typedef struct {
	GStringElement	OFBCP_opcode;	/* GR_FILL_BITMAP_CP */
	word		OFBCP_size;
} OpFillBitmapAtCP;

#define GSFillBitmapAtCP(bsize_w) 					\
	GR_FILL_BITMAP_CP, GOC_WORD(bsize_w)

typedef struct {
	GStringElement	OFBP_opcode;	/* GR_FILL_BITMAP_PTR */
	word		OFBP_x;
	word		OFBP_y;
	word		OFBP_ptr;
} OpFillBitmapPtr;

/*NOT DONE-- PTR*/
#define GSFillBitmapPtr(x_w,y_w,offptr) 					\
	GR_DRAW_BITMAP_PTR,GOC_SW(x_w),GOC_SW(y_w),GOC_PTR(offptr)

typedef struct {
	GStringElement	OFBOP_opcode;	/* GR_FILL_BITMAP_OPTR */
	word		OFBOP_x;
	word		OFBOP_y;
	optr		OFBOP_bitmap;
} OpFillBitmapOptr;

/* The GSFillBitmapOptr macro will NOT work, since GOC cannot
   generate the high & low bytes of a segment */

#if 0
#define GSFillBitmapOptr(x_w,y_w,o_ptr) 				\
	GR_FILL_BITMAP_OPTR,GOC_SW(x_w),GOC_SW(y_w),GOC_OPTR(o_ptr)

#endif

/*
 * XXX
 * 	
 * WARNING: all of the points must be converted to words with the 
 * GOC_POINT macro -- if not, the program will compile, but crash geos
 * at runtime.
 */
typedef struct {
	GStringElement	ODPL_opcode;	/* GR_DRAW_POLYLINE */
	word		ODPL_count;
} OpDrawPolyline;

#define GSDrawPolyline(count_w)				/*TESTED*/	\
	GR_DRAW_POLYLINE,GOC_WORD(count_w)

typedef struct {
	GStringElement	OBPL_opcode;	/* GR_BRUSH_POLYLINE */
	word		OBPL_count;
	byte		OBPL_width;
	byte		OBPL_height;
} OpBrushPolyLine;

#define GSBrushPolyline(width_b,height_b,pts_b) \
	GR_BRUSH_POLYLINE, GOC_WORD(pts_b), (width_b), (height_b)

typedef struct {
	GStringElement	ODE_opcode;	/* GR_DRAW_ELLIPSE */
	word		ODE_x1;
	word		ODE_y1;
	word		ODE_x2;
	word		ODE_y2;
} OpDrawEllipse;

#define GSDrawEllipse(x1_w,y1_w,x2_w,y2_w) 		/*TESTED*/	\
	GR_DRAW_ELLIPSE,GOC_SW(x1_w),GOC_SW(y1_w),			\
			GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODA_opcode;	/* GR_DRAW_ARC */
	ArcCloseType	ODA_close;
	word		ODA_x1;
	word		ODA_y1;
	word		ODA_x2;
	word		ODA_y2;
	word		ODA_ang1;
	word		ODA_ang2;
} OpDrawArc;

#define GSDrawArc(close_enum,x1_w,y1_w,x2_w,y2_w,ang1_w,ang2_w) /*TESTED*/\
	GR_DRAW_ARC,GOC_WORD(close_enum),				\
	GOC_SW(x1_w), GOC_SW(y1_w),					\
	GOC_SW(x2_w), GOC_SW(y2_w),					\
	GOC_SW(ang1_w),GOC_SW(ang2_w)

typedef struct {
	GStringElement	ODCV_opcode;	/* GR_DRAW_CURVE */
	sword		ODCV_x1;
	sword		ODCV_y1;
	sword		ODCV_x2;
	sword		ODCV_y2;
	sword		ODCV_x3;
	sword		ODCV_y3;
	sword		ODCV_x4;
	sword		ODCV_y4;
} OpDrawCurve;

#define GSDrawCurve(x1_sw,y1_sw,x2_sw,y2_sw,x3_sw,y3_sw,x4_sw,y4_sw) 	\
	GR_DRAW_CURVE,GOC_SW(x1_sw),GOC_SW(y1_sw),			\
	GOC_SW(x2_sw),GOC_SW(y2_sw), 					\
	GOC_SW(x3_sw),GOC_SW(y3_sw),GOC_SW(x4_sw),GOC_SW(y4_sw)
			
typedef struct {
	GStringElement	ODCVT_opcode;	/* GR_DRAW_CURVE_TO */
	sword		ODCVT_x2;
	sword		ODCVT_y2;
	sword		ODCVT_x3;
	sword		ODCVT_y3;
	sword		ODCVT_x4;
	sword		ODCVT_y4;
} OpDrawCurveTo;

#define GSDrawCurveTo(x2_sw,y2_sw,x3_sw,y3_sw,x4_sw,y4_sw)   		\
	GR_DRAW_CURVE_TO,GOC_SW(x2_sw),GOC_SW(y2_sw),			\
	GOC_SW(x3_sw),GOC_SW(y3_sw), 					\
	GOC_SW(x4_sw),GOC_SW(y4_sw)

typedef struct {
	GStringElement	ODRCVT_opcode;	/* GR_DRAW_REL_CURVE_TO */
	sword		ODRCVT_x2;
	sword		ODRCVT_y2;
	sword		ODRCVT_x3;
	sword		ODRCVT_y3;
	sword		ODRCVT_x4;
	sword		ODRCVT_y4;
} OpDrawRelCurveTo;

#define GSDrawRelCurveTo(x2_sw,y2_sw,x3_sw,y3_sw,x4_sw,y4_sw)   	\
	GR_DRAW_REL_CURVE_TO,GOC_SW(x2_sw),GOC_SW(y2_sw),		\
	GOC_SW(x3_sw),GOC_SW(y3_sw), 					\
	GOC_SW(x4_sw),GOC_SW(y4_sw)

typedef struct {
	GStringElement	ODS_opcode;	/* GR_DRAW_SPLINE */
	word		ODS_count;
} OpDrawSpline;

#define GSDrawSpline(count_w)  						\
	GR_DRAW_SPLINE,GOC_WORD(count_w)

typedef struct {
	GStringElement	ODST_opcode;	/* GR_DRAW_SPLINE_TO */
	word		ODST_count;
} OpDrawSplineTo;

#define GSDrawSplineTo(count_w) 					\
	GR_DRAW_SPLINE_TO,GOC_WORD(count_w)

typedef struct {
	GStringElement	OFFR_opcode;	/* GR_FILL_RECT */
	word		OFFR_x1;
	word		OFFR_y1;
	word		OFFR_x2;
	word		OFFR_y2;
} OpFillRect;

#define GSFillRect(x1_w,y1_w,x2_w,y2_w) 		/*TESTED*/  	\
	GR_FILL_RECT,GOC_SW(x1_w),GOC_SW(y1_w),			\
	GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	OFFRT_opcode;	/* GR_FILL_RECT_TO */
	word		OFFRT_x2;
	word		OFFRT_y2;
} OpFillRectTo;

#define GSFillRectTo(x2_w,y2_w)  			/*TESTED*/  	\
	GR_FILL_RECT_TO ,GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	OFRR_opcode;	/* GR_FILL_ROUND_RECT */
	word		OFRR_x1;
	word		OFRR_y1;
	word		OFRR_x2;
	word		OFRR_y2;
} OpFillRoundRect;

#define GSFillRoundRect(x1_w,y1_w,x2_w,y2_w,r_w) 			\
	GR_FILL_ROUND_RECT,GOC_WORD(r_w),GOC_SW(x1_w),			\
	GOC_SW(y1_w),GOC_SW(x2_w),					\
	GOC_SW(y2_w)

typedef struct {
	GStringElement	OFRRT_opcode;	/* GR_FILL_ROUND_RECT_TO */
	word		OFRRT_radius;
	word		OFRRT_x2;
	word		OFRRT_y2;
} OpFillRoundRectTo;

#define GSFillRoundRectTo(x2_w,y2_w,r_w) 				\
	GR_FILL_ROUND_RECT_TO,GOC_WORD(r_w),GOC_SW(x2_w),		\
	GOC_SW(y2_w)

typedef struct {
	GStringElement	OFA_opcode;	/* GR_FILL_ARC */
	word		OFA_close;
	word		OFA_x1;
	word		OFA_y1;
	word		OFA_x2;
	word		OFA_y2;
	word		OFA_ang1;
	word		OFA_ang2;
} OpFillArc;

/*TESTED*/
#define GSFillArc(close_enum,x1_w,y1_w,x2_w,y2_w,ang1_w,ang2_w)    	\
	GR_FILL_ARC,GOC_WORD(close_enum),				\
	GOC_SW(x1_w),GOC_SW(y1_w), 					\
	GOC_SW(x2_w),GOC_SW(y2_w),GOC_SW(ang1_w),			\
	GOC_SW(ang2_w)

typedef struct {
	GStringElement	OFP_opcode;	/* GR_FILL_POLYGON */
	word		OFP_count;
	RegionFillRule	OFP_rule;
} OpFillPolygon;

#define GSFillPolygon(count_w,fillrule_enum)  		/*TESTED*/	\
	GR_FILL_POLYGON,GOC_WORD(count_w),(fillrule_enum)

typedef struct {
	GStringElement	ODPG_opcode;	/* GR_DRAW_POLYGON */
	word		ODPG_count;
} OpDrawPolygon;

#define GSDrawPolygon(count_w) 						\
	GR_DRAW_POLYGON,GOC_WORD(count_w)

typedef struct {
	GStringElement	OFE_opcode;	/* GR_FILL_ELLIPSE */
	word		OFE_x1;
	word		OFE_y1;
	word		OFE_x2;
	word		OFE_y2;
} OpFillEllipse;

#define GSFillEllipse(x1_w,y1_w,x2_w,y2_w)  		/*TESTED*/ 	\
	GR_FILL_ELLIPSE,GOC_SW(x1_w),GOC_SW(y1_w), 			\
		GOC_SW(x2_w),GOC_SW(y2_w)

typedef struct {
	GStringElement	ODC_opcode;	/* GR_DRAW_CHAR */
	char		ODC_char;
	word		ODC_x1;
	word		ODC_y1;
} OpDrawChar;

#define GSDrawChar(c,x1_w,y1_w) 			/*TESTED*/	\
	GR_DRAW_CHAR,(c),GOC_SW(x1_w),GOC_SW(y1_w)

typedef struct {
	GStringElement	ODCCP_opcode;	/* GR_DRAW_CHAR_CP */
	char		ODCCP_char;
} OpDrawCharAtCP;

#define GSDrawCharAtCP(c) 				/*TESTED*/	\
	GR_DRAW_CHAR_CP,(c)

/*
 * Follow this macro immediately with a string -- goc will format the
 * the string as a two size bytes and a bunch of text bytes.
 */

typedef struct {
	GStringElement	ODT_opcode;	/* GR_DRAW_TEXT */
	word		ODT_x1;
	word		ODT_y1;
	word		ODT_len;
} OpDrawText;

#define GSDrawText(x1_w,y1_w)  		                                \
	GR_DRAW_TEXT,GOC_SW(x1_w),GOC_SW(y1_w) 			


typedef struct {
	GStringElement	ODTCP_opcode;	/* GR_DRAW_TEXT_CP */
	word		ODTCP_len;
} OpDrawTextAtCP;

/*
 * Follow this macro immediately with a string -- goc will format the
 * the string as a two size bytes and a bunch of text bytes.
 */

#define GSDrawTextAtCP()    	    	    	GR_DRAW_TEXT_CP


typedef struct {
	GStringElement	ODTP_opcode;	/* GR_DRAW_TEXT_PTR */
	word		ODTP_x1;
	word		ODTP_y1;
	word		ODBOP_ptr;	/* near pointer to text */
} OpDrawTextPtr;

#define GSDrawTextPtr(x_w,y_w,off_ptr) 			/*NOT_DONE*/	\
		GR_DRAW_TEXT_PTR, GOC_SW(x_w),\
		GOC_SW(y_w),GOC_PTR(off_ptr)

typedef struct {
	GStringElement	ODTO_opcode;	/* GR_DRAW_TEXT_OPTR */
	word		ODTO_x1;
	word		ODTO_y1;
	optr		ODTO_optr;
} OpDrawTextOptr;

/*  The GSDrawXXXOptr macros will not work in GOC */

#if 0
#define GSDrawTextOptr(x_w,y_w,o_ptr) 			/*NOT_TESTED*/	\
	GR_DRAW_TEXT_OPTR, GOC_SW(x_w),				\
	GOC_SW(y_w),GOC_OPTR(o_ptr)
#endif

typedef struct {
	GStringElement	OMT_opcode;	/* GR_MOVE_TO */
	word		OMT_x1;
	word		OMT_y1;
} OpMoveTo;

#define GSMoveTo(x1_w,y1_w) 				/*TESTED*/	\
	GR_MOVE_TO, GOC_SW(x1_w), GOC_SW(y1_w)

typedef struct {
	GStringElement	ORMT_opcode;	/* GR_REL_MOVE_TO */
	word		ORMT_x1;
	word		ORMT_y1;
} OpRelMoveTo;

#define GSRelMoveTo(x1_wwf,y1_wwf) 			/*TESTED*/	\
	GR_REL_MOVE_TO, 						\
	GOC_WWF(x1_wwf),GOC_WWF(y1_wwf)

typedef struct {
	GStringElement	OMTW_opcode;	/* GR_MOVE_TO_WWFIXED */
	word		OMTW_x1;
	word		OMTW_y1;
} OpMoveToWWFixed;

#define GSMoveToWWFixed(x1_wwf,y1_wwf) 			/* NOT TESTED*/	\
	GR_MOVE_TO_WWFIXED, 						\
	GOC_WWF(x1_wwf),GOC_WWF(y1_wwf)

typedef struct {
	GStringElement	OSMM_opcode;	/* GR_SET_MIX_MODE */
	MixMode		OSMM_mode;
} OpSetMixMode;

#define GSSetMixMode(mode) GR_SET_MIX_MODE, (mode)

typedef struct {
	GStringElement	OSLC_opcode;	/* GR_SET_LINE_COLOR */
	RGBValue	OSLC_color;
} OpSetLineColor;

#define GSSetLineColor(r,g,b) 		    GR_SET_LINE_COLOR,(r),(g),(b)

typedef struct {
	GStringElement	OSLCI_opcode;	/* GR_SET_LINE_COLOR_INDEX */
	Color     	OSLCI_color;
} OpSetLineColorIndex;

#define GSSetLineColorIndex(color)  	    GR_SET_LINE_COLOR_INDEX, (color)

typedef struct {
	GStringElement	OSAC_opcode;	/* GR_SET_AREA_COLOR */
	RGBValue	OSAC_color;
} OpSetAreaColor;

#define GSSetAreaColor(r,g,b) 	    	    GR_SET_AREA_COLOR,(r),(g),(b)

typedef struct {
	GStringElement	OSACI_opcode;	/* GR_SET_AREA_COLOR_INDEX */
	Color		OSACI_color;
} OpSetAreaColorIndex;

#define GSSetAreaColorIndex(index)  	    GR_SET_AREA_COLOR_INDEX,(index)

typedef struct {
	GStringElement	OSTC_opcode;	/* GR_SET_TEXT_COLOR */
	RGBValue	OSTC_color;
} OpSetTextColor;

#define GSSetTextColor(r,g,b) 	    	    GR_SET_TEXT_COLOR,(r),(g),(b)

typedef struct {
	GStringElement	OSTCI_opcode;	/* GR_SET_TEXT_COLOR_INDEX */
	Color		OSTCI_color;
} OpSetTextColorIndex;

#define GSSetTextColorIndex(index)  	    GR_SET_TEXT_COLOR_INDEX,(index)

typedef struct {
	GStringElement	OLSM_opcode;	/* GR_SET_LINE_MASK */
	SysDrawMask	OLSM_mask;
} OpSetLineMask;

#define GSSetLineMask(index) 	    	    GR_SET_LINE_MASK, (index)

typedef struct {
	GStringElement	OSCLM_opcode;	/* GR_SET_CUSTOM_LINE_MASK */
	DrawMask	OSCLM_mask;
} OpSetCustomLineMask;

#define GSSetCustomLineMask(m1,m2,m3,m4,m5,m6,m7,m8)	    	    \
	GR_SET_CUSTOM_LINE_MASK, (m1), (m2), (m3), (m4), (m5), (m6), (m7), (m8)

typedef struct {
	GStringElement	OSAM_opcode;	/* GR_SET_AREA_MASK */
	SysDrawMask	OSAM_mask;
} OpSetAreaMask;

#define GSSetAreaMask(index) 	    	    GR_SET_AREA_MASK, (index)

typedef struct {
	GStringElement	OSCAM_opcode;	/* GR_SET_CUSTOM_AREA_MASK */
	DrawMask	OSCAM_mask;
} OpSetCustomAreaMask;

#define GSSetCustomAreaMask(m1,m2,m3,m4,m5,m6,m7,m8)	    	    \
	GR_SET_CUSTOM_AREA_MASK, (m1), (m2), (m3), (m4), (m5), (m6), (m7), (m8)

typedef struct {
	GStringElement	OSTM_opcode;	/* GR_SET_TEXT_MASK */
	SysDrawMask	OSTM_mask;
} OpSetTextMask;

#define GSSetTextMask(index) 	    	    GR_SET_TEXT_MASK, (index)

typedef struct {
	GStringElement	OSCTM_opcode;	/* GR_SET_CUSTOM_TEXT_MASK */
	DrawMask	OSCTM_mask;
} OpSetCustomTextMask;

#define GSSetCustomTextMask(m1,m2,m3,m4,m5,m6,m7,m8)	    	    \
	GR_SET_CUSTOM_TEXT_MASK, (m1), (m2), (m3), (m4), (m5), (m6), (m7), (m8)

typedef struct {
	GStringElement	OSLCM_opcode;	/* GR_SET_LINE_COLOR_MAP */
	ColorMapMode	OSLCM_mode;
} OpSetLineColorMap;

#define GSSetLineColorMap(mode)     	    	GR_SET_LINE_COLOR_MAP,(mode)

typedef struct {
	GStringElement	OSACM_opcode;	/* GR_SET_AREA_COLOR_MAP */
	ColorMapMode	OSACM_mode;
} OpSetAreaColorMap;

#define GSSetAreaColorMap(mode)			GR_SET_AREA_COLOR_MAP,(mode)

typedef struct {
	GStringElement	OSTCM_opcode;	/* GR_SET_TEXT_COLOR_MAP */
	ColorMapMode	OSTCM_mode;
} OpSetTextColorMap;

#define GSSetTextColorMap(mode)			GR_SET_TEXT_COLOR_MAP,(mode)

typedef struct {
	GStringElement	OSLW_opcode;	/* GR_SET_LINE_WIDTH */
	WWFixed		OSLW_width;
} OpSetLineWidth;

#define GSSetLineWidth(width_wwf) 					\
	GR_SET_LINE_WIDTH, GOC_WWF(width_wwf)

typedef struct {
	GStringElement	OSLS_opcode;	/* GR_SET_LINE_STYLE */
	LineStyle	OSLS_style;
	byte		OSLS_index;
} OpSetLineStyle;

#define GSSetLineStyle(style,index) 					\
	GR_SET_LINE_STYLE,(style),(index)

typedef struct {
	GStringElement	OSCLS_opcode;	/* GR_SET_CUSTOM_LINE_STYLE */
	word		OSCLS_index;
	word		OSCLS_count;
} OpSetCustomLineStyle;

#define GSSetCustomLineStyle(index,count) 				\
	GR_SET_CUSTOM_LINE_STYLE,(index),(count)

typedef struct {
	GStringElement	OSLE_opcode;	/* GR_SET_LINE_END */
	LineEnd		OSLE_mode;
} OpSetLineEnd;

#define GSSetLineEnd(end) 						\
	GR_SET_LINE_END,(end)

typedef struct {
	GStringElement	OSLJ_opcode;	/* GR_SET_LINE_JOIN */
	LineJoin	OSLJ_mode;
} OpSetLineJoin;

#define GSSetLineJoin(join) 						\
	GR_SET_LINE_JOIN,(join)

typedef struct {
	GStringElement	OSML_opcode;	/* GR_SET_MITER_LIMIT */
	WWFixed		OSML_mode;
} OpSetMiterLimit;

#define GSSetMiterLimit(limit_wwf) GR_SET_MITER_LIMIT, GOC_WWF(limit_wwf)

typedef struct {
	GStringElement	OSLA_opcode;	/* GR_SET_LINE_ATTR */
	LineAttr	OSLA_attr;
} OpSetLineAttr;

#define GSSetLineAttr(r,g,b,mode,mask,width,end,join,style) \
	GR_SET_LINE_ATTR,(CF_RGB),(r),(g),(b),(mask),(mode),(end),(join),(style),GOC_WWF(width)

typedef struct {
	GStringElement	OSAA_opcode;	/* GR_SET_AREA_ATTR */
	AreaAttr	OSAA_attr;
} OpSetAreaAttr;

#define GSSetAreaAttr(r,g,b,mode,mask) 					\
	GR_SET_AREA_ATTR,(CF_RGB),(r),(g),(b),(mask),(mode)

typedef struct {
	GStringElement	OSTS_opcode;	/* GR_SET_TEXT_STYLE */
	TextStyle	OSTS_set;
	TextStyle	OSTS_reset;
} OpSetTextStyle;

#define GSSetTextStyle(set,reset) 					\
	GR_SET_TEXT_STYLE,(set),(reset)

typedef struct {
	GStringElement	OSTMo_opcode;	/* GR_SET_TEXT_MODE */
	TextMode	OSTMo_set;
	TextMode	OSTMo_reset;
} OpSetTextMode;

#define GSSetTextMode(set,reset) 					\
	GR_SET_TEXT_MODE,(set),(reset)

typedef struct {
	GStringElement	OSTSP_opcode;	/* GR_SET_TEXT_SPACE_PAD */
	WBFixed		OSTSP_pad;
} OpSetTextSpacePad;

#define GSSetTextSpacePad(pad_wbf) 					\
	GR_SET_TEXT_SPACE_PAD, GOC_WBF(pad_wbf)

typedef struct {
	GStringElement	OSF_opcode;	/* GR_SET_FONT */
	WBFixed		OSF_size;
	FontID		OSF_id;
} OpSetFont;

#define GSSetFont(id,size_wbf) 				/*TESTED*/	\
	GR_SET_FONT,GOC_WBF(size_wbf),GOC_WORD(id)

typedef struct {
	GStringElement	OSTA_opcode;	/* GR_SET_TEXT_ATTR */
	TextAttr	OSTA_attr;
} OpSetTextAttr;

#define GSSetTextAttr(cflag,r,g,b,mask,sSet,sReset,mSet,mReset,sPad,id,pSize,trkKrn,fWeight,fWidth) \
	GR_SET_TEXT_ATTR,(cflag),(r),(g),(b),(mask),(sSet),	\
       (sReset),(mSet),(mReset),GOC_WWF(sPad),         \
	GOC_WORD(id), GOC_WWF(pSize),GOC_SW(trkKrn),(fWeight),(fWidth)

typedef struct {
	GStringElement	OSTK_opcode;	/* GR_SET_TRACK_KERN */
	sword		OSTK_degree;
} OpSetTrackKern;

#define GSSetTrackKern(degree) GR_SET_TRACK_KERN, GOC_SW(degree)

typedef struct {
	GStringElement	OSCR_opcode;	/* GR_SET_CLIP_RECT */
	PathCombineType	OSCR_flags;
	Rectangle	OSCR_rect;
} OpSetClipRect;

#define GSSetClipRect(path,rl_sw,rt_sw,rr_sw,rb_sw) 			\
	GR_SET_CLIP_RECT,GOC_SW(rl_sw), 				\
	GOC_SW(rt_sw),GOC_SW(rr_sw),GOC_SW(rb_sw)
	
typedef struct {
	GStringElement	OSWCR_opcode;	/* GR_SET_WIN_CLIP_RECT */
	PathCombineType	OSWCR_flags;
	Rectangle	OSWCR_rect;
} OpSetWinClipRect;

#define GSSetWinClipRect(path,rl_sw,rt_sw,rr_sw,rb_sw) 			\
	GR_SET_WIN_CLIP_RECT,GOC_SW(rl_sw), 				\
	GOC_SW(rt_sw),GOC_SW(rr_sw),GOC_SW(rb_sw)

typedef struct {
	GStringElement	OBP_opcode;	/* GR_BEGIN_PATH */
	PathCombineType	OBP_combine;
	byte		OBP_flags;
	byte		OBP_unused;
} OpBeginPath;

#define GSBeginPath(flags)  	    	    	GR_BEGIN_PATH,(flags)

typedef struct {
	GStringElement	OSCP_opcode;	/* GR_SET_CLIP_PATH */
	RegionFillRule	OSCP_rule;
	PathCombineType	OSCP_flags;
} OpSetClipPath;

#define GSSetClipPath(flags)			GR_SET_CLIP_PATH,(flags)

typedef struct {
	GStringElement	OSWCP_opcode;	/* GR_SET_WIN_CLIP_PATH */
	RegionFillRule	OSWCP_rule;
	PathCombineType	OSWCP_flags;
} OpSetWinClipPath;

#define GSSetWinClipPath(flags)			GR_SET_WIN_CLIP_PATH,(flags)

typedef struct {
	GStringElement	OEP_opcode;	/* GR_END_PATH */
} OpEndPath;

#define GSEndPath()				GR_END_PATH

typedef struct {
	GStringElement	OCSP_opcode;	/* GR_CLOSE_SUB_PATH */
} OpCloseSubPath;

#define GSCloseSubPath()			GR_CLOSE_SUB_PATH

typedef struct {
	GStringElement	OSNP_opcode;	/* GR_SET_NULL_PATH */
} OpSetNullPath;

#define GSSetNullPath()				GR_SET_NULL_PATH

typedef struct {
	GStringElement	OFLP_opcode;	/* GR_FILL_PATH */
	RegionFillRule	OFLP_rule;
} OpFillPath;

#define GSFillPath(region_fill_rule) 					\
	GR_FILL_PATH,(region_fill_rule)

typedef struct {
	GStringElement	ODRP_opcode;	/* GR_DRAW_PATH */
} OpDrawPath;

#define GSDrawPath() 	    	    	    	GR_DRAW_PATH

typedef struct {
	GStringElement	OSSP_opcode;	/* GR_SET_STROKE_PATH */
} OpSetStrokePath;

#define GSSetStrokePath()			GR_SET_STROKE_PATH

typedef struct {
	GStringElement	ODATP_opcode;	/* GR_DRAW_ARC_3POINT */
	ArcCloseType	ODATP_close;
	WWFixed		ODATP_x1;
	WWFixed		ODATP_y1;
	WWFixed		ODATP_x2;
	WWFixed		ODATP_y2;
	WWFixed		ODATP_x3;
	WWFixed		ODATP_y3;
} OpDrawArc3Point;

#define GSDrawArc3Point(close, x1, y1, x2, y2, x3, y3) 	    		\
	GR_DRAW_ARC_3POINT,GOC_WORD(close),GOC_WWF(x1),			\
	GOC_WWF(y1), GOC_WWF(x2), GOC_WWF(y2), 				\
	GOC_WWF(x3), GOC_WWF(y3)

typedef struct {
	GStringElement	ODATPT_opcode;	/* GR_DRAW_ARC_3POINT_TO */
	ArcCloseType	ODATPT_close;
	WWFixed		ODATPT_x2;
	WWFixed		ODATPT_y2;
	WWFixed		ODATPT_x3;
	WWFixed		ODATPT_y3;
} OpDrawArc3PointTo;

#define GSDrawArc3PointTo(close, x2, y2, x3, y3) \
	GR_DRAW_ARC_3POINT_TO,GOC_WORD(close), \
	GOC_WWF(x2), GOC_WWF(y2), GOC_WWF(x3), GOC_WWF(y3)

typedef struct {
	GStringElement	ODRATPT_opcode;	/* GR_DRAW_REL_ARC_3POINT_TO */
	ArcCloseType	ODRATPT_close;
	WWFixed		ODRATPT_x2;
	WWFixed		ODRATPT_y2;
	WWFixed		ODRATPT_x3;
	WWFixed		ODRATPT_y3;
} OpDrawRelArc3PointTo;

#define GSDrawRelArc3PointTo(close, x2, y2, x3, y3) \
	GR_DRAW_REL_ARC_3POINT_TO,GOC_WORD(close), \
	GOC_WWF(x2), GOC_WWF(y2), GOC_WWF(x3), GOC_WWF(y3)

typedef struct {
	GStringElement	OFATP_opcode;	/* GR_FILL_ARC_3POINT */
	ArcCloseType	OFATP_CLOSE;
	WWFixed		OFATP_x1;
	WWFixed		OFATP_y1;
	WWFixed		OFATP_x2;
	WWFixed		OFATP_y2;
	WWFixed		OFATP_x3;
	WWFixed		OFATP_y3;
} OpFillArc3Point;

#define GSFillArc3Point(close, x1, y1, x2, y2, x3, y3) \
	GR_FILL_ARC_3POINT,GOC_WORD(close),GOC_WWF(x1), GOC_WWF(y1),\
	GOC_WWF(x2), GOC_WWF(y2), \
	GOC_WWF(x3), GOC_WWF(y3)

typedef struct {
	GStringElement	OFATPT_opcode;	/* GR_FILL_ARC_3POINT_TO */
	ArcCloseType	OFATPT_close;
	WWFixed		OFATPT_x2;
	WWFixed		OFATPT_y2;
	WWFixed		OFATPT_x3;
	WWFixed		OFATPT_y3;
} OpFillArc3PointTo;

#define GSFillArc3PointTo(close, x2, y2, x3, y3) \
	GR_FILL_ARC_3POINT_TO,GOC_WORD(close), \
	GOC_WWF(x2), GOC_WWF(y2), GOC_WWF(x3), GOC_WWF(y3)

typedef struct {
	GStringElement	OSFW_opcode;	/* GR_SET_FONT_WEIGHT */
	FontWeight	OSFW_weight;
} OpSetFontWeight;

#define GSSetFontWeight(weight) GR_SET_FONT_WEIGHT,GOC_WORD(weight)

typedef struct {
	GStringElement	OSFWI_opcode;	/* GR_SET_FONT_WIDTH */
	FontWidth	OSFWI_width;
} OpSetFontWidth;

#define GSSetFontWidth(width) GR_SET_FONT_WIDTH,GOC_WORD(width)

typedef struct {
	GStringElement	OSSBA_opcode;	/* GR_SET_SUBSCRIPT_ATTR */
	byte		OSSBA_pos;
	byte		OSSBA_size;
} OpSetSubscriptAttr;

#define GSSetSubscriptAttr(pos,size) GR_SET_SUBSCRIPT_ATTR,(pos),(size)

typedef struct {
	GStringElement	OSSA_opcode;	/* GR_SET_SUPERSCRIPT_ATTR */
	byte		OSSA_pos;
	byte		OSSA_size;
} OpSetSuperscriptAttr;

#define GSSetSuperscriptAttr(pos,size) GR_SET_SUPERSCRIPT_ATTR,(pos),(size)

typedef struct {
	GStringElement	OSAP_opcode;	/* GR_SET_AREA_PATTERN */
	GraphicPattern	OSAP_pattern;
} OpSetAreaPattern;

#define GSSetAreaPattern(pattern) GR_SET_AREA_PATTERN,GOC_PATTERN(pattern)

typedef struct {
	GStringElement	OSTP_opcode;	/* GR_SET_TEXT_PATTERN */
	GraphicPattern	OSTP_pattern;
} OpSetTextPattern;

#define GSSetTextPattern(pattern) GR_SET_TEXT_PATTERN,GOC_PATTERN(pattern)

typedef struct {
	GStringElement	OSCAP_opcode;	/* GR_SET_CUSTOM_AREA_PATTERN */
	GraphicPattern	OSCAP_pattern;
	word		OSCAP_size;
} OpSetCustomAreaPattern;

#define GSSetCustomAreaPattern(pattern,size) GR_SET_CUSTOM_AREA_PATTERN, \
	GOC_PATTERN(pattern),GOC_WORD(size)

typedef struct {
	GStringElement	OSCTP_opcode;	/* GR_SET_CUSTOM_TEXT_PATTERN */
	GraphicPattern	OSCTP_pattern;
	word		OSCTP_size;
} OpSetCustomTextPattern;

#define GSSetCustomTextPattern(pattern,size)  				\
	GR_SET_CUSTOM_TEXT_PATTERN,GOC_PATTERN(pattern), 		\
	GOC_WORD(size)

typedef struct {
	GStringElement	OCP_opcode;	/* GR_CREATE_PALETTE */
} OpCreatePalette;

#define GSCreatePalette()   	    	    	GR_CREATE_PALETTE

typedef struct {
	GStringElement	ODSP_opcode;	/* GR_DESTROY_PALETTE */
} OpDestroyPalette;

#define GSDestroyPalette()			GR_DESTROY_PALETTE

typedef struct {
	GStringElement	OSPE_opcode;	/* GR_SET_PALETTE_ENTRY */
	word		OSPE_entry;
	RGBValue	OSPE_color;
} OpSetPaletteEntry;

#define GSSetPaletteEntry(entry,r,g,b) GR_SET_PALETTE_ENTRY GOC_WORD(entry),(r),(g),(b)

typedef struct {
	GStringElement	OSP_opcode;	/* GR_SET_PALETTE */
	byte		OSP_start;
	word		OSP_num;
} OpSetPalette;

#define GSSetPalette(entry, count) GR_SET_PALETTE,(entry),(count)


typedef struct {
	word		OB_width;
	word		OB_heigth;
	BMCompact	OB_compact;
	BMType		OB_type;
} OpBitmap;

#define Bitmap(wid,hei,compact,type) \
  GOC_WORD(wid),GOC_WORD(hei),(compact), (type)

#endif
