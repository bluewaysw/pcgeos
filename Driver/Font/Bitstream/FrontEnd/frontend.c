/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	FrontEnd/frontend.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: frontend.c,v 1.1 97/04/18 11:45:06 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("FrontEndCode")

/*****************************************************************************
*                                                                            *
*  Copyright 1992, as an unpublished work by Bitstream Inc., Cambridge, MA   *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/
/***************************** FRONTEND. C ***********************************
 * This is the front end processor for Four-In-One                           *
 *
 * Revision 2.19  93/03/15  13:54:58  roberte
 * Release
 * 
 * Revision 2.14  93/03/01  11:02:44  roberte
 * Added hooks to MsltoIndex() under compile time option HAVE_MSL2INDEX.
 * 
 * Revision 2.13  93/02/23  16:56:31  roberte
 * Added #include of finfotbl.h before #include of ufe.h.
 * 
 * Revision 2.12  93/02/19  12:20:48  roberte
 * Added optimization to speed up BuildSorted list function.  The resident fonts
 * are in sorted order, so optimized on that.  The function will switch itself into
 * more rigorous and slow merge sort mode if it detects an element out of sort order.
 * 
 * Revision 2.11  93/02/08  16:15:18  roberte
 * Added stuff for bounding box functions for TrueType and Type1.
 * Changed locally prototyped functions to use PROTO macro.
 * 
 * Revision 2.10  93/01/29  08:55:19  roberte
 * Added reentrant code macros PARAMS1 and PARAMS2 to support REENTRANT_ALLOC. 
 * 
 * Revision 2.9  93/01/06  13:46:32  roberte
 * Changed references to processor_type, gCharProtocol, gDestProtocol, gMustTranslate, gCurrentSymbolsSet, numChars
 * and gSortedBCIDList.  These are now a part of sp_globals.
 * 
 * Revision 2.8  93/01/04  17:35:23  roberte
 * Changed stray read_word_u to sp_read_word_u and report_error to sp_report_error.
 * 
 * Revision 2.7  93/01/04  17:18:40  laurar
 * put WDECL in front of f_get_char_width.
 * change read_word_u() to sp_read_word_u().
 * 
 * Revision 2.6  93/01/04  16:56:50  roberte
 * Changed all references to new union fields of SPEEDO_GLOBALS to sp_globals.processor.speedo prefix.
 * 
 * Revision 2.5  92/12/29  14:28:53  roberte
 * Some prototypes moved to ufe.h, support for not PROTOS_AVAIL addressed.
 * 
 * Revision 2.4  92/12/15  13:34:53  roberte
 * Changed all prototype function declarations to
 * standard function declarations ala K&R.
 * 
 * Revision 2.3  92/12/09  16:39:32  laurar
 * add STACKFAR to pointers.
 * 
 * Revision 2.2  92/12/02  12:29:16  laurar
 * call report_error instead of sp_report_error;
 * fi_reset initializes the callback structure for the Windows DLL.
 * 
 * Revision 2.1  92/11/24  17:18:44  laurar
 * include fino.h
 * 
 * Revision 2.0  92/11/19  15:39:15  roberte
 * Release
 * 
 * Revision 1.23  92/11/18  18:50:08  laurar
 * Add RESTRICTED_ENVIRON functions again.
 * 
 * Revision 1.22  92/11/17  15:47:29  laurar
 * Add function definitions for RESTRICTED_ENVIRON.
 * 
 * Revision 1.21  92/11/12  16:51:05  roberte
 * Corrected sort indexing problem in BCIDtoIndex for new code.
 * 
 * Revision 1.20  92/11/04  09:22:25  roberte
 * Added support for non BCID sorted speedo files.  Now builds a sorted
 * BSearch list at fi_set_specs() when sp_globals.gCharProtocol != protoDirectIndex.
 * 
 * Revision 1.19  92/11/03  13:54:32  laurar
 * Include type1.h for CHARACTERNAME declaration.
 * 
 * Revision 1.18  92/11/03  12:24:00  roberte
 * Added support for tr_get_char_width() returning a real.
 * Converts it to fix31 units of 65536ths of an em for
 * consistency with other processors.
 * 
 * 
 * Revision 1.17  92/11/02  18:30:33  laurar
 * Add WDECL for Windows CALLBACK function declaration (for the DLL), it is contained in a macro called WDECL;
 * add STACKFAR for parameters that are pointers (also for DLL).
 * 
 * Revision 1.15  92/10/21  10:16:08  roberte
 * Improved logic of direct indexing and error catching for protoDirectIndex
 * for TRUETYPE and TYPE1 processors. Added new error code, 5001, for
 * direct indexing unsupported.  TrueType now able to support both
 * direct indexing and Glyphcode indexing, dependant on compile time
 * option GLYPH_INDEX.
 * 
 * Revision 1.14  92/10/20  17:13:01  roberte
 * Removed calls to CanonicalToFileIndex() if sp_globals.gDestProtocol==protoUnicode.
 * Adjusted CanonicalToFileIndex() to NOT have a case for protoUnicode.
 * Reflects cahnge to 4sample.c, now calls tt_make_char instead tt_make_char_idx.
 * This allows full support for Unicode glyph codes!!!
 * 
 * Revision 1.13  92/10/19  13:03:32  roberte
 * Removed bogus way of getting bitmap width.
 * 
 * Revision 1.12  92/10/16  15:19:35  roberte
 * Added possibly temporary function rf_get_bitmap_width() for
 * support of proofing accuracy.  May need permanent, and better
 * support of getting accurate pixel width.
 * 
 * Revision 1.11  92/10/15  17:35:46  roberte
 * Added support for PROTOS_AVAIL compile time option. Also changed test used
 * before calling CanonicalToFileIndex().  Now tests input protocol NOT
 * one of the direct indexing modes, and destination protocol NOT PSName.
 * 
 * Revision 1.10  92/10/14  13:18:33  roberte
 * Updated all calls to CanonicalToFileIndex() to copy value to translate
 * into a local, so the calls won't change value passed in as parameter.
 * 
 * Revision 1.9  92/09/29  14:11:03  weili
 * moved the preprocessor directives into ufe.h
 * 
 * Revision 1.8  92/09/28  19:12:02  weili
 * separated the font processors with preprocessor directives
 * 
 * Revision 1.7  92/09/26  15:29:14  roberte
 * Added copyright header and RCS marker. Prettied up
 * code and added comments.  Corrected casting to silence
 * compiler warnings.  Moved the setting of sp_globals.numChars
 * to the fi_reset() function, so these won't be repeatedly set
 * on each character translation in BCIDtoIndex().
 * 
 *
 *
 *                                                                           *
 *****************************************************************************/

