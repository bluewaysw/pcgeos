/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Gopher Client
MODULE:		Gopher Client - header file
FILE:		gclient.h

AUTHOR:		Alvin Cham, Aug  2, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	8/ 2/94   	Initial version.

DESCRIPTION:
	This file includes structures and definitions for the gopher 
	client application.

	$Id: gclient.h,v 1.1 97/04/04 15:10:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include <geos.h>
#include <gopher.h>

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  		Testing strategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef  TEST_SOCKET
#define  TEST_SOCKET  1
/*#define  TEST_SOCKET  0*/
#endif

#ifndef  TEST_SERIAL
#define  TEST_SERIAL  0
/*#define  TEST_SERIAL  1*/
#endif

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Definitions + constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* for UI */
/* there are four trigger options in each of the menu screen in the app */
#define		NUM_OF_TRIGGER_OPTIONS		4

/* maximum number of characters in an option trigger */
#define		MAX_OPTION_SIZE			10

/* some default values for the app */
#define		DEFAULT_GOPHER_SERVER_PORT	70
#define		DEFAULT_GOPHER_SERVER_HOST	"geoworks.com"

/* some constant strings */
#define		GOPHER_BOOKMARK_FILENAME	"bookmark.gfr"

/* this is a fixed length */
#define		GOPHER_MOD_DATE_STRING_LENGTH	21

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Enumrated types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*
 * The following includes the possible types of items for the item group
 * of connection parameters. 
 */
typedef enum
{
  CPIT_ITEM,	/* item description parameter */
  CPIT_TYPE,	/* type parameter */
  CPIT_HOST,	/* host parameter */
  CPIT_PORT,	/* port parameter */
  CPIT_SELECTOR,	/* selector parameter */
  CPIT_ASK,	/* ask item parameter */
  CPIT_GOPHERPLUS,	/* gopher plus parameter */
} ConnectionParaItemType;

#define NUM_PARAMETERS	CPIT_GOPHERPLUS+1

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Structures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* 
 * The following structure is used to keep track of the attributes of
 * the current entries that are being stored in the history list.
 */
typedef	struct
{
	FileLongName	GCHLE_filename;
	GopherItem	GCHLE_item;
	word	        GCHLE_fileID;
} GCHistoryListElement;




