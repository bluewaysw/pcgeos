/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	HWR Library
 * FILE:	hwr.h
 *
 *
 * REVISION HISTORY:
 *	
 *	Name	Date		Description
 *	----	----		-----------
 *	atw	9/16/92		Initial revision
 *
 *
 * DESCRIPTION:
 *	Contains exported routines/structures for the HWR library.
 *		
 *	$Id: hwr.h,v 1.1 97/04/04 15:57:14 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__HWR_H
#define	__HWR_H

/* Include "graphics.h" for definition of Rectangle */
#include <graphics.h>

/***********************************************************************
 * HWR Library Protocol
 ***********************************************************************/
/*
 * All hwr libraries will need to have the following line in their
 * local.mk file:
 *	PROTOCONST	= HWRLIB
 */

#define HWRLIB_PROTO_MAJOR 2
#define HWRLIB_PROTO_MINOR 0
#define HWRLIB_PROTO_MAJOR_FOR_2_1 2

#define HWR_NUMBER_RESERVED_ENTRIES 16
/*
 * This is the number of library entry points reserved for future HWR Library
 * routines defined for geos.
 *
 * A HWR Library should use skip until HWRR_LAST_RESERVED_ENTRY in its
 * .gp file between the exported routines defined for geos, and any
 * exported routines specific to that Library.
 */

#ifdef DBCS_PCGEOS
#define HWR_STRING_ESCAPE_VALUE	0xee01
#else
#define HWR_STRING_ESCAPE_VALUE 0xff01
#endif