#include "spdo_prv.h"               /* General definitions for Speedo    */
#include "fino.h"
#include "type1.h"
#include "finfotbl.h"
#include "ufe.h"					/* Unified Front End definitions */

#ifdef __GEOS__
#if PROC_TRUETYPE || PROC_TYPE1
/*****************************************************************************/
#include <Ansi/stdlib.h>
#include <geode.h>

#define NUM_SAVE_MALLOC 20
void* saveMalloc[NUM_SAVE_MALLOC];

void InitSaveMalloc()
{
    int i;
    for (i=0; i<NUM_SAVE_MALLOC; i++) {
	saveMalloc[i] = NULL;
    }
}

void* Malloc(blockSize)
word blockSize;
{
    return (_Malloc(blockSize, GeodeGetCodeProcessHandle(), TRUE));
}
void* MallocAndSave(blockSize)
word blockSize;
{
    void* foo;
    int i;
    foo = Malloc(blockSize);
    /* okay to save even if error and foo = NULL */
    if (PtrToOffset(foo) != 2) return(foo);
    for (i=0; i<NUM_SAVE_MALLOC; i++) {
       if (saveMalloc[i] == NULL) {
	    saveMalloc[i] = foo;
	    break;
	}
    }
#if ERROR_CHECK
    if (i==NUM_SAVE_MALLOC) FatalError(-1);
#endif
    return(foo);
}

void Free(blockPtr)
void *blockPtr;
{
    _Free(blockPtr, GeodeGetCodeProcessHandle());
}
void FreeAndSave(blockPtr)
void *blockPtr;
{
    int i;
    for (i=0; i<NUM_SAVE_MALLOC; i++) {
        if (SegmentOf(saveMalloc[i]) == SegmentOf(blockPtr)) {
	    saveMalloc[i] = NULL;
	    break;
	}
    }
    Free(blockPtr);
}

void FreeSaveMalloc()
{
    int i;
    for (i=0; i<NUM_SAVE_MALLOC; i++) {
	if (saveMalloc[i] != NULL) {
	    _Free(saveMalloc[i], GeodeGetCodeProcessHandle());
	    saveMalloc[i] = NULL;
	}
    }
}
/*****************************************************************************/
#endif
#endif

/***** GLOBAL VARIABLES *****/

/*****  GLOBAL FUNCTIONS *****/
#if	WINDOWS_4IN1
callback_struct      callback_ptrs;
#endif

/***** EXTERNAL VARIABLES *****/

/***** EXTERNAL FUNCTIONS *****/

/***** STATIC VARIABLES *****/

