/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	FrontEnd/ufe.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: ufe.h,v 1.1 97/04/18 11:45:07 newdeal Exp $
 *
 ***********************************************************************/

/*                                                                            *
 *  Copyright 1992, as an unpublished work by Bitstream Inc., Cambridge, MA   *
 *                               Patent Pending                               *
 *                                                                            *
 *         These programs are the sole property of Bitstream Inc. and         *
 *           contain its proprietary and confidential information.            *
 *                           All rights reserved                              *
 *                                                                            *
******************************************************************************/
/**********************************************************************************************
    FILE:       UFE.H
	PROJECT:	4-in-1
	AUTHOR:		DW
	CONTENTS:	Constants and type definitions
				Macros
				Function prototypes
				
***********************************************************************************************/
/*
 *
 *	26-Aug-92	DKW	Updated eFontProtocol set names from 4-in-1 design detail
 *					Draft version 1.2 of 11-Aug-92.
 *	28-Jul-92	DKW	creation
 *
 *	ufe.h	support enumerations/structures for the 4-in-1 product
 *
 *	NOTE:	This file should be included AFTER spdo_prv.h or speedo.h to
 *			utilize the standard Bitstream portable datatypes.
*/
/********* Revision Control Information **********************************
 * Revision 2.19  93/03/15  14:00:12  roberte
 * Release
 * 
 * Revision 2.13  93/02/25  15:43:40  roberte
 * Corrected the fi_sel_* macros for reentrant code.
 * Added symbol BAD_BCID.
 * 
 * Revision 2.12  93/02/23  17:29:05  roberte
 * Changed function prototype of fi_check_ssd() to match actual defintion.
 * 
 * Revision 2.11  93/02/19  12:29:38  roberte
 * Added some bit macros for the "flags" field of Symbol Set Type.
 * Added the field "flags" to SymbolSetType.
 * 
 * Revision 2.10  93/02/08  16:16:08  roberte
 * Changed prototype of fi_get_char_bbox() adding STACKFAR macro for the void * param.
 * 
 * Revision 2.9  93/02/04  13:48:03  roberte
 * Added fields char_requirement_msw and char_requirement_lsw to SymbolSetType.
 * Added function prototype for fi_check_ssd().
 * 
 * Revision 2.8  93/01/29  08:58:09  roberte
 * Added reentrant code macros PARAMS1 and PARAMS2 to support REENTRANT_ALLOC.
 * 
 * Revision 2.7  93/01/13  15:19:04  roberte
 * Moved default definitions of PROC_PCL, PROC_TRUETYPE and PROC_TYPE1 to speedo.h
 * 
 * Revision 2.6  93/01/06  13:42:15  roberte
 * Moved enumerations of eFontProtocols and eFontProcessors
 * to speedo.h
 * 
 * Revision 2.5  93/01/04  17:18:10  laurar
 * put WDECL in front of fi_get_char_width.
 * 
 * Revision 2.4  92/12/29  14:31:43  roberte
 * Moved some function prototypes here from frontend.c
 * 
 * Revision 2.3  92/12/09  16:23:34  laurar
 * take out a control z.
 * 
 * Revision 2.2  92/12/09  15:35:11  laurar
 * add STACKFAR to PSName in GlyphCode definition.
 * 
 * Revision 2.1  92/12/02  12:30:12  laurar
 * change prototype for fi_reset for DLL only.
 * 
 * Revision 2.0  92/11/19  15:42:16  roberte
 * Release
 * 
 * Revision 1.18  92/11/18  13:33:48  roberte
 * Changed all fi_sel_*() macros so that they reference &array[0] as the
 * pointer value.  Silences compiler warnings.
 * 
 * Revision 1.17  92/11/18  12:50:20  roberte
 * Added externs of the PS encoding arrays so the macros
 * to select them will work.
 * 
 * Revision 1.16  92/11/17  15:53:14  laurar
 * Add function prototypes for RESTRICTED ENVIRON.
 * 
 * Revision 1.15  92/11/03  12:25:43  roberte
 * Added prototyping for tr_get_char_width() function.
 * 
 * Revision 1.14  92/11/02  18:34:32  laurar
 * Add WDECL macro (for Windows CALLBACK functions) and STACKFAR to parameters that are pointers.
 * These changes are for DLL.\
 * 
 * Revision 1.13  92/10/30  13:57:22  roberte
 * Corrected stupid mistake in ssTABLE_SIZE.
 * 
 * Revision 1.12  92/10/30  13:23:03  roberte
 * Increased ss_TABLE_SIZE to accomodate the 2 MS sets.  Had
 * the constant conditionally compile correctly based on INCL_MS_SETS.
 * 
 * Revision 1.11  92/10/29  11:15:08  roberte
 * Completed support for MSSymbol and MSWingdings as a PCL symbol set.
 * 
 * Revision 1.10  92/10/29  10:41:12  roberte
 * Added SSID's for Symbol and Wingdings
 * 
 * Revision 1.9  92/10/16  15:20:59  roberte
 * Function fi_get_char_width() must return a fix31, not a fix15
 * 
 * Revision 1.8  92/10/15  17:33:20  roberte
 * Added support for PROTOS_AVAIL or not PROTOS_AVAIL compile option.
 * Also changed all fi_sel_PSISOLatin() and other similar macros to
 * pass the address of the exceptionList array.
 * 
 * Revision 1.7  92/10/01  13:45:31  roberte
 * Added some macros to allow switching off of columns in the 
 * Character Mapping Table (gMasterGlyphCodes[]) in cmt.c and the
 * code to access these columns in cmt.c.
 * 
 * Revision 1.6  92/09/29  14:11:41  weili
 * put preprocessor directives for separating the font processors
 * 
 * Revision 1.5  92/09/26  17:01:20  roberte
 * Added copyright header, RCS marker and comments.
 * 
 * Revision 1.4  92/09/25  14:21:39  weili
 * Moved the macros for selecting encoding arrays from msst.c to here
 * 
 * Revision 1.3  92/09/18  15:08:40  roberte
 * *** empty log message ***
 * 
 *****************************************************************************/

