/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/tt_iface.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tt_iface.c,v 1.1 97/04/18 11:45:25 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTIfaceCode")

/*****************************************************************************
*                                                                            *
*  Copyright 1991,92 as an unpublished work by Bitstream Inc., Cambridge, MA *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/
/********************* Revision Control Information **************************
 *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/tt_iface.c,v 1.1 97/04/18 11:45:25 newdeal Exp $
*     $Log:	tt_iface.c,v $
 * Revision 1.1  97/04/18  11:45:25  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:58  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:16:45  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:24:03  roberte
 * Release
 * 
 * Revision 6.43  93/03/12  12:00:07  glennc
 * Make sure memoryBases 5, 6, and 7 are zero when opening
 * a new font.
 * 
 * Revision 6.42  93/03/12  11:26:10  glennc
 * Code cleanup for allocation/reallocation of memoryBases 5, 6
 * and 7 (bad structure of if statements caused problems).
 * 
 * Revision 6.41  93/03/11  15:51:19  roberte
 * Changed #if __MSDOS to #ifdef MSDOS.
 * 
 * Revision 6.40  93/03/10  10:46:35  glennc
 * For Apple scan converter, make sure we reallocate the 5, 6, and 7
 * memoryBases if already allocated and deallocate them when the
 * font is closed.
 * 
 * Revision 6.39  93/03/10  09:39:45  roberte
 * Changed compile time test for inclusion of malloc.h to #ifdef MSDOS
 * 
 * Revision 6.38  93/03/04  14:31:58  roberte
 * Moved lpoint_t (point tag) structure from newscan.c and tt_iface.c to fontscal.h.
 * 
 * Revision 6.37  93/03/04  13:48:29  roberte
 * Remove setting of platformID and specificID from the tt_reset() function.
 * These parameters must be set at time of fontload, when mapping is computed.
 * 
 * Revision 6.36  93/03/04  11:56:54  roberte
 * Added new function tt_load_font_params() which really does font load.
 * The existing tt_load_font() now just calls this with the params for
 * platformID and specificID as we had them set before.
 * 
 * Revision 6.35  93/02/10  15:10:58  roberte
 * Removed un-needed stack allocation of plaid in tt_make_char_idx.
 * 
 * Revision 6.34  93/02/08  16:11:54  roberte
 * Removed DAVID's code to set 4 local variables to the character
 * bounding box via a call to fs_FindBitMapSize.  We have a better
 * solution now in 4-in-1 that costs much less code.
 * 
 * Revision 6.33  93/01/29  10:58:54  roberte
 * Changed reference to sp_globals.plaid reflecting move of that
 * element back to common area of SPEEDO_GLOBALS.
 * 
 * Revision 6.32  93/01/27  15:32:51  glennc
 * Added traceFunc to tt_set_specs (only if NEEDTRACEFUNC is defined).
 * 
 * Revision 6.31  93/01/26  15:18:00  roberte
 * Corrected inadvertant use of PARAMS1 macro for dump_bitmap. Now PARAMS2.
 * 
 * Revision 6.30  93/01/26  13:38:24  roberte
 * Added PARAMS1 and PARAMS2 macros to all reentrant function calls and definitions.
 * Changed return type of split_Qbez, tt_rendercurve (int16) and dump_bitmap ().
 * Purged some int's to int16's.
 * 
 * Revision 6.29  93/01/26  10:31:35  roberte
 * Changed calls to sp_open_bitmap, sp_set_bitmap_bits and sp_close_bitmap back to no prefix.
 * 
 * Revision 6.28  93/01/25  16:51:25  roberte
 * Silly cleanup of code.
 * #ifdef'ed dump_bitmap() with INCL_APPLESCAN.  Renamed its' calls
 * to open_bitmap, set_bitmap_bits and close_bitmap to have "sp_" prefix.
 * 
 * Revision 6.27  93/01/25  13:20:45  roberte
 * Removed unused local variables declared in tt_make_char().
 * 
 * Revision 6.26  93/01/25  13:02:09  roberte
 * Changed function tt_make_char() and tt_get_char_width() to call tt_make_char_idx()
 * and tt_get_char_width_idx() respectively.  #defining GLYPH_INDEX is no longer
 * sensible or needed.
 * 
 * Revision 6.25  93/01/22  15:54:47  roberte
 * Removed 2 unreferenced varibles.
 * 
 * Revision 6.24  93/01/20  09:57:29  davidw
 * 80 column cleanup.
 * 
 * Revision 6.23  93/01/13  11:49:20  glennc
 * Add NEEDTRACEFUNC compile flag. If not defined, tt_make_char_idx has normal
 * behavior. If it is defined, tt_make_char_idx take a second argument, a
 * traceFunc to be placed in the gridFit.traceFunc member.
 * 
 * Revision 6.22  93/01/08  15:28:17  roberte
 * Changes reflecting addition of emResolution, emResRnd, sfnt_?min/max, iPtr,
 * glyph_in, oPtr, glyph_out, globalMatrix, abshift and abround to
 * SPEEDO_GLOBALS union structure.
 * 
 * Revision 6.21  92/12/29  10:10:29  roberte
 * Include spdo_prv.h, changed function declaration to older 
 * K&R style, and changed bad cast of bitmap->baseAddr
 * 
 * Revision 6.20  92/11/25  14:59:00  davidw
 * Changed pointSize reclmation from yy & xymult to account for landscape
 * orientation.
 * 
 * Revision 6.19  92/11/25  14:13:25  davidw
 * Removed function util_BitCount(), no longer used.
 * cleaned up code, comments to reflect ANSI "C"
 * 80 column cleanup
 * 
 * Revision 6.18  92/11/24  13:34:07  laurar
 * include fino.h
 * 
 * Revision 6.17  92/11/11  09:17:44  davidw
 * changed tt_make_char to use actual character wide bounding box instead of
 * the font-wide bounding box
 * 80 column cleanup
 * removed DAVIDW0 switches, except for debugging printf's
 * 
 * Revision 6.16  92/11/10  14:57:03  davidw
 * fixed debugging messages (again)
 * 
 * Revision 6.15  92/11/10  14:52:08  davidw
 * turn off debugging messages
 * 
 * Revision 6.14  92/11/10  14:19:12  davidw
 * made work sharing switchable using DAVIDW0 define
 * 
 * Revision 6.13  92/11/10  14:04:11  davidw
 * working on char bounding box problem
 * 
 * Revision 6.12  92/11/10  14:02:59  davidw
 * working on char bounding box problem
 * 
 * Revision 6.11  92/11/09  17:01:55  davidw
 * working on do_char_bbox
 * added comments
 * cleaned up code for 80 columns
 * 
 * Revision 6.10  92/11/09  14:50:50  davidw
 * added comments to code for clarity
 * 
 * Revision 6.9  92/11/09  14:41:36  davidw
 * 80 column cleanup, working on do_char_bbox(), not fixed yet, now uses font
 * wide bbox instead of char_bbox().
 * 
 * Revision 6.8  92/11/09  14:14:04  davidw
 * WIP: new character bbox code to replace do_char_bbox()
 * 
 * Revision 6.7  92/11/09  12:32:42  roberte
 * Added #ifdef PCLETTO setting of platformID for shutting of
 * cmap code during tt_reset() and tt_load_font().
 * 
 * Revision 6.6  92/11/02  12:21:06  roberte
 * Added routine tt_get_char_width_idx() so support
 * of Unicode and glyph index is consonant with the make_char functionality.
 * 
 * Revision 6.5  92/10/30  13:39:06  roberte
 * Added tenuous support for glyph code (Unicode) to tt_get_char_width().
 * 
 * Revision 6.4  92/09/28  14:26:56  roberte
 * Added param.scan. references for union fields bottomClip and topClip.
 * 
 * Revision 6.3  92/02/21  13:56:45  mark
 * Removed format checks from read_SfntOffsetTable since they are
 * verifying unused fields which are not set the same by certain
 * applications.
 * 
 * Revision 6.2  91/09/12  12:57:05  mark
 * add support for indexed glyph access (tt_make_char_idx) so that
 * we can bypass encoding table.  Enabled by flag GLYPH_INDEX
 * and only used (currently) by gsample.
 * 
 * Revision 6.1  91/08/14  16:49:23  mark
 * Release
 * 
 * Revision 5.2  91/08/14  15:11:11  mark
 * remove superfluous report_error call with MALLOC_FAILURE
 * when tt_set_spglob fails.
 * 
 * Revision 5.1  91/08/07  12:30:27  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:59:46  mark
 * fix rcs control strings.
 *  
*/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/tt_iface.c,v 1.1 97/04/18 11:45:25 newdeal Exp $"
#endif

