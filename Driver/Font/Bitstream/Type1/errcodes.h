/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/errcodes.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: errcodes.h,v 1.1 97/04/18 11:45:17 newdeal Exp $
 *
 ***********************************************************************/

/* Font loader error message codes */

#define TR_NO_ALLOC_FONT 4000          /* Cannot malloc space for font data structure */
#define TR_NO_SPC_STRINGS 4002         /* Cannot malloc space for charstrings */
#define TR_NO_SPC_SUBRS 4003           /* Cannot malloc space for subrs */
#define TR_NO_READ_SLASH 4004          /* Cannot read / before charactername in Encoding */
#define TR_NO_READ_STRING 4005         /* Cannot read / or end token for CharString */
#define TR_NO_READ_FUZZ 4006           /* Cannot read BlueFuzz value */
#define TR_NO_READ_SCALE 4007          /* Cannot read BlueScale value */
#define TR_NO_READ_SHIFT 4008          /* Cannot read BlueShift value */
#define TR_NO_READ_VALUES 4009         /* Cannot read BlueValues array */
#define TR_NO_READ_ENCODE 4010         /* Cannot read Encoding index */
#define TR_NO_READ_FAMILY 4011         /* Cannot read FamilyBlues array */
#define TR_NO_READ_FAMOTHER 4012       /* Cannot read FamilyOtherBlues array */
#define TR_NO_READ_BBOX0 4013          /* Cannot read FontBBox element 0 */
#define TR_NO_READ_BBOX1 4014          /* Cannot read FontBBox element 1 */
#define TR_NO_READ_BBOX2 4015          /* Cannot read FontBBox element 2 */
#define TR_NO_READ_BBOX3 4016          /* Cannot read FontBBox element 3 */
#define TR_NO_READ_MATRIX 4017         /* Cannot read FontMatrix */
#define TR_NO_READ_NAMTOK 4018         /* Cannot read FontName / token */
#define TR_NO_READ_NAME 4019           /* Cannot read FontName */
#define TR_NO_READ_BOLD 4020           /* Cannot read ForceBold value */
#define TR_NO_READ_FULLNAME 4021       /* Cannot read FullName value */
#define TR_NO_READ_LANGGRP 4022        /* Cannot read LanguageGroup value */
#define TR_NO_READ_OTHERBL 4023        /* Cannot read OtherBlues array */
#define TR_NO_READ_SUBRTOK 4024        /* Cannot read RD token for subr */
#define TR_NO_READ_STRINGTOK 4025      /* Cannot read RD token in charstring */
#define TR_NO_READ_STDHW 4026          /* Cannot read StdHW value */
#define TR_NO_READ_STDVW 4027          /* Cannot read StdVW value */
#define TR_NO_READ_SNAPH 4028          /* Cannot read StemSnapH array */
#define TR_NO_READ_SNAPV 4029          /* Cannot read StemSnapV array */
#define TR_NO_READ_BINARY 4030         /* Cannot read binary data size for Subr */
#define TR_NO_READ_EXECBYTE 4031       /* Cannot read a byte after eexec */
#define TR_NO_READ_CHARNAME 4032       /* Cannot read charactername */
#define TR_NO_READ_STRINGBIN 4033      /* Cannot read charstring binary data */
#define TR_NO_READ_STRINGSIZE 4034     /* Cannot read charstring size */
#define TR_NO_READ_DUPTOK 4035         /* Cannot read dup token for subr */
#define TR_NO_READ_ENCODETOK 4036      /* Cannot read dup, def or readonly token for Encoding */
#define TR_NO_READ_EXEC1BYTE 4037      /* Cannot read first byte after eexec */
#define TR_NO_READ_LENIV 4038          /* Cannot read lenIV value */
#define TR_NO_READ_LITNAME 4039        /* Cannot read literal name after / */
#define TR_NO_READ_STRINGNUM 4040      /* Cannot read number of CharStrings */
#define TR_NO_READ_NUMSUBRS 4041       /* Cannot read number of Subrs */
#define TR_NO_READ_SUBRBIN 4042        /* Cannot read subr binary data */
#define TR_NO_READ_SUBRINDEX 4043      /* Cannot read subr index */
#define TR_NO_READ_TOKAFTERENC 4044    /* Cannot read token after Encoding */
#define TR_NO_READ_OPENBRACKET 4045    /* Cannot read { or [ in FontBBox */
#define TR_EOF_READ 4046               /* End of file read */
#define TR_MATRIX_SIZE 4047            /* FontMatrix has wrong number of elements */
#define TR_PARSE_ERR 4048              /* Parsing error in Character program string */
#define TR_TOKEN_LARGE 4049            /* Token too large */
#define TR_TOO_MANY_SUBRS 4050         /* Too many subrs */
#define TR_NO_SPC_ENC_ARR 4051         /* Unable to allocate storage for encoding array  */
#define TR_NO_SPC_ENC_ENT 4052         /* Unable to malloc space for encoding entry */
#define TR_NO_FIND_CHARNAME 4053       /* get_chardef: Cannot find char name */
#define TR_INV_FILE 4054               /* Not a valid Type1 file */
#define TR_BUFFER_TOO_SMALL 4055       /* Static load buffer too small */
#define TR_BAD_RFB_TAG      4056       /* Dynamic load of RFB char failed */