/* -------------Character Mapping Table compile options:-------------- */
/* to shut off  MSL's in table, #define CMT_MSL	0 in useropt.h */
#ifndef CMT_MSL
#define CMT_MSL	1
#endif

/* to shut off  Unicodes's in table, #define CMT_UNI	0 in useropt.h */
#ifndef CMT_UNI
#define CMT_UNI	1
#endif

/* to shut off  PostScript Names in table, #define CMT_PS	0 in useropt.h */
#ifndef CMT_PS
#define CMT_PS	1
#endif

/* to shut off User in table, #define CMT_USR	0 in useropt.h */
#ifndef CMT_USR
#define CMT_USR	1
#endif


/* Symbol Set Table Constants: */
#ifdef INCL_MS_SETS
#define	  ss_TABLE_SIZE 	53
#else
#define	  ss_TABLE_SIZE 	51
#endif
#define   ss_MAX_ENTRY	   	256
#define	  UNKNOWN	   	-1 
#define	  NOT_USED		0

/* return values for Character Mapping compare functions */
#define  LESS_THAN      -1
#define  EQUAL_TO        0


/* HP Symbol Set Identification Codes: */
#define SSID_Din10L		( 10*32+'L'-64 )
#define SSID_Din11L		( 11*32+'L'-64 )
#define SSID_Din12L		( 12*32+'L'-64 )
#define SSID_Din13L		( 13*32+'L'-64 )
#define SSID_Din9L		( 9*32+'L'-64 )
#define	SSID_DeskTop		( 7*32+'J'-64 )
#define	SSID_EC94L1		( 'N'-64 )
#define	SSID_German		( 'G'-64 )
#define	SSID_ISO10		( 3*32+'S'-64 )
#define	SSID_ISO11		( 'S'-64 )
#define	SSID_ISO14		( 'K'-64 )
#define	SSID_ISO15		( 'I'-64 )
#define	SSID_ISO16		( 4*32+'S'-64 )
#define	SSID_ISO17		( 2*32+'S'-64 )
#define	SSID_ISO2		( 2*32+'U'-64 )
#define	SSID_ISO21		( 1*32+'G'-64 )
#define	SSID_ISO25		( 'F'-64 )
#define	SSID_ISO4		( 1*32+'E'-64 )
#define	SSID_ISO57		( 2*32+'K'-64 )
#define	SSID_ISO6		( 'U'-64 )
#define	SSID_ISO60		( 'D'-64 )
#define	SSID_ISO61		( 1*32+'D'-64 )
#define	SSID_ISO69		( 1*32+'F'-64 )
#define	SSID_ISO84		( 5*32+'S'-64 )
#define	SSID_ISO85		( 6*32+'S'-64 )
#define SSID_ISO8859Lat2	( 2*32+'N'-64 )
#define SSID_ISO8859Lat5	( 5*32+'N'-64 )
#define	SSID_LEGAL		( 1*32+'U'-64 )
#define SSID_MAC12J		( 12*32+'J'-64 )
#define	SSID_MATH8		( 8*32+'M'-64 )
#define	SSID_MSPubl		( 6*32+'J'-64 )
#define	SSID_PC8		( 10*32+'U'-64 )
#define	SSID_PC850		( 12*32+'U'-64 )
#define SSID_PC852_Lat2		( 17*32+'U'-64 )
#define	SSID_PC8DN		( 11*32+'U'-64 )
#define SSID_PC8TK		( 9*32+'T'-64 )
#define	SSID_PiFont		( 15*32+'U'-64 )
#define SSID_PSEncode		NOT_USED
#define	SSID_PSMath		( 5*32+'M'-64 )
#define	SSID_PSText		( 10*32+'J'-64 )
#define	SSID_ROMAN8		( 8*32+'U'-64 )
#define	SSID_R8EXT		( 'E'-64 )
#define	SSID_Spanish		( 1*32+'S'-64 )
#define SSID_USER		UNKNOWN		
#define	SSID_VNIntl		( 13*32+'J'-64 )
#define	SSID_VNMath		( 6*32+'M'-64 )
#define	SSID_VNUS		( 14*32+'J'-64 )
#define SSID_Win3_1		( 19*32+'U'-64 )
#define SSID_Win3_1_Lat2	( 9*32+'E'-64 )
#define SSID_Win3_1_Lat5	( 5*32+'T'-64 )
#define	SSID_Windows		( 9*32+'U'-64 )
#define	SSID_Symbol		( 19*32+'M'-64 )
#define	SSID_Wingding		( 579*32+'L'-64 )