/***** STATIC FUNCTIONS *****/
static boolean DoTranslate PROTO((PROTO_DECL2 void STACKFAR *char_id, ufix16 STACKFAR *intPtr, char STACKFAR *strPtr));
static boolean BCIDtoIndex PROTO((PROTO_DECL2 ufix16 STACKFAR *intPtr));
static boolean CanonicalToFileIndex PROTO((PROTO_DECL2 ufix16 STACKFAR *intPtr));
static void BuildSortedSpeedoIDList PROTO((PARAMS1));
#if RESTRICTED_ENVIRON
boolean get_any_char_bbox PROTO((PARAMS2 ufix8 STACKFAR*font_ptr,void STACKFAR *char_id, bbox_t *bbox, boolean type1));
#else
boolean get_any_char_bbox PROTO((PARAMS2 void STACKFAR *char_id, bbox_t *bbox, boolean type1));
#endif

/*****************************************************************************
 * fi_reset()
 *   Initialize the processors
 *
 ****************************************************************************/

#if WINDOWS_4IN1
FUNCTION void  WDECL fi_reset(PARAMS2 fcn_ptrs, protocol, f_type)
GDECL
callback_struct   STACKFAR*fcn_ptrs;
#else
FUNCTION void  fi_reset(PARAMS2 protocol, f_type)
GDECL
#endif
eFontProtocol protocol;	/* protocol of character selection */
eFontProcessor f_type;	/* font processor selected */
{
	sp_globals.processor_type = f_type;
	sp_globals.gCharProtocol = protocol;

#if   WINDOWS_4IN1
   /* initialize pointers to callback functions. */
   callback_ptrs.sp_report_error = fcn_ptrs->sp_report_error;
   callback_ptrs.sp_open_bitmap = fcn_ptrs->sp_open_bitmap;
   callback_ptrs.sp_set_bitmap_bits = fcn_ptrs->sp_set_bitmap_bits;
   callback_ptrs.sp_close_bitmap = fcn_ptrs->sp_close_bitmap;
   callback_ptrs.sp_load_char_data = fcn_ptrs->sp_load_char_data;
   callback_ptrs.get_byte = fcn_ptrs->get_byte;
   callback_ptrs.dynamic_load = fcn_ptrs->dynamic_load;
#endif

	switch (sp_globals.processor_type) {
	case procSpeedo:
	    sp_reset(PARAMS1); 
		sp_globals.gDestProtocol = protoBCID;
		/* canonical to canonical ? */
		sp_globals.gMustTranslate = 	(
							(sp_globals.gCharProtocol == protoMSL) ||
							(sp_globals.gCharProtocol == protoUnicode) ||
							(sp_globals.gCharProtocol == protoPSName) ||
							(sp_globals.gCharProtocol == protoUser)
							);
		break;  

#if PROC_PCL
	case procPCL:   /* there is no reset for hpreader */
		sp_globals.gDestProtocol = protoMSL;
		/* canonical to canonical ? */
		sp_globals.gMustTranslate = 	(
							(sp_globals.gCharProtocol == protoBCID) ||
							(sp_globals.gCharProtocol == protoUnicode) ||
							(sp_globals.gCharProtocol == protoPSName) ||
							(sp_globals.gCharProtocol == protoUser)
							);
		break;  
#endif

#if PROC_TYPE1
	case procType1:
	    tr_init(PARAMS1); 
		sp_globals.gDestProtocol = protoPSName;
		/* canonical to canonical ? */
		sp_globals.gMustTranslate = 	(
							(sp_globals.gCharProtocol == protoMSL) ||
							(sp_globals.gCharProtocol == protoUnicode) ||
							(sp_globals.gCharProtocol == protoBCID) ||
							(sp_globals.gCharProtocol == protoUser)
							);
		break;  
#endif

#if PROC_TRUETYPE
	case procTrueType:
	    tt_reset(PARAMS1); 
		sp_globals.gDestProtocol = protoUnicode;
		/* canonical to canonical ? */
		sp_globals.gMustTranslate = 	(
							(sp_globals.gCharProtocol == protoMSL) ||
							(sp_globals.gCharProtocol == protoBCID) ||
							(sp_globals.gCharProtocol == protoPSName) ||
							(sp_globals.gCharProtocol == protoUser)
							);
		break;  
#endif

	default:
		/*  shouldn't get here unless bad processor type selected */
	   sp_report_error (PARAMS2 5000);
		break;
	}

	return;
}	/* end fi_reset() */


/*****************************************************************************
 * fi_make_char()
 *   Call the character generator for this font type
 *
 ****************************************************************************/

