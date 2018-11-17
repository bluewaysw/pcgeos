/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	library.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines library structures and routines.
 *
 *	$Id: library.h,v 1.1 97/04/04 15:58:46 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__LIBRARY_H
#define __LIBRARY_H

#include <geode.h>

/***/

extern GeodeHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal GeodeUseLibrary(const char *name, word protoMajor, word protoMinor,
		    	    	GeodeLoadError	*err);

/***/

extern GeodeHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal GeodeUseLibraryPermName(const char *pname, word protoMajor, 
				word protoMinor, GeodeLoadError	*err);

/***/

extern void	/*XXX*/
    _pascal GeodeFreeLibrary(GeodeHandle gh);

/***/

typedef enum /* word */ {
    LCT_ATTACH,
    LCT_DETACH,
    LCT_NEW_CLIENT,
    LCT_NEW_CLIENT_THREAD,
    LCT_CLIENT_THREAD_EXIT,
    LCT_CLIENT_EXIT,
} LibraryCallType;

/*
 *	Library entry point prototype:
 *
 *       extern Boolean		* TRUE if error *
 *	    _pascal LibraryEntry(LibraryCallType ty, GeodeHandle client);
 */

#ifdef __HIGHC__
pragma Alias(GeodeUseLibrary, "GEODEUSELIBRARY");
pragma Alias(GeodeFreeLibrary, "GEODEFREELIBRARY");
#endif

#endif