#include "spdo_prv.h"
#include "fino.h"
#include "fscdefs.h"
#undef boolean
#include "fontscal.h"
#include "sfnt.h"
#include "fserror.h"
#include "truetype.h"

#undef boolean
#include <math.h>
#ifdef __GEOS__
extern double _pascal floor(double __x);
#include <ec.h>
#endif

#ifdef MSDOS
#ifdef __GEOS__
/* malloc stuff */
extern void* MallocAndSave(word blockSize);
extern void FreeAndSave(void *blockPtr);
#undef malloc
#define malloc(s) (MallocAndSave((s)))
#undef free
#define free(s) if ((s)!=NULL) FreeAndSave((s))
#else
#include <malloc.h>
#endif
#else
void *malloc();
#endif

#define GET_WORD(A)  ((ufix16)((ufix16)A[0] << 8) | ((ufix8)A[1]))
#define MAXDEPTH  8
#define AP_PIXSHIFT 6	/* subpixel unit shift used by Apple scan converter */

#ifdef OLDWAY
static ufix16    emResolution;
static ufix16    emResRnd;
	/* Fontwide bounding box */
static fix15     sfnt_xmin;
static fix15     sfnt_xmax;
static fix15     sfnt_ymin;
static fix15     sfnt_ymax;
fs_GlyphInputType  *iPtr, glyph_in;
fs_GlyphInfoType   *oPtr, glyph_out;
static transMatrix globalMatrix;
static fix15 abshift;
static fix15 abround;
#endif

extern int32 fs_OpenFonts();
extern int32 fs_Initialize();
extern int32 fs_NewSfnt();
extern int32 fs_NewTransformation();
extern int32 fs_sfntBBox();
extern int32 fs_GetCharWidth();
extern int32 fs_NewGlyph();
extern int32 fs_ContourGridFit();

static int   read_SfntOffsetTable();
static int   loadTable();
static int32 do_char_bbox();
static void tt_error PROTO((PROTO_DECL2 int32 error));


FUNCTION  boolean  tt_reset(PARAMS1)
GDECL
/*  This function initializes the TrueType font interpreter. Call it
    once at startup time. Calls the TrueType Interpreter functions
    fs_OpenFonts and fs_Initialize. */

{
int32   err;

sp_globals.processor.truetype.iPtr = &sp_globals.processor.truetype.glyph_in;
sp_globals.processor.truetype.oPtr = &sp_globals.processor.truetype.glyph_out;

#ifdef OLDWAY
/* spurious re-setting of these ! */
#ifdef PCLETTO
sp_globals.processor.truetype.iPtr->param.newsfnt.platformID = 0xffff;
#else
sp_globals.processor.truetype.iPtr->param.newsfnt.platformID = 0;
#endif
sp_globals.processor.truetype.iPtr->param.newsfnt.specificID = 0; /* resed ? */
#endif /* OLDWAY */
sp_globals.processor.truetype.iPtr->param.gridfit.styleFunc = NULL;

sp_globals.processor.truetype.iPtr->GetSfntFragmentPtr = tt_get_font_fragment;
sp_globals.processor.truetype.iPtr->ReleaseSfntFrag = tt_release_font_fragment;

err = fs_OpenFonts(sp_globals.processor.truetype.iPtr,
				   sp_globals.processor.truetype.oPtr);
if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

if ((sp_globals.processor.truetype.iPtr->memoryBases[0] =
	(char *)malloc(((word)sp_globals.processor.truetype.oPtr->memorySizes[0]))) == NULL)
    goto malerr1;
if ((sp_globals.processor.truetype.iPtr->memoryBases[1] =  
	(char *)malloc(((word)sp_globals.processor.truetype.oPtr->memorySizes[1]))) == NULL)
    goto malerr1;
if ((sp_globals.processor.truetype.iPtr->memoryBases[2] =  
	(char *)malloc(((word)sp_globals.processor.truetype.oPtr->memorySizes[2]))) == NULL)
    goto malerr1;

err = fs_Initialize(sp_globals.processor.truetype.iPtr,
				   sp_globals.processor.truetype.oPtr);
if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

return TRUE;

malerr1:
  sp_report_error(PARAMS2 MALLOC_FAILURE);           /* malloc error */
  return FALSE;
} /* end tt_reset() */


	/*  This function calls fs_NewSfnt whenever a new font is needed. */