#if RESTRICTED_ENVIRON
FUNCTION boolean WDECL fi_make_char(PARAMS2 font_ptr, char_id)
GDECL
ufix8 STACKFAR *font_ptr;
void STACKFAR *char_id;
#else
FUNCTION boolean WDECL fi_make_char(PARAMS2 char_id)
GDECL
void STACKFAR *char_id;
#endif
{
char STACKFAR *strPtr, strBuffer[32];
ufix16 STACKFAR *intPtr, translatedValue;
boolean return_value = FALSE;	/* assume failure */

	intPtr = (ufix16 STACKFAR *)char_id;
	strPtr = (char STACKFAR *)char_id;
	if (sp_globals.gMustTranslate || (sp_globals.gCharProtocol == protoSymSet) || (sp_globals.gCharProtocol == protoPSEncode) )
		{/* do any and all translations */
		intPtr = (ufix16 STACKFAR *)&translatedValue;
		strPtr = (char STACKFAR *)strBuffer;
		if (!DoTranslate(PARAMS2 char_id, intPtr, strPtr))
			return(return_value); /* already FALSE */
		}
	if ( (sp_globals.gDestProtocol == protoBCID) || (sp_globals.gDestProtocol == protoMSL)
				|| (sp_globals.gDestProtocol == protoUser) )
		{
		translatedValue = *intPtr;
		intPtr = &translatedValue;
		if (!CanonicalToFileIndex(PARAMS2 intPtr))
			return(return_value); /* already FALSE */
		}

	switch (sp_globals.processor_type) {
	case procSpeedo:
		return_value = sp_make_char(PARAMS2 *intPtr);
		break;  
#if PROC_PCL
	case procPCL:
	    return_value = eo_make_char(PARAMS2 *intPtr); 
		break;
#endif

#if PROC_TYPE1
	case procType1:
#if RESTRICTED_ENVIRON
	    return_value = tr_make_char(PARAMS2 font_ptr,strPtr);
#else
	    return_value = tr_make_char(PARAMS2 strPtr);
#endif
		break;  
#endif

#if PROC_TRUETYPE
	case procTrueType:
		if (sp_globals.gCharProtocol == protoDirectIndex)
	    	return_value = tt_make_char_idx(PARAMS2 *intPtr); 
		else
	    	return_value = tt_make_char(PARAMS2 *intPtr); 
		break;  
#endif

	default:
		/*  shouldn't get here unless bad processor type selected */
		sp_report_error (PARAMS2 5000);
		/* return_value already set to FALSE */
		break;
	}
	return(return_value);
}	/* end fi_make_char() */

/****************************************************************************
 *	fi_set_specs()
 *		set parameters for the next character
 ****************************************************************************/

FUNCTION boolean WDECL fi_set_specs(PARAMS2 pspecs)
GDECL
ufe_struct STACKFAR *pspecs;
{
	boolean success = FALSE;

	switch (sp_globals.processor_type) {
	case procSpeedo:
		success = sp_set_specs(PARAMS2 pspecs->Gen_specs);
		if (success)
			{/* set up these statics for BSearching */
			sp_globals.numChars = sp_read_word_u(PARAMS2 sp_globals.processor.speedo.font_org + FH_NCHRL);
			if (sp_globals.gCharProtocol != protoDirectIndex)
				BuildSortedSpeedoIDList(PARAMS1);
			}
        break;

#if PROC_PCL
    case procPCL:
		success = eo_set_specs(PARAMS2 pspecs->Gen_specs);
#ifdef HAVE_MSL2INDEX
		/* Enable if YOU write this function !!!  */
		if (success)
			{/* set up these statics for BSearching */
			if (sp_globals.gCharProtocol != protoDirectIndex)
				BuildSortedMSLIDList();
			}
#endif
        break;
#endif

#if PROC_TYPE1
    case procType1:
		if (sp_globals.gCharProtocol != protoDirectIndex)
			success = tr_set_specs(PARAMS2	pspecs->Gen_specs->flags,
								(real STACKFAR*)pspecs->Matrix,
								(ufix8 STACKFAR*)pspecs->Font.org);
		/* else success is FALSE, direct indexing
			unsupported for Type1 processor */
		else
        	sp_report_error (PARAMS2 5001);
        break;
#endif

#if PROC_TRUETYPE
    case procTrueType:
		success = tt_set_specs(PARAMS2 pspecs->Gen_specs);
        break;
#endif

    default:
        /*  shouldn't get here unless bad processor type selected */
        sp_report_error (PARAMS2 5000);
        break;
    } /* end switch(sp_globals.processor_type) */

	return success;
} /* end fi_set_specs() */

/****************************************************************************
 *	fi_get_char_width()
 *		using the current font, return the requested character's width
 ****************************************************************************/

