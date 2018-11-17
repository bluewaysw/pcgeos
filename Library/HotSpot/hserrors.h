/************************************************************************

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:        GEOS
MODULE:         HotSpot Library
FILE:           hsErrors.h

AUTHOR:         Cassie Hartzog, Apr 13, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Cassie  4/13/94         Initial version.

DESCRIPTION:            

	$Id: hserrors.h,v 1.1 97/04/04 18:09:04 newdeal Exp $

************************************************************************/

#ifndef _HSERRORS_H_
#define _HSERRORS_H_

#include <ec.h>

/************************************************************************  
 *			MACROS
 ************************************************************************/ 

#define MK_FP(seg,ofs)	((void _seg *)(seg) + (void near *)(ofs))

#define HW(dw)		((word)(dw >> 16))

#define ABS(x)		((x) >= 0  ? (x) : (-x))


/************************************************************************ 
 *			STRUCTURES
 ************************************************************************/

/********** OldHotSpotArray is used in 3.0 and older documents ***********/

/*
 * The HotSpotArray is used to map between graphic runs and HotSpot
 * objects.  Each graphic run's position and a unique token is
 * stored in this array and updated as text is inserted and deleted.
 * HotSpot objects are referenced by the token stored here with the
 * position of their graphic run.
 */

typedef struct {
    dword   OHSAE_position;      /* position of start of graphic run */
    word    OHSAE_token;         /* token to use to refer to graphic */
} OldHotSpotArrayElement;


/********** GraphicArrayElement is used in 4.0 and newer documents *********/

typedef WordFlags GraphicType;
#define GT_PAGE_NUMBER	    	    	0x0000
#define	GT_PAGE_NUMBER_IN_SECTION	0x0001
#define GT_NUMBER_OF_PAGES		0x0002
#define GT_NUMBER_OF_PAGES_IN_SECTION	0x0003
#define GT_SECTION_NUMBER		0x0004
#define GT_NUMBER_OF_SECTIONS		0x0005
#define GT_CREATION_DATE_TIME		0x0006
#define GT_MODIFICATION_DATE_TIME	0x0007
#define GT_CURRENT_DATE_TIME		0x0008
#define GT_STORED_DATE_TIME		0x0009
#define GT_CONTEXT_PAGE		    	0x000a
#define GT_CONTEXT_PAGE_IN_SECTION	0x000b
#define GT_CONTEXT_SECTION		0x000c
#define GT_CONTEXT_NAME		    	0x000d
#define GT_HOTSPOT			0x000e

#define GT_VARIABLE 	    	    	0x2000  	/* variable graphic */
#define GT_GSTRING 	    	    	0x4000 	    	/* gstring graphic */
#define GT_NONE 	    	    	0x8000   	/* no graphic */


/* NOTE: HotSpots have GraphicType = GT_VARIABLE | GT_HOTSPOT */

typedef struct {
    dword   	   HSAE_position;    /* position of start of graphic run */
    GraphicType    HSAE_type;	    /* graphic type */
    word    	   HSAE_token;       /* token to use to refer to graphic */
} HotSpotArrayElement;


/*
 *  The following structure is exactly the same as in the grobj instance data.
 *  Without it, somehow Borland C++ 4.0 compiler can't recognize the grobj 
 *  instance data.  Thus, I re-define the grobj instance data here.  
 */
typedef struct {
    LinkPart                GOI_drawLink;
    LinkPart                GOI_reverseLink; 
    GrObjAttrFlags          GOI_attrFlags;
    GrObjOptimizationFlags  GOI_optFlags;
    GrObjMessageOptimizationFlags GOI_msgOptFlags;
    GrObjLocks              GOI_locks;
    GrObjActionModes        GOI_actionModes;
    GrObjTempModes          GOI_tempState;
    ChunkHandle             GOI_normalTransform;
    ChunkHandle             GOI_spriteTransform;
    word                    GOI_areaAttrToken;
    word                    GOI_lineAttrToken;
} MyGrObj;

typedef struct {
    GrObjInstance           GrObjVisGuardian_metaInstance;
    optr                    GOVGI_ward;
    ClassStruct             *GOVGI_class;
    GrObjVisGuardianFlags   GOVGI_flgs;
} MySpline;


/*  The following structure is used as a parameter to ObjComProcessChildren */
typedef struct {
    word         *CBD_token;        /* token of the graphic which moved */
    PointDWFixed *CBD_position;     /* new position of the graphic      */
} Data;


/*  The following structure is used as a parameter to MSG_HOT_SPOT_MANAGER_
 *	CHILDREN_IN_GROUP_NOTIFY_TEXT
 */
typedef struct {
    word    token;
    word    x_position;
    word    y_position;
} callbackNotify;



/************************************************************************ 
 *              CONSTANTS
 ************************************************************************/

/*
 *      Fatal Errors 
 */
