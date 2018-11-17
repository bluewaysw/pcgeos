/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools -- OS/90 File structures.
 * FILE:	  os90File.h
 *
 * AUTHOR:  	  Adam de Boor: Jan  2, 1990
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/ 2/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Structures contained in the header of all files created or used
 *	by OS/90
 *
 *
 * 	$Id: os90File.h,v 1.9 93/09/08 16:55:21 gene Exp $
 *
 ***********************************************************************/
#ifndef _OS90FILE_H_
#define _OS90FILE_H_

#include    <os90.h>

/*
 * Version control
 */

typedef struct {
    word	major;		/* A */
    word	minor;		/*  .B */
    word	change;		/*    .C */
    word	engineering;	/*      .D */
} ReleaseNumber;

typedef struct {
    word	major;		/* A */
    word	minor;		/*  .B */
} ProtocolNumber;

/*
 * Standard OS/90 file header
 */

typedef enum {
    GFT_NOT_GEOS_FILE=0,
    GFT_EXECUTABLE=1,
    GFT_VM=2,
    GFT_DATA=3,
    GFT_DIRECTORY=4,
} GeosFileType;

/*
 *	GEOS file header flags (FEA_FLAGS)
 */
#define GFHF_TEMPLATE	    	0x8000
#define GFHF_SHARED_MULTIPLE	0x4000	/* also called "multi-user" */
#define GFHF_SHARED_SINGLE  	0x2000	/* also called "public" */
#define GFHF_HIDDEN 	    	0x0800	/* This file is hidden. 
				    	 * This flag does not replace the
					 * DOS "hidden" attribute -- the two
					 * may be set/cleared independently of
				    	 * each-other. */
#define GFHF_DBCS   	    	0x0400	/* TRUE: DBCS filename, etc. */

#define GFT_RELEASE_1_OFFSET	(1)	/* Amount to subtract from GFT constants
					 * when creating/examining a 1.X PC/GEOS
					 * file */

#define TOKEN_CHARS_SIZE 4

typedef struct {
	char		chars[TOKEN_CHARS_SIZE];
	word		manufID;
} IconToken;

/*
 * All but GFH_TOKEN_SIZE must be a multiple of 4
 */
#define GFH_LONGNAME_BUFFER_SIZE    36
#define GFH_LONGNAME_SIZE   	    32
#define GFH_TOKEN_SIZE 	    	    6
#define GFH_USER_NOTES_SIZE 	    100
#define GFH_RESERVED_SIZE   	    32

typedef struct {
    char		signature[4];	/* "GEOS" with high bits of G,O set */
    word	    	type;
    word		flags;
    ReleaseNumber	release;
    ProtocolNumber	protocol;
    IconToken		token;
    IconToken		creator;
    char		longName[GFH_LONGNAME_BUFFER_SIZE];
} GeosFileHeaderCore;

typedef struct {
    GeosFileHeaderCore	core;
    char		userNotes[GFH_USER_NOTES_SIZE];
    char		reserved[GFH_RESERVED_SIZE];
} GeosFileHeader;

#define FILE_PASSWORD_SIZE  8
#define FILE_DESKTOP_INFO_SIZE 16

#define FILE_FUTURE_USE_SIZE 28

#define FT_HOUR		0xf800
#define FT_MINUTE	0x07e0
#define FT_2SECOND	0x001f
#define FD_YEAR		0xfe00
#define FD_MONTH	0x01e0
#define FD_DAY		0x001f

#define FT_HOUR_OFFSET	    11
#define FT_MINUTE_OFFSET    5
#define FT_2SECOND_OFFSET   0
#define FD_YEAR_OFFSET	    9
#define FD_MONTH_OFFSET	    5
#define FD_DAY_OFFSET	    0

#define FD_BASE_YEAR	    1980

typedef struct {
    unsigned char	signature[4];	/* "GEAS" with high bits of G,A set */
    char		longName[GFH_LONGNAME_BUFFER_SIZE];
    word	    	type;
    word		flags;
    ReleaseNumber	release;
    ProtocolNumber	protocol;
    IconToken		token;
    IconToken		creator;
    char		userNotes[GFH_USER_NOTES_SIZE];
    char		notice[GFH_RESERVED_SIZE];
    word    	    	createdDate;
    word    	    	createdTime;
    char    	    	password[FILE_PASSWORD_SIZE];
    byte    	    	desktop[FILE_DESKTOP_INFO_SIZE];
    byte    	    	reserved[FILE_FUTURE_USE_SIZE];
} GeosFileHeader2;		/* File header in 2.0. All file offsets are
				 * from the end of this header. The header
				 * itself is 256 bytes long */

#endif /* _OS90FILE_H_ */