#if RESTRICTED_ENVIRON
FUNCTION fix31 WDECL fi_get_char_width(PARAMS2 font_ptr, *char_id)
GDECL
ufix8 STACKFAR *font_ptr;
void STACKFAR *char_id;
#else
FUNCTION fix31 WDECL fi_get_char_width(PARAMS2 char_id)
GDECL
void STACKFAR *char_id;
#endif
{
	fix31 char_width = 0; /* assume no width */
	ufix16 STACKFAR*intPtr, translatedValue;
	char STACKFAR*strPtr, strBuffer[32];
#if PROC_TYPE1
	real tr_width;
#endif

	intPtr = (ufix16 STACKFAR*)char_id;
	strPtr = (char STACKFAR*)char_id;
	if (sp_globals.gMustTranslate || (sp_globals.gCharProtocol == protoSymSet) || (sp_globals.gCharProtocol == protoPSEncode) )
		{/* do any and all translations */
		intPtr = &translatedValue;
		strPtr = strBuffer;
		if (!DoTranslate(PARAMS2 char_id, intPtr, strPtr))
			return(char_width); /* already 0 */
		}
	if ( (sp_globals.gDestProtocol == protoBCID) || (sp_globals.gDestProtocol == protoMSL)
				|| (sp_globals.gDestProtocol == protoUser) )
		{
		translatedValue = *intPtr;
		intPtr = &translatedValue;
		if (!CanonicalToFileIndex(PARAMS2 intPtr))
			return(char_width); /* already 0 */
		}

	switch (sp_globals.processor_type) {
	case procSpeedo:
		char_width = sp_get_char_width(PARAMS2 *intPtr);
        break;

#if PROC_PCL
    case procPCL:
		char_width = eo_get_char_width(PARAMS2 *intPtr);
        break;
#endif

#if PROC_TYPE1
    case procType1:
#if RESTRICTED_ENVIRON
		tr_width = tr_get_char_width(PARAMS2 font_ptr, strPtr);
#else
		tr_width = tr_get_char_width(PARAMS2 strPtr);
#endif
		char_width = (fix31)(tr_width * (real)65536.0);
        break;
#endif

#if PROC_TRUETYPE
    case procTrueType:
		if (sp_globals.gCharProtocol == protoDirectIndex)
	    	char_width = tt_get_char_width_idx(PARAMS2 *intPtr); 
		else
			char_width = tt_get_char_width(PARAMS2 *intPtr);
        break;
#endif

    default:
        /*  shouldn't get here unless bad processor type selected */
        sp_report_error (PARAMS2 5000);
		/* char_width already set to 0 */
		break;
    } /* end switch(sp_globals.processor_type) */

	return char_width;
}	/* end fi_get_char_width() */

/*****************************************************************************
 *	fi_get_char_bbox()
 *		using the current font, return the bounding box of the requested
 *		character
 ****************************************************************************/

#if RESTRICTED_ENVIRON
FUNCTION boolean fi_get_char_bbox(PARAMS2 font_ptr, char_id, bounding_box)
GDECL
ufix8 STACKFAR *font_ptr;
void *char_id;
bbox_t *bounding_box;
#else
FUNCTION boolean fi_get_char_bbox(PARAMS2 char_id, bounding_box)
GDECL
void *char_id;
bbox_t *bounding_box;
#endif
{
boolean return_value = FALSE; /* assume failure */
	ufix16 STACKFAR*intPtr, translatedValue;
	char STACKFAR*strPtr, strBuffer[32];


	intPtr = (ufix16 STACKFAR*)char_id;
	strPtr = (char STACKFAR*)char_id;
	if (sp_globals.gMustTranslate || (sp_globals.gCharProtocol == protoSymSet) || (sp_globals.gCharProtocol == protoPSEncode) )
		{ /* do any and all translations */
		intPtr = (ufix16 STACKFAR*)&translatedValue;
		strPtr = (char STACKFAR*)strBuffer;
		if (!DoTranslate(PARAMS2 char_id, intPtr, strPtr))
			return(return_value); /* already FALSE */
		}
	if ( (sp_globals.gDestProtocol == protoBCID) || (sp_globals.gDestProtocol == protoMSL)
				|| (sp_globals.gDestProtocol == protoUser) )
		{
		translatedValue = *intPtr;
		intPtr = (ufix16 STACKFAR*)&translatedValue;
		if (!CanonicalToFileIndex(PARAMS2 intPtr))
			return(return_value); /* already FALSE */
		}
		
	switch (sp_globals.processor_type) {
	case procSpeedo:
		return_value = sp_get_char_bbox(PARAMS2 *intPtr, bounding_box);
        break;

#if PROC_PCL
    case procPCL:
		return_value = eo_get_char_bbox(PARAMS2 *intPtr, bounding_box);
        break;
#endif

#if PROC_TYPE1
    case procType1:
#if RESTRICTED_ENVIRON
		return_value = get_any_char_bbox(PARAMS2 font_ptr, strPtr, bounding_box, TRUE);
#else
		return_value = get_any_char_bbox(PARAMS2 strPtr, bounding_box, TRUE);
#endif
        break;
#endif

#if PROC_TRUETYPE
    case procTrueType:
#if RESTRICTED_ENVIRON
		return_value = get_any_char_bbox(PARAMS2 font_ptr, intPtr, bounding_box, FALSE);
#else
		return_value = get_any_char_bbox(PARAMS2 intPtr, bounding_box, FALSE);
#endif
        break;
#endif

    default:
        /*  shouldn't get here unless bad processor type selected */
        sp_report_error (PARAMS2 5000);
		/* return_value already == FALSE */
    } /* end switch(sp_globals.processor_type) */

	return return_value;
}	/* end fi_get_char_bbox() */

