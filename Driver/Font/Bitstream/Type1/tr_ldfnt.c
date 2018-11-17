/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/tr_ldfnt.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tr_ldfnt.c,v 1.1 97/04/18 11:45:18 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TrLdFntCode")

#undef INCL_PFB
#define INCL_PFB 1

/*************************  L D _ F N T _ A . C ******************************
*                                                                            *
*  Copyright 1990 as an unpublished work by Bitstream Inc., Cambridge, MA    *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/

/*************************  L D _ F N T _ A . C ******************************
 *                                                                           *
 * This is the Type A font loader for testing PS QEM 2.0                     *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 * $Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_ldfnt.c,v 1.1 97/04/18 11:45:18 newdeal Exp $
 *
 * $Log:	tr_ldfnt.c,v $
 * Revision 1.1  97/04/18  11:45:18  newdeal
 * Initial revision
 * 
 * Revision 1.1.10.1  97/03/29  07:05:57  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:17:29  brianc
 * support Type1
 * 
 * Revision 28.24  93/03/15  13:10:44  roberte
 * Release
 * 
 * Revision 28.17  93/03/11  15:47:59  roberte
 * Changed #if __MSDOS to #ifdef MSDOS.
 * 
 * Revision 28.16  93/03/09  13:08:18  roberte
 * Tended to #include files, various platforms.
 * 
 * Revision 28.15  93/03/09  12:16:29  roberte
 *  Replaced #if INTEL tests with #ifdef MSDOS as appropriate.
 * 
 * Revision 28.14  93/01/21  13:22:59  roberte
 * Reentrant code work.  Added macros to support sp_global_ptr parameter pass in all essential call threads.
 * 
 * Revision 28.13  93/01/14  10:13:07  roberte
 * Changed all data references to sp_globals.processor.type1.<varname> since these are all part of union structure there. 
 * 
 * Revision 28.12  93/01/04  17:22:43  roberte
 * Changed all the report_error calls back to sp_report_error to 
 * be in line with the spdo_prv.h changes.
 * 
 * Revision 28.11  92/12/28  11:22:39  roberte
 * Correctly typed tr_error() return value as void.
 * 
 * Revision 28.10  92/12/15  13:00:06  roberte
 * Added #if PROTOS_AVAIL conditional around prototype of compstr().
 * Changed read_long() to tr_read_long() so won't conflict with
 * sp_read_long() macros.
 * 
 * Revision 28.9  92/12/02  11:50:16  laurar
 * change calls to sp_report_error to report_error, so that the function will
 * be called properly with the DLL.
 * 
 * Revision 28.8  92/11/24  13:15:16  laurar
 * include fino.h
 * 
 * Revision 28.7  92/11/19  15:35:16  weili
 * Release
 * 
 * Revision 26.9  92/11/18  18:55:50  laurar
 * Add STACKFAR.
 * 
 * Revision 26.8  92/11/16  18:28:46  laurar
 * Add STACKFAR for Windows; add #ifdef's for functions that Windows calls
 * differently; add function compstr() which calls the appropriate strcmp
 * library function depending on the platform.
 * 
 * Revision 26.7  92/10/21  09:58:24  davidw
 * Turned off DEBUG
 * 
 * Revision 26.6  92/10/19  09:36:25  davidw
 * Changed the default FontBBox values to -2000,-2000 2000, 2000 as per Adobe Type 1 Font Book
 * To fix bug of all zero FontBBox.
 * 
 * Revision 26.5  92/10/16  16:40:28  davidw
 * WIP: working on t1 bug, not done yet
 * 
 * Revision 26.4  92/10/01  12:12:46  laurar
 * include stdio.h for PC (NULL is defined there);
 * initialize local_font_ptr->no_subrs, so if font has to 
 * be unloaded, it will not free unallocated memory.
 * 
 * Revision 26.3  92/09/28  16:45:10  roberte
 * Changed "#include "fnt.h" to "#include "fnt_a.h".
 * Same include file needs different name for 4in1.
 * 
 * Revision 26.2  92/07/22  21:29:09  ruey
 * take out redundant define for FONTNAMESIZE. 
 * 
 * Revision 26.1  92/06/26  10:25:49  leeann
 * Release
 * 
 * Revision 25.1  92/04/06  11:42:13  leeann
 * Release
 * 
 * Revision 24.1  92/03/23  14:10:29  leeann
 * Release
 * 
 * Revision 23.2  92/03/23  11:49:16  leeann
 * accept empty name strings
 * consider replaced characters in read_string (allows a space to
 * exist between strings)
 * 
 * 
 * Revision 23.1  92/01/29  17:01:29  leeann
 * Release
 * 
 * Revision 22.2  92/01/28  14:28:43  leeann
 * support strangely constructed fonts by accepting the first
 * font BBox encountered, regardless of whether it is in the
 * font dictionary or the private dictionary.
 * 
 * Revision 22.1  92/01/20  13:32:52  leeann
 * Release
 * 
 * Revision 21.1  91/10/28  16:45:18  leeann
 * Release
 * 
 * Revision 20.1  91/10/28  15:28:59  leeann
 * Release
 * 
 * Revision 18.2  91/10/22  15:59:14  leeann
 * support radix numbers
 * 
 * Revision 18.1  91/10/17  11:40:34  leeann
 * Release
 * 
 * Revision 17.5  91/10/07  09:55:36  leeann
 * fix to add_encoding for RESTRICTED_ENVIRON
 * 
 * Revision 17.4  91/09/24  16:46:11  leeann
 * when unloading font - don't try to free staticly allocated notdef
 * 
 * Revision 17.3  91/09/24  16:16:44  leeann
 * add tr_get_leniv function
 * 
 * Revision 17.2  91/09/24  11:50:00  leeann
 * allow four bytes following eexec to be > 126
 * 
 * Revision 17.1  91/06/13  10:45:12  leeann
 * Release
 * 
 * Revision 16.2  91/06/13  10:26:20  leeann
 * malloc and fill encoding structures properly when
 * NAME_STRUCT is on
 * 
 * Revision 16.1  91/06/04  15:35:51  leeann
 * Release
 * 
 * Revision 15.4  91/06/04  15:23:57  leeann
 * add RESTRICTED_ENVIRON functions to replace sscanf
 * 
 * Revision 15.3  91/05/15  14:05:12  leeann
 * declare sp_globals.processor.type1.current_font to be extern
 * 
 * Revision 15.2  91/05/13  13:54:05  leeann
 * put fnt_file_type default assignment inside PFB conditional
 * 
 * Revision 15.1  91/05/08  18:08:00  leeann
 * Release
 * 
 * Revision 14.1  91/05/07  16:29:48  leeann
 * Release
 * 
 * Revision 13.3  91/05/07  13:49:50  leeann
 * initialize font type to PFA
 * 
 * Revision 13.2  91/05/06  09:51:39  leeann
 * fix get encoding array for RESTRICTED_ENVIRON
 * 
 * Revision 13.1  91/04/30  17:04:29  leeann
 * Release
 * 
 * Revision 12.1  91/04/29  14:54:51  leeann
 * Release
 * 
 * Revision 11.5  91/04/24  17:47:21  leeann
 * read the useropt.h file
 * 
 * Revision 11.4  91/04/24  10:37:40  leeann
 * change default values for bluescale, blueshift, and bluefuzz
 * 
 * Revision 11.3  91/04/23  10:43:48  leeann
 * support Hybrid fonts
 * 
 * Revision 11.2  91/04/10  13:19:23  leeann
 *  support character names as structures
 * 
 * Revision 11.1  91/04/04  10:58:26  leeann
 * Release
 * 
 * Revision 10.4  91/04/03  17:53:04  leeann
 * make tag_bytes a fix31
 * 
 * Revision 10.3  91/03/26  09:51:00  leeann
 * fix index on read binary function
 * 
 * Revision 10.2  91/03/22  15:57:59  leeann
 * clean up code, performance improvements
 * 
 * Revision 10.1  91/03/14  14:30:47  leeann
 * Release
 * 
 * Revision 9.2  91/03/14  14:17:02  leeann
 * fixup function declarations, global variables
 * 
 * Revision 9.1  91/03/14  10:06:17  leeann
 * Release
 * 
 * Revision 8.7  91/03/13  17:32:32  leeann
 * add support for RESTRICTED_ENVIRON
 * 
 * Revision 8.6  91/02/20  16:08:52  leeann
 * make PFB support conditional with INCL_PFB flag
 * 
 * Revision 8.5  91/02/20  09:03:25  joyce
 * *** empty log message ***
 * 
 * Revision 8.4  91/02/14  10:40:20  joyce
 * Optimized the pfb code
 * 
 * Revision 8.3  91/02/13  16:05:56  joyce
 * Provided loader with the ability to load .pfb files
 * Major changes:
 * (1) Added new function: get_tag(), which reads the first
 *     six bytes of each binary/ascii section of the file
 *     and determines the mode (ascii or binary) and the
 *     number of bytes for the next section
 * (2) Changed the next_byte function to accomodate .pfb
 *     files by converting binary bytes to ascii.
 * 
 * Revision 8.2  91/01/31  13:46:13  leeann
 * read int as short in "read_int" function
 * 
 * Revision 8.1  91/01/30  19:03:11  leeann
 * Release
 * 
 * Revision 7.3  91/01/30  18:54:11  leeann
 * clarify integer sizes
 * 
 * Revision 7.2  91/01/22  14:38:22  leeann
 * correct spelling of include ctypes=>ctype
 * 
 * Revision 7.1  91/01/22  14:27:23  leeann
 * Release
 * 
 * Revision 6.5  91/01/22  14:20:13  leeann
 * include file ctypes.h added
 * 
 * Revision 6.4  91/01/17  19:16:29  joyce
 * Made standard_encoding function global (removed static declaration)
 * to be called by an application. The function now checks whether
 * a special encoding array has aleady been allocated, and if so,
 * deallocates it.
 * 
 * Revision 6.3  91/01/17  18:32:03  joyce
 * added code to tr_set_encode - if unable to allocate
 * memory for encoding array at any point, then deallocate
 * all memory allocated up to that point, and free encoding pointer
 * 
 * Revision 6.2  91/01/16  18:20:23  joyce
 * fixed tr_unload_font to free all allocated memory
 * in the font structure, and to check whether a pointer
 * is valid before calling free
 * 
 * Revision 6.1  91/01/16  10:53:26  leeann
 * Release
 * 
 * Revision 5.9  91/01/15  17:51:55  leeann
 * turn off timer
 * 
 * Revision 5.8  91/01/15  17:21:19  joyce
 * Added new function, tr_error, which:
 *   1. Calls sp_report_error with error code
 *   2. Calls unload_font to free any memory that might have
 *      been allocated
 * All calls to sp_report_error have been changed to tr_error
 * 
 * Revision 5.7  91/01/10  18:34:20  joyce
 * Fixed error with ".notdef" string in tr_set_encode
 * 
 * Revision 5.6  91/01/10  12:08:00  leeann
 * put font definition in include file, fix get_byte bug
 * 
 * Revision 5.5  91/01/10  11:23:05  joyce
 * 1. Changed direct printf error messages to calls to sp_report_error
 * 2. Added 3 functions: tr_set_encode, tr_get_encode, tr_unload_font
 * 
 * Revision 5.4  91/01/07  19:55:11  leeann
 * optimize, remove static buffers, remove file access code
 * 
 * Revision 5.3  91/01/07  10:59:52  joyce
 * optimized switch statement
 * 
 * Revision 5.2  90/12/26  16:58:20  leeann
 * put timing code into the loader
 * 
 * Revision 5.1  90/12/12  17:20:05  leeann
 * Release
 * 
 * Revision 4.2  90/12/12  17:15:01  leeann
 * fix syntax error, change STORAGESIZE
 * 
 * Revision 4.1  90/12/12  14:45:49  leeann
 * Release
 * 
 * Revision 3.2  90/12/06  15:22:31  leeann
 * declare malloc, set font type to binary in fopen
 * 
 * Revision 3.1  90/12/06  10:28:14  leeann
 * Release
 * 
 * Revision 2.1  90/12/03  12:56:55  mark
 * Release
 * 
 * Revision 1.2  90/12/03  12:21:49  joyce
 * Changed include line to reference new include file names:
 * fnt_a.h -> fnt.h, ps_qem.h -> type1.h
 * 
 * Revision 1.1  90/11/30  11:27:46  joyce
 * Initial revision
 * 
 * Revision 1.4  90/11/29  15:14:06  leeann
 * change function names, allow multiple font load
 * 
 * Revision 1.3  90/11/19  15:50:11  joyce
 * changed function names to fit spec
 * 
 * Revision 1.2  90/09/17  13:27:34  roger
 * put in rcsid[] for RCS and put in a ";" so that a 
 * goto will work on the pc
 * 
 * Revision 1.1  90/08/13  15:27:10  arg
 * Initial revision
 * 
 *                                                                           *
 *  1) 14 Mar 90  jsc  Created                                               *
 *                                                                           *
 *  2) 30 Mar 90  jsc  Modified to accept either hex or binary eexec         *
 *                     encrypted data                                        *
 *                                                                           *
 *  3) 23 Jul 90  jsc  Modified put_binary() to defer execution of character *
 *                     string decryption to run time.                        *
 *                                                                           *
 ****************************************************************************/

static char     rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_ldfnt.c,v 1.1 97/04/18 11:45:18 newdeal Exp $";

#define   _TYPE1_       /* define this constant so that the */
#include "spdo_prv.h"    /* speedo read functions do not get */
#undef     _TYPE1_      /* substituted for the type1 read functions. */

#include "fino.h"
#include "stdef.h"
#include "type1.h"

#ifdef __GEOS__
#include <Ansi/ctype.h>
#include <Ansi/string.h>
/* malloc stuff */
extern void* Malloc(word blockSize);
extern void Free(void *blockPtr);
#undef malloc
#define malloc(s) (Malloc((s)))
#undef free
#define free(s) if ((s)!=NULL) Free((s))
#endif

#ifndef __GEOS__
#ifdef MSDOS
#include <stdio.h>
#endif
#endif

/* you need one of the following includes, depending on your system: */
#ifndef __GEOS__
#if defined(__STDC__) || defined(vms)
#include <string.h>
#else
#include <memory.h>
#endif
#endif
#include <math.h>
#ifdef __GEOS__
extern double fabs(double __x);
#endif
#include "fnt_a.h"
#include "errcodes.h"
#include "tr_fdata.h"
#ifndef __GEOS__
#include <ctype.h>
#endif
#if TIMEIT
#include <sys/types.h>
#endif

#define   DEBUG      0


#if   WINDOWS_4IN1
#include <windows.h>
#endif

#if DEBUG
#ifdef __GEOS__
#define SHOW(X)
#else
#include <stdio.h>
#define SHOW(X) printf("    X = %d\n", X)
#endif
#else
#define SHOW(X)
#endif

