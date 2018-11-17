/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	win.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines window structures and routines.
 *
 *	$Id: win.h,v 1.2 98/06/12 02:55:07 joon Exp $
 *
 ***********************************************************************/

#ifndef	__WIN_H
#define __WIN_H

/* #include <object.h> */
/* #include <metaC.h> */
#include <graphics.h>

/**	NOTE: moved definition for RectDWord to graphics.h  -jim  **/

extern void	/*XXX*/
    _pascal WinGetWinScreenBounds(WindowHandle win,
						Rectangle *bounds);

/***/

typedef byte WinColorFlags;
#define WCF_RGB		0x80
#define WCF_TRANSPARENT	0x40
#define WCF_PLAIN	0x20
#define WCF_MAP_MODE	0x07

#define WCF_MAP_MODE_OFFSET     0

typedef ByteEnum LayerPriority;
#define LAYER_PRIO_MODAL   6
#define LAYER_PRIO_ON_TOP   8
#define LAYER_PRIO_STD  12
#define LAYER_PRIO_ON_BOTTOM 14

typedef ByteEnum WinPriority;
#define WIN_PRIO_POPUP   4
#define WIN_PRIO_MODAL   6
#define WIN_PRIO_ON_TOP   8
#define WIN_PRIO_COMMAND   10
#define WIN_PRIO_STD 12
#define WIN_PRIO_ON_BOTTOM 14

#define WPF_CREATE_GSTATE	0x8000
#define WPF_ROOT		0x4000
#define WPF_SAVE_UNDER		0x2000
#define WPF_INIT_EXCLUDED	0x1000
#define WPF_PLACE_BEHIND	0x0800
#define WPF_PLACE_LAYER_BEHIND	0x0400
#define WPF_LAYER		0x0200
#define WPF_ABS			0x0100
#define WPF_INIT_SUSPENDED	WPF_ABS
#define WPF_LAYER_PRIORITY	0x00f0
#define WPF_WIN_PRIORITY	0x000f

#define WPF_LAYER_PRIORITY_OFFSET	4
#define WPF_WIN_PRIORITY_OFFSET		0

extern WindowHandle	/*XXX*/
    _pascal WinOpen(Handle parentWinOrVidDr, 
		optr inputRecipient, optr exposureRecipient,
		word colorFlags, word redOrIndex,
		word green, word blue, word flags, word layerID,
		GeodeHandle owner, const Region *winReg, word axParam,
		word bxParam, word cxParam, word dxParam);

/***/

extern void	/*XXX*/
    _pascal WinClose(WindowHandle win);

/***/

typedef WordFlags WinPassFlags;
#define WPF_CREATE_GSTATE	0x8000
#define WPF_ROOT		0x4000
#define WPF_SAVE_UNDER		0x2000
#define WPF_INIT_EXCLUDED	0x1000
#define WPF_PLACE_BEHIND	0x0800
#define WPF_PLACE_LAYER_BEHIND	0x0400
#define	WPF_LAYER		0x0200
#define WPF_ABS			0x0100
#define WPF_PRIORITY		0x00ff

extern void	/*XXX*/
    _pascal WinMove(WindowHandle win, sword xMove, sword yMove,	WinPassFlags flags);

/***/

extern void	/*XXX*/
    _pascal WinResize(WindowHandle win, const Region *reg,
			word axParam, word bxParam, word cxParam, word dxParam,
			WinPassFlags flags);

/***/


extern void	/*XXX*/
    _pascal WinChangePriority(WindowHandle win, WinPassFlags flags, word layerID);

/***/

extern void	/*XXX*/
    _pascal WinScroll(WindowHandle win, WWFixedAsDWord xMove, 
			   WWFixedAsDWord yMove, PointWWFixed *scrollAmt);
								

/***/

extern void
    _pascal GrBeginUpdate(GStateHandle gstate);

/***/

extern void
    _pascal GrEndUpdate(GStateHandle gstate);