#pragma Code ()

#pragma Code ("ConvertCode")

/*****************************************************************************
 * DoTranslate()
 *   Master character translation wrap-around.  Calls fi_CharCodeXLate()
 *	Handles also symbol-set protocol, doing lookup in sp_globals.gCurrentSymbolSet[]
 *
 ****************************************************************************/
FUNCTION static boolean DoTranslate(PARAMS2 char_id, intPtr, strPtr)
GDECL
void STACKFAR *char_id;
ufix16 STACKFAR *intPtr;
char STACKFAR *strPtr;
{
ufix16 STACKFAR *iPtr;
boolean return_value = FALSE; /* assume the worst */
	if (sp_globals.gMustTranslate)
		{/* this was set in fi_reset() */
		/* this means canonical to canonical */
		return_value = fi_CharCodeXLate  (char_id,
								(sp_globals.gDestProtocol == protoPSName) ?
								(void STACKFAR *)strPtr : (void STACKFAR *)intPtr,
								sp_globals.gCharProtocol, sp_globals.gDestProtocol);
		}
	else /* if ( (sp_globals.gCharProtocol == protoSymSet) || (sp_globals.gCharProtocol == protoPSEncode) ) */
		{/* this means symbol set lookup, then BCID to canonical */
		iPtr = (ufix16 STACKFAR *)char_id;
		if ( (*intPtr = sp_globals.gCurrentSymbolSet[*iPtr]) == UNKNOWN)
			return(return_value); /* already FALSE */
		return_value = fi_CharCodeXLate  ((void STACKFAR *)intPtr,
								(sp_globals.gDestProtocol == protoPSName) ?
									(void STACKFAR *)strPtr : (void STACKFAR *)intPtr,
								protoBCID, sp_globals.gDestProtocol);
		}
	return(return_value);
}

#pragma Code ()

#pragma Code ("FrontEndCode")

/*****************************************************************************
 * CanonicalToFileIndex()
 *   Convert input varible parameter <some canonical ID> -> actual file index
 *
 ****************************************************************************/
FUNCTION static boolean CanonicalToFileIndex(PARAMS2 intPtr)
GDECL
ufix16 STACKFAR *intPtr;
{
boolean return_value = FALSE;

	if (sp_globals.gCharProtocol != protoDirectIndex)
		{
		switch(sp_globals.gDestProtocol)
			{
			case protoBCID:
				return_value = BCIDtoIndex(PARAMS2 intPtr);
				break;
			case protoMSL:
#ifdef HAVE_MSL2INDEX
				/* Enable if YOU write this function !!!  */
				return_value = MSLtoIndex(PARAMS2 intPtr);
#endif
				break;
			case protoUser:
				/* !!! Enable when YOU write this function !!!
				return_value = UsertoIndex(PARAMS2 intPtr);
				*/
				break;
			default:
				/* already set to FALSE, above
				return_value = FALSE;
				*/
				break;
			}
		}
	else
		return_value = TRUE; /* direct, no translation */
	return(return_value);
}

#pragma Code ()

#pragma Code ("ConvertCode")

/*****************************************************************************
 * BCIDCompare()
 *   Comparison function for BSearch when called by BCIDtoIndex()
 *		(relies upon sp_globals.processor.speedo.first_char_idx having already been set)
 *	RETURNS:	result of NumComp() (-1, 0 or 1 like strcmp())
 *
 ****************************************************************************/