/* some handy macros for setting gMasterSymbolSet[0]
	to one of 4 PostScript encoding arrays,
	or to one of 2 Microsoft Unicode "custom" sets */
		/* Adobe standard encoding */
#if REENTRANT_ALLOC
#define	fi_sel_PSEncode(pArg)	set_exceptionList (pArg, &PSEncodeSet[0])
#else
#define	fi_sel_PSEncode()	set_exceptionList (&PSEncodeSet[0])
#endif

		/* Adobe dingbats encoding */
#if REENTRANT_ALLOC
#define fi_sel_PSDingbat(pArg)	set_exceptionList (pArg, &PSDingbatSet[0])
#else
#define fi_sel_PSDingbat()	set_exceptionList (&PSDingbatSet[0])
#endif

		/* Adobe symbol encoding */
#if REENTRANT_ALLOC
#define fi_sel_PSSymbol(pArg)	set_exceptionList (pArg, &PSSymbolSet[0])
#else
#define fi_sel_PSSymbol()	set_exceptionList (&PSSymbolSet[0])
#endif

		/* Adobe ISO Latin encoding */
#if REENTRANT_ALLOC
#define fi_sel_PSISOLatin(pArg)	set_exceptionList (pArg, &PSISOLatinSet[0])
#else
#define fi_sel_PSISOLatin()	set_exceptionList (&PSISOLatinSet[0])
#endif

		/* Microsoft wingding encoding */
#if REENTRANT_ALLOC
#define fi_sel_MSWingding(pArg)	fi_select_symbol_set(pArg, SSID_Wingding)
#else
#define fi_sel_MSWingding()	fi_select_symbol_set(SSID_Wingding)
#endif

		/* Microsoft symbol encoding */
#if REENTRANT_ALLOC
#define fi_sel_MSSymbol(pArg) fi_select_symbol_set(pArg, SSID_Symbol)
#else
#define fi_sel_MSSymbol() fi_select_symbol_set(SSID_Symbol)
#endif


/*-------- SymbolSetType "flags" bit settings: --------*/
/* symbol set is 8 bits, 32-127 and 160-255 printable: */
#define BITS8_1	1
/* symbol set is 8 bits, 0-255 printable: */
#define BITS8_2	2
/* mask for isolating the symbol set type bits: */
#define SS_TYPE_MASK 0x03

/* symbol set is compatible with a TrueType resident font: */
#define TT_OK	4

