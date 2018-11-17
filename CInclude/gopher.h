/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Gopher Client	
MODULE:		Sample Library -- Gopher Library
FILE:		gopher.h

AUTHOR:		Alvin Cham, Aug  3, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	8/ 3/94   	Initial version.

DESCRIPTION:
	

	$Id: gopher.h,v 1.1 97/04/04 16:00:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef	__GOPHER_HEADER_FILE
#define __GOPHER_HEADER_FILE

#include <geos.h>
#include <char.h>
#include <ec.h>

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Defines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#define	    GOPHER_READ_BUFFER_SIZE 	256
#define	    GOPHER_ITEM_INFORMATION_SIZE 	256
#define	    GOPHER_TMP_TEXT_FILENAME	"tmp.gfr"
#define	    GOPHER_TMP_FILENAME_TEMPLATE	"\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
#define	    GOPHER_TMP_FILENAME_TEMPLATE_LENGTH	14
#define	    GOPHER_TMP_FILE_LENGTH GOPHER_TMP_FILENAME_TEMPLATE_LENGTH

#define	    GOPHER_CACHE_FILE_ARRAY_SIZE 3


/* the following are for parsing a gopher+ information attributes */
#define	    GOPHER_TOKEN_SEPARATOR	C_COLON
#define	    GOPHER_INFO_START_INDICATOR	C_LESS_THAN
#define	    GOPHER_INFO_END_INDICATOR	C_GREATER_THAN
#define	    GOPHER_LENGTH_OF_DATE	14
#define	    GOPHER_PLUS_INDICATOR	C_PLUS

/* 
 * GopherClientRequest is a record that represents the type of requests
 * that the client can retrieve information from the server.
 */
typedef	byte	GopherClientRequest;
#define		GCR_NORMAL	0x0001
#define		GCR_GOPHER_PLUS	0x0002
#define		GCR_ATTR_INFO	0x0004
#define		GCR_WITH_DATA	0x0008

/*
 * GopherItemTypeChar represents the type (in character) of the menu item
 * that are being transmitted from the gopher server.
 */ 
typedef	byte	GopherItemTypeChar;
#define		GITC_FILE 	C_ZERO
#define		GITC_DIRECTORY 	C_ONE
#define		GITC_CSO 	C_TWO
#define		GITC_ERROR 	C_THREE
#define		GITC_MAC 	C_FOUR
#define		GITC_DOS 	C_FIVE
#define		GITC_UUENCODE 	C_SIX
#define		GITC_TEXT_SEARCH_SERVER 	C_SEVEN
#define		GITC_TELNET 	C_EIGHT
#define		GITC_BINARY 	C_NINE

typedef	byte	GopherParseItemType;
#define		GPIT_FILE 	0
#define		GPIT_DIRECTORY  1
/* 
 * 2-9 are reserved for other gopher built-in types, just in case we need to 
 * use them later 
 */
#define		GPIT_GOPHER_PLUS  10
#define		GPIT_BOOKMARK     11
/* more new types can be added later */

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Enumerated types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*
 * The following includes the possible different kinds of languages that
 * the gopher server accepts.
 *
 *  GLT_DANISH	        --"Da_DK"
 *  GLT_DUTCH_BELGIUM	--"Nl_BE"
 *  GLT_DUTCH	        --"Nl_NL"
 *  GLT_ENGLISH_GB	--"En_GB"	English (Great Britain)
 *  GLT_ENGLISH	        --"En_US"	English (US)
 *  GLT_FINNISH	        --"Fi_FI"
 *  GLT_FRENCH_BELGIUM	--"Fr_BE" 
 *  GLT_FRENCH_CANADA	--"Fr_CA" 
 *  GLT_FRENCH_SWISS	--"Fr_CH"       French (Switzerland)
 *  GLT_FRENCH	        --"Fr_FR" 
 *  GLT_GERMAN_SWISS	--"De_CH"       German (Switzerland)
 *  GLT_GERMAN	        --"De_DE" 
 *  GLT_GREEK	        --"El_GR" 
 *  GLT_ICELANDIC	--"Is_IS" 
 *  GLT_ITALIAN	        --"It_IT" 
 *  GLT_JAPANESE	--"Jp_JP" 
 *  GLT_NORWEGIAN	--"No_NO" 
 *  GLT_PORTUGUESE	--"Pt_PT" 
 *  GLT_SPANISH	        --"Es_ES" 
 *  GLT_SWEDISH	        --"Sv_SE" 
 *  GLT_TURKISH	        --"Tr_TR"  
 */

typedef enum {
    GLT_DANISH,
    GLT_DUTCH_BELGIUM,
    GLT_DUTCH,
    GLT_ENGLISH_GB,
    GLT_ENGLISH,
    GLT_FINNISH,
    GLT_FRENCH_BELGIUM,
    GLT_FRENCH_CANADA,
    GLT_FRENCH_SWISS,
    GLT_FRENCH,
    GLT_GERMAN_SWISS,
    GLT_GERMAN,
    GLT_GREEK,
    GLT_ICELANDIC,
    GLT_ITALIAN,
    GLT_JAPANESE,
    GLT_NORWEGIAN,
    GLT_PORTUGUESE,
    GLT_SPANISH,
    GLT_SWEDISH,
    GLT_TURKISH,
} GopherLanguageType;