FUNCTION fix15    BCIDCompare (PARAMS2 idx, keyValue)
GDECL
fix31 idx;
void STACKFAR *keyValue;
{
fix15 NumComp(), result;
ufix16 theBCID;
	theBCID = sp_globals.gSortedBCIDList[idx].charID;
	result = NumComp( (ufix16 STACKFAR *)keyValue, (ufix16 STACKFAR*)&theBCID);
	return(result);
}

/*****************************************************************************
 * BCIDtoIndex()
 *   Convert input varible parameter BCID -> Speedo file index
 *		(relies upon sp_globals.processor.speedo.first_char_idx and sp_globals.numChars having already been set)
 *	 Calls BSearch()
 *	RETURNS:	TRUE on success, FALSE, failure.
 *
 ****************************************************************************/
FUNCTION static boolean BCIDtoIndex(PARAMS2 intPtr)
GDECL
ufix16 STACKFAR *intPtr;
{
ufix16 outValue;
boolean success = FALSE;
	outValue = 0;
	success = BSearch (PARAMS2  (fix15 STACKFAR*)&outValue, BCIDCompare,
						(void STACKFAR *)intPtr, (fix31)sp_globals.numChars );
	if (success)
		*intPtr = sp_globals.gSortedBCIDList[outValue].fileIndex;
	return(success);
}

/*****************************************************************************
 * BuildSortedSpeedoIDList()
 *   
 *
 *
 *	RETURNS:	nothing
 *
 ****************************************************************************/
FUNCTION static void BuildSortedSpeedoIDList(PARAMS1)
GDECL
{
fix15 i, j, k, theSlot, numAdded;
ufix16 theBCID, oldBCID = 0;
boolean found, rigorous;
	rigorous = FALSE;
	sp_globals.gSortedBCIDList[0].charID = 0xffff;	/* the highest possible value */
	numAdded = 0;
	/* sp_globals.numChars holds # glyphs in speedo font */
	for (i=0; i < sp_globals.numChars; i++, numAdded++)
		{
		theBCID = sp_get_char_id(PARAMS2 sp_globals.processor.speedo.first_char_idx + i);
		/* now find a home for it in the list: */
		theSlot = numAdded;
		if (!rigorous && theBCID < oldBCID)
			rigorous = TRUE;
		if (rigorous)
			{
			found = FALSE;
			for (j=0; !found && (j < numAdded); j++)
				{
				if (sp_globals.gSortedBCIDList[j].charID > theBCID)
					{/* put it here */
					theSlot = j;
					found = TRUE;
					}
				}
			/* move up all items from theSlot to numAdded by 1 */
			for (k = numAdded; k > theSlot; k--)
				sp_globals.gSortedBCIDList[k] = sp_globals.gSortedBCIDList[k-1];
			}

		/* drop new item in theSlot */
		sp_globals.gSortedBCIDList[theSlot].charID = theBCID;
		sp_globals.gSortedBCIDList[theSlot].fileIndex = i;
		oldBCID = theBCID;
		}
}

#pragma Code ()

#pragma Code ("FrontEndCode")

#if PROC_TRUETYPE | PROC_TYPE1
/* --------- Bounding Box functions for TrueType and Type1: ------------ */
typedef void (*PFV)();
typedef boolean (*PFVB)();

void bb_do_nothing();
boolean bb_its_true();

void bb_check_point();
void bb_begin_contour();
void bb_line();
void bb_curve();

#define BB_INFINITY	0x7FFF
static fix15 bb_xMin, bb_xMax, bb_yMin, bb_yMax;
static boolean bb_someCall;