/***/

extern void	/*XXX*/
    _pascal WinAckUpdate(WindowHandle win);

/***/

extern void	/*XXX*/
    _pascal WinDecRefCount(WindowHandle win);

/***/

extern void	/*XXX*/
    _pascal WinInvalReg(WindowHandle win, const Region *reg,
		word axParam, word bxParam, word cxParam, word dxParam);

/***/

extern void	/*XXX*/
    _pascal WinSuspendUpdate(WindowHandle win);

/***/

extern void	/*XXX*/
    _pascal WinUnSuspendUpdate(WindowHandle win);

/***/

#define WRF_DELAYED_WASH		0x80
#define WRF_DELAYED_V			0x40
#define WRF_SIBLING_VALID		0x20
#define WRF_EXPOSE_PENDING		0x10
#define WRF_CLOSED			0x08

#define WPF_PTR_IN_UNIV		0x20
#define WPF_PTR_IN_VIS		0x10

typedef enum /* word */ {
    WIT_PRIVATE_DATA  =0,
    WIT_COLOR  =2,
    WIT_INPUT_OBJ  =4,
    WIT_EXPOSURE_OBJ  =6,
    WIT_STRATEGY  =8,
    WIT_FLAGS  =10,
    WIT_LAYER_ID  =12,
    WIT_PARENT_WIN  =14,
    WIT_FIRST_CHILD_WIN  =16,
    WIT_LAST_CHILD_WIN  =18,
    WIT_PREV_SIBLING_WIN  =20,
    WIT_NEXT_SIBLING_WIN  =22,
    WIT_PRIORITY=24,
} WinInfoType;

extern void	/*XXX*/
    _pascal WinGetInfo(WindowHandle win, WinInfoType type,
							void *data);

/***/

extern void	/*XXX*/
    _pascal WinSetInfo(WindowHandle win, WinInfoType type, dword data);


/***/

typedef ByteEnum WinInvalFlag;
#define WIF_INVALIDATE 0
#define WIF_DONT_INVALIDATE 1

extern void	/*XXX*/
    _pascal WinApplyRotation(WindowHandle win, WWFixedAsDWord angle,
							WinInvalFlag flag);

/***/

extern void	/*XXX*/
    _pascal WinApplyScale(WindowHandle win, WWFixedAsDWord xScale,
				WWFixedAsDWord yScale, WinInvalFlag flag);

/***/

extern void	/*XXX*/
    _pascal WinApplyTranslation(WindowHandle win, WWFixedAsDWord xTrans,
				WWFixedAsDWord yTrans, WinInvalFlag flag);

/***/

extern void	/*XXX*/
    _pascal WinApplyTranslationDWord(WindowHandle win, sdword xTrans,
					sdword yTrans, WinInvalFlag flag);

/***/

extern XYValueAsDWord	/*XXX*/
    _pascal WinTransform(WindowHandle win, sword x, sword y);

/***/

extern XYValueAsDWord	/*XXX*/
    _pascal WinUntransform(WindowHandle win, sword x, sword y);

/***/

extern void	/*XXX*/
    _pascal WinTransformDWord(WindowHandle win, sdword xCoord,
			sdword yCoord, PointDWord *screenCoordinates);

/***/

extern void	/*XXX*/
    _pascal WinUntransformDWord(WindowHandle win, sdword xCoord,
			sdword yCoord, PointDWord *documentCoordinates);

/***/

extern void	/*XXX*/
    _pascal WinSetTransform(WindowHandle win, const TransMatrix *tm,
							WinInvalFlag flag);

/***/

extern void	/*XXX*/
    _pascal WinApplyTransform(WindowHandle win,
			const TransMatrix *tm, WinInvalFlag flag);

/***/

extern void	/*XXX*/
    _pascal WinSetNullTransform(WindowHandle win, WinInvalFlag flag);

/***/