/*
 * The followings are the possible types of gopher+ item attribute 
 * information
 *
 *	GPIAIT_INFO			- this type represents a block
 *					  containing all gopher item
					  description
 *	GPIAIT_ADMIN			- this type represents a block
 *					  containing all kinds of 
 *					  adminstrative attributes like
 *					  modification date, administrator
 *					  of the item, etc
 *	GPIAIT_VIEWS			- this type represents a block
 *					  that lists different formats the
 *					  document can be retrieved, and
 *					  some information about the display
 *	GPIAIT_ABSTRACT			- this type represents a block
 *					  containing lines of text
 */ 
typedef enum
{
	GPIAIT_INFO,
	GPIAIT_ADMIN,
	GPIAIT_VIEWS,
	GPIAIT_ABSTRACT,
} GopherPlusItemAttrInfoType;

/*
 * The followings are the possible types of gopher server respond.
 *
 * 	GITT_gopher			- a normal gopher item type
 *	GITT_gopherPlus			- a gopher+ attribute item
 */
typedef enum
{
	GITT_gopher,
	GITT_gopherPlus,
} GopherItemTypeType;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Structures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * The following structure includes all of the information stored in a 
 * gopher item.
 *
 *	GI_type			- the kind of object the item is 
 *	GI_userVisibleName	- used to browse and select from menu 
 *				  listings
 *	GI_selectorString	- containing the pathname used by the 
 *				  destination host to locate the 
 *				  desired object
 *	GI_hostname		- host to contact to obtain this item
 *	GI_portNumber		- the port at which the server process
 *				  listens for connections
 *
 *	(the following are needed for the gopher+ features)
 *
 *	GI_gopherPlusInfo	- Is there any gopher+ information
 */
typedef	struct
{
        GopherParseItemType     GI_type;
	ChunkHandle	GI_userVisibleName;
	ChunkHandle	GI_selectorString;	
	ChunkHandle	GI_hostname;
	word		GI_portNumber;

	/* fill in gopher+ features here */
	Boolean		GI_gopherPlusInfo;
} GopherItem;

/* The INFO simply includes the gopher item description. */
typedef	GopherItem GopherPlusItemAttrInfo; 


/*
 * The following definition includes the information of the ADMIN field of a 
 * gopher+ item 
 * attribute.
 */
typedef	ChunkHandle GopherPlusItemAttrAdminInfo;

/*
 * The following structure includes the information that may be stored 
 * within the 'date' attribute of an ADMIN field of a gopher+ item 
 * attribute.
 *
 *	GPIADI_year			- year of modification
 *	GPIADI_month		        - month of modification
 *	GPIADI_day			- day of modification
 *	GPIADI_hour			- hour of modification
 *	GPIADI_minute			- minute of modification
 *	GPIADI_second			- second of modification
 */
typedef struct
{
	word	GPIADI_year;
	word	GPIADI_month;
	word	GPIADI_day;
	word	GPIADI_hour;
	word	GPIADI_minute;
	word	GPIADI_second;
} GopherPlusItemAttrDateInfo;


/*
 * The following structure includes the information of an ADMIN field of 
 * a gopher+ item attribute.  The ADMIN field keeps track of the information
 * of the item's administrator.
 * 
 */
typedef struct
{
	GopherPlusItemAttrAdminInfo	GPIAA_email;
	GopherPlusItemAttrDateInfo	GPIAA_modDate;
} GopherPlusItemAttrAdmin;

/*
 * A chunk to store the information of a VIEW field of a gopher+ item 
 * attribute.
 */
typedef ChunkHandle GopherPlusItemAttrView;

/*
 * A chunk array to store the location of the chunks of the gopher+ items. 
 */
typedef ChunkHandle GopherPlusViewChunkArray;

/*
 * Type for storing the text of the ABSTRACT filed of a gopher+ item attribute.
 */
typedef ChunkHandle GopherPlusItemAttrAbstract;

/*
 * The following structure includes the information of an element stored in 
 * the cached file chunk array.
 *
 *	GCFAE_valid		        - whether the entry is valid
 *	GCFAE_filename			- the filename itself
 *    	GCFAE_fileID			- the fileID
 */
typedef struct
{
        Boolean GCFAE_valid;
	char    GCFAE_filename[GOPHER_TMP_FILE_LENGTH];
	word    GCFAE_fileID;
} GopherCacheFileArrayElement;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fatal errors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

typedef enum {
    ERROR_NO_MEMORY_TO_ALLOC_TMP_BLOCK,
    ERROR_NO_MEMORY_TO_ALLOC_CHUNK,
    ERROR_UNDEFINED_CACHE_FILE_CHUNK,
    ERROR_INVALID_GOPHER_PLUS_INDICATOR,
    ERROR_INVALID_GOPHER_PLUS_BLOCK_START_INDICATOR,
    ERROR_INVALID_TOKEN_SEPARATOR,
    ERROR_INVALID_FILE_OFFSET_POSITION,
    ERROR_OVERREADING_BUFFER,
    ERROR_INCOMPATIBLE_DATE_LENGTH,
    ERROR_UNEQUAL_PARSED_LENGTH_WITH_BUFFER_LENGTH,
    ERROR_INVALID_CACHE_FILE_ARRAY_ELEMENT,
} FatalErrors;

#endif	/* __GOPHER_HEADER_FILE */