#if RESTRICTED_ENVIRON
boolean get_any_char_bbox(PARAMS2 font_ptr, char_id, bbox, type1)
GDECL
ufix8 STACKFAR *font_ptr;
void *char_id;
bbox_t *bbox;
boolean type1;
#else
boolean get_any_char_bbox(PARAMS2 char_id, bbox, type1)
GDECL
void STACKFAR *char_id;
bbox_t *bbox;
boolean type1;
#endif
{
PFV sv_begin_sub_char, sv_begin_contour,
	sv_curve, sv_line, sv_end_contour, sv_end_sub_char;
PFVB sv_init_out, sv_begin_char,
	sv_end_char;
ufix16 STACKFAR *intPtr, translatedValue;
boolean success = FALSE;

	intPtr = char_id;

		/* save original function pointers: */
	sv_init_out					= sp_globals.init_out;
   	sv_begin_char				= sp_globals.begin_char;
   	sv_begin_sub_char			= sp_globals.begin_sub_char;
   	sv_begin_contour			= sp_globals.begin_contour;
   	sv_curve					= sp_globals.curve;
   	sv_line						= sp_globals.line;
   	sv_end_contour				= sp_globals.end_contour;
   	sv_end_sub_char				= sp_globals.end_sub_char;
   	sv_end_char					= sp_globals.end_char;
	/* substitute our function pointers: */
	sp_globals.init_out			= bb_its_true;
   	sp_globals.begin_char		= bb_its_true;
   	sp_globals.begin_sub_char	= bb_do_nothing;
   	sp_globals.begin_contour	= bb_begin_contour;
   	sp_globals.curve			= bb_curve;
   	sp_globals.line				= bb_line;
   	sp_globals.end_contour		= bb_do_nothing;
   	sp_globals.end_sub_char		= bb_do_nothing;
   	sp_globals.end_char			= bb_its_true;

	/* initialize bb_ max/min variables: */
	bb_xMax = -BB_INFINITY;
	bb_xMin = BB_INFINITY;
	bb_yMax = -BB_INFINITY;
	bb_yMin = BB_INFINITY;
	bb_someCall = FALSE;
	bbox->xmin  = (fix31)0;
	bbox->xmax  = (fix31)0;
	bbox->ymin  = (fix31)0;
	bbox->ymax  = (fix31)0;


	/* do the voo-doo: */
#if PROC_TYPE1
	if (type1)
		{
#if RESTRICTED_ENVIRON
	    success = tr_make_char(PARAMS2 font_ptr,char_id);
#else
	    success = tr_make_char(PARAMS2 char_id);
#endif
		}
#endif
#if PROC_TRUETYPE
	if (!type1)
		{/* must be TrueType */
		if (sp_globals.gCharProtocol == protoDirectIndex)
	    	success = tt_make_char_idx(PARAMS2 *intPtr); 
		else
	    	success = tt_make_char(PARAMS2 *intPtr); 
		}
#endif

	/* restore original function pointers: */
	sp_globals.init_out			= sv_init_out;
   	sp_globals.begin_char		= sv_begin_char;
   	sp_globals.begin_sub_char	= sv_begin_sub_char;
   	sp_globals.begin_contour	= sv_begin_contour;
   	sp_globals.curve			= sv_curve;
   	sp_globals.line				= sv_line;
   	sp_globals.end_contour		= sv_end_contour;
   	sp_globals.end_sub_char		= sv_end_sub_char;
   	sp_globals.end_char			= sv_end_char;

	if (bb_someCall)
		{
#ifdef D_BBOX
		if 
			(
			(sp_globals.bmap_xmax != bb_xMax) ||
			(sp_globals.bmap_xmin != bb_xMin) ||
			(sp_globals.bmap_ymax != bb_yMax) ||
			(sp_globals.bmap_ymin != bb_yMin) 
			)
			printf("Different bitmap coords! ");
#endif
		bbox->xmin  = (fix31)bb_xMin << sp_globals.poshift;
		bbox->xmax  = (fix31)bb_xMax << sp_globals.poshift;
		bbox->ymin  = (fix31)bb_yMin << sp_globals.poshift;
		bbox->ymax  = (fix31)bb_yMax << sp_globals.poshift;
		}
	return success;
}



/* --------------- the BUSINESS functions ------------ */

void bb_check_point(P1)
point_t P1;
{
	/* check P1 x and y against current extremes: */
	if (P1.x < bb_xMin)
		bb_xMin = P1.x;
	if (P1.x > bb_xMax)
		bb_xMax = P1.x;

	if (P1.y < bb_yMin)
		bb_yMin = P1.y;
	if (P1.y > bb_yMax)
		bb_yMax = P1.y;
	bb_someCall = TRUE; /* show something was checked */
}

void bb_begin_contour(PARAMS2 P1, outside)
GDECL
point_t P1;       /* Start point of contour */            
boolean outside;  /* TRUE if outside (counter-clockwise) contour */
{
	bb_check_point(P1);
}

void bb_line(PARAMS2 P1)
GDECL
point_t P1;      /* End point of vector */             
{
	bb_check_point(P1);
}

void bb_curve(PARAMS2 P1, P2, P3, depth)
GDECL
point_t P1;      /* First control point of Bezier curve */
point_t P2;      /* Second control point of Bezier curve */
point_t P3;      /* End point of Bezier curve */
fix15 depth;
{
	/* bb_check_point(P1); */
	/* bb_check_point(P2); */
	bb_check_point(P3);
}


/* ---------------- the NOP functions ---------------- */
boolean bb_its_true()
{
	/* everything went splendidly! */
	return TRUE;
}

void bb_do_nothing()
{
	/* retired- no variables, no code */
}


#endif /* PROC_TRUETYPE | PROC_TYPE1 */


/* EOF: frontend.c */

#pragma Code ()