extern void	/*XXX*/
    _pascal WinGetTransform(WindowHandle win, TransMatrix *tm);


/***/

/* HELP !!! */
extern Boolean	/*XXX*/
    _pascal WinGrabChange(WindowHandle win, optr newObj);

/***/

/* HELP !!! */
extern void	/*XXX*/
    _pascal WinReleaseChange(WindowHandle win, optr obj);

/***/

/* HELP !!! */
extern WindowHandle	/*XXX*/
    _pascal WinChangeAck(WindowHandle win, sword x, sword y, optr *winOD);

/***/

/* HELP !!! */
extern void	/*XXX*/
    _pascal WinEnsureChangeNotification(void);

typedef enum {
    PIV_NONE,
    PIV_VIDEO_DRIVER_DEFAULT,
    PIV_UPDATE
} PtrImageValue;

typedef enum {
    PIL_SYSTEM,
    PIL_1,
    PIL_FLOW,
    PIL_3,
    PIL_GEODE,
    PIL_5,
    PIL_GADGET,
    PIL_7,
    PIL_WINDOW,
    PIL_DEFAULT
} PtrImageLevel;

extern void	/*XXX*/
    _pascal WinSetPtrImage(WindowHandle win, PtrImageLevel ptrLevel,
		   optr ptrCh);

extern void	/*XXX*/
    _pascal WinGeodeSetPtrImage(GeodeHandle gh, optr ptrCh);

extern optr	/*XXX*/
    _pascal WinGeodeGetInputObj(GeodeHandle gh);

extern void	/*XXX*/
    _pascal WinGeodeSetInputObj(GeodeHandle gh, optr iobj);

extern optr	/*XXX*/
    _pascal WinGeodeGetParentObj(GeodeHandle gh);

extern void	/*XXX*/
    _pascal WinGeodeSetParentObj(GeodeHandle gh, optr pObj);

extern void	/*XXX*/
    _pascal WinGeodeSetActiveWin(GeodeHandle gh, WindowHandle win);

extern void 	/*XXX*/
    _pascal WinRealizePalette(WindowHandle win);

/***/


/* HELP !!! */
/* Must declare imported methods */

/* Display Types */

typedef ByteEnum DisplaySize;
#define DS_TINY 0
#define DS_STANDARD 1
#define DS_LARGE 2
#define DS_HUGE 3

typedef ByteEnum DisplayAspectRatio;
#define DAR_NORMAL 0
#define DAR_SQUISHED 1
#define DAR_VERY_SQUISHED 2
#define DAR_TV 3

typedef ByteEnum DisplayClass;
#define DC_TEXT 0
#define DC_GRAY_1 1
#define DC_GRAY_2 2
#define DC_GRAY_4 3
#define DC_GRAY_8 4
#define DC_COLOR_2 5
#define DC_COLOR_4 6
#define DC_COLOR_8 7
#define DC_CF_RGB 8

typedef ByteFlags DisplayType;
#define DT_DISP_SIZE		0xc0
#define DT_DISP_ASPECT_RATIO	0x30
#define DT_DISP_CLASS		0x0f

#define DT_DISP_SIZE_OFFSET 6
#define DT_DISP_ASPECT_RATIO_OFFSET 4
#define DT_DISP_CLASS_OFFSET 0

typedef ByteEnum DisplayModeOrientation;
#define DMO_NO_CHANGE	0x0
#define DMO_DEFAULT	0x1
#define DMO_PORTRAIT	0x2
#define DMO_TOGGLE	0x3

typedef ByteEnum DisplayModeColor;
#define DMC_NO_CHANGE	0x0
#define DMC_DEFAULT	0x1
#define DMC_INVERTED	0x2
#define DMC_TOGGLE	0x3

typedef ByteEnum DisplayModeDefinition;
#define DMD_NO_CHANGE	0x0
#define DMD_DEFAULT	0x1
#define DMD_HIGH	0x2
#define DMD_TOGGLE	0x3