/* an impossible BCID: */
#define BAD_BCID 0x7fff

/* 
 *	global generalized data structure to provide everything a
 *	font processor would want 
*/
typedef struct {
	buff_t	Font;		/* points to font information, size */
	real	Matrix[6];	/* real CTM data */
	specs_t STACKFAR *Gen_specs;	/* ptr to the general specs needed to run the world */
} ufe_struct;

/* Symbol Set Table Exception List Entry */
typedef	struct	TableEntry
	{
	ufix8		ssIndex;
	fix15	  	charID;
	} ssEntry, *ssEntryPtr;


/* Symbol Set Table List Entry */
typedef	struct	ListEntry
	{
	fix15			symSetID;
	fix15			parentSymSetID;
	ssEntryPtr		exceptionList;
	ufix32  		char_requirement_msw; /* character requirement MSW */
    ufix32		    char_requirement_lsw; /* character requirement LSW */	
	ufix8			flags;			 /* other flags */
	} SymbolSetType;



/* Character Mapping Table Entry */
typedef  struct   Mapping_Table
{
   ufix16   BCID;
#if CMT_MSL
   ufix16   MSL;
#endif
#if CMT_UNI
   ufix16   Unicode;
#endif
#if CMT_PS
   char     STACKFAR*PSName;
#endif
#if CMT_USR
   ufix16   User;
#endif
} GlyphCodes;

/*
 *	function prototypes for unified functions
*/
#if   WINDOWS_4IN1
void WDECL fi_reset PROTO((PROTO_DECL2 callback_struct STACKFAR*, eFontProtocol, eFontProcessor));
#else
void fi_reset PROTO((PROTO_DECL2 eFontProtocol, eFontProcessor));
#endif
boolean WDECL fi_set_specs PROTO((PROTO_DECL2 ufe_struct STACKFAR *));
#if RESTRICTED_ENVIRON
boolean WDECL fi_make_char PROTO((PROTO_DECL2 ufix8 STACKFAR *, void STACKFAR *));
#else
boolean WDECL fi_make_char PROTO((PROTO_DECL2 void STACKFAR *));
#endif
#if RESTRICTED_ENVIRON
fix31 WDECL fi_get_char_width PROTO((PROTO_DECL2 ufix8 STACKFAR *, void STACKFAR *));
#else
fix31 WDECL fi_get_char_width PROTO((PROTO_DECL2 void STACKFAR *));
#endif
boolean fi_get_char_bbox PROTO((PROTO_DECL2 void STACKFAR*, bbox_t *));
char *load_font PROTO((char *, eFontProcessor));

boolean	fi_select_symbol_set PROTO((PROTO_DECL2 ufix16	ssid));
boolean	fi_set_cset PROTO((PROTO_DECL2 ufix16 ssid, void *userList[], ufix16 inProtocol, \
		     ufix16 first_code, ufix16 last_code));
void set_exceptionList PROTO((PROTO_DECL2 ssEntryPtr Entry0_Ptr));
boolean  fi_CharCodeXLate  PROTO((void STACKFAR *inValue, void  STACKFAR *outValue, \
			ufix16 inCharProtocol,ufix16 outCharProtocol));
#if REENTRANT_ALLOC
boolean  BSearch PROTO((PROTO_DECL2 fix15 STACKFAR*indexPtr, fix15 (*ComparisonTo)(SPEEDO_GLOBALS *,fix31, void STACKFAR *), \
					void STACKFAR *theValue, fix31 nElements));
#else
boolean  BSearch PROTO((fix15 STACKFAR*indexPtr, fix15 (*ComparisonTo)(fix31, void STACKFAR *), \
					void STACKFAR *theValue, fix31 nElements));
#endif
#if RESTRICTED_ENVIRON
FUNCTION real tr_get_char_width PROTO((PROTO_DECL2 ufix8 STACKFAR*font_ptr, CHARACTERNAME STACKFAR*charname));
#else
FUNCTION real tr_get_char_width PROTO((PROTO_DECL2 CHARACTERNAME *charname));
#endif

boolean	fi_check_ssd PROTO((pclHdrType *lfontHdr, ufix16 ssid, boolean *found_ssd));

extern ssEntry PSEncodeSet[];
extern ssEntry PSDingbatSet[];
extern ssEntry PSISOLatinSet[];
extern ssEntry PSSymbolSet[];

/* EOF: ufe.h */

