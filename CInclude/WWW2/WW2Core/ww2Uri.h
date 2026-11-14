/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  GEOS WWW2 Library
 * MODULE:	  WW2Core Library
 * FILE:	  ww2Uri.h
 *
 * AUTHOR:  	  Allen Yuen: Aug  7, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	allen   	8/ 7/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	URI management.
 *      //depot/liberty/project/ellery/main/include/www/wwcore/wwuri.h#8 
 *
 *	$Id: //depot/pcgeos/CInclude/WWW2/WW2Core/ww2Uri.h#1 $
 *
 ***********************************************************************/
#ifndef _WW2URI_H_
#define _WW2URI_H_

#include <geos.h>
#include <WWW2/ww2mem.h>

    //////////
    //
    // Indicate what components you want to parse of in a URI.

#define WWURI_PARSE_PORT               0x20
#define WWURI_PARSE_ACCESS             0x10
#define WWURI_PARSE_HOST               0x8
#define WWURI_PARSE_PATH               0x4
#define WWURI_PARSE_ANCHOR             0x2
#define WWURI_PARSE_PUNCTUATION        0x1
#define WWURI_PARSE_ALL                (WWURI_PARSE_PORT                | \
                                        WWURI_PARSE_ACCESS              | \
                                        WWURI_PARSE_HOST                | \
                                        WWURI_PARSE_PATH                | \
                                        WWURI_PARSE_ANCHOR              | \
                                        WWURI_PARSE_PUNCTUATION)

    //////////
    //
    // WWSimplifyURI simplifies a URI.
    //
    // Ported from W3C HTSimplify in HTParse.c
    //
    // Return_value_ The simplified passed in URI.
    // A URI is allowed to contain the seqeunce xxx/../ which may be
    // replaced by "" , and the seqeunce "/./" which may be replaced by "/".
    // Simplification helps us recognize duplicate URIs. 
    // 
    // Thus,   /etc/junk/../fred   becomes /etc/fred
    //         /etc/junk/./fred    becomes /etc/junk/fred
    // 
    // but we should NOT change
    //         http://fred.xxx.edu/../..
    // 
    //     or  ../../albert.html
    // 
    // In order to avoid empty URLs the following URLs become:
    // 
    //       /fred/..                becomes /fred/..
    //       /fred/././..            becomes /fred/..
    //       /fred/.././junk/.././   becomes /fred/..
    // 
    // If more than one set of `://' is found (several proxies in cascade) then
    // only the part after the last `://' is simplified.
    //
    // Status_ Superficially engineering tested.
    //

char *WWSimplifyURI(char **url);

    //////////
    //
    // WWParseURIStr returns those parts of a name which are given and 
    // requested. We substitute parts from the related name where 
    // necessary. 
    //
    // Parameters_
    // [in] aName       The absolute URL or filename given relatedName.
    // [in] relateName  Related to aName. Pass NULL if aName is absolute.
    // [in] wanted      A mask for the parts which are wanted. See #defines
    //                  above.
    //
    // Return_value_ Allocated using malloc() and must be freed be caller
    //               if not NULL.
    //
    // Status_ Superficially engineering tested.
    //

char * WWParseURIStr(const char *aName, const char *relatedName, word
                  wanted);

    //////////
    //
    // Same as WWParseURIStr(const char*, const char*, uint16), but takes
    // two WWMemHandles.
    //
    // Parameters_
    // [in] aName       The absolute URL or filename given relatedName.
    // [in] relateName  Related to aName. Pass NULL if aName is absolute.
    // [in] wanted      A mask for the parts which are wanted. See #defines
    //                  above.
    //
    // Return_value_ Allocated using malloc() and must be freed be caller
    //               if not NULL.
    //
    // Status_ Superficially engineering tested.
    //
char * WWParseURIHandle(WWMemHandle aNameH, WWMemHandle relatedNameH, word
                  wanted);

    //////////
    //
    // These two functions should be used by applications. They call 
    // WWParseURIxxx( xx, NULL, WWURI_PARSE_ALL) for both aName and related,
    // and then combine them.
    //
    // Parameters_
    // [in] aName       The absolute URL or filename given relatedName.
    // [in] relateName  Related to aName. Pass NULL if aName is absolute.
    //
    // Return_value_ Allocated using malloc() and must be freed be caller
    //               if not NULL.
    //
    // Status_ Superficially engineering tested.
    //
char * WWParseURIStrAll(const char *aName, const char *relatedName);
char * WWParseURIHandleAll(WWMemHandle aNameH, WWMemHandle relatedNameH);

    //////////
    //
    // WWFileURIOpen opens a file URI.
    // The New Sokoto filesystem is in a state of flux. For
    // Sokoto B this function will need to be revised.
    // Responsibility for file closing is with the caller.
    //
    // This function does not attempt to implement non local
    // (or remote) file retrieval.
    //
    // Return_value_ FileHandle if open, else NULL.
    //
    // Status_ Engineering tested.
    //
 
FileHandle WWFileURIOpen(const char *url);

#endif /* _WW2URI_H_ */