/* Flag bit assignments for character type table */
#define CTRL_CHAR  1
#define SPACE_CHAR 2
#define PUNCT_CHAR 4
#define HEX_DIGIT  8
#define EOL_CHAR  16
#define OTHER_CHAR 0

#if RESTRICTED_ENVIRON
#define MAX_CHARSTRINGS_LOADED 256	/* Maximum number of charstrings to
					 * load */
#define MAX_SUBRS_LOADED       500	/* Maximum number of subrs to load */
#endif

#define CHARNAMESIZE   32	/* Maximum character name size */

#if INCL_PFB
#define   PFA        0
#define   PFB        1
#endif

extern unsigned char *charname_tbl[];	/* Extended encoding table */

static boolean  decrypt_mode;	/* Decrypt mode enabled when True */
static boolean  hex_mode;	/* Hex input mode enabled when True */
static ufix16   decrypt_r;
static ufix16   decrypt_c1 = 52845;
static ufix16   decrypt_c2 = 22719;
static ufix8    look_ahead[4];

ufix8           replaced_byte;
static boolean  replaced_avail;

#if INCL_PFB
static ufix16   fnt_file_type;
static fix31    tag_bytes;
boolean         reading_tag;
static ufix16   tag_mode;
#endif

/* Character type table for parsing */
static fix15    char_type[] =
{
 CTRL_CHAR,			/* 00 */
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 SPACE_CHAR,			/* Tab */
 SPACE_CHAR | EOL_CHAR,		/* Line feed */
 CTRL_CHAR,
 CTRL_CHAR,
 SPACE_CHAR | EOL_CHAR,		/* Carriage return */
 CTRL_CHAR,
 CTRL_CHAR,

 CTRL_CHAR,			/* 10 */
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,
 CTRL_CHAR,

 SPACE_CHAR,			/* 20 Space */
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,			/* 23 numbersign */
 OTHER_CHAR,
 PUNCT_CHAR,			/* 25 % */
 OTHER_CHAR,
 OTHER_CHAR,
 PUNCT_CHAR,			/* 28 ( */
 PUNCT_CHAR,			/* 29 ) */
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 PUNCT_CHAR,			/* 2F / */

 OTHER_CHAR | HEX_DIGIT,	/* 30 0 */
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR,
 OTHER_CHAR,
 PUNCT_CHAR,			/* 3C < */
 OTHER_CHAR,
 PUNCT_CHAR,			/* 3E > */
 OTHER_CHAR,

 OTHER_CHAR,			/* 40 @ */
 OTHER_CHAR | HEX_DIGIT,	/* 41 A */
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,

 OTHER_CHAR,			/* 50 P */
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 PUNCT_CHAR,			/* 5B [ */
 OTHER_CHAR,
 PUNCT_CHAR,			/* 5D ] */
 OTHER_CHAR,
 OTHER_CHAR,

 OTHER_CHAR,			/* 60 ' */
 OTHER_CHAR | HEX_DIGIT,	/* 61 a */
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR | HEX_DIGIT,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,

 OTHER_CHAR,			/* 70 p */
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 OTHER_CHAR,
 PUNCT_CHAR,			/* 7B { */
 OTHER_CHAR,
 PUNCT_CHAR,			/* 7D } */
 OTHER_CHAR,
 CTRL_CHAR,
};

#ifdef OLDWAY
/* global pointer to current_font */
extern font_data STACKFAR*current_font;
#endif

#if NAME_STRUCT
static CHARACTERNAME notdef_struct = {7, (unsigned char *) ".notdef"};
static CHARACTERNAME *notdef = &notdef_struct;
#define CHARSIZE sizeof(CHARACTERNAME)+strlen(charactername)
#else
static CHARACTERNAME *notdef = (CHARACTERNAME *) ".notdef";
#define CHARSIZE strlen(charactername)+1
#endif

#if RESTRICTED_ENVIRON
static fix15    no_charstrings_loaded;	/* count of charstrings in memory */

static struct {
	ufix16          offset;	/* offset in buffer where charstring is
				 * loaded */
	ufix16         *tbl_entry;	/* location in charstrings_t table
					 * indicating this */
	/* string is in memory */
	fix15           charstring_size;	/* number of bytes in the
						 * charstring */
}
                loaded_charstrings[MAX_CHARSTRINGS_LOADED];
ufix32          file_byte_count;
ufix16          offset_from_top;
ufix16          offset_from_bottom;

/* static function prototypes: */
static boolean base2decimal PROTO((fix15 base,char STACKFAR*buffer,
				fix15 STACKFAR*number));
static boolean read_int PROTO((PROTO_DECL2 fix15 STACKFAR*pdata));
static boolean tr_read_long PROTO((PROTO_DECL2 fix31 STACKFAR*pdata));
static boolean read_long_array PROTO((PROTO_DECL2 fix31 STACKFAR*datafix15 STACKFAR*pn));
static boolean read_real PROTO((PROTO_DECL2 real STACKFAR*pdata));
static boolean read_real_array PROTO((PROTO_DECL2 real STACKFAR*data,fix15 STACKFAR*pn));
static boolean read_boolean PROTO((PROTO_DECL2 boolean STACKFAR*pdata));
static fix15 read_token PROTO((PROTO_DECL2 char STACKFAR*buf,fix15 count));
static fix15 read_name PROTO((PROTO_DECL2 char STACKFAR*buf,fix15 count));
static fix15 read_string PROTO((char STACKFAR*buf,fix15 count));
static fix15 read_binary PROTO((char STACKFAR*buf,fix15 count));
static	fix15 asctohex PROTO((ufix8 asciivalue));
static boolean read_byte PROTO((ufix8 STACKFAR*pbyte));
#if RESTRICTED_ENVIRON
static boolean clear_encoding PROTO((PROTO_DECL2 font_data STACKFAR*font_ptr));
#else
static void clear_encoding PROTO((PROTO_DECL2 font_data STACKFAR*font_ptr));
#endif
static boolean add_encoding PROTO((PROTO_DECL2 font_data STACKFAR*font_ptr,fix15 index,
			ufix8 STACKFAR*charactername));
static void clear_hints PROTO((font_data STACKFAR*font_ptr));
static boolean parse_tag PROTO((ufix16 *tag_mode,fix31 *tag_bytes,
			ufix8 STACKFAR*tag_string));
#if DEBUG
static void print_binary PROTO((PROTO_DECL2 ufix8 *buf, fix15 n));
#endif
#if RESTRICTED_ENVIRON
static void unload_charstring PROTO((PROTO_DECL1));
static boolean get_space PROTO((PROTO_DECL2 ufix16 space_needed));
#if INCL_PFB
static boolean remove_tags PROTO((PROTO_DECL2 fix15 tag_position, unsigned char STACKFAR *char_data, fix15 total_bytes));
#endif
#endif

FUNCTION long 
latol(lpS, nChars)
#if UNIX
	char           *lpS;
#else
	char far       *lpS;
#endif
	short          STACKFAR*nChars;

{
	long            r = 0, s = 1;
	short           len = 0;

	if (*lpS == '-') {
		s = -1;
		++lpS;
		len++;
	}
	while (*lpS >= '0' && *lpS <= '9') {
		r *= 10;
		r += *lpS++ - '0';
		len++;
	}

	if (nChars)
		*nChars = len;

	return r * s;
}

FUNCTION float 
latof(lpS)
#if UNIX
	char           *lpS;
#else
	char far       *lpS;
#endif
{
	float           tmp1, tmp2;
	short           i;

	tmp1 = (float) latol(lpS, (short STACKFAR*)&i);

	lpS += i;

	if (*lpS == '.') {
		long            div = 1;

		lpS++;

		while (*lpS == '0') {
			++lpS;
			div *= 10;
		}

		tmp2 = (float) latol(lpS, (ufix8 STACKFAR*)NULL);

		while (tmp2 >= 1.0)
			tmp2 /= 10.0;

		tmp1 += tmp2 / (float) div;
	}
	return tmp1;
}
#endif

/****************************************************************************/
/* to replace sscanf for __GEOS__ */
#ifdef __GEOS__
FUNCTION long 
latol(lpS, nChars)
	char 		*lpS;
	short          STACKFAR*nChars;

{
	long            r = 0, s = 1;
	short           len = 0;

	if (*lpS == '-') {
		s = -1;
		++lpS;
		len++;
	}
	while (*lpS >= '0' && *lpS <= '9') {
		r *= 10;
		r += *lpS++ - '0';
		len++;
	}

	if (nChars)
		*nChars = len;

	return r * s;
}

FUNCTION float 
latof(lpS)
	char 		*lpS;
{
	float           tmp1, tmp2;
	short           i;

	tmp1 = (float) latol(lpS, (short STACKFAR*)&i);

	lpS += i;

	if (*lpS == '.') {
		long            div = 1;

		lpS++;

		while (*lpS == '0') {
			++lpS;
			div *= 10;
		}

		tmp2 = (float) latol(lpS, (ufix8 STACKFAR*)NULL);

		while (tmp2 >= 1.0)
			tmp2 /= 10.0;

		tmp1 += tmp2 / (float) div;
	}
	return tmp1;
}
#endif
/****************************************************************************/



#if RESTRICTED_ENVIRON
FUNCTION boolean WDECL tr_load_font(PARAMS2 font_ptr, buffer_size)
	GDECL
	ufix8          STACKFAR*font_ptr;
	ufix16          buffer_size;
#else
FUNCTION boolean tr_load_font(PARAMS2 font_ptr)
	GDECL
	font_data     **font_ptr;