typedef	enum {
    HWRR_BEGIN_INTERACTION,
    HWRR_END_INTERACTION,
/*
 *	Most HWR drivers can not handle multiple clients at once. Clients
 *	should call HWRR_BEGIN_INTERACTION before any other HWR calls, and
 *	HWRR_END_INTERACTION after their HWR calls.
 *
 *	NOTE: Assume that after you call HWRR_END_INTERACTION, all of the
 *	      parameters you've set up (points added, filters activated) will
 *	      be destroyed.
 *
 *	PROTOTYPES:
 *	    Boolean HWRBeginInteraction(void);
 *	    void HWREndInteraction(void);
 *
 *		 If HWRR_BEGIN_INTERACTION returns non-zero, do not call
 *		 HWRR_END_INTERACTION.
 */

    HWRR_RESET,
/*
 *	Resets the library in preparation of sending a new set of ink data
 *	to it. This nukes all old points, and re-enables the entire character
 *	set.
 *
 *	PROTOTYPE:
 *	    void HWRReset(void);
 */

    HWRR_DISABLE_CHAR_RANGE,
/*
 *	Disables the passed range of characters - this means that strokes
 *	will not be recognized as these characters.
 *
 *	PROTOTYPE:
 *	    void HWRDisableCharRange(wchar firstChar, wchar lastChar);
 */

    HWRR_ENABLE_CHAR_RANGE,
/*
 *	Enables the passed range of characters - this means that strokes
 *	can be recoginized by these characters.
 *
 *	PROTOTYPE:
 *	    void HWREnableCharRange(wchar firstChar, wchar lastChar);
 */

    HWRR_SET_CHAR_FILTER_CALLBACK,
/*    
 *
 *	Calls the passed callback routine with characters.
 *
 *	PROTOTYPE:
 *	    void HWRSetCharFilterCallback(HWRCharFilter *callback,
 *	    	    	    	    	  void *callbackData);
 *
 *	Callback should return character chosen (it does not necessarily have
 *	    to be one of the characters in the passed array)
 *	If none of the choices are satisfactory, it can return 0, which means
 *	    to ignore the character.
 */

    HWRR_SET_STRING_FILTER_CALLBACK,
/*
 *	This allows the application to specify his own filter routine on
 *	an entire word basis (as opposed to a char by char basis)
 *
 *	NOTE: If the app specifies a "WHOLE_WORD" filter callback, it should
 *	      not also specify a "CHAR_FILTER" callback, as the "CHAR_FILTER"
 *	      callback will not be called.
 *
 *	PROTOTYPE:
 *	    void HWRSetWholeWordFilterCallback(HWRStringFilter *callback,
 *	    	    	    	    	       void *callbackData);
 *
 *	Callback routine returns:
 *
 *		Handle of block containing null-terminated
 *		     ink data
 */


    HWRR_ADD_POINT,
/*
 *	This allows the application to add one point at a time to the list of
 *	points being collected and recognized
 *
 *	PROTOTYPE:
 *	   void HWRAddPoint (InkXCoord xCoord, sword yCoord, dword timeStamp);
 *
 *	The time stamp is normally passed as 0 (many HWR drivers will ignore
 * 	it in any case), but it can be passed as an actual value for
 *	certain real-time applications, such as signature verification)
 */

    HWRR_ADD_POINTS,
/*
 *	This adds a bunch of points at once. No time stamp information is
 *	passed - if you need to pass time stamp information, use HWRR_ADD_POINT
 *	instead.
 *
 *	PROTOTYPE:
 *	    void HWRAddPoints (word numPoints, InkPoint *points);
 */

    HWRR_DO_GESTURE_RECOGNITION,
/*
 *	Checks to see if the points are a single gesture.
 *
 *	PROTOTYPE:
 *	    GestureType HWRDoGestureRecognition(void);
 */

    HWRR_DO_SINGLE_CHAR_RECOGNITION,
/*
 *	This tries to recognize the ink input as a single character. This is
 *	useful in situations where you know that the input should be just one
 *	character.
 *
 *	PROTOTYPE:
 *	    wchar HWRDoSingleCharRecognition(void);
 *
 *	    Returns 0 if the ink wasn't recognized.
 */

    HWRR_DO_MULTIPLE_CHAR_RECOGNITION,
/*
 *	This returns a null-terminated string that was recognized from the
 *	input.
 *
 *	PROTOTYPE:
 *	    MemHandle HWRDoMultipleCharRecognition(InkPoint *);
 *
 *	    Returns handle of block containing null-terminated data
 */

    HWRR_GET_HWR_MANUF_ID,
/*
 *	Returns the manufacturer of the HWR. This may be useful if you want
 *	to call certain special features that only exist in certain drivers.
 *	(For example, if one was writing a signature verification application
 *	that required a specific HWR driver).
 *
 *	PROTOTYPE:
 *	    ManufacturerID HWRGetHWRManufID (void)
 */

    HWRR_SET_CONTEXT,
/*
 *	Puts the hwr engine in line/grid/boxed mode.
 *
 *	PROTOTYPE:
 *	    void HWRSetContext(HWRContext *context);
 */

    HWRR_SET_LANGUAGE,
/*
 *	Sets the default hwr language
 *
 *	PROTOTYPE:
 *	    void HWRSetLanguage(StandardLanguage language);
 */

/*
 *  The following functions were added for release 2.1 and later
 */

    HWRR_GET_GESTURE_BOUNDS,
/*
 *	Returns a handle to a rectangle structure which contains the
 *      bounds of the last gesture recognized
 *
 *	PROTOTYPE:
 *	    MemHandle HWRGetGestureBounds(void);
 */

    HWRR_RESET_MACRO,
/*
 *
 *      Tells the HWR library that the current macro in progress must
 *	be cleared. Returns a handle to a HWRStringMacro that will
 *	clean up anything displayed for the current macro
 *
 *      PROTOTYPE:
 *          MemHandle HWRResetMacro(void);
 */

    HWRR_GET_CHAR_BOUNDS,    
/*
 *      called from the custom char callback, returns a handle to a
 *      rectangle structure which contains the bounds of the last 
 *      character recognized.
 *
 *      PROTOTYPE:
 *          MemHandle HWRGetCharBounds(void);
 */


} HWRRoutine;

#define HWRR_LAST_RESERVED_ENTRY (HWRR_GET_CHAR_BOUNDS + HWR_NUMBER_RESERVED_ENTRIES)