FUNCTION  boolean  tt_load_font(PARAMS2 fontHandle)
GDECL
int32 fontHandle;
{
#ifdef PCLETTO
	return(tt_load_font_params(PARAMS2 fontHandle, 0xffff, 0);
#else
	return(tt_load_font_params(PARAMS2 fontHandle, 1, 0));
#endif
}

	/*  This function calls fs_NewSfnt whenever a new font is needed. */
FUNCTION  boolean  tt_load_font_params(PARAMS2 fontHandle, platID, specID)
GDECL
int32 fontHandle;
uint16 platID;
uint16 specID;
{
int32   err;
ufix8  *sfptr;

sp_globals.processor.truetype.iPtr->clientID = fontHandle;

sp_globals.processor.truetype.iPtr->param.newsfnt.platformID = platID;

sp_globals.processor.truetype.iPtr->param.newsfnt.specificID = specID;

if ((sp_globals.processor.truetype.iPtr->sfntDirectory = 
	(int32 *)malloc(sizeof(sfnt_OffsetTable))) == NULL)
    goto malerr2;

/* FCALL */
sfptr = (ufix8 *)sp_globals.processor.truetype.iPtr->GetSfntFragmentPtr (sp_globals.processor.truetype.iPtr->clientID, 0L, 12L);

if (!read_SfntOffsetTable (sfptr, sp_globals.processor.truetype.iPtr->sfntDirectory))
    {
    tt_release_font_fragment(sfptr);
    tt_error(PARAMS2 (int32)MALLOC_FAILURE);         /* bad data in sfnt offset table */
    return(FALSE);
}

tt_release_font_fragment(sfptr);

/* FCALL */
sfptr = (ufix8 *)sp_globals.processor.truetype.iPtr->GetSfntFragmentPtr (sp_globals.processor.truetype.iPtr->clientID, 12L, ((sfnt_OffsetTable *)sp_globals.processor.truetype.iPtr->sfntDirectory)->numOffsets * 16L);

if (!loadTable (sfptr, sp_globals.processor.truetype.iPtr->sfntDirectory)) {
    tt_release_font_fragment(sfptr);
    tt_error(PARAMS2 (int32)MALLOC_FAILURE);         /* can't load sfnt pointers */
    return(FALSE);
}

tt_release_font_fragment(sfptr);

err = fs_NewSfnt (sp_globals.processor.truetype.iPtr,
				  sp_globals.processor.truetype.oPtr);
if (err != NO_ERR) {
    tt_error(PARAMS2 err);
    return(FALSE);
}

if ((sp_globals.processor.truetype.iPtr->memoryBases[3] =  
	(char *)malloc(((word)sp_globals.processor.truetype.oPtr->memorySizes[3]))) == NULL)
    goto malerr2;
if ((sp_globals.processor.truetype.iPtr->memoryBases[4] =  
	(char *)malloc(((word)sp_globals.processor.truetype.oPtr->memorySizes[4]))) == NULL)
    goto malerr2;

#if INCL_APPLESCAN
/* [GAC] Make sure memoryBases 5, 6, and 7 are zero! */
sp_globals.processor.truetype.iPtr->memoryBases[5] =
    sp_globals.processor.truetype.iPtr->memoryBases[6] =
	sp_globals.processor.truetype.iPtr->memoryBases[7] = NULL;
#endif /* INCL_APPLESCAN */

err = fs_sfntBBox (	sp_globals.processor.truetype.iPtr,
					&sp_globals.processor.truetype.sfnt_xmin,
					&sp_globals.processor.truetype.sfnt_ymin,
					&sp_globals.processor.truetype.sfnt_xmax,
					&sp_globals.processor.truetype.sfnt_ymax,
					&sp_globals.processor.truetype.emResolution );
if (err != NO_ERR){
    tt_error(PARAMS2 err);        /* sfnt has no 'head' section */
    return(FALSE);
}

sp_globals.processor.truetype.emResRnd = 
	sp_globals.processor.truetype.emResolution >> 1;

return(TRUE);

malerr2:
  tt_error(PARAMS2 (int32)MALLOC_FAILURE);           /* malloc error */
  return(FALSE);
}	/* end tt_load_font() */



FUNCTION void tt_error(PARAMS2 error)
GDECL
int32 error;
{
	sp_report_error(PARAMS2 (fix15)error);
	tt_release_font(PARAMS1);
}

FUNCTION  boolean  tt_release_font(PARAMS1)
GDECL
{/* frees memory, checking pointers for nullness, in reverse order of allocation: */
	sp_globals.processor.truetype.iPtr->clientID = 0;

/* [GAC] release 5, 6, and 7 on close (if Apple) */
#if INCL_APPLESCAN
	if (sp_globals.processor.truetype.iPtr->memoryBases[5]) {
	    free(sp_globals.processor.truetype.iPtr->memoryBases[5]);
	    sp_globals.processor.truetype.iPtr->memoryBases[5] = NULL;
	}
	if (sp_globals.processor.truetype.iPtr->memoryBases[6]) {
	    free(sp_globals.processor.truetype.iPtr->memoryBases[6]);
	    sp_globals.processor.truetype.iPtr->memoryBases[6] = NULL;
	}
	if (sp_globals.processor.truetype.iPtr->memoryBases[7]) {
	    free(sp_globals.processor.truetype.iPtr->memoryBases[7]);
	    sp_globals.processor.truetype.iPtr->memoryBases[7] = NULL;
	}
#endif /* INCL_APPLESCAN */

	if (sp_globals.processor.truetype.iPtr->memoryBases[4])
		{
		free(sp_globals.processor.truetype.iPtr->memoryBases[4]);
		sp_globals.processor.truetype.iPtr->memoryBases[4] = NULL;
		}
	if (sp_globals.processor.truetype.iPtr->memoryBases[3])
		{
		free(sp_globals.processor.truetype.iPtr->memoryBases[3]);
		sp_globals.processor.truetype.iPtr->memoryBases[3] = NULL;
		}
	if (((sfnt_OffsetTable *)sp_globals.processor.truetype.iPtr->sfntDirectory)->table)
		{
		free(((sfnt_OffsetTable *)sp_globals.processor.truetype.iPtr->sfntDirectory)->table);
		((sfnt_OffsetTable *)sp_globals.processor.truetype.iPtr->sfntDirectory)->table = NULL;
		}
	if (sp_globals.processor.truetype.iPtr->sfntDirectory)
		{
		free(sp_globals.processor.truetype.iPtr->sfntDirectory);
		sp_globals.processor.truetype.iPtr->sfntDirectory = NULL;
		}

	return FALSE;	/* success */
}


/*
 *	THIS FUNCTION USES FLOATING POINT 
 *
 *  This function calls fs_NewSfnt whenever a new font is needed.
*/

/* [GAC] Need to add ability for tt_set_specs to allow a traceFunc */
#ifdef NEEDTRACEFUNC
FUNCTION  boolean  tt_set_specs(PARAMS2 pspecs, traceFunc)
GDECL
specs_t *pspecs;
voidFunc traceFunc; /* [GAC] add a trace function argument */
#else /* ifdef NEEDTRACEFUNC */
FUNCTION  boolean  tt_set_specs(PARAMS2 pspecs)
GDECL
specs_t *pspecs;
#endif /* ifdef NEEDTRACEFUNC */

{
double  dps;
int32   err;
boolean tt_set_spglob();
boolean tmp_err;
fix15 nn;

if (pspecs->yymult == 0) {
		/* can't use yymult for the point size */
	if (pspecs->xymult < 0) {
			/* landscape mode */
		sp_globals.processor.truetype.iPtr->param.newtrans.pointSize = 
		-pspecs->xymult;
	} else {
			/* portrait mode */
		sp_globals.processor.truetype.iPtr->param.newtrans.pointSize = 
		pspecs->xymult;
	}
} else {
		/* use yymult as the pointSize (in 16.16 representation) */
	sp_globals.processor.truetype.iPtr->param.newtrans.pointSize = 
		pspecs->yymult; 
}

	/* for the target display (marking) device, establish resolution */
sp_globals.processor.truetype.iPtr->param.newtrans.xResolution = 72;
sp_globals.processor.truetype.iPtr->param.newtrans.yResolution = 72;

	/*
	 *	pixelDiameter is set to sqrt(2) (0x16a0a) in 16.16 as suggested by
	 *	FS Client Interface doc
	*/
sp_globals.processor.truetype.iPtr->param.newtrans.pixelDiameter = 0x16a0a;

	/* get the current transformation matrix */
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix = 
	&sp_globals.processor.truetype.globalMatrix;

	/*
	 *	Initialize the 3 x 3 matrix array  transformMatrix[row][column]
	 *	(see  key->currentTMatrix.transform[3][3])
	*/
dps = (double)sp_globals.processor.truetype.iPtr->param.newtrans.pointSize;
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[0][0] = (Fixed)(pspecs->xxmult * 65536.0 / dps);
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[1][0] = (Fixed)(pspecs->xymult * 65536.0 / dps);
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[2][0] = (Fixed)(pspecs->xoffset * 65536.0 / dps);
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[0][1] = (Fixed)(pspecs->yxmult * 65536.0 / dps);
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[1][1] = (Fixed)(pspecs->yymult * 65536.0 / dps);
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[2][1] = (Fixed)(pspecs->yoffset * 65536.0 / dps);
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[0][2] = 0L;
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[1][2] = 0L;
sp_globals.processor.truetype.iPtr->param.newtrans.transformMatrix->transform[2][2] = 1L << 30;

/* [GAC] may need trace function */
#ifdef NEEDTRACEFUNC
sp_globals.processor.truetype.iPtr->param.newtrans.traceFunc = traceFunc;
#else /* ifdef NEEDTRACEFUNC */
sp_globals.processor.truetype.iPtr->param.newtrans.traceFunc = NULL;
#endif /* ifdef NEEDTRACEFUNC */

err = fs_NewTransformation (sp_globals.processor.truetype.iPtr, 
							sp_globals.processor.truetype.oPtr);
if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

tmp_err = tt_set_spglob(PARAMS2 pspecs,
						sp_globals.processor.truetype.sfnt_xmin,
						sp_globals.processor.truetype.sfnt_ymin,
						sp_globals.processor.truetype.sfnt_xmax,
						sp_globals.processor.truetype.sfnt_ymax,
						sp_globals.processor.truetype.emResolution);
if (!tmp_err)
    return(FALSE);

	/*
	 *	Transform vectors of type 'Fixed' (16.16) to Speedo subpixel
	 *	resolution units
	 */
nn = 16 - sp_globals.pixshift;
if ((sp_globals.processor.truetype.abshift = sp_globals.pixshift - AP_PIXSHIFT) < 0)
    sp_globals.processor.truetype.abround = 1 << (-sp_globals.processor.truetype.abshift-1);
else if (sp_globals.processor.truetype.abshift == 0)
    sp_globals.processor.truetype.abround = 0;

return(TRUE);
}	/* end tt_set_specs() */


#define  INIT          0
#define  MOVE          1
#define  LINE          2
#define  CURVE         3
#define  END_CONTOUR   4
#define  END_CHAR      5
#define  ERROR        -1

FUNCTION  boolean  tt_make_char(PARAMS2 char_code)
GDECL
ufix16 char_code;/* Unicode value */
{
int32    err;


sp_globals.processor.truetype.iPtr->param.newglyph.characterCode = char_code;

	/*
	 * Compute the glyph index from the character code.
 	*/
err = fs_NewGlyph (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr);
if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

#ifdef NEEDTRACEFUNC
return (tt_make_char_idx(PARAMS2 sp_globals.processor.truetype.oPtr->glyphIndex, (voidFunc)NULL));
#else
return (tt_make_char_idx(PARAMS2 sp_globals.processor.truetype.oPtr->glyphIndex));
#endif
}




/* make character at physical glyph index */

/* [GAC] Need to add ability for tt_make_char_idx to allow a traceFunc */
#ifdef NEEDTRACEFUNC
FUNCTION  boolean  tt_make_char_idx(PARAMS2 char_idx, traceFunc)
  GDECL
  ufix16              char_idx; /* file position */
  voidFunc            traceFunc; /* [GAC] add a trace function argument */
#else /* ifdef NEEDTRACEFUNC */
FUNCTION  boolean  tt_make_char_idx(PARAMS2 char_idx)
  GDECL
  ufix16              char_idx; /* file position */
#endif /* ifdef NEEDTRACEFUNC */

{
int      ptype;
lpoint_t vstore[3];
int16    ii, nn;
int32    err;
Fixed    xmin, ymin, xmax, ymax;
fix31    round;
boolean  outside;
point_t  Pmove, Pline, Pcurve[3];
point_t  Psw, Pbbx_min, Pbbx_max;
register fix31 temp;
void     ns_ProcOutlSetUp();
int      ns_ProcOutl();
int16    tt_rendercurve();
#if REENTRANT_ALLOC
#if INCL_BLACK || INCL_SCREEN || INCL_2D
intercepts_t intercepts;
sp_globals.intercepts = &intercepts;
#endif
#endif


nn = 16 - sp_globals.pixshift;
round = ((fix31)1 << (nn-1));

sp_globals.processor.truetype.iPtr->param.newglyph.characterCode = 0xFFFF;
sp_globals.processor.truetype.iPtr->param.newglyph.glyphIndex = char_idx;
if ((err = fs_NewGlyph (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr)) != NO_ERR)
    {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

#ifdef NEEDTRACEFUNC
sp_globals.processor.truetype.iPtr->param.gridfit.traceFunc = traceFunc;
#else /* ifdef NEEDTRACEFUNC */
sp_globals.processor.truetype.iPtr->param.gridfit.traceFunc = NULL;
#endif /* ifdef NEEDTRACEFUNC */

sp_globals.processor.truetype.iPtr->param.gridfit.styleFunc = NULL;

if (sp_globals.pspecs->flags & BOGUS_MODE)
	err = fs_ContourNoGridFit (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr);
else
	err = fs_ContourGridFit (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr);


if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

err = fs_GetAdvanceWidth(sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr);
if (err != NO_ERR){
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

err = do_char_bbox(PARAMS2 sp_globals.processor.truetype.iPtr, &xmin, &ymin, &xmax, &ymax);
if (err != NO_ERR){
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

Psw.x = (fix15)((sp_globals.processor.truetype.oPtr->metricInfo.advanceWidth.x + round) >> nn);
Psw.y = (fix15)((sp_globals.processor.truetype.oPtr->metricInfo.advanceWidth.y + round) >> nn);
Pbbx_min.x = (fix15)((xmin + round) >> nn);
Pbbx_min.y = (fix15)((ymin + round) >> nn);
Pbbx_max.x = (fix15)((xmax + round) >> nn);
Pbbx_max.y = (fix15)((ymax + round) >> nn);

#if INCL_APPLESCAN
if (sp_globals.output_mode == MODE_APPLE)
	{
	char *tptr;	/* [GAC] Need for realloc */

	if ((err = fs_FindBitMapSize (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr)) != NO_ERR)
	    {
	    sp_report_error(PARAMS2 (fix15)err);
	    return(FALSE);
	    }
/* [GAC] Reallocate 5, 6, and 7 if already allocated */
	if ((tptr = sp_globals.processor.truetype.iPtr->memoryBases[5])==NULL) {
	    if ((sp_globals.processor.truetype.iPtr->memoryBases[5] =
		 (char *)malloc(sp_globals.processor.truetype.oPtr->memorySizes[5])) == NULL) {
		sp_report_error(PARAMS2 (fix15)MALLOC_FAILURE);
		return (FALSE);
	    }
	}
	else {
	    if ((sp_globals.processor.truetype.iPtr->memoryBases[5] =
		 (char *)realloc(tptr, sp_globals.processor.truetype.oPtr->memorySizes[5])) == NULL) {
		sp_report_error(PARAMS2 (fix15)MALLOC_FAILURE);
		return (FALSE);
	    }
	}
	if ((tptr = sp_globals.processor.truetype.iPtr->memoryBases[6])==NULL) {
	    if ((sp_globals.processor.truetype.iPtr->memoryBases[6] =
		 (char *)malloc(sp_globals.processor.truetype.oPtr->memorySizes[6])) == NULL) {
		sp_report_error(PARAMS2 (fix15)MALLOC_FAILURE);
		return (FALSE);
	    }
	}
	else {
	    if ((sp_globals.processor.truetype.iPtr->memoryBases[6] =
		 (char *)realloc(tptr, sp_globals.processor.truetype.oPtr->memorySizes[6])) == NULL) {
		sp_report_error(PARAMS2 (fix15)MALLOC_FAILURE);
		return (FALSE);
	    }
	}
	if ((tptr = sp_globals.processor.truetype.iPtr->memoryBases[7])==NULL) {
	    if ((sp_globals.processor.truetype.iPtr->memoryBases[7] =
		 (char *)malloc(sp_globals.processor.truetype.oPtr->memorySizes[7])) == NULL) {
		sp_report_error(PARAMS2 (fix15)MALLOC_FAILURE);
		return (FALSE);
	    }
	}
	else {
	    if ((sp_globals.processor.truetype.iPtr->memoryBases[7] =
		 (char *)realloc(tptr, sp_globals.processor.truetype.oPtr->memorySizes[7])) == NULL) {
		sp_report_error(PARAMS2 (fix15)MALLOC_FAILURE);
		return (FALSE);
	    }
	}
	sp_globals.processor.truetype.iPtr->param.scan.bottomClip = sp_globals.processor.truetype.oPtr->bitMapInfo.bounds.bottom;
	sp_globals.processor.truetype.iPtr->param.scan.topClip = sp_globals.processor.truetype.oPtr->bitMapInfo.bounds.top;

	if ((err = fs_ContourScan (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr)) != NO_ERR)
	    {
	    sp_report_error(PARAMS2 (fix15)err);
	    return(FALSE);
	    }
	dump_bitmap(PARAMS2 &sp_globals.processor.truetype.oPtr->bitMapInfo,&Psw);
	}
else
#endif
	{
#ifdef FNDEBUG
	    printf("fn_begin_char: %d %d  %d %d %d %d\n", Psw.x,Psw.y, Pbbx_min.x,Pbbx_min.y, Pbbx_max.x,Pbbx_max.y);
#endif
	if (!fn_begin_char(Psw, Pbbx_min, Pbbx_max))
	    {
/*  ERROR   */
	    return(FALSE);
	    }
	ns_ProcOutlSetUp(sp_globals.processor.truetype.oPtr, vstore);
	ptype = INIT;
	while (ptype != END_CHAR)
	    {
	    ptype = ns_ProcOutl(sp_globals.processor.truetype.oPtr);
	    switch(ptype)
	        {
	        case MOVE:
	            if (sp_globals.processor.truetype.abshift >= 0)
	                {
	                Pmove.x = (fix15)(vstore[0].x << sp_globals.processor.truetype.abshift);
	                Pmove.y = (fix15)(vstore[0].y << sp_globals.processor.truetype.abshift);
	                }
	            else
	                {
	                Pmove.x = (fix15)((vstore[0].x + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift);
	                Pmove.y = (fix15)((vstore[0].y + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift);
	                }
	            fn_begin_contour(Pmove, (boolean)outside);
#ifdef FNDEBUG
	    printf("fn_move: %d %d  %s\n", Pmove.x, Pmove.y, outside ? "outside" : "inside");
#endif
	            break;
	        case LINE:
	            if (sp_globals.processor.truetype.abshift >= 0)
	                {
	                Pline.x = (fix15)(vstore[0].x << sp_globals.processor.truetype.abshift);
	                Pline.y = (fix15)(vstore[0].y << sp_globals.processor.truetype.abshift);
	                }
	            else
	                {
	                Pline.x = (fix15)((vstore[0].x + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift);
	                Pline.y = (fix15)((vstore[0].y + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift);
	                }
	            fn_line(Pline);
#ifdef FNDEBUG
	    printf("fn_line: %d %d\n", Pline.x, Pline.y);
#endif
	            break;
	        case CURVE:
            /* The 3 points that define the curve are vstore[0], ... , vstore[2]  */
#if INCL_OUTLINE
	            if (sp_globals.curves_out)
	                {
	                /* For curve output want to generate cubic Beziers from
	                 * quadratics. Use degree elevation [see G.Farin, _Curves_and_
	                 * _Surfaces_for_Computer_Aided_Geometric_Design_, p.45 ]   */
	                if (sp_globals.processor.truetype.abshift >= 0)
	                    {
	                    temp = (vstore[0].x + (vstore[1].x << 1)) << sp_globals.processor.truetype.abshift;
	                    Pcurve[0].x = (temp + (temp>=0 ? 1 : -1)) / 3;
	                    temp = (vstore[0].y + (vstore[1].y << 1)) << sp_globals.processor.truetype.abshift;
	                    Pcurve[0].y = (temp + (temp>=0 ? 1 : -1)) / 3;
	                    temp = ((vstore[1].x << 1) + vstore[2].x) << sp_globals.processor.truetype.abshift;
	                    Pcurve[1].x = (temp + (temp>=0 ? 1 : -1)) / 3;
	                    temp = ((vstore[1].y << 1) + vstore[2].y) << sp_globals.processor.truetype.abshift;
	                    Pcurve[1].y = (temp + (temp>=0 ? 1 : -1)) / 3;
	                    Pcurve[2].x = vstore[2].x << sp_globals.processor.truetype.abshift;
	                    Pcurve[2].y = vstore[2].y << sp_globals.processor.truetype.abshift;
	                    }
	                else
	                    {
	                    temp = vstore[0].x + (vstore[1].x << 1);
	                    Pcurve[0].x = ((temp + (temp>=0 ? 1 : -1)) / 3 + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
	                    temp = vstore[0].y + (vstore[1].y << 1);
	                    Pcurve[0].y = ((temp + (temp>=0 ? 1 : -1)) / 3 + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
	                    temp = (vstore[1].x << 1) + vstore[2].x;
	                    Pcurve[1].x = ((temp + (temp>=0 ? 1 : -1)) / 3 + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
	                    temp = (vstore[1].y << 1) + vstore[2].y;
	                    Pcurve[1].y = ((temp + (temp>=0 ? 1 : -1)) / 3 + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
	                    Pcurve[2].x = (vstore[2].x + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
	                    Pcurve[2].y = (vstore[2].y + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
	                    }
	                fn_curve(Pcurve[0], Pcurve[1], Pcurve[2], (fix15)0);
	                }
	            else
#endif
	                {
	                if ((nn = tt_rendercurve(PARAMS2 vstore[0].x, vstore[0].y, vstore[1].x, vstore[1].y,
	                                         vstore[2].x, vstore[2].y)) <= 0)
	                    {
	                /*  ERROR   */
	                    return(FALSE);
	                    }
	                }
#ifdef FNDEBUG
	    printf("CURVE:   %d %d  %d %d  %d %d    %d\n", vstore[0].x,vstore[0].y, vstore[1].x,vstore[1].y, vstore[2].x,vstore[2].y, nn);
#endif
	            break;
	        case END_CONTOUR:
	            fn_end_contour();
#ifdef FNDEBUG
	    printf("fn_end_contour\n");
#endif
	            break;
	        case END_CHAR:
	            if (!fn_end_char())         /* continue loop if bitmap requires */
	                {                       /* more banding */
	                ns_ProcOutlSetUp(sp_globals.processor.truetype.oPtr, vstore);
	                ptype = INIT;
	                }
#ifdef FNDEBUG
	    printf("fn_end_char\n");
#endif
	            break;
	        default:
	            break;
	        }
	    }
	}

return(TRUE);
}


FUNCTION  fix31  tt_get_char_width_idx(PARAMS2 char_index)
  GDECL
  ufix16              char_index; /* file position */

/*  Returns: ideal character set width in units of 1/65536 em.
    tt_set_specs _m_u_s_t_ be called before this function */

{
ufix16      width;
fix31     emwidth;
int32         err;

if ((err = fs_GetCharWidth (sp_globals.processor.truetype.iPtr, char_index, &width)) != NO_ERR)
    {
    sp_report_error(PARAMS2 (fix15)err);        /* */
    return(FALSE);
	}
emwidth = (((ufix32)width << 16) + sp_globals.processor.truetype.emResRnd) / sp_globals.processor.truetype.emResolution;
return(emwidth);
}

FUNCTION  fix31  tt_get_char_width(PARAMS2 char_code)
  GDECL
  ufix16              char_code;  /* Unicode value */

/*  Returns: ideal character set width in units of 1/65536 em.
    tt_set_specs _m_u_s_t_ be called before this function */

{
int32         err;

sp_globals.processor.truetype.iPtr->param.newglyph.characterCode = char_code;
if ((err = fs_NewGlyph (sp_globals.processor.truetype.iPtr, sp_globals.processor.truetype.oPtr)) != NO_ERR)
    {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
	}
return(tt_get_char_width_idx(PARAMS2 sp_globals.processor.truetype.oPtr->glyphIndex));
}



/*                                             */
/*      THIS FUNCTION USES FLOATING POINT      */
/*                                             */
FUNCTION  int16 tt_rendercurve(PARAMS2 Ax, Ay, Bx, By, Cx, Cy)
  GDECL
  F26Dot6  Ax, Ay;              /* end point of quadratic Bezier curve */
  F26Dot6  Bx, By;              /* control point */      
  F26Dot6  Cx, Cy;              /* end point */
{
F26Dot6  area2;
F26Dot6  dist;
long dist2;
point_t  Pline;
fix15   split_depth;        /* actual curve splitting depth */
long     distance();
int16    split_Qbez();
F26Dot6  Mul26Dot6();

#define  SPLITTHRESH   0x20         /* = .5 in F26Dot6 (effective value = .25) */

/* Estimate point-line distance: point B to line AC
 *    area of triangle ABC = [(Bx-Ax)(Cy-Ay) - (By-Ay)(Cx-Ax)] / 2
 *    Now use Height = 2 * Area / Base                      */
area2 = Mul26Dot6(Bx - Ax, Cy - Ay) - Mul26Dot6(By - Ay, Cx - Ax);
if (area2 < 0)
    area2 = -area2;
dist2 = distance(Ax, Ay, Cx, Cy);

split_depth = 0;
if (dist2 != 0)
    {
    dist = floor((double)area2 * 64.0 /     /* F26Dot6 conversion -- dist is in  64ths */
                 (double)dist2 + 0.5);
    while (dist > SPLITTHRESH)
        {
        split_depth++;
        dist >>= 2;
        }
    if (split_depth > MAXDEPTH)
        split_depth = MAXDEPTH;
	}

if (split_depth > 0)
    {
    return(split_Qbez(PARAMS2 Ax, Ay, Bx, By, Cx, Cy, 0, split_depth));
	}
else
    {
    if (sp_globals.processor.truetype.abshift >= 0)
        {
        Pline.x = Cx << sp_globals.processor.truetype.abshift;
        Pline.y = Cy << sp_globals.processor.truetype.abshift;
        }
    else
        {
        Pline.x = (Cx + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
        Pline.y = (Cy + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
        }
    fn_line(Pline);
#ifdef FNDEBUG
    printf("fn_line: %d %d\n", Pline.x, Pline.y);
#endif
    return(1);
	}
}


FUNCTION  int16 split_Qbez(PARAMS2 Ax, Ay, Bx, By, Cx, Cy, index, depth)
  GDECL
  long  Ax, Ay, Bx, By, Cx, Cy;
  int   index;
  fix15 depth;
/*  Recursive subdivider for quadratic Beziers
                            + Bx,By     . P2        @ Cx,Cy
                             . MID
                  . P1

        @ Ax,Ay
*/
{
int16     count;
long    midx, midy;
long    p1x, p1y, p2x, p2y;
point_t Pline;

depth--;
p1x = (Ax + Bx) >> 1;
p1y = (Ay + By) >> 1;
p2x = (Bx + Cx) >> 1;
p2y = (By + Cy) >> 1;
midx = (p1x + p2x) >> 1;
midy = (p1y + p2y) >> 1;
if (depth == 0)
    {
    if (sp_globals.processor.truetype.abshift >= 0)
        {
        Pline.x = midx << sp_globals.processor.truetype.abshift;
        Pline.y = midy << sp_globals.processor.truetype.abshift;
        fn_line(Pline);
#ifdef FNDEBUG
    printf("fn_line: %d %d\n", Pline.x, Pline.y);
#endif
        Pline.x = Cx << sp_globals.processor.truetype.abshift;
        Pline.y = Cy << sp_globals.processor.truetype.abshift;
        fn_line(Pline);
#ifdef FNDEBUG
    printf("fn_line: %d %d\n", Pline.x, Pline.y);
#endif
        }
    else
        {
        Pline.x = (midx + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
        Pline.y = (midy + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
        fn_line(Pline);
#ifdef FNDEBUG
    printf("fn_line: %d %d\n", Pline.x, Pline.y);
#endif
        Pline.x = (Cx + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
        Pline.y = (Cy + sp_globals.processor.truetype.abround) >> -sp_globals.processor.truetype.abshift;
        fn_line(Pline);
#ifdef FNDEBUG
    printf("fn_line: %d %d\n", Pline.x, Pline.y);
#endif
        }
    return(2+index);
}
else
    {
    count = split_Qbez(PARAMS2 Ax, Ay, p1x, p1y, midx, midy, index, depth);
    count = split_Qbez(PARAMS2 midx, midy, p2x, p2y, Cx, Cy, count, depth);
    return (count);
}
}



FUNCTION  static int read_SfntOffsetTable (ptr, dir)
  ufix8  *ptr;
  sfnt_OffsetTable  *dir;

{

dir->version = (ufix32)(GET_WORD(ptr)) << 16;
dir->version += GET_WORD((ptr+2));
dir->numOffsets = GET_WORD((ptr+4));
dir->searchRange = GET_WORD((ptr+6));
dir->entrySelector = GET_WORD((ptr+8));
dir->rangeShift = GET_WORD((ptr+10));

if (dir->numOffsets > 256)
    return(FALSE);                                          

return(TRUE);                   /* all is OK */
}


FUNCTION  static int loadTable (ptr, sfntdir)
  ufix8  *ptr;                  /* font pointer, starting at the Sfnt Directory entries */
  sfnt_OffsetTable  *sfntdir;

{
int16   ii;
ufix8  *pf;


sfntdir->table = (sfnt_DirectoryEntry *)
                 malloc(sfntdir->numOffsets * sizeof(sfnt_DirectoryEntry));
if (sfntdir->table == NULL)
    return(FALSE);                      /* can't allocate memory for offset tables */
for (pf=ptr, ii=0; ii<sfntdir->numOffsets; ii++)
    {
    sfntdir->table[ii].tag = (ufix32)(GET_WORD(pf)) << 16;
    sfntdir->table[ii].tag += GET_WORD((pf+2));
    pf += 4;
    sfntdir->table[ii].checkSum = (ufix32)(GET_WORD(pf)) << 16;
    sfntdir->table[ii].checkSum += GET_WORD((pf+2));
    pf += 4;
    sfntdir->table[ii].offset = (ufix32)(GET_WORD(pf)) << 16;
    sfntdir->table[ii].offset += GET_WORD((pf+2));
    pf += 4;
    sfntdir->table[ii].length = (ufix32)(GET_WORD(pf)) << 16;
    sfntdir->table[ii].length += GET_WORD((pf+2));
    pf += 4;
}
return(TRUE);
}

FUNCTION  static int32 do_char_bbox(PARAMS2 iPtr, xmin, ymin, xmax, ymax)
GDECL
fs_GlyphInputType *iPtr;
Fixed *xmin;
Fixed *ymin;
Fixed *xmax;
Fixed *ymax;
{
int    iden;
Fixed  x0 = 0, y0 = 0;
int32  err = TRUE;

	/*
	 * This Function returns 1 if the TrueType transformation matrix (reduced
	 * form) is the identity matrix; otherwise returns 0.
	 */
err = fs_IdentityTransform (iPtr, &iden);
if (err != NO_ERR){
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

	/* using the current transformatin matrix, transform the point */
err = fs_TransformPoint (iPtr, sp_globals.processor.truetype.sfnt_xmin, sp_globals.processor.truetype.sfnt_ymin, &x0, &y0);
if (err != NO_ERR){
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

	/* set bbox to known state */
*xmin = x0; *ymin = y0; *xmax = x0; *ymax = y0;

	/* using the current transformatin matrix, transform the point */
err = fs_TransformPoint (iPtr, sp_globals.processor.truetype.sfnt_xmax, sp_globals.processor.truetype.sfnt_ymax, &x0, &y0);
if (err != NO_ERR){
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

	/* update bbox if limits changed */
if (x0 < *xmin)
    *xmin = x0;
if (y0 < *ymin)
    *ymin = y0;
if (x0 > *xmax)
    *xmax = x0;
if (y0 > *ymax)
    *ymax = y0;

	/* if the transformation is the idenity matrix, we are done */
if (iden) {
    return NO_ERR;
}

	/* using the current transformatin matrix, transform the point */
err = fs_TransformPoint (iPtr, sp_globals.processor.truetype.sfnt_xmin, sp_globals.processor.truetype.sfnt_ymax, &x0, &y0);
if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

	/* update bbox if limits changed */
if (x0 < *xmin)
    *xmin = x0;
if (y0 < *ymin)
    *ymin = y0;
if (x0 > *xmax)
    *xmax = x0;
if (y0 > *ymax)
    *ymax = y0;

	/* using the current transformatin matrix, transform the point */
err = fs_TransformPoint (iPtr, sp_globals.processor.truetype.sfnt_xmax, sp_globals.processor.truetype.sfnt_ymin, &x0, &y0);
if (err != NO_ERR) {
    sp_report_error(PARAMS2 (fix15)err);
    return(FALSE);
}

	/* update bbox if limits changed */
if (x0 < *xmin)
    *xmin = x0;
if (y0 < *ymin)
    *ymin = y0;
if (x0 > *xmax)
    *xmax = x0;
if (y0 > *ymax)
    *ymax = y0;

return NO_ERR;
}

#if INCL_APPLESCAN
#define TEST(p,bit) (p[bit>>3]&(0x80>>(bit&7)))
void dump_bitmap(PARAMS2 bitmap,Psw) 
GDECL
BitMap *bitmap;
point_t *Psw;
{
fix31 xsw, ysw;
fix31 xorg,yorg;
fix15 xsize,ysize;
ufix8 *ptr;
ufix16 y, xbit1, xbit2, curbit;
ufix16 xwid;

xsw = (fix31)Psw->x << sp_globals.poshift;
ysw = (fix31)Psw->y << sp_globals.poshift;

xorg = (fix31)bitmap->bounds.left << 16;
yorg = (fix31)bitmap->bounds.top << 16;

xsize = bitmap->bounds.right - bitmap->bounds.left;
ysize = bitmap->bounds.bottom - bitmap->bounds.top;


open_bitmap(xsw,ysw,xorg,yorg,xsize,ysize);

xwid = bitmap->rowBytes;
ptr = (ufix8 *)bitmap->baseAddr;

for (y = 0; y < ysize; y++)
	{
	curbit = 0;
	while (1)
		{
		while (TEST(ptr,curbit) == 0 && curbit < xsize)
			curbit++;
		if (curbit >= xsize)
			break;	
		xbit1 = curbit;
		while (TEST(ptr,curbit) != 0 && curbit < xsize)
			curbit++;
		xbit2 = curbit;
		set_bitmap_bits(y,xbit1,xbit2);
		}
	ptr += xwid;
	}

close_bitmap();
}
#endif

/* end of file tt_iface.c */

#pragma Code ()