#endif
{
#if RESTRICTED_STATS
	ufix16          encoding_data_start, encoding_data_end, subr_data_start, subr_data_end, start_charstring_names, end_charstring_names;
	charstrings_t  *rest_strings;
#endif
#if RESTRICTED_ENVIRON
	static ufix8    buffer[1024];
#else
	ufix8           buffer[1024];
#endif
	fix15           i;
	real            tempr;
	fix15           tempi;
	fix31           templi;
	boolean         tempb;
	boolean         foundFontBBox;
	fix15           index, subr_size;
#if RESTRICTED_ENVIRON
	static char     charactername[CHARNAMESIZE];
#else
	char            charactername[CHARNAMESIZE];
#endif
	fix15           max_no_charstrings;
	fix15           charstring_size;
	ufix8           byte;
	long            eexec_data_offset;
	boolean         char_str_read;
	boolean         subrs_found;
	boolean         private_read;
	boolean         ignore_private;

#if INCL_PFB
	ufix8           buf[2];
#endif

	boolean         read_int();
	boolean  	tr_read_long();
	boolean         read_real();
	boolean         read_long_array();
	boolean         read_real_array();
	boolean         read_boolean();
	boolean         hybrid_font;
	fix15           asctohex();
	void            print_real_array();
	void            print_long_array();
	fix15           read_token();
	fix15           read_name();
	fix15           read_string();
	fix15           read_binary();
	boolean         read_byte();
	boolean         add_encoding();
#if RESTRICTED_ENVIRON
	boolean         clear_encoding();
	fix15           old_file_byte_count;
#else
	void            clear_encoding();
#endif
	void            standard_encoding();
	void            print_encoding();
	void            clear_hints();
/*	void           *malloc();*/
	font_data      STACKFAR*local_font_ptr;
#if INCL_PFB
#if   !(WINDOWS_4IN1)
	boolean         WDECL get_byte();
#endif
	boolean         parse_tag();
	boolean         get_tag_string();
	char            tag_string[6];
#endif

#if TIMEIT
#include <time.h>
#include <sys/types.h>
#include <sys/timeb.h>
	struct timeb    ElapseBegin, ElapseEnd;
	long            CpuBegin, CpuEnd;
	long            seconds, result_seconds, result_milliseconds;
	float           real_time;
#endif

#if RESTRICTED_ENVIRON
	ufix16          space_avilable, space_needed;
	void            unload_charstring();
	boolean         get_space();
	boolean         inquire_about_space();
	subrs_t        STACKFAR*subrs_ptr;
	ufix8          STACKFAR*subr_value_ptr;
	ufix8          STACKFAR*charstring_value_ptr;
	charstrings_t  STACKFAR*chars_ptr;
	char          STACKFAR*STACKFAR*encoding_ptr;
#endif
void tr_error();

#if INCL_PFB
	reading_tag = FALSE;
#endif

#if TIMEIT
	/* get the system clock */
	ftime(&ElapseBegin);

	/* get the cpu clock */
	CpuBegin = clock();
#endif

#if RESTRICTED_ENVIRON
	if (buffer_size < sizeof(font_data)) {
		sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
		return FALSE;
	}
	sp_globals.processor.type1.current_font = (font_data STACKFAR *)local_font_ptr = (font_data STACKFAR*) font_ptr;
	offset_from_top = sizeof(font_data);
	offset_from_bottom = buffer_size;
	no_charstrings_loaded = 0;
	file_byte_count = 0;
#else
	if ((local_font_ptr = (font_data *) malloc(sizeof(font_data))) == NULL) {
		sp_report_error(PARAMS2 TR_NO_ALLOC_FONT);
		return FALSE;
	}
#endif

	local_font_ptr->no_subrs = 0;
	local_font_ptr->paint_type = 0;
	replaced_avail = FALSE;
	decrypt_mode = FALSE;
	hex_mode = FALSE;
	hybrid_font = FALSE;
	local_font_ptr->no_charstrings = 0;
	local_font_ptr->font_bbox.xmin = 0.0;
	local_font_ptr->font_bbox.ymin = 0.0;
	local_font_ptr->font_bbox.xmax = 0.0;
	local_font_ptr->font_bbox.ymax = 0.0;
	clear_hints(local_font_ptr);
	local_font_ptr->leniv = 4;
	char_str_read = FALSE;
	subrs_found = FALSE;
	private_read = FALSE;
	ignore_private = FALSE;
	foundFontBBox = FALSE;
#if INCL_PFB
	fnt_file_type = PFA;

	/* Read first byte in file */
	if (!read_byte((ufix8 STACKFAR*)&(buf[0])))
		return FALSE;

	/* if 80 hex (tag code), assume it's a .pfb file */
	if (buf[0] == 0x80) {
#if RESTRICTED_ENVIRON
		sp_globals.processor.type1.current_font->font_file_type = PFB;
#endif
		tag_string[0] = buf[0];
		for (i = 1; i < 6; i++)
			if (!read_byte((char STACKFAR*)&tag_string[i])) {
				tr_error(PARAMS2 TR_INV_FILE, local_font_ptr);	/* ERROR MESSAGE Not a
									 * valid Type1 file */
				return FALSE;
			}
		fnt_file_type = PFB;
		if (parse_tag(&tag_mode, &tag_bytes, (char STACKFAR*)tag_string) == FALSE) {
			tr_error(PARAMS2 TR_INV_FILE, local_font_ptr);	/* ERROR MESSAGE Not a
								 * valid Type1 file */
			return FALSE;
		}
	} else {		/* check wither it's a .pfa */
		if (buf[0] == '%') {
#if RESTRICTED_ENVIRON
			sp_globals.processor.type1.current_font->font_file_type = PFA;
#endif
			fnt_file_type = PFA;
		} else {	/* If first byte is neither "%" nor "80",
				 * it's not a Type1 font file */
			tr_error(PARAMS2 TR_INV_FILE, local_font_ptr);	/* ERROR MESSAGE Not a
								 * valid Type1 file */
			return FALSE;
		}
	}

#endif
	while (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 101) >= 0) {
		if (compstr((ufix8 STACKFAR*)buffer, "/") == 0) {	/* / token? */
			if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 101) < 0) {
				tr_error(PARAMS2 TR_NO_READ_LITNAME, local_font_ptr);	/* ERROR MESSAGE Cannot
										 * read literal name
										 * after /" */
				return FALSE;
			}
			switch (buffer[0]) {
			case 'B':
				if (compstr((ufix8 STACKFAR*)buffer, "BlueValues") == 0) {	/* /BlueValues? */
					if (ignore_private)
						continue;
					if (!read_long_array(PARAMS2 local_font_ptr->font_hints.pblue_values, &local_font_ptr->font_hints.no_blue_values)) {
						tr_error(PARAMS2 TR_NO_READ_VALUES, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read
												 * BlueValues array" */
						return FALSE;
					}
#if DEBUG
					printf("BlueValues = ");
					print_long_array(local_font_ptr->font_hints.pblue_values, local_font_ptr->font_hints.no_blue_values);
					printf("\n");
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "BlueScale") == 0) {	/* /BlueScale? */
					if (ignore_private)
						continue;
					if (!read_real(PARAMS2 (real STACKFAR*)&tempr)) {
						tr_error(PARAMS2 TR_NO_READ_SCALE, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read BlueScale
												 * value" */
						return FALSE;
					}
					local_font_ptr->font_hints.blue_scale = tempr;
#if DEBUG
					printf("BlueScale = %7.5f\n", local_font_ptr->font_hints.blue_scale);
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "BlueShift") == 0) {	/* /BlueShift? */
					if (ignore_private)
						continue;
					if (!tr_read_long(PARAMS2 &(local_font_ptr->font_hints.blue_shift))) {
						tr_error(PARAMS2 TR_NO_READ_SHIFT, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read BlueShift
												 * value" */
						return FALSE;
					}
#if DEBUG
					printf("BlueShift = %ld\n", local_font_ptr->font_hints.blue_shift);
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "BlueFuzz") == 0) {	/* /BlueFuzz? */
					if (ignore_private)
						continue;
					if (!tr_read_long(PARAMS2 &(local_font_ptr->font_hints.blue_fuzz))) {
						tr_error(PARAMS2 TR_NO_READ_FUZZ, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read BlueFuzz
												 * value" */
						return FALSE;
					}
#if DEBUG
					printf("BlueFuzz = %ld\n", local_font_ptr->font_hints.blue_fuzz);
#endif
				}
				break;

			case 'F':
				if (compstr((ufix8 STACKFAR*)buffer, "FullName") == 0) {	/* /FullName? */
					if (private_read)
						continue;
					if (read_string(local_font_ptr->full_name, FULLNAMESIZE) < 0) {
						tr_error(PARAMS2 TR_NO_READ_FULLNAME, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FullName
												 * value" */
						return FALSE;
					}
#if DEBUG
					printf("FullName = %s\n", local_font_ptr->full_name);
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "FontName") == 0) {	/* /FontName? */
					if (private_read)
						continue;
					if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 101) < 0) {
						tr_error(PARAMS2 TR_NO_READ_NAMTOK, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FontName
												 * / token" */
						return FALSE;
					}
					if (compstr((ufix8 STACKFAR*)buffer, "/") != 0) {
						continue;	/* Ignore unless
								 * followed by '/' */
					}
					if (read_token(PARAMS2 (char STACKFAR*)local_font_ptr->font_name, FONTNAMESIZE) < 0) {
						tr_error(PARAMS2 TR_NO_READ_NAME, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FontName" */
						return FALSE;
					}
#if DEBUG
					printf("FontName =  %s\n", local_font_ptr->font_name);
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "FontMatrix") == 0) {	/* /FontMatrix? */
					if (private_read)
						continue;
					if (!read_real_array(PARAMS2 (real STACKFAR*)local_font_ptr->font_matrix, (fix15 STACKFAR*)&tempi)) {
						tr_error(PARAMS2 TR_NO_READ_MATRIX, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read
												 * FontMatrix" */
						return FALSE;
					}
					if (tempi != 6) {
						tr_error(PARAMS2 TR_MATRIX_SIZE, local_font_ptr);	/* ERROR MESSAGE "***
												 * FontMatrix has %d
												 * elements", tempi); */
						return FALSE;
					}
#if DEBUG
					printf("FontMatrix = ");
					print_real_array(local_font_ptr->font_matrix, tempi);
					printf("\n");
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "FontBBox") == 0) {
					real rtemp = 0.0;	/* temp to check for zero FontBBox */

					if (foundFontBBox)	/* accept only the first FontBBox found */
						continue;

					foundFontBBox = TRUE;

					if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
						/* Read open bracket or brace */
						tr_error(PARAMS2 TR_NO_READ_OPENBRACKET, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read { or [ in
													 * FontBBox" */
						return FALSE;
					}

					if ((compstr((ufix8 STACKFAR*)buffer, "{") != 0) && (strcmp((char *)buffer, "[") != 0)) {
						tr_error(PARAMS2 TR_NO_READ_OPENBRACKET, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read { or [ in
													 * FontBBox" */
						return FALSE;
					}

					if (!read_real(PARAMS2 (real STACKFAR*)&tempr)) {
						tr_error(PARAMS2 TR_NO_READ_BBOX0, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FontBBox
												 * element 0" */
						return FALSE;
					}
					local_font_ptr->font_bbox.xmin = tempr;
					rtemp += tempr;

					if (!read_real(PARAMS2 (real STACKFAR*)&tempr)) {
						tr_error(PARAMS2 TR_NO_READ_BBOX1, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FontBBox
												 * element 1" */
						return FALSE;
					}
					local_font_ptr->font_bbox.ymin = tempr;
					rtemp += tempr;

					if (!read_real(PARAMS2 (real STACKFAR*)&tempr)) {
						tr_error(PARAMS2 TR_NO_READ_BBOX2, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FontBBox
												 * element 2" */
						return FALSE;
					}
					local_font_ptr->font_bbox.xmax = tempr;
					rtemp += tempr;

					if (!read_real(PARAMS2 (real STACKFAR*)&tempr)) {
						tr_error(PARAMS2 TR_NO_READ_BBOX3, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read FontBBox
												 * element 3" */
						return FALSE;
					}
					local_font_ptr->font_bbox.ymax = tempr;
					rtemp += tempr;

					/*	Here we compare the sum of all coordinates against
					 *	an impossibly small character to check for a passed
					 *	zero font bounding box.
					*/
					if (fabs(rtemp) < 0.01) {
						/*
						 *	A zero sized FontBBox was passed along,
						 *	force the FontBBox to the default BBox
						 *	as specified in the Adobe Type 1 Font format book,
						 *	page 26.
						*/
						local_font_ptr->font_bbox.xmin = -2000.0;
						local_font_ptr->font_bbox.ymin = -2000.0;
						local_font_ptr->font_bbox.xmax = 2000.0;
						local_font_ptr->font_bbox.ymax = 2000.0;
					}
#if DEBUG
					printf("FontBBox = {%3.1f %3.1f %3.1f %3.1f}\n",
					    local_font_ptr->font_bbox.xmin,
					    local_font_ptr->font_bbox.ymin,
					    local_font_ptr->font_bbox.xmax,
					    local_font_ptr->font_bbox.ymax);
#endif

				} else if (compstr((ufix8 STACKFAR*)buffer, "FamilyBlues") == 0) {	/* /FamilyBlues? */
					if (ignore_private)
						continue;
					if (!read_long_array(PARAMS2 local_font_ptr->font_hints.pfam_blues, &(local_font_ptr->font_hints.no_fam_blues))) {
						tr_error(PARAMS2 TR_NO_READ_FAMILY, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read
												 * FamilyBlues array" */
						return FALSE;
					}
#if DEBUG
					printf("FamilyBlues = ");
					print_long_array(local_font_ptr->font_hints.pfam_blues, local_font_ptr->font_hints.no_fam_blues);
					printf("\n");
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "FamilyOtherBlues") == 0) {	/* /FamilyOtherBlues? */
					if (!read_long_array(PARAMS2 local_font_ptr->font_hints.pfam_other_blues, &(local_font_ptr->font_hints.no_fam_other_blues))) {
						tr_error(PARAMS2 TR_NO_READ_FAMOTHER, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read
												 * FamilyOtherBlues
												 * array" */
						return FALSE;
					}
#if DEBUG
					printf("FamilyOtherBlues = ");
					print_long_array(local_font_ptr->font_hints.pfam_other_blues, local_font_ptr->font_hints.no_fam_other_blues);
					printf("\n");
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "ForceBold") == 0) {	/* /ForceBold? */
					if (ignore_private)
						continue;
					if (!read_boolean(PARAMS2 &(local_font_ptr->font_hints.force_bold))) {
						tr_error(PARAMS2 TR_NO_READ_BOLD, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read ForceBold
												 * value" */
						return FALSE;
					}
#if DEBUG
					printf("ForceBold = %s\n", local_font_ptr->font_hints.force_bold ? "true" : "false");
#endif
				}
				break;

			case 'S':
				if (compstr((ufix8 STACKFAR*)buffer, "StdHW") == 0) {	/* /StdHW? */
					if (ignore_private)
						continue;
					if (!read_real_array(PARAMS2 (real STACKFAR*)&tempr, (fix15 STACKFAR*)&tempi) ||
					    (tempi != 1)) {
						tr_error(PARAMS2 TR_NO_READ_STDHW, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read StdHW
												 * value" */
						return FALSE;
					}
					local_font_ptr->font_hints.stdhw = tempr;
#if DEBUG
					printf("StdHW = %3.1f\n", local_font_ptr->font_hints.stdhw);
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "StdVW") == 0) {	/* /StdVW? */
					if (ignore_private)
						continue;
					if (!read_real_array(PARAMS2 (real STACKFAR*)&tempr, (fix15 STACKFAR*)&tempi) ||
					    (tempi != 1)) {
						tr_error(PARAMS2 TR_NO_READ_STDVW, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read StdVW
												 * value" */
						return FALSE;
					}
					local_font_ptr->font_hints.stdvw = tempr;
#if DEBUG
					printf("StdVW = %3.1f\n", local_font_ptr->font_hints.stdvw);
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "StemSnapH") == 0) {	/* /StemSnapH? */
					if (ignore_private)
						continue;
					if (!read_real_array(PARAMS2 local_font_ptr->font_hints.pstem_snap_h, (ufix8 STACKFAR*)&(local_font_ptr->font_hints.no_stem_snap_h))) {
						tr_error(PARAMS2 TR_NO_READ_SNAPH, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read StemSnapH
												 * array" */
						return FALSE;
					}
#if DEBUG
					printf("StemSnapH = ");
					print_real_array(local_font_ptr->font_hints.pstem_snap_h, local_font_ptr->font_hints.no_stem_snap_h);
					printf("\n");
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "StemSnapV") == 0) {	/* /StemSnapV? */
					if (ignore_private)
						continue;
					if (!read_real_array(PARAMS2 local_font_ptr->font_hints.pstem_snap_v, (fix15 STACKFAR*)&(local_font_ptr->font_hints.no_stem_snap_v))) {
						tr_error(PARAMS2 TR_NO_READ_SNAPV, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read StemSnapV
												 * array" */
						return FALSE;
					}
#if DEBUG
					printf("StemSnapV = ");
					print_real_array(local_font_ptr->font_hints.pstem_snap_v, local_font_ptr->font_hints.no_stem_snap_v);
					printf("\n");
#endif
				} else if (compstr((ufix8 STACKFAR*)buffer, "Subrs") == 0) {	/* /Subrs? */
					if (ignore_private)
						continue;
					if (hybrid_font) {
						/*
						 * Note: Here we assume that
						 * the standard defined in
						 * the   
						 */
						/*
						 * "Adobe Type 1 Font Format"
						 * sec 9.2 is followed, that
						 * is 
						 */
						/*
						 * the first set of subrs
						 * read are low res, and the
						 * second 
						 */
						/* are high res.                                           */
#if LOW_RES
						if (subrs_found)	/* for low res read the
									 * first group of subrs */
# else
							if (!subrs_found)	/* for high res read
										 * second group of subrs */
# endif
							{
								subrs_found = TRUE;
								continue;
							}
					}
					subrs_found = TRUE;
					if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
						tr_error(PARAMS2 TR_NO_READ_NUMSUBRS, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read number of
												 * Subrs" */
						return FALSE;
					}
					local_font_ptr->no_subrs = tempi;
					/*
					 * malloc space for array of subr
					 * entries 
					 */
#if RESTRICTED_ENVIRON
					/* assign space for subrs array */
					/* is there room ? */
					space_needed = sizeof(subrs_t) * tempi;
					if (!get_space(PARAMS2 space_needed)) {
						/* abandon ship */
						sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
						return FALSE;
					}
					/* allocate the space */
					subrs_ptr = (subrs_t STACKFAR*) ((ufix32) font_ptr + (ufix32) offset_from_top);
					local_font_ptr->subrs_offset = offset_from_top;
#if RESTRICTED_DEBUG
					printf("Subrs table loaded at offset %x\n", offset_from_top);
#endif
					offset_from_top += space_needed;
#else
					if ((local_font_ptr->subrs =
					     (subrs_t *) malloc(sizeof(subrs_t) * tempi)) == NULL) {
						tr_error(PARAMS2 TR_NO_SPC_SUBRS, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot malloc space
												 * for subrs " */
						return FALSE;
					}
#endif
#if RESTRICTED_STATS
					subr_data_start = offset_from_top;
#endif

					for (i = 0; i < local_font_ptr->no_subrs; i++) {
						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
							tr_error(PARAMS2 TR_NO_READ_DUPTOK, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read dup token
													 * for subr" */
							return FALSE;
						}
						while (compstr((ufix8 STACKFAR*)buffer, "dup") != 0) {
							if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
								tr_error(PARAMS2 TR_NO_READ_DUPTOK, local_font_ptr);	/* ERROR MESSAGE "***
														 * Cannot read dup token
														 * for subr" */
								return FALSE;
							}
						}

						if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
							tr_error(PARAMS2 TR_NO_READ_SUBRINDEX, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read subr
													 * index" */
							return FALSE;
						}
						index = tempi;

						if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
							tr_error(PARAMS2 TR_NO_READ_BINARY, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read binary
													 * data size for Subr" */
							return FALSE;
						}
						subr_size = tempi;
#if DEBUG
						printf("\nSubr %d, %d bytes\n", index, subr_size);
#endif

						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
							tr_error(PARAMS2 TR_NO_READ_SUBRTOK, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read RD token
													 * for subr" */
							return FALSE;
						}
#if RESTRICTED_ENVIRON
						/* load a subr */
						/*
						 * initialize the data
						 * structure 
						 */
						subrs_ptr[index].subr_size = subr_size;

						/* is there room ? */
						if (!get_space(PARAMS2 subr_size)) {
							/* abandon ship */
							sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
							return FALSE;
						} else
							/* allocate the space */
							subr_value_ptr = (ufix8 STACKFAR*) font_ptr + offset_from_top;
						subrs_ptr[index].data_offset = offset_from_top;
						if (read_binary(subr_value_ptr, subr_size) != subr_size) {
							tr_error(PARAMS2 TR_NO_READ_SUBRBIN, local_font_ptr);
							/*
							 * ERROR ME SSAGE "***
							 * Cannot read subr
							 * binary data" 
							 */
							return FALSE;
						}
#if RESTRICTED_DEBUG
						printf("Subr %i loaded at offset %x\n", index,
						       subrs_ptr[index].data_offset);
#endif
						offset_from_top += subr_size;

#else
						/*
						 * malloc the space for the
						 * subr 
						 */
						if ((local_font_ptr->subrs[index].value = (ufix8 *) malloc(subr_size))
						    == NULL) {
							tr_error(PARAMS2 TR_NO_SPC_SUBRS, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot malloc space
													 * for subrs" */
							return FALSE;
						}
						/* fill in the size */
						local_font_ptr->subrs[index].size = subr_size;

						if (read_binary(local_font_ptr->subrs[index].value, subr_size) != subr_size) {
							tr_error(PARAMS2 TR_NO_READ_SUBRBIN, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read subr
													 * binary data" */
							return FALSE;
						}
#endif
					}
#if RESTRICTED_STATS
					subr_data_end = offset_from_top - 1;
#endif
				}
				break;

			case 'U':
				if (compstr((ufix8 STACKFAR*)buffer, "UniqueID") == 0) {	/* /UniqueID? */
					if (private_read)
						continue;
					if (!tr_read_long(PARAMS2 &(local_font_ptr->font_hints.unique_id)))
						continue;
#if DEBUG
					printf("UniqueID =  %ld\n", local_font_ptr->font_hints.unique_id);
#endif
				}
				break;

			case 'E':
				if (compstr((ufix8 STACKFAR*)buffer, "Encoding") == 0) {	/* /Encoding? */
					if (private_read)
						continue;
					if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 101) < 0) {
						tr_error(PARAMS2 TR_NO_READ_TOKAFTERENC, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read token
													 * after Encoding" */
						return FALSE;
					}
					if (compstr((ufix8 STACKFAR*)buffer, "StandardEncoding") == 0) {
#if RESTRICTED_ENVIRON
						local_font_ptr->encoding_offset = NULL;
#else
						local_font_ptr->encoding = NULL;
						standard_encoding(local_font_ptr);
#endif
#if DEBUG
						printf("Encoding = StandardEncoding\n");
#endif
						continue;
					}
#if RESTRICTED_ENVIRON
					/*
					 * get the space for the encoding
					 * array 
					 */
					/* is there room ? */
					space_needed = 256 * sizeof(ufix16);
					if (!get_space(PARAMS2 space_needed)) {
						/* abandon ship */
						sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
						return FALSE;
					}
					/* allocate the space */
					encoding_ptr = (char STACKFAR*STACKFAR*) ((ufix32) font_ptr + (ufix32) offset_from_top);
					local_font_ptr->encoding_offset = offset_from_top;
					offset_from_top += space_needed;
					if (clear_encoding(PARAMS2 local_font_ptr) == FALSE)
						return FALSE;
#else
					/* allocate the 256 pointer table */
					if ((local_font_ptr->encoding = (CHARACTERNAME **) malloc(256 * sizeof(CHARACTERNAME *))) == NULL) {
						tr_error(PARAMS2 TR_NO_SPC_ENC_ARR, local_font_ptr);	/* ERROR MESSAGE "**
												 * Unable to allocate
												 * storage for encoding
												 * array " */
						return FALSE;
					}
#endif
					/*
					 * set all the entries to point to
					 * not defined 
					 */
					clear_encoding(PARAMS2 local_font_ptr);
#if RESTRICTED_STATS
					encoding_data_start = offset_from_top;
#endif
					while (TRUE) {	/* Loop over encoding
							 * vector entries */
						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
							tr_error(PARAMS2 TR_NO_READ_ENCODETOK, local_font_ptr);	/* ERROR MESSAGE "Cannot
													 * read dup, def or
													 * readonly token for
													 * Encoding" */
							return FALSE;
						}
						while (TRUE) {	/* Look for encoding
								 * entry or end of
								 * encoding table */
							if (compstr((ufix8 STACKFAR*)buffer, "dup") == 0)	/* Start of encoding
											 * entry */
								break;
							if (compstr((ufix8 STACKFAR*)buffer, "def") == 0)	/* End of encoding table */
								goto end_encoding;
							if (compstr((ufix8 STACKFAR*)buffer, "readonly") == 0)	/* End of encoding table */
								goto end_encoding;
							if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
								tr_error(PARAMS2 TR_NO_READ_ENCODETOK, local_font_ptr);	/* ERROR MESSAGE "Cannot
														 * read dup, def or
														 * readonly token for
														 * Encoding" */
								return FALSE;
							}
						}

						if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
							tr_error(PARAMS2 TR_NO_READ_ENCODE, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read Encoding
													 * index" */
							return FALSE;
						}
						index = tempi;

						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 10) < 0) {	/* Read / before
											 * character name */
							tr_error(PARAMS2 TR_NO_READ_SLASH, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read / before
													 * charactername in
													 * Encoding" */
							return FALSE;
						}
						if (compstr((ufix8 STACKFAR*)buffer, "/") != 0) {	/* Not / character? */
							tr_error(PARAMS2 TR_NO_READ_SLASH, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read / before
													 * charactername in
													 * Encoding" */
							return FALSE;
						}
						if (read_token(PARAMS2 (char STACKFAR*)charactername, CHARNAMESIZE) < 0) {	/* Read character name */
							tr_error(PARAMS2 TR_NO_READ_CHARNAME, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read
													 * charactername" */
							return FALSE;
						}
						if (!add_encoding(PARAMS2 local_font_ptr, index, charactername)) {
							tr_error(PARAMS2 TR_NO_SPC_ENC_ENT, local_font_ptr);	/* ERROR MESSAGE "***
													 * Unable to malloc
													 * space for encoding
													 * entry" */
							return FALSE;
						}
					}
			end_encoding:
#if RESTRICTED_STATS
					encoding_data_end = offset_from_top - 1;
#endif
#if DEBUG
					print_encoding(local_font_ptr);
#endif
					;
				}
				break;

			case 'P':
				if (compstr((ufix8 STACKFAR*)buffer, "Private") == 0) {	/* /Private? */
					if (private_read) {	/* Second Private dict? */
						ignore_private = TRUE;
					}
					private_read = TRUE;
				}
				break;

			case 'O':
				if (compstr((ufix8 STACKFAR*)buffer, "OtherBlues") == 0) {	/* /OtherBlues? */
					if (ignore_private)
						continue;
					if (!read_long_array(PARAMS2 local_font_ptr->font_hints.pother_blues,
							     &(local_font_ptr->font_hints.no_other_blues))) {
						tr_error(PARAMS2 TR_NO_READ_OTHERBL, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read
												 * OtherBlues array" */
						return FALSE;
					}
#if DEBUG
					printf("OtherBlues = ");
					print_long_array(local_font_ptr->font_hints.pother_blues, local_font_ptr->font_hints.no_other_blues);
					printf("\n");
#endif
				}
				break;

			case 'L':
				if (compstr((ufix8 STACKFAR*)buffer, "LanguageGroup") == 0) {	/* /LanguageGroup? */
					if (ignore_private)
						continue;
					if (!tr_read_long(PARAMS2 &(local_font_ptr->font_hints.language_group))) {
						tr_error(PARAMS2 TR_NO_READ_LANGGRP, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read
												 * LanguageGroup value" */
						return FALSE;
					}
#if DEBUG
					printf("LanguageGroup = %d\n", local_font_ptr->font_hints.language_group);
#endif
				}
				break;

			case 'l':
				if (compstr((ufix8 STACKFAR*)buffer, "lenIV") == 0) {	/* /lenIV? */
					if (ignore_private)
						continue;
					if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
						tr_error(PARAMS2 TR_NO_READ_LENIV, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read lenIV
												 * value" */
						return FALSE;
					}
					local_font_ptr->leniv = tempi;
#if DEBUG
					printf("lenIV = %d\n", (int) local_font_ptr->leniv);
#endif
				}
				break;
			case 'h':
				if (compstr((ufix8 STACKFAR*)buffer, "hires") == 0)
					hybrid_font = TRUE;
				break;

			case 'C':
				if (compstr((ufix8 STACKFAR*)buffer, "CharStrings") == 0) {	/* /CharStrings? */
					if (char_str_read)	/* CharStrings already
								 * read? */
						continue;

					if (hybrid_font) {
						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 101) < 0) {
							tr_error(PARAMS2 TR_NO_READ_LITNAME, local_font_ptr);
							return FALSE;
						}
						/*
						 * This implementation of
						 * Hybrid fonts relies on     
						 */
						/*
						 * Adobe's implementation in
						 * Optima.  They           
						 */
						/*
						 * put the first set of
						 * Charstrings (we assume
						 * these 
						 */
						/*
						 * are low res) after an
						 * "if", and the second after  
						 */
						/*
						 * an ifelse. We do not
						 * interpret the if or ifelse   
						 */
						/* operators.                                        */
#if LOW_RES
						while (compstr((ufix8 STACKFAR*)buffer, "if") != 0)
#else
						while (compstr((ufix8 STACKFAR*)buffer, "ifelse") != 0)
#endif
							if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 101) < 0) {
								tr_error(PARAMS2 TR_NO_READ_LITNAME, local_font_ptr);
								return FALSE;
							}
					}
					if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
						tr_error(PARAMS2 TR_NO_READ_STRINGNUM, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot read number of
												 * CharStrings" */
						return FALSE;
					}
					max_no_charstrings = tempi;

#if RESTRICTED_ENVIRON
					/* is there room ? */
					space_needed = sizeof(charstrings_t) * max_no_charstrings;
					if (!inquire_about_space(space_needed)) {
						/* abandon ship */
						sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
						return FALSE;
					}
					/* allocate the space */
					chars_ptr = (charstrings_t STACKFAR*) ((ufix32) font_ptr + (ufix32) offset_from_top);
					local_font_ptr->charstrings_offset = offset_from_top;
#if RESTRICTED_DEBUG
					printf("CharStrings table loaded at offset %x\n", offset_from_top);
#endif
					offset_from_top += space_needed;
#else
					/*
					 * malloc the space for the
					 * charstrings array 
					 */
					if ((local_font_ptr->charstrings = (charstrings_t *)
					     malloc(sizeof(charstrings_t) * max_no_charstrings)) == NULL) {
						tr_error(PARAMS2 TR_NO_SPC_STRINGS, local_font_ptr);	/* ERROR MESSAGE "***
												 * Cannot malloc space
												 * for charstrings " */
						return FALSE;
					}
#endif
#if RESTRICTED_STATS
					start_charstring_names = offset_from_top;
#endif
					for (i = 0; i < max_no_charstrings; i++) {
						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
							tr_error(PARAMS2 TR_NO_READ_STRING, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read / or end
													 * token for CharString" */
							return FALSE;
						}
						while (TRUE) {	/* Look for character
								 * name or end of
								 * charstrings */
							if (compstr((ufix8 STACKFAR*)buffer, "/") == 0)
								break;
							if (compstr((ufix8 STACKFAR*)buffer, "end") == 0)
								goto end_charstrings;
							if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
								tr_error(PARAMS2 TR_NO_READ_STRING, local_font_ptr);	/* ERROR MESSAGE "***
														 * Cannot read / or end
														 * token for CharString" */
								return FALSE;
							}
						}
						if (read_name(PARAMS2 (char STACKFAR*)charactername, CHARNAMESIZE) < 0) {
							tr_error(PARAMS2 TR_NO_READ_CHARNAME, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read
													 * charactername" */
							return FALSE;
						}
#if RESTRICTED_ENVIRON
						/* store character name */
						space_needed = strlen(charactername) + 1;
						if (!get_space(PARAMS2 space_needed)) {
							/* abandon ship */
							sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
							return FALSE;
						}
						/* allocate the space */
						chars_ptr[local_font_ptr->no_charstrings].key_offset = offset_from_top;
#if RESTRICTED_DEBUG
						printf("Charname %s loaded at offset %x\n", charactername, offset_from_top);
#endif
#if   WINDOWS_4IN1
						lstrcpy((char STACKFAR*) ((ufix32) local_font_ptr + (ufix32) offset_from_top), charactername);
#else
						strcpy((char *) ((ufix32) local_font_ptr + (ufix32) offset_from_top), charactername);
#endif
						offset_from_top += space_needed;
#else
						/*
						 * allocate storage for
						 * character name 
						 */
						if ((local_font_ptr->charstrings[local_font_ptr->no_charstrings].key =
						     (CHARACTERNAME *) malloc(CHARSIZE)) == NULL) {
							tr_error(PARAMS2 TR_NO_SPC_STRINGS, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot malloc space
													 * for CharString" */
							return FALSE;
						}
#if NAME_STRUCT
						local_font_ptr->charstrings[local_font_ptr->no_charstrings].key->char_name =
							(unsigned char *) ((ufix32) (local_font_ptr->charstrings[local_font_ptr->no_charstrings].key) + (ufix32) sizeof(CHARACTERNAME));
#endif
						STRcpy((char *)local_font_ptr->charstrings[local_font_ptr->no_charstrings].key, (char *)charactername);

#endif

						if (!read_int(PARAMS2 (fix15 STACKFAR*)&tempi)) {
							tr_error(PARAMS2 TR_NO_READ_STRINGSIZE, local_font_ptr);	/* ERROR MESSAGE "***
														 * Cannot read
														 * charstring size" */
							return FALSE;
						}
						charstring_size = tempi;
#if DEBUG
						printf("\nCharString %s, %d bytes\n", charactername, charstring_size);
#endif
#if RESTRICTED_ENVIRON

#else
						/*
						 * allocate storage for
						 * character program string  
						 */
						if ((local_font_ptr->charstrings[local_font_ptr->no_charstrings].value = (ufix8 *) malloc(charstring_size)) == NULL) {
							tr_error(PARAMS2 TR_NO_SPC_STRINGS, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot malloc space
													 * for CharString" */
							return FALSE;
						}
#endif
						if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
							tr_error(PARAMS2 TR_NO_READ_STRINGTOK, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read RD token
													 * in charstring" */
							return FALSE;
						}
#if RESTRICTED_ENVIRON
						chars_ptr[local_font_ptr->no_charstrings].decryption_key = decrypt_r;
						chars_ptr[local_font_ptr->no_charstrings].file_position = file_byte_count;
						chars_ptr[local_font_ptr->no_charstrings].charstring_size = charstring_size;
						chars_ptr[local_font_ptr->no_charstrings].hex_mode = hex_mode;
						old_file_byte_count = file_byte_count;
#if INCL_PFB
						chars_ptr[local_font_ptr->no_charstrings].tag_bytes = tag_bytes;
#endif
						if (!inquire_about_space(charstring_size)) {
#if RESTRICTED_DEBUG
							printf("No room to load charstring data for %s\n", charactername);
#endif
							chars_ptr[local_font_ptr->no_charstrings].value_offset = 0;
							if (read_binary((ufix8 STACKFAR*)buffer, charstring_size) != charstring_size) {
								tr_error(PARAMS2 TR_NO_READ_STRINGBIN, local_font_ptr);
								/*
								 * ERROR MES
								 * SAGE 
								 * Cannot
								 * read
								 * charstring
								 * binary
								 * data" 
								 */
								return FALSE;
							}
						} else {
							no_charstrings_loaded++;
							charstring_value_ptr = (ufix8 STACKFAR*) font_ptr + offset_from_bottom
								- charstring_size;
							chars_ptr[local_font_ptr->no_charstrings].value_offset = offset_from_bottom - charstring_size;
							if (read_binary(charstring_value_ptr, charstring_size) != charstring_size) {
								tr_error(PARAMS2 TR_NO_READ_STRINGBIN, local_font_ptr);
								/*
								 * ERROR ME
								 * SSAGE "*
								 * Cannot
								 * read
								 * charstring
								 * binary
								 * data" 
								 */
								return FALSE;
							}
							offset_from_bottom -= charstring_size;
#if RESTRICTED_DEBUG
							printf("Charstring for %s loaded at offset %x\n", charactername, offset_from_bottom);
#endif
						}
						chars_ptr[local_font_ptr->no_charstrings].file_bytes = file_byte_count - old_file_byte_count;
#else
						if (read_binary(local_font_ptr->charstrings[local_font_ptr->no_charstrings].value, charstring_size) != charstring_size) {
							tr_error(PARAMS2 TR_NO_READ_STRINGBIN, local_font_ptr);	/* ERROR MESSAGE "***
													 * Cannot read
													 * charstring binary
													 * data" */
							return FALSE;
						}
						local_font_ptr->charstrings[local_font_ptr->no_charstrings].size = charstring_size;
#if DEBUG
						print_binary(PARAMS2 buffer, charstring_size);
#endif
#endif
						local_font_ptr->no_charstrings++;
					}
			end_charstrings:
#if RESTRICTED_STATS
					end_charstring_names = offset_from_top - 1;
#endif
					char_str_read = TRUE;
				}
			}	/* end switch (buffer[0]) */
		}
		 /* end if (compstr((ufix8 STACKFAR*)buffer, "/") == 0) */ 
		else if (compstr((ufix8 STACKFAR*)buffer, "eexec") == 0) {	/* eexec? */

			tempb = TRUE;	/* Expect hex data */
			if (!read_byte((ufix8 STACKFAR*)&look_ahead[0])) {	/* Read first byte after
								 * eexec */
				tr_error(PARAMS2 TR_NO_READ_EXEC1BYTE, local_font_ptr);	/* ERROR MESSAGE "***
										 * Cannot read first
										 * byte after eexec" */
				return FALSE;
			}
			if ((look_ahead[0] > 126) || ((char_type[look_ahead[0]] & (SPACE_CHAR | HEX_DIGIT)) == 0))	/* Not space or hex
															 * digit? */
				tempb = FALSE;	/* Expect binary data */
			for (i = 0; i < 3; i++) {
				if (!read_byte((ufix8 STACKFAR*)&look_ahead[i + 1])) {	/* Read next byte */
					tr_error(PARAMS2 TR_NO_READ_EXECBYTE, local_font_ptr);	/* ERROR MESSAGE "***
											 * Cannot read byte %d
											 * after eexec\n", (i +
											 * 2)); */
					return FALSE;
				}
				if ((look_ahead[i + 1] > 126) || ((char_type[look_ahead[i + 1]] & HEX_DIGIT) == 0))	/* Not hex digit? */
					tempb = FALSE;	/* Expect binary data */
			}

			decrypt_r = 55665;	/* Initialize decryption */
			decrypt_mode = TRUE;	/* Enable decryption */
			hex_mode = tempb;	/* Select binary or hex mode */
			if (hex_mode) {	/* skip first four hex bytes */
				look_ahead[0] = (asctohex(look_ahead[0]) << 4) + asctohex(look_ahead[1]);
				look_ahead[1] = (asctohex(look_ahead[2]) << 4) + asctohex(look_ahead[3]);
				decrypt_r = (look_ahead[0] + decrypt_r) * decrypt_c1 + decrypt_c2;
				decrypt_r = (look_ahead[1] + decrypt_r) * decrypt_c1 + decrypt_c2;
				read_byte((ufix8 STACKFAR*)&byte);
				read_byte((ufix8 STACKFAR*)&byte);
			} else
				/* update the decryption key */
				/* skip first bytes */
				for (i = 0; i < 4; i++)
					decrypt_r = (look_ahead[i] + decrypt_r) * decrypt_c1 + decrypt_c2;
		} else if (strcmp((char *)buffer, "closefile") == 0) {	/* closefile? */
			if (char_str_read) {	/* CharStrings read? */
				decrypt_mode = FALSE;
				hex_mode = FALSE;
#if RESTRICTED_ENVIRON
				sp_globals.processor.type1.current_font->offset_from_bottom = offset_from_bottom;
				sp_globals.processor.type1.current_font->offset_from_top = offset_from_top;
#else
				*font_ptr = local_font_ptr;
#endif
#if TIMEIT
				/* get the cpu clock end time */
				CpuEnd = clock();

				/* get the system end time */
				ftime(&ElapseEnd);
				result_seconds = ElapseEnd.time - ElapseBegin.time;
				result_milliseconds = ElapseEnd.millitm - ElapseBegin.millitm;
				real_time = (float) result_seconds + (((float) result_milliseconds) / 1000.0);

				/* print out the results */
				printf("Total elapse time is  %f \n", real_time);
				printf("Total cpu time is     %f \n", (double) (CpuEnd - CpuBegin) / 1000000.0);
#endif
#if RESTRICTED_STATS
				printf("Memory size is %x bytes\n", buffer_size);
				printf("  font_data structure loaded at offset 0\n");
				if (sp_globals.processor.type1.current_font->encoding_offset == 0)
					printf("  This font uses standard encoding.\n");
				else {
					printf("  Encoding array loaded at offset %x, total_bytes = %x\n",
					       sp_globals.processor.type1.current_font->encoding_offset,
					       256 * sizeof(ufix16));
					printf("    Encoding data starts at offset %x\n", encoding_data_start);
					printf("    Encoding data ends at offset %x\n", encoding_data_end);
				}
				printf("  Subrs structure loaded at offset %x \n", sp_globals.processor.type1.current_font->subrs_offset);
				printf("    Subrs data starts at offset %x\n", subr_data_start);
				printf("    Subrs data ends at offset %x\n", subr_data_end);
				printf("  Charstring structure loaded at offset %x, total bytes = %x\n",
				       sp_globals.processor.type1.current_font->charstrings_offset,
				       sizeof(charstrings_t) * sp_globals.processor.type1.current_font->no_charstrings);
				printf("    Charstring name data loaded at %x\n", start_charstring_names);
				printf("    Charstring name data ends at %x\n", end_charstring_names);
				rest_strings = (charstrings_t *) ((ufix32) sp_globals.processor.type1.current_font +
								  (ufix32) ((font_data *) sp_globals.processor.type1.current_font->charstrings_offset));
				/*
				 * look through the entire charstrings
				 * dictionary 
				 */
				for (i = 0; i < sp_globals.processor.type1.current_font->no_charstrings; i++) {
					/* is this character in memory ? */
					if (rest_strings[i].value_offset != 0)
						printf("Character %s loaded at offset %x\n",
						       (char *) ((ufix32) sp_globals.processor.type1.current_font + (ufix32) rest_strings[i].key_offset),
						       rest_strings[i].value_offset);
				}
#endif
				return TRUE;
			}
		}		/* if "closefile" */
	}			/* end of WHILE */
	tr_error(PARAMS2 TR_EOF_READ, local_font_ptr);	/* ERROR MESSAGE "*** End of
						 * file read" */
	return FALSE;
}


/* base2decimal                                                         */
/* This function converts an ascii number of any base 2-36 to decimal */

FUNCTION boolean 
base2decimal(base, buffer, number)
	fix15           base;	/* base of ascii representation */
	char           STACKFAR*buffer;	/* ascii representation of number */
	fix15          STACKFAR*number;	/* returned result of converting ascii ->
				 * binary */
{
	fix15           i;
	fix15           value, result;

	result = 0;
	i = 0;
#if WINDOWS_4IN1
	while (i < lstrlen(buffer)) {
#else
	while (i < strlen(buffer)) {
#endif
		switch (buffer[i]) {
		case '0':
			value = 0;
			break;
		case '1':
			value = 1;
			break;
		case '2':
			value = 2;
			break;
		case '3':
			value = 3;
			break;
		case '4':
			value = 4;
			break;
		case '5':
			value = 5;
			break;
		case '6':
			value = 6;
			break;
		case '7':
			value = 7;
			break;
		case '8':
			value = 8;
			break;
		case '9':
			value = 9;
			break;
		case 'A':
			value = 10;
			break;
		case 'B':
			value = 11;
			break;
		case 'C':
			value = 12;
			break;
		case 'D':
			value = 13;
			break;
		case 'E':
			value = 14;
			break;
		case 'F':
			value = 15;
			break;
		case 'G':
			value = 16;
			break;
		case 'H':
			value = 17;
			break;
		case 'I':
			value = 18;
			break;
		case 'J':
			value = 19;
			break;
		case 'K':
			value = 20;
			break;
		case 'L':
			value = 21;
			break;
		case 'M':
			value = 22;
			break;
		case 'N':
			value = 23;
			break;
		case 'O':
			value = 24;
			break;
		case 'P':
			value = 25;
			break;
		case 'Q':
			value = 26;
			break;
		case 'R':
			value = 27;
			break;
		case 'S':
			value = 28;
			break;
		case 'T':
			value = 29;
			break;
		case 'U':
			value = 30;
			break;
		case 'V':
			value = 31;
			break;
		case 'W':
			value = 32;
			break;
		case 'X':
			value = 33;
			break;
		case 'Y':
			value = 34;
			break;
		case 'Z':
			value = 35;
			break;
		case 'a':
			value = 10;
			break;
		case 'b':
			value = 11;
			break;
		case 'c':
			value = 12;
			break;
		case 'd':
			value = 13;
			break;
		case 'e':
			value = 14;
			break;
		case 'f':
			value = 15;
			break;
		case 'g':
			value = 16;
			break;
		case 'h':
			value = 17;
			break;
		case 'i':
			value = 18;
			break;
		case 'j':
			value = 19;
			break;
		case 'k':
			value = 20;
			break;
		case 'l':
			value = 21;
			break;
		case 'm':
			value = 22;
			break;
		case 'n':
			value = 23;
			break;
		case 'o':
			value = 24;
			break;
		case 'p':
			value = 25;
			break;
		case 'q':
			value = 26;
			break;
		case 'r':
			value = 27;
			break;
		case 's':
			value = 28;
			break;
		case 't':
			value = 29;
			break;
		case 'u':
			value = 30;
			break;
		case 'v':
			value = 31;
			break;
		case 'w':
			value = 32;
			break;
		case 'x':
			value = 33;
			break;
		case 'y':
			value = 34;
			break;
		case 'z':
			value = 35;
			break;
		default:
			return FALSE;
		}
		if (value > base) {
			return FALSE;	/* invalid syntax */
		}
		result = (result * base) + value;
		i = i + 1;
	}
	*number = result;
	return TRUE;
}


FUNCTION boolean 
read_int(PARAMS2 pdata)
	GDECL
	fix15          STACKFAR*pdata;	/* Data read */
{
	char            buffer[20];
	fix15           index;
	boolean         found_radix;

	fix15           read_token();

	if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
		return FALSE;
	}
	/* check if it is a radix number */
	found_radix = FALSE;
	index = 0;
	while (index < strlen(buffer)) {
		if (buffer[index] == '#') {	/* found a radix number */
			found_radix = TRUE;	/* set the flag */
			buffer[index] = 0;	/* take out the pound sign */
			break;	/* exit the loop - the index for the */
			/* poundsign is saved  in index  */
		}
		index++;
	}
	index++;

#if RESTRICTED_ENVIRON
	if (*buffer != '-' && *buffer != '+' && (*buffer < '0' || *buffer > '9'))
		return FALSE;
	*pdata = (fix15) latol((char STACKFAR*)buffer, (ufix8 STACKFAR*)NULL);
#else
#if WINDOWS_4IN1
   if (wvsprintf(pdata, "%hd", buffer) != 1)
      return FALSE;
#else
#ifdef __GEOS__
	if (*buffer != '-' && *buffer != '+' && (*buffer < '0' || *buffer > '9'))
		return FALSE;
	*pdata = (fix15) latol((char STACKFAR*)buffer, (ufix8 STACKFAR*)NULL);
#else
	if (sscanf(buffer, "%hd", pdata) != 1) {
		return FALSE;
	}
#endif
#endif
#endif
	/* if this is a radix number - determine the decimal value */
	if (found_radix) {
		if ((*pdata > 36) || (*pdata < 2)) {	/* pdata now contains
							 * the base */
			return FALSE;	/* only base 2 - 36 supported */
		}
		if (base2decimal(*pdata, (char STACKFAR*)&buffer[index], pdata) != 1) {
			return FALSE;
		}
	}
	return TRUE;
}


FUNCTION boolean 
tr_read_long(PARAMS2 pdata)
	GDECL
	fix31          STACKFAR*pdata;	/* Data read */
{
	char            buffer[20];

	fix15           read_token();

	if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
		return FALSE;
	}
#if RESTRICTED_ENVIRON
	if (*buffer != '-' && *buffer != '+' && (*buffer < '0' || *buffer > '9'))
		return FALSE;
	*pdata = (fix31) latol((ufix8 STACKFAR*)buffer, (ufix8 STACKFAR*)NULL);
#else
#if WINDOWS_4IN1
   if (wvsprintf(pdata, "%ld", buffer) != 1)
      return FALSE;
#else
#ifdef __GEOS__
	if (*buffer != '-' && *buffer != '+' && (*buffer < '0' || *buffer > '9'))
		return FALSE;
	*pdata = (fix31) latol((ufix8 STACKFAR*)buffer, (ufix8 STACKFAR*)NULL);
#else
#else
	if (sscanf(buffer, "%ld", pdata) != 1) {
		return FALSE;
	}
#endif
#endif
#endif
	return TRUE;
}



FUNCTION boolean 
read_long_array(PARAMS2 data, pn)
GDECL
fix31           STACKFAR*data;	/* Array for data */
fix15          STACKFAR*pn;		/* Number of elements read */
{
	fix15           i;
	char            buffer[20];

	fix15           read_token();

	if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
		return FALSE;
	}
	if (compstr((ufix8 STACKFAR*)buffer, "[") != 0) {
		return FALSE;
	}
	for (i = 0; TRUE; i++) {
		if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
			return FALSE;
		}
		if (compstr((ufix8 STACKFAR*)buffer, "]") == 0) {
			*pn = i;
			return TRUE;
		}
#if RESTRICTED_ENVIRON
		if (*buffer != '-' && *buffer != '+' && (*buffer < '0' || *buffer > '9'))
			return FALSE;
		data[i] = (fix31) latol((char STACKFAR*)buffer, (ufix8 STACKFAR*)NULL);
#else
#if WINDOWS_4IN1
   if (wvsprintf((fix31 STACKFAR*)&data[i], "%ld", buffer) != 1)
      return FALSE;
#else
#ifdef __GEOS__
		if (*buffer != '-' && *buffer != '+' && (*buffer < '0' || *buffer > '9'))
			return FALSE;
		data[i] = (fix31) latol((char STACKFAR*)buffer, (ufix8 STACKFAR*)NULL);
#else
#else
		if (sscanf(buffer, "%ld", &data[i]) != 1) {
			return FALSE;
		}
#endif
#endif
#endif
	}
}


FUNCTION boolean 
read_real(PARAMS2 pdata)
	GDECL
	real           STACKFAR*pdata;	/* Data read */
{
	char            buffer[20];
	float           tempf;

	fix15           read_token();

	if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
		return FALSE;
	}
#if RESTRICTED_ENVIRON
	tempf = latof((char STACKFAR*)buffer);
#else
#if WINDOWS_4IN1
   if (wvsprintf((float STACKFAR*)&tempf, "%f", buffer) != 1)
      return FALSE;
#else
#ifdef __GEOS__
	tempf = latof((char STACKFAR*)buffer);
#else
	if (sscanf(buffer, "%f", &tempf) != 1) {
		return FALSE;
	}
#endif
#endif
#endif
	*pdata = (real) tempf;
	return TRUE;
}


FUNCTION boolean 
read_real_array(PARAMS2 data, pn)
	GDECL
	real            STACKFAR*data;	/* Array for data */
fix15          STACKFAR*pn;		/* Number of elements read */
{
	fix15           i;
	char            buffer[20];
	float           tempf;

	fix15           read_token();

	if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
		return FALSE;
	}
	if (compstr((ufix8 STACKFAR*)buffer, "[") != 0) {
		return FALSE;
	}
	for (i = 0; TRUE; i++) {
		if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
			return FALSE;
		}
		if (compstr((ufix8 STACKFAR*)buffer, "]") == 0) {
			*pn = i;
			return TRUE;
		}
#if RESTRICTED_ENVIRON
		tempf = latof((char STACKFAR*)buffer);
#else
#if WINDOWS_4IN1
   if (wvsprintf((float STACKFAR*)&tempf, "%f", buffer) != 1)
      return FALSE;
#else
#ifdef __GEOS__
		tempf = latof((char STACKFAR*)buffer);
#else
		if (sscanf(buffer, "%f", &tempf) != 1) {
			return FALSE;
		}
#endif
#endif
#endif
		*(real STACKFAR*)(data+i) = (real) tempf;
	}
}


FUNCTION boolean 
read_boolean(PARAMS2 pdata)
	GDECL
	boolean        STACKFAR*pdata;	/* Data read */
{
	char            buffer[20];

	fix15           read_token();

	if (read_token(PARAMS2 (ufix8 STACKFAR*)buffer, 20) < 0) {
		return FALSE;
	}
	if ((compstr((ufix8 STACKFAR*)buffer, "true") == 0) ||
	    (compstr((ufix8 STACKFAR*)buffer, "TRUE") == 0)) {
		*pdata = TRUE;
		return TRUE;
	}
	if ((compstr((ufix8 STACKFAR*)buffer, "false") == 0) ||
	    (compstr((ufix8 STACKFAR*)buffer, "FALSE") == 0)) {
		*pdata = FALSE;
		return TRUE;
	}
	return FALSE;
}



FUNCTION fix15 
read_token(PARAMS2 buf, count)
	GDECL
	char           STACKFAR*buf;	/* buffer for token read */
	fix15           count;	/* maximum length string returned in 'buf'
				 * (incl '\0') */

/*
 * Reads a token into the buffer buf Returns a 0-terminated string in 'buf'
 * with a maximum length of 'count' bytes. Token separators space, tab,
 * carriage return, linefeed etc are not part of the string. Return value =
 * string length of 'buf' (not including terminator). Returns  -1 if EOF
 * found before any input is read. 
 */

{
	fix15           i;
	ufix8           byte;

	boolean         read_byte();

L1:
	if (replaced_avail) {
		byte = replaced_byte;
		replaced_avail = FALSE;
	} else if (!read_byte((ufix8 STACKFAR*)&byte))	/* Read first character */
		return -1;	/* Return -1 if end of file */

	/* Skip leading spaces */
	while (char_type[byte] & SPACE_CHAR) {
		if (!read_byte((ufix8 STACKFAR*)&byte))
			/* Read another character */
			return -1;	/* Return -1 if end of file */
	}

	i = 0;
	*(char STACKFAR*)(buf+i++) = byte;	/* Put first non-space char in buffer */

	if (char_type[byte] & PUNCT_CHAR) {	/* First char is punctuation? */
		if (byte == '%') {	/* Start of comment? */
			do {	/* Skip to end of line */
				if (!read_byte((ufix8 STACKFAR*)&byte))
					return -1;
			}
			while (!(char_type[byte] & EOL_CHAR));
			goto L1;/* Start again */
		}
		*(char STACKFAR*)(buf+i) = '\0';
		return i;
	}
	count--;
	while (read_byte((ufix8 STACKFAR*)&byte)) {
		if (char_type[byte] & SPACE_CHAR) {	/* Space terminator? */
			*(char STACKFAR*)(buf+i) = '\0';
			return i;
		}
		if (char_type[byte] & PUNCT_CHAR) {	/* Punctuation
							 * terminator? */
			replaced_byte = byte;	/* Save punctuation char for
						 * next call */
			replaced_avail = TRUE;
			*(char STACKFAR*)(buf+i) = '\0';	/* Terminate string */
			return i;	/* Return string length */
		}
		if (i < count) {/* Still room in buffer? */
			*(char STACKFAR*)(buf+i++) = byte;	/* Add char to buffer */
		} else {
			sp_report_error(PARAMS2 TR_TOKEN_LARGE);	/* ERROR MESSAGE "***
								 * Token too large" */
		}
	}
	return -1;
}
FUNCTION fix15 
read_name(PARAMS2 buf, count)
	GDECL
	char           STACKFAR*buf;	/* buffer for token read */
	fix15           count;	/* maximum length string returned in 'buf'
				 * (incl '\0') */

/*
 * Reads a token into the buffer buf Returns a 0-terminated string in 'buf'
 * with a maximum length of 'count' bytes. Token separators space, tab,
 * carriage return, linefeed etc are not part of the string. Return value =
 * string length of 'buf' (not including terminator). Returns  -1 if EOF
 * found before any input is read. 
 */

{
	fix15           i;
	ufix8           byte;

	boolean         read_byte();

L1:
	if (replaced_avail) {
		byte = replaced_byte;
		replaced_avail = FALSE;
	} else if (!read_byte((ufix8 STACKFAR*)&byte))	/* Read first character */
		return -1;	/* Return -1 if end of file */


	i = 0;
	/* special case - empty name */
	if (byte == ' ') {
		*(char STACKFAR*)(buf+i) = '\0';
		return i;
	}
	*(char STACKFAR*)(buf+i++) = byte;	/* Put first non-space char in buffer */

	if (char_type[byte] & PUNCT_CHAR) {	/* First char is punctuation? */
		if (byte == '%') {	/* Start of comment? */
			do {	/* Skip to end of line */
				if (!read_byte((ufix8 STACKFAR*)&byte))
					return -1;
			}
			while (!(char_type[byte] & EOL_CHAR));
			goto L1;/* Start again */
		}
		*(char STACKFAR*)(buf+i) = '\0';
		return i;
	}
	count--;
	while (read_byte((ufix8 STACKFAR*)&byte)) {
		if (char_type[byte] & SPACE_CHAR) {	/* Space terminator? */
			*(char STACKFAR*)(buf+i) = '\0';
			return i;
		}
		if (char_type[byte] & PUNCT_CHAR) {	/* Punctuation
							 * terminator? */
			replaced_byte = byte;	/* Save punctuation char for
						 * next call */
			replaced_avail = TRUE;
			*(char STACKFAR*)(buf+i) = '\0';	/* Terminate string */
			return i;	/* Return string length */
		}
		if (i < count) {/* Still room in buffer? */
			*(char STACKFAR*)(buf+i++) = byte;	/* Add char to buffer */
		} else {
			sp_report_error(PARAMS2 TR_TOKEN_LARGE);	/* ERROR MESSAGE "***
								 * Token too large" */
		}
	}
	return -1;
}


FUNCTION fix15 
read_string(buf, count)
	char           STACKFAR*buf;	/* buffer for string read */
	fix15           count;	/* maximum length string returned in 'buf'
				 * (incl '\0') */

/*
 * read_string (FP, BUF, COUNT) Reads a string from a file (or stdin) Returns
 * a 0-terminated string in 'buf' with a maximum length of 'count' bytes.
 * Return value = length of string in buf (-1 if EOF found and no input). 
 */

{
	fix15           i, p;
	ufix8           byte;

	boolean         read_byte();

	if (replaced_avail) {
		byte = replaced_byte;
		replaced_avail = FALSE;
	} else if (!read_byte((ufix8 STACKFAR*)&byte))	/* Read first character */
		return -1;	/* Return -1 if end of file */

	if (byte != '(')	/* First char not open parenthesis? */
		return -1;

	i = 0;			/* Initialize buffer index */
	p = 0;			/* Initialize parenthesis count */
	count--;		/* Adjust count to leave space for terminator */
	while (read_byte((ufix8 STACKFAR*)&byte))
		/* Read next byte */
	{
		if (byte == ')') {	/* Right paren? */
			if (p-- == 0) {	/* All parentheses matched? */
				*(char STACKFAR*)(buf+i) = '\0';	/* Terminate string */
				return i;	/* Return length of string
						 * read */
			}
		}
		if (i < count)	/* Space left in buffer? */
			*(char STACKFAR*)(buf+i++) = byte;	/* Add new char to buffer */
		if (byte == '(')/* character is open paren? */
			p++;	/* Increment parenthesis matching count */
	}
	*(char STACKFAR*)(buf+i) = '\0';		/* Terminate string */
	return i;		/* Return length of string read */
}


FUNCTION fix15 
read_binary(buf, count)
	char           STACKFAR*buf;	/* buffer for binary data */
	fix15           count;	/* number of bytes to be read */

/*
 * Reads up to count bytes of binary data into the byte array buf Returns
 * number of bytes read 
 */

{
	fix15           i;

	boolean         read_byte();

	for (i = 0; i < count; i++) {
		if (!read_byte((ufix8 STACKFAR*)&buf[i]))	/* Read character into buffer */
			return count;
	}
	return count;		/* Return length of string read */
}



FUNCTION fix15 
asctohex(asciivalue)
	ufix8           asciivalue;
{
	switch (asciivalue) {
	case '0':
		return 0;
	case '1':
		return 1;
	case '2':
		return 2;
	case '3':
		return 3;
	case '4':
		return 4;
	case '5':
		return 5;
	case '6':
		return 6;
	case '7':
		return 7;
	case '8':
		return 8;
	case '9':
		return 9;
	case 'A':
		return 10;
	case 'a':
		return 10;
	case 'B':
		return 11;
	case 'b':
		return 11;
	case 'C':
		return 12;
	case 'c':
		return 12;
	case 'D':
		return 13;
	case 'd':
		return 13;
	case 'E':
		return 14;
	case 'e':
		return 14;
	case 'F':
		return 15;
	case 'f':
		return 15;
	default:
		return 0;
	}
}
/*
 * this function is used to return a byte to stream input - it is assumed
 * that the byte has not been processed in any way 
 */



FUNCTION boolean 
read_byte(pbyte)
	ufix8          STACKFAR*pbyte;
{
	ufix8            byte;
	ufix8           tempi;
	boolean         flag;
	fix15           i;

#if INCL_PFB
	boolean         parse_tag();
	boolean         get_tag_string();
	char            tag_string[6];
#endif

	i = 0;

	while (TRUE) {
#if INCL_PFB
		/* If PFA file, just read next byte and return */
		if (fnt_file_type == PFA) {
#endif
			if (!get_byte((char STACKFAR*)&byte))
				return FALSE;
#if RESTRICTED_ENVIRON
			file_byte_count++;
#endif
#if INCL_PFB
		} else {

			/* Else it's a PFB file */

			/* Check whether need to read the next tag */
			if (tag_bytes == 0 && (!reading_tag))	/* if run out of bytes
								  in current e section and not getting a tag  */
			{
				if ((get_tag_string((char STACKFAR*)tag_string) == FALSE) ||
				    (parse_tag(&tag_mode, &tag_bytes, (char STACKFAR*)tag_string) == FALSE))	/* read next tag */
					return FALSE;

			}
			if (!get_byte((char STACKFAR*)&byte))	/* read next byte */
				return FALSE;

#if RESTRICTED_ENVIRON
			file_byte_count++;
#endif

			if (!reading_tag)
				tag_bytes--;	/* count byte read */
		}
#endif
		if (!hex_mode)
			break;
		if (!isalnum((char) byte))
			continue;
		if (i == 0) {
			tempi = byte;
			i++;
			continue;
		}
		byte = (asctohex(tempi) << 4) + asctohex(byte);
		break;
	}

	if (decrypt_mode) {
		*(ufix8 STACKFAR*)pbyte = (byte ^ (decrypt_r >> 8));
		decrypt_r = (byte + decrypt_r) * decrypt_c1 + decrypt_c2;
	} else {
		*(ufix8 STACKFAR*)pbyte = byte;
	}
	return TRUE;
}


#if DEBUG
FUNCTION void
print_binary(PARAMS2 buf, n)
	GDECL
	ufix8          *buf;
	fix15           n;
{
	ufix16          r = 4330;
	ufix8           byte;
	int             i, state;
	fix31           operand;
	ufix16          command;

	state = 0;
	for (i = 0; i < n; i++) {
		byte = buf[i] ^ (r >> 8);
		r = (buf[i] + r) * decrypt_c1 + decrypt_c2;

		if (i < 4)	/* Discard first 4 bytes */
			continue;

		switch (state) {
		case 0:	/* Initial state */
			if (byte < 32) {	/* Command? */
				if (byte != 12) {
					command = byte;
					do_command(command);
				} else {
					state = 1;
				}
			} else if (byte < 247) {	/* 1-byte integer? */
				operand = (fix31) byte - 139;
				do_operand(operand);
			} else if (byte < 251) {	/* 2-byte positive
							 * integer? */
				operand = ((fix31) byte - 247) << 8;
				state = 2;
			} else if (byte < 255) {	/* 2-byte negative
							 * integer? */
				operand = -(((fix31) byte - 251) << 8);
				state = 3;
			} else {/* 5-byte integer? */
				operand = 0;
				state = 7;
			}
			break;

		case 1:	/* Second byte of 2-byte command */
			command = byte + 32;
			do_command(command);
			state = 0;
			break;

		case 2:	/* Second byte of 2-byte positive integer */
			operand += (fix31) byte + 108;
			do_operand(operand);
			state = 0;
			break;

		case 3:	/* Second byte of 2-byte negative integer */
			operand -= (fix31) byte + 108;
			do_operand(operand);
			state = 0;
			break;
		case 4:	/* Last byte of 5-byte integer */
			operand = (operand << 8) + (fix31) byte;
			do_operand(operand);
			state = 0;
			break;

		default:	/* Other bytes of 5-byte integer */
			operand = (operand << 8) + (fix31) byte;
			state--;
			break;
		}
	}
	if (state != 0) {
		sp_report_error(PARAMS2 TR_PARSE_ERR);	/* ERROR MESSAGE "*** Parsing
						 * error in Character program
						 * string" */
	}
}
#endif


#if DEBUG
FUNCTION 
do_command(command)
	ufix16          command;
{
	switch (command) {
	case 1:
		printf("hstem\n");
		break;

	case 3:
		printf("vstem\n");
		break;

	case 4:
		printf("vmoveto\n");
		break;

	case 5:
		printf("rlineto\n");
		break;

	case 6:
		printf("hlineto\n");
		break;

	case 7:
		printf("vlineto\n");
		break;

	case 8:
		printf("rrcurveto\n");
		break;

	case 9:
		printf("closepath\n");
		break;

	case 10:
		printf("callsubr\n");
		break;

	case 11:
		printf("return\n");
		break;

	case 13:
		printf("hsbw\n");
		break;

	case 14:
		printf("endchar\n");
		break;

	case 21:
		printf("rmoveto\n");
		break;

	case 22:
		printf("hmoveto\n");
		break;

	case 30:
		printf("vhcurveto\n");
		break;

	case 31:
		printf("hvcurveto\n");
		break;

	case 32:
		printf("dotsection\n");
		break;

	case 33:
		printf("vstem3\n");
		break;

	case 34:
		printf("hstem3\n");
		break;

	case 38:
		printf("seac\n");
		break;

	case 39:
		printf("sbw\n");
		break;

	case 44:
		printf("div\n");
		break;

	case 48:
		printf("callothersubr\n");
		break;

	case 49:
		printf("pop\n");
		break;

	case 65:
		printf("setcurrentpoint\n");
		break;

	default:
		if (command < 32)
			printf("command %d\n", command);
		else
			printf("command 12 %d\n", command - 32);
		break;

	}
}
#endif


#if DEBUG
FUNCTION 
do_operand(operand)
	fix31           operand;
{
	printf("%d ", operand);
}
#endif


#if RESTRICTED_ENVIRON
FUNCTION boolean 
clear_encoding(PARAMS2 font_ptr)
#else
FUNCTION void 
clear_encoding(PARAMS2 font_ptr)
#endif
	GDECL
	font_data      STACKFAR*font_ptr;
{
	int             i;
	char           *j;

#if RESTRICTED_ENVIRON

	char           STACKFAR*notdef_ptr;
	ufix16          notdef_offset;
	ufix16         STACKFAR*encoding_ptr;
	ufix16          space_needed;

	space_needed = strlen(".notdef") + 1;
	if (!inquire_about_space(space_needed)) {
		/* abandon ship */
		sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
		return FALSE;
	}
	/* allocate the space */
	notdef_ptr = (char STACKFAR*) ((ufix32) font_ptr + (ufix32) offset_from_top);
	offset_from_top += space_needed;
	notdef_offset = offset_from_top;
	encoding_ptr = (ufix16 STACKFAR*) ((ufix32) font_ptr + (ufix32) (font_ptr->encoding_offset));
#if WINDOWS_4IN1
 	lstrcpy(notdef_ptr, ".notdef");
#else
	strcpy(notdef_ptr, ".notdef");
#endif
	for (i = 0; i < 256; i++)
		encoding_ptr[i] = notdef_offset;
	return TRUE;

#else

	for (i = 0; i < 256; i++) {
		font_ptr->encoding[i] = notdef;
	}

#endif
}



FUNCTION boolean 
add_encoding(PARAMS2 font_ptr, index, charactername)
	GDECL
	font_data      STACKFAR*font_ptr;
	fix15           index;
	ufix8          STACKFAR*charactername;
{
#if NAME_STRUCT
	fix15           i;
#endif

#if RESTRICTED_ENVIRON
	char           STACKFAR*char_ptr;
	ufix16          space_needed;
	ufix16         STACKFAR*encoding_ptr;
	boolean         get_space();


#if WINDOWS_4IN1
	space_needed = lstrlen(charactername) + 1;
#else
	space_needed = strlen(charactername) + 1;
#endif
	if (!get_space(PARAMS2 space_needed)) {
		/* abandon ship */
		sp_report_error(PARAMS2 TR_BUFFER_TOO_SMALL);
		return FALSE;
	}
	encoding_ptr = (ufix16 STACKFAR*) ((ufix32) font_ptr + (ufix32) (font_ptr->encoding_offset));
	/* allocate the space */
	char_ptr = (char STACKFAR*) ((ufix32) font_ptr + (ufix32) offset_from_top);
	encoding_ptr[index] = offset_from_top;
	offset_from_top += space_needed;
#if WINDOWS_4IN1
	lstrcpy(char_ptr, charactername);
#else
	strcpy(char_ptr, charactername);
#endif
	return TRUE;

#else


	/* allocate storage for the charactername */
#if NAME_STRUCT
	if ((font_ptr->encoding[index] = (CHARACTERNAME *) malloc(sizeof(CHARACTERNAME))) == NULL)
		return FALSE;
	if ((font_ptr->encoding[index]->char_name = (unsigned char *) malloc(strlen(charactername))) == NULL)
		return FALSE;
	font_ptr->encoding[index]->count = strlen(charactername);
	for (i = 0; i < strlen(charactername); i++)
		font_ptr->encoding[index]->char_name[i] = charactername[i];
#else
	if ((font_ptr->encoding[index] = (CHARACTERNAME *) malloc(strlen((char *)charactername) + 1)) == NULL)
		return FALSE;
#if WINDOWS_4IN1
	lstrcpy(font_ptr->encoding[index], charactername);
#else
	strcpy((char *)font_ptr->encoding[index], (char *)charactername);
#endif
#endif

	return TRUE;
#endif

}


FUNCTION void 
standard_encoding(font_ptr)
	font_data      STACKFAR*font_ptr;
{
	int             i;
#if RESTRICTED_ENVIRON
#else
	/* don't deallocate charname_tbl! */
	if (font_ptr->encoding == (CHARACTERNAME **) charname_tbl)
		return;

	/* if there's a special encoding array, deallocate it */
	if (font_ptr->encoding) {
		for (i = 0; i < 256; i++)
			if (font_ptr->encoding[i])
				free(font_ptr->encoding[i]);

		free(font_ptr->encoding);
	}
	/* and set encoding to standard */
	font_ptr->encoding = (CHARACTERNAME **) charname_tbl;
#endif
}


#if DEBUG
FUNCTION void 
print_encoding(font_ptr)
	font_data      STACKFAR*font_ptr;
{
	int             i;

	printf("\nEncoding vector:\n");
	for (i = 0; i < 256; i++) {
		printf("%3d: %s\n", i, font_ptr->encoding[i]);
	}
	printf("\n");
}
#endif


FUNCTION void 
clear_hints(font_ptr)
	font_data      STACKFAR*font_ptr;
/*
 * Initializes font hint storage 
 */
{
	font_ptr->font_hints.unique_id = 0;
	font_ptr->font_hints.no_blue_values = 0;
	font_ptr->font_hints.pblue_values = font_ptr->blue_values;
	font_ptr->font_hints.no_other_blues = 0;
	font_ptr->font_hints.pother_blues = font_ptr->other_blues;
	font_ptr->font_hints.no_fam_blues = 0;
	font_ptr->font_hints.pfam_blues = font_ptr->fam_blues;
	font_ptr->font_hints.no_fam_other_blues = 0;
	font_ptr->font_hints.pfam_other_blues = font_ptr->fam_other_blues;
	font_ptr->font_hints.blue_scale = -1.0;
	font_ptr->font_hints.blue_shift = -1;
	font_ptr->font_hints.blue_fuzz = -1;
	font_ptr->font_hints.stdhw = 0.0;
	font_ptr->font_hints.stdvw = 0.0;
	font_ptr->font_hints.no_stem_snap_h = 0;
	font_ptr->font_hints.pstem_snap_h = font_ptr->stem_snap_h;
	font_ptr->font_hints.no_stem_snap_v = 0;
	font_ptr->font_hints.pstem_snap_v = font_ptr->stem_snap_v;
	font_ptr->font_hints.force_bold = FALSE;
	font_ptr->font_hints.language_group = 0;
}



#if DEBUG
FUNCTION void 
print_long_array(data, n)
	fix31           data[];
fix15           n;
{
	fix15           i;

	printf("[");
	for (i = 0; i < n; i++) {
		if (i != 0) {
			printf(" ");
		}
		printf("%ld", data[i]);
	}
	printf("]");
}
#endif


#if DEBUG
FUNCTION void 
print_real_array(data, n)
	real            data[];
int             n;
{
	int             i;

	printf("[");
	for (i = 0; i < n; i++) {
		if (i != 0) {
			printf(" ");
		}
		printf("%7.5f", data[i]);
	}
	printf("]");
}
#endif



FUNCTION char  STACKFAR*
tr_get_font_name(PARAMS1)
GDECL
{
	return sp_globals.processor.type1.current_font->font_name;
}



FUNCTION void 
tr_get_font_matrix(PARAMS2 matrix)
	GDECL
	real            STACKFAR*matrix;
{
	int             i;

	for (i = 0; i < 6; i++) {
		*(real STACKFAR*)(matrix+i) = sp_globals.processor.type1.current_font->font_matrix[i];
	}
}



FUNCTION fbbox_t STACKFAR* tr_get_font_bbox(PARAMS1)
GDECL
{
	return &sp_globals.processor.type1.current_font->font_bbox;
}


FUNCTION fix15 tr_get_paint_type(PARAMS1)
GDECL
{
	return sp_globals.processor.type1.current_font->paint_type;
}


FUNCTION CHARACTERNAME STACKFAR* tr_encode(PARAMS2 i)
	GDECL
	int             i;
{
#if RESTRICTED_ENVIRON
	if (sp_globals.processor.type1.current_font->encoding_offset == NULL)
		return (unsigned char STACKFAR*) charname_tbl[i];
	else {
	}
#else
	return (CHARACTERNAME *) sp_globals.processor.type1.current_font->encoding[i];
#endif
}


FUNCTION unsigned char STACKFAR*
tr_get_subr(PARAMS2 i)
	GDECL
	int             i;
{
#if RESTRICTED_ENVIRON
	subrs_t        STACKFAR*subrs_ptr;

	subrs_ptr = (subrs_t STACKFAR*) ((ufix32) sp_globals.processor.type1.current_font + (ufix32) sp_globals.processor.type1.current_font->subrs_offset);
	return (unsigned char STACKFAR*) ((ufix32) sp_globals.processor.type1.current_font + (ufix32) subrs_ptr[i].data_offset);
#else
	return (unsigned char *) sp_globals.processor.type1.current_font->subrs[i].value;
#endif
}
#if RESTRICTED_ENVIRON
#if INCL_PFB
FUNCTION boolean 
remove_tags(PARAMS2 tag_position, char_data, total_bytes)
	GDECL
	fix15           tag_position;
	unsigned char  STACKFAR*char_data;
	fix15           total_bytes;
{
	boolean         more_tags;

	more_tags = TRUE;
	while (more_tags) {
		/* get rid of those tags */
		if (parse_tag(&tag_mode, &tag_bytes, (char STACKFAR*)&char_data[tag_position]) == FALSE) {
			sp_report_error(PARAMS2 TR_BAD_RFB_TAG);
			return FALSE;
		}
		_fmemcpy((void STACKFAR*) &char_data[tag_position], (void STACKFAR*) &char_data[tag_position + 6], (size_t) tag_bytes);
		tag_position = tag_position + 6 + tag_bytes;
		if (total_bytes - tag_position <= 0)
			more_tags = FALSE;
	}
	return TRUE;
}
#endif

FUNCTION void 
asc2bin_buffer(byte_count, char_data)
	fix15           byte_count;
	unsigned char  STACKFAR*char_data;
{
	int             j, k;

	/* convert the hex data to binary  */
	k = 0;
	for (j = 0; j < byte_count; j++) {
		while (!isalnum(*(char STACKFAR*)(char_data+k)))
			k++;
		*(unsigned char STACKFAR*)(char_data+j) = asctohex(*(unsigned char STACKFAR*)(char_data+k++)) << 4;
		while (!isalnum(*(char STACKFAR*)(char_data+k)))
			k++;
		*(unsigned char STACKFAR*)(char_data+j) = *(unsigned char STACKFAR*)(char_data+j) + asctohex(*(unsigned char STACKFAR*)(char_data+k++));
	}
}
#endif


FUNCTION unsigned char STACKFAR*
tr_get_chardef(PARAMS2 charname)
	GDECL
	CHARACTERNAME  STACKFAR*charname;
{
	int             i;
#if RESTRICTED_ENVIRON
	int             j, k;
	charstrings_t  STACKFAR*ch_strings;
#if  !(WINDOWS_4IN1)
	unsigned char  STACKFAR* WDECL dynamic_load();
#endif
	ufix16          decrypt_key;
	unsigned char   new_byte, success, STACKFAR*char_data;

	ch_strings = (charstrings_t STACKFAR*)
         ((ufix8 STACKFAR*)sp_globals.processor.type1.current_font +
   		 sp_globals.processor.type1.current_font->charstrings_offset);
	/* look through the entire charstrings dictionary */
	for (i = 0; i < sp_globals.processor.type1.current_font->no_charstrings; i++)
   {
		/* is this the character ? */
		if (compstr((CHARACTERNAME STACKFAR*)charname,
			   (ufix8 STACKFAR*)sp_globals.processor.type1.current_font + ch_strings[i].key_offset) == 0)
      {
			/* is this character in memory ? */
			if (ch_strings[i].value_offset != 0)
				/* yes - just return the pointer */
				return (unsigned char STACKFAR*) ((ufix32) sp_globals.processor.type1.current_font + (ufix32) ch_strings[i].value_offset);

			else
				/*
				 * get the character data from the
				 * application 
				 */
			{
				char_data = dynamic_load(ch_strings[i].file_position,
						  ch_strings[i].file_bytes, success);
#if INCL_PFB
				/*
				 * if this is a PFB file, get rid of the tag
				 * bytes 
				 */
				if (sp_globals.processor.type1.current_font->font_file_type == PFB) {
					if (ch_strings[i].file_bytes > ch_strings[i].tag_bytes) {
						if (!remove_tags(PARAMS2 ch_strings[i].tag_bytes, char_data,
						  ch_strings[i].file_bytes))
							return NULL;
					}
				} else
#endif
					/*
					 * if this is a PFA, but in hex ascii
					 * mode - convert to binary 
					 */
				if (ch_strings[i].hex_mode)
					asc2bin_buffer(ch_strings[i].file_bytes, char_data);

				/* decrypt the data */
				decrypt_key = ch_strings[i].decryption_key;
				for (j = 0; j < ch_strings[i].charstring_size; j++) {
					new_byte = (*(unsigned char STACKFAR*)(char_data+j) ^ (decrypt_key >> 8));
					decrypt_key = (*(unsigned char STACKFAR*)(char_data+j) + decrypt_key) * decrypt_c1 + decrypt_c2;
					*(unsigned char STACKFAR*)(char_data+j) = new_byte;
				}
				return (char_data);
			}	/* end of ther char from the app */
		}		/* end of found the character */
	}			/* end of search through charstring dict */
#else
	for (i = 0; i < sp_globals.processor.type1.current_font->no_charstrings; i++) {
		if (STRCMP((char *)charname, (char *)sp_globals.processor.type1.current_font->charstrings[i].key) == 0) {
			return (unsigned char STACKFAR*) sp_globals.processor.type1.current_font->charstrings[i].value;
		}
	}
#endif
	sp_report_error(PARAMS2 TR_NO_FIND_CHARNAME);	/* ERROR MESSAGE "***
						 * get_chardef: Cannot find
						 * %s\n", charname); */
	return NULL;
}


FUNCTION font_hints_t STACKFAR* tr_get_font_hints(PARAMS1)
GDECL
{
	return &(sp_globals.processor.type1.current_font->font_hints);
}

#if RESTRICTED_ENVIRON
FUNCTION boolean 
tr_set_encode(PARAMS2 font_ptr, set_array)
	GDECL
	ufix8          STACKFAR*font_ptr;
	char           STACKFAR*set_array[256];
#else
FUNCTION int 
tr_set_encode(PARAMS2 set_array)
	GDECL
	CHARACTERNAME  STACKFAR*set_array[256];
#endif
{
	int             i, j;
#if NAME_STRUCT
#define CHSIZE sizeof(CHARACTERNAME)+set_array[i]->count
#else
#define CHSIZE strlen((char *)set_array[i])+1
#endif

#if RESTRICTED_ENVIRON
	ufix16          space_needed;
	ufix16          save_offset;

	offset_from_bottom = sp_globals.processor.type1.current_font->offset_from_bottom;
	save_offset = offset_from_top = sp_globals.processor.type1.current_font->offset_from_top;
	if (sp_globals.processor.type1.current_font->encoding_offset == 0) {
		space_needed = 256 * sizeof(ufix16);
		if (!get_space(PARAMS2 space_needed)) {
			/* abandon ship */
			return FALSE;
		}
		/* allocate the space */
		sp_globals.processor.type1.current_font->encoding_offset = offset_from_top;
		offset_from_top += space_needed;
	}
	for (i = 0; i < 256; i++)
		if (!add_encoding(PARAMS2 sp_globals.processor.type1.current_font, i, set_array[i])) {
			offset_from_top = save_offset;
			return FALSE;
		}
	return TRUE;
#else
	/* If null pointer passed, just return */
	if (!set_array)
		return TRUE;

	/* Else, allocate space for array of 256 char pointers */
	if ((sp_globals.processor.type1.current_font->encoding = (CHARACTERNAME **) malloc(256 * sizeof(CHARACTERNAME *))) == NULL) {
		sp_report_error(PARAMS2 TR_NO_SPC_ENC_ARR);	/* ERROR MESSAGE "Unable
							 * to allocate storage
							 * for encoding array" */
		return FALSE;
	}
	/*
	 * For each element of set_array, allocate space to store the string
	 * in the font data structure. 
	 */
	for (i = 0; i < 256; i++) {
		if (STRCMP((char *)set_array[i], (char *)notdef) == 0) {
			/* store pointer to ".notdef" string */
			sp_globals.processor.type1.current_font->encoding[i] = (CHARACTERNAME *) notdef;
		} else {	/* if string is not ".notdef", allocate
				 * memory and copy it */
			/*
			 * if unable to allocate current string, free all
			 * memory allocated up to this point 
			 */

			if ((sp_globals.processor.type1.current_font->encoding[i] = (CHARACTERNAME *) malloc(CHSIZE)) == NULL) {
				for (j = 0; j < i; j++)
					if (sp_globals.processor.type1.current_font->encoding[j])
						free(sp_globals.processor.type1.current_font->encoding[j]);
				free(sp_globals.processor.type1.current_font->encoding);
				sp_report_error(PARAMS2 TR_NO_SPC_ENC_ARR);	/* ERROR MESSAGE "Unable
									 * to allocate storage
									 * for encoding array" */
				return FALSE;
			}
#if NAME_STRUCT
			sp_globals.processor.type1.current_font->encoding[i]->char_name =
				(unsigned char *) ((ufix32) (sp_globals.processor.type1.current_font->encoding[i])
					  + (ufix32) sizeof(CHARACTERNAME));
#endif
			STRCPY((char *)sp_globals.processor.type1.current_font->encoding[i], (char *)set_array[i]);
		}
	}
	return TRUE;
#endif
}

#if RESTRICTED_ENVIRON
FUNCTION char STACKFAR*STACKFAR*
WDECL tr_get_encode(PARAMS2 font_ptr)
	GDECL
	ufix8          STACKFAR*font_ptr;
#else
FUNCTION CHARACTERNAME **
tr_get_encode(PARAMS1)
	GDECL
#endif
{
#if RESTRICTED_ENVIRON
	if (sp_globals.processor.type1.current_font->encoding_offset == NULL)
		return ((char STACKFAR*STACKFAR*) charname_tbl);
	else {
		return ((char STACKFAR*STACKFAR*) ((ufix32) sp_globals.processor.type1.current_font + (ufix32) (sp_globals.processor.type1.current_font->encoding_offset)));
	}
#else
	return (sp_globals.processor.type1.current_font->encoding);
#endif
}


FUNCTION void  WDECL
tr_unload_font(font_ptr)
	font_data      STACKFAR*font_ptr;
{
	int             i;
#if RESTRICTED_ENVIRON
#else

	/*
	 * if font structure hasn't been allocated yet, nothing to do 
	 */
	if (!font_ptr)
		return;

	/* free and NULL ptrs to memory for each char_string */
	if (font_ptr->charstrings) {
		for (i = 0; i < font_ptr->no_charstrings; i++) {
			if (font_ptr->charstrings[i].key)
				{
				free(font_ptr->charstrings[i].key);
				font_ptr->charstrings[i].key = NULL;
				}
			if (font_ptr->charstrings[i].value)
				{
				free(font_ptr->charstrings[i].value);
				font_ptr->charstrings[i].value = NULL;
				}
		}
		free(font_ptr->charstrings);
		font_ptr->charstrings = NULL;
	}
	/* free memory for subrs */
	if (font_ptr->subrs) {
		for (i = 0; i < font_ptr->no_subrs; i++) {
			if (font_ptr->subrs[i].value)
				{	
				free(font_ptr->subrs[i].value);
				font_ptr->subrs[i].value = NULL;
				}
		}
		free(font_ptr->subrs);
		font_ptr->subrs = NULL;
	}
	/*
	 * If not standard encoding, free each string in the encoding array,
	 * and the array itself 
	 */
	if (font_ptr->encoding && font_ptr->encoding != (CHARACTERNAME **) charname_tbl) {
		for (i = 0; i < 256; i++)
			if (font_ptr->encoding[i] && (font_ptr->encoding[i] != (CHARACTERNAME *) notdef)) {
#if NAME_STRUCT
				free(font_ptr->encoding[i]->char_name);
				font_ptr->encoding[i]->char_name = NULL;
#endif
				free(font_ptr->encoding[i]);
				font_ptr->encoding[i] = NULL;
			}
		free(font_ptr->encoding);
		font_ptr->encoding = NULL;
	}
	/* free the font data struct */
	free((char *) font_ptr);
	font_ptr = NULL;
#endif
}

FUNCTION 
void tr_error(PARAMS2 errcode, font_ptr)
	GDECL
	int             errcode;
	font_data      STACKFAR*font_ptr;
{
	sp_report_error(PARAMS2 errcode);
	tr_unload_font(font_ptr);
}
#if INCL_PFB
FUNCTION boolean 
get_tag_string(tag_string)
	ufix8          STACKFAR*tag_string;
{
	int             i;
	boolean         save_mode;

	reading_tag = TRUE;
	save_mode = decrypt_mode;
	decrypt_mode = FALSE;

	for (i = 0; i < 6; i++) {
		if (!read_byte((char STACKFAR*)&tag_string[i]))
			return FALSE;
	}

	reading_tag = FALSE;
	decrypt_mode = save_mode;
	return TRUE;
}

/******************************************************************
 * FUNCTION static boolean parse_tag
 *
 * Read tag for next section of a PFB file. The tag consists of
 * 6 bytes:
 * (1) 80 (hex) - flags that this is a new tag
 * (2) mode: 1=ASCII, 2=binary 3=EOF
 * (3-6) number of bytes in section. The bytes are in reverse
 * order, so the number has to be read a byte at a time and added in.
 *
 ******************************************************************/
FUNCTION boolean 
parse_tag(tag_mode, tag_bytes, tag_string)
	ufix16         *tag_mode;
	fix31          *tag_bytes;
	ufix8          STACKFAR*tag_string;
{
	ufix8           byte;


	/*
	 * If byte is not tag code (80 hex), file is invalid or is being read
	 * incorrectly 
	 */
	if (tag_string[0] != 0x80)
		return FALSE;

	/* Get the mode of the upcoming data (ascii or binary) */
	*tag_mode = tag_string[1];

	/* If end-of-file tag, done */
	if (*tag_mode == 3)
		return TRUE;

	/* Get the byte count */
	*tag_bytes = tag_string[2];
	*tag_bytes += (fix31) tag_string[3] << 8;
	*tag_bytes += (fix31) tag_string[4] << 16;
	*tag_bytes += (fix31) tag_string[5] << 24;

	return TRUE;
}
#endif
#if RESTRICTED_ENVIRON
static void 
unload_charstring(PARAMS1)
GDECL
{
	charstrings_t  STACKFAR*chars_ptr;	/* charstrings table pointer */
	fix15           i;

	/*
	 * this function de-allocates the charstring nearest the top of the
	 * buffer 
	 */
	chars_ptr = (charstrings_t STACKFAR*) ((ufix32) sp_globals.processor.type1.current_font +
		         (ufix32)sp_globals.processor.type1.current_font->charstrings_offset);
	for (i = 0; i < sp_globals.processor.type1.current_font->no_charstrings; i++) {
		if (chars_ptr[i].value_offset == offset_from_bottom) {	/* deallocate this
									 * charstring */
			chars_ptr[i].value_offset = 0;
			offset_from_bottom += (*(charstrings_t STACKFAR*)(chars_ptr+i)).charstring_size;
			no_charstrings_loaded--;
			return;
		}
	}
}

static boolean 
get_space(PARAMS2 space_needed)
	GDECL
	ufix16          space_needed;
{
	ufix16          space_available;
	boolean         inquire_about_space();

	/* is there room ? */
	if (inquire_about_space(space_needed))
		return TRUE;

	space_available = offset_from_bottom - offset_from_top;

	/* try throwing away some charstrings */
	while (no_charstrings_loaded != 0 &&
	       (space_available < space_needed)) {
		unload_charstring(PARAMS1);
		space_available = offset_from_bottom - offset_from_top;
	}

	/* still no room ? */
	if (space_available < space_needed)
		return FALSE;
	return TRUE;
}

static boolean 
inquire_about_space(space_needed)
	ufix16          space_needed;
{
	ufix16          space_available;

	/* is there room ? */
	space_available = offset_from_bottom - offset_from_top;
	if (space_available >= space_needed)
		return TRUE;

	return FALSE;
}
#endif
#if NAME_STRUCT
static fix15 
ns_strlen(charname)
	CHARACTERNAME   charname;
{
	return charname.count;
}
/* copy a charactername structer into another charactername structure */
static fix15 
ns_strcmp(char1, char2)
	CHARACTERNAME  *char1, *char2;
{
	fix15           j;

	if (char1->count != char2->count)
		return 1;

	for (j = 0; j < char1->count; j++)
		if (char1->char_name[j] != char2->char_name[j])
			return 1;

	return 0;
}
static void 
ns_strcpy(char1, char2)
	CHARACTERNAME  *char1, *char2;
{
	fix15           j;

	char1->count = char2->count;

	for (j = 0; j < char1->count; j++)
		char1->char_name[j] = char2->char_name[j];

	return;
}
/* copy a string into a charactername structure */
static void 
ns_string_to_struct(struct1, string1)
	CHARACTERNAME  *struct1;
	char           *string1;
{
	int             i;

	struct1->count = strlen(string1);
	for (i = 0; i < strlen(string1); i++)
		struct1->char_name[i] = string1[i];
	return;
}
#endif
FUNCTION fix15 
tr_get_leniv(PARAMS1)
GDECL
{
	return (sp_globals.processor.type1.current_font->leniv);
}

short    compstr(buff, string)
ufix8 STACKFAR*buff, STACKFAR*string;
/* if are compiling for a DLL, then there is a different library function */
/* for comparing strings. */
{
#if   WINDOWS_4IN1
   return(lstrcmp(buff,string));
#else
   return(strcmp((char *)buff,(char *)string));
#endif
}

#pragma Code()