typedef enum {
	ERROR_ATTR_HOT_SPOT_MANAGER_GRAPHIC_TOKEN_NOT_FOUND,
	ERROR_CANT_CREATE_A_HOTSPOT,
	ERROR_FIRST_ANCHOR_SHOULD_NOT_BE_OUTSIDE_THE_GRAPHIC,
	ERROR_HOT_SPOT_TOKEN_NOT_FOUND,
	ERROR_GRAB_HANDLE,
	ERROR_NO_GRAPHIC_RUN_TOKEN_FOUND_IN_GROBJ_BODY,
	ERROR_NOT_A_HOT_SPOT_GROUP_OBJECT,

/* Errors for HotSpotTextClass */

	HSTEXT_NO_HOT_SPOT_ARRAY,	
	/* This HotSpotText object has no hotspot array */
	
	HSTEXT_HOT_SPOT_ARRAY_ELEMENT_NOT_FOUND,
	/* The requested element was not found in the HotSpotArray */
	
	HSTEXT_HOT_SPOT_ARRAY_POSITION_ALREADY_IN_ARRAY,
	/* An attempt was made to add an element to the HotSpotArray, but
	 * there is already an element with the same position in the array 
	 */
	
	HSTEXT_HOT_SPOT_TEXT_BAD_REPLACE_RANGE,
	/* The passed replace range is invalid, probably because it separates
	 * an embedded graphic and its hotspots.
	 */
	 
	HSTEXT_HOT_SPOT_ARRAY_EMPTY,
	/* Somehow the HotSpotArray has lost all its elements, including
	 * the sentinel element which should always be there.
	 */

	HSTEXT_UNEXPECTED_END_OF_HUGE_ARRAY,
	HSTEXT_UNEXPECTED_HUGE_ARRAY_ELEMENT_SIZE,
	/* errors which occur when the HotSpotArray has
	 * been corrupted. 
	 */
	
	HSTEXT_INVALID_GRAPHIC,
	/* A graphic element was expected to be of one type (embedded, hotspot)
	 * but is of the other.
	 */

	HSTEXT_UNSUPPORTED_TEXT_REFERENCE_TYPE,
	/* A text replace operation occurred, but the TextReference was of
	 * an unsupported type.  (Supported types are pointer and HugeArray)
	 */
	 
	HSTEXT_ESCAPE_ELEMENT_NOT_FOUND,
	/* The hotspot escape element was not found in the hotspot's gstring */
	
	HSTEXT_HOT_SPOT_ARRAY_OUT_OF_SYNC,
	/* The position of graphics as recorded in the HotSpotArray does
	 * not agree with the actual text.
	 */

	HOTSPOT_TOKEN_COUNT_OVERFLOW, 
	/* The token count has grown so large that it equals the value
	 * for NULL_HOT_SPOT_TOKEN.
	 */

	ERROR_GROUPS_CANNOT_HAVE_HYPERLINKS,

	HSTEXT_INVALID_GRAPHIC_TYPE,
	/* The graphic type stored in the HotSpotArrayElement disagrees
	 * with the actual VisTextGraphic type.
	 */

	ERROR_MEMALLOC_FAILED,
} FatalErrors;


/*
 *		Warnings
 */
typedef enum {
	WARNING_MESSAGE_HOT_SPOT_UNSUPPORTED_TOOL,
	WARNING_POINT_OUT_OF_BOUNDS,
	
/* Warnings for HotSpotTextClass */

	HSTEXT_HOT_SPOT_ARRAY_AT_LAST_ELEMENT,
	/* The end of the HotSpotArray was reached before expected */
	
	HSTEXT_SELECT_RANGE_SEPARATES_HOT_SPOTS,
	/* Embedded graphics and their hotspots should never be separated
	 * by a select range.  Either all or none should be in a select range,
	 * except when the user has cut a HotSpot object. 
	 */
	 
	HOTSPOT_DATA_SIZE_ZERO,
	/* zero-sized HotSpot object instance data is being passed
	 * for udpate or create operation 
	 */
	HSTEXT_CANT_UNDO_GROUP_DELETE,
	/* Nothing in group which needs un-deleting */
} Warnings;

extern FatalErrors shme; 
extern Warnings shmoo; 



/************************************************************************ 
 *	External Function Declarations for HotSpotTextClass
 ************************************************************************/

extern dword    HotSpotArrayLock(optr oself, HotSpotArrayElement **elemPtr);
extern void     HotSpotArrayUnlock(HotSpotArrayElement *elemPtr);
extern word     HotSpotArrayNext(HotSpotArrayElement **elemPtr);
extern word     HotSpotArrayPrev(HotSpotArrayElement **elemPtr);
extern word     HotSpotArrayGetToken(optr oself, HotSpotArrayElement **elemPtr,
                                     dword position);
extern dword    HotSpotArrayGetPosition(HotSpotArrayElement **elemPtr,
                                        word token);
extern GraphicType HotSpotArrayGetType(optr oself, dword position);
extern void 	HotSpotArraySetType(optr oself, dword position, 
				    GraphicType type);
extern void     UpdateHotSpotArray(optr oself, 
                                   VisTextReplaceParameters *params,
				   Boolean flag);
extern word 	GetEmbeddedGraphicForHotSpot(optr oself, word token, 
					     dword *position, 
					     VisTextGraphic *graphic);
extern void    	GetEmbeddedGraphicOffset(optr oself, word token, 
					 PointDWFixed *offset);

extern VMFileHandle GetVMFile(optr oself);
extern void 	MakeIntegerEven(PointDWFixed *point);
extern void 	RoundOffFractionalPart(PointDWFixed *point);
extern void 	RedrawHotSpots(optr oself);

#if ERROR_CHECK
void ECCheckHotSpotArray(optr oself);
#endif

#endif