typedef ByteEnum DisplayModeResolution;
#define DMR_NO_CHANGE	0x0
#define DMR_DEFAULT	0x1
#define DMR_HIGH	0x2
#define DMR_TOGGLE	0x3


typedef WordFlags DisplayMode;
/* 8 bits unused */
#define DM_color	(0x0080 | 0x0040)
#define DM_color_OFFSET	6
#define DM_orientation	(0x0020 | 0x0010)
#define DM_orientation_OFFSET	4
#define DM_definition	(0x0008 | 0x0004)
#define DM_definition_OFFSET	2
#define DM_resolution	(0x0002 | 0x0001)
#define DM_resolution_OFFSET	0

#ifdef __HIGHC__
pragma Alias(WinGetWinScreenBounds, "WINGETWINSCREENBOUNDS");
pragma Alias(WinOpen, "WINOPEN");
pragma Alias(WinClose, "WINCLOSE");
pragma Alias(WinMove, "WINMOVE");
pragma Alias(WinResize, "WINRESIZE");
pragma Alias(WinDecRefCount, "WINDECREFCOUNT");
pragma Alias(WinChangePriority, "WINCHANGEPRIORITY");
pragma Alias(WinScroll, "WINSCROLL");
pragma Alias(GrBeginUpdate, "GRBEGINUPDATE");
pragma Alias(GrEndUpdate, "GRENDUPDATE");
pragma Alias(WinAckUpdate, "WINACKUPDATE");
pragma Alias(WinInvalReg, "WININVALREG");
pragma Alias(WinSuspendUpdate, "WINSUSPENDUPDATE");
pragma Alias(WinUnSuspendUpdate, "WINUNSUSPENDUPDATE");
pragma Alias(WinGetInfo, "WINGETINFO");
pragma Alias(WinSetInfo, "WINSETINFO");
pragma Alias(WinApplyRotation, "WINAPPLYROTATION");
pragma Alias(WinApplyScale, "WINAPPLYSCALE");
pragma Alias(WinApplyTranslation, "WINAPPLYTRANSLATION");
pragma Alias(WinApplyTranslationDWord, "WINAPPLYTRANSLATIONDWORD");
pragma Alias(WinTransform, "WINTRANSFORM");
pragma Alias(WinUntransform, "WINUNTRANSFORM");
pragma Alias(WinTransformDWord, "WINTRANSFORMDWORD");
pragma Alias(WinUntransformDWord, "WINUNTRANSFORMDWORD");
pragma Alias(WinSetTransform, "WINSETTRANSFORM");
pragma Alias(WinApplyTransform, "WINAPPLYTRANSFORM");
pragma Alias(WinSetNullTransform, "WINSETNULLTRANSFORM");
pragma Alias(WinGetTransform, "WINGETTRANSFORM");
pragma Alias(WinGrabChange, "WINGRABCHANGE");
pragma Alias(WinReleaseChange, "WINRELEASECHANGE");
pragma Alias(WinChangeAck, "WINCHANGEACK");
pragma Alias(WinEnsureChangeNotification, "WINENSURECHANGENOTIFICATION");
pragma Alias(WinSetPtrImage, "WINSETPTRIMAGE");
pragma Alias(WinGeodeSetPtrImage, "WINGEODESETPTRIMAGE");
pragma Alias(WinGeodeGetInputObj, "WINGEODEGETINPUTOBJ");
pragma Alias(WinGeodeSetInputObj, "WINGEODESETINPUTOBJ");
pragma Alias(WinGeodeGetParentObj, "WINGEODEGETPARENTOBJ");
pragma Alias(WinGeodeSetParentObj, "WINGEODESETPARENTOBJ");
pragma Alias(WinGeodeSetActiveWin, "WINGEODESETACTIVEWIN");
pragma Alias(WinRealizePalette, "WINREALIZEPALETTE");
#endif

#endif