typedef enum {    
	HM_NONE,
	/*
	 * The user is writing in a multi-line object - no guidelines
	 */

	HM_LINE,
	/*    
	 * The user has a reference line to write on
	 */

	HM_BOX,
	/*    
	 * The user has a box to write into
	 */

	HM_GRID
	/*    
	 * The user has a grid to write chars into (one char per box)
	 */
	
} HWRMode;

typedef	struct {
	HWRMode	HWRND_mode;
} HWRNoneData;

typedef	struct {
	HWRMode	    	HWRLD_mode;	
	sword	    	HWRLD_line;	
} HWRLineData;

typedef struct {
	HWRMode	    	HWRBD_mode;	
	sword	    	HWRBD_top;	
	sword	    	HWRBD_bottom;	
} HWRBoxData;

typedef	struct {
	HWRMode	    	HWRGD_mode;	
	Rectangle   	HWRGD_bounds;	
	/* Bounds of grid area (in same coords as ink data) */

	sword	    	HWRGD_xOffset;	
	sword	    	HWRGD_yOffset;	
	/* X/Y offsets between grid lines */
} HWRGridData;

typedef	union {
      	HWRNoneData 	HWRC_none;
	HWRLineData 	HWRC_lined;
	HWRBoxData	HWRC_boxed;	
	HWRGridData 	HWRC_grid;
} HWRContext;

typedef struct {
    	word	CCI_numChoices;
	/*
	 * The # choices for this character - note, this can be zero if the
	 * user entered a blob of ink that was not recognized, but was also
	 * parsed as being a separate character.
	 */
	
	word	CCI_firstPoint;
	/*
	 * Offset to the first point in the ink data corresponding to this char
	 */

	word	CCI_lastPoint;
	/* Offset to the last point in the ink data in this char */

	wchar    *CCI_data;
	/* Ptr to characters */

} CharChoiceInformation;

typedef wchar _pascal HWRCharFilter (word numChoices, word firstPoint, word lastPoint, wchar *charChoices, void *callbackData);   
typedef MemHandle _pascal HWRStringFilter (word numChars, CharChoiceInformation *data, void *callbackData);

typedef	WordFlags   InkXCoord;
#define IXC_TERMINATE_STROKE	0x8000

typedef struct {
	InkXCoord   	IP_x;	
	word	    	IP_y;	
} InkPoint;

typedef enum {
	GT_NO_GESTURE,
	GT_DELETE_SELECTION,
	GT_SELECT_CHARS,
	GT_V_CROSSOUT,
	GT_H_CROSSOUT,
	GT_BACKSPACE,
/*
 *  The following gesture types were added for release 2.1 and later
 */
	GT_CHAR,
	GT_STRING_MACRO,
	GT_IGNORE_GESTURE,
	GT_COPY,
	GT_PASTE,
	GT_CUT,
	GT_MODE_CHAR,
	GT_REPLACE_LAST_CHAR,
} GestureType;

typedef struct {
        word            HWRSM_deleteCount;
} HWRStringMacro;

typedef	ByteFlags   HWRLockState;
#define HWRLS_EQN_LOCK	0x04
#define HWRLS_NUM_LOCK	0x02
#define HWRLS_CAP_LOCK	0x01

typedef	ByteEnum    HWRTemporaryShiftState;
#define HWRTSS_NONE 0
#define	HWRTSS_PUNCTUATION  1
#define HWRTSS_EXTENDED	2
#define HWRTSS_CASE 3
#define HWRTSS_DOWNCASE 4

/*
 *	Macros to make it easier to call the HWR library
 */

#define	CallHWRLibrary_NoArgs(libHan, callType) (ProcCallFixedOrMovable_pascal (ProcGetLibraryEntry(libHan, callType)))

#define	CallHWRLibrary_OneArg(libHan, callType, arg) (ProcCallFixedOrMovable_pascal (arg, ProcGetLibraryEntry(libHan, callType)))

#define CallHWRLibrary_TwoArgs(libHan, callType, arg1, arg2) (ProcCallFixedOrMovable_pascal (arg1, arg2, ProcGetLibraryEntry(libHan, callType)))

#endif
