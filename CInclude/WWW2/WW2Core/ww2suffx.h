/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Geos-SC WWW Library
 * MODULE:	  File suffix
 * FILE:	  suffix.h
 *
 * AUTHOR:  	  Kok Kin Kee: Feb 23, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	kkee    	2/23/98		Initial version
 *
 * DESCRIPTION:
 *
 *	Map file suffix to content type.
 *
 * 	$Id: //depot/pcgeos/CInclude/WWW2/WW2Core/ww2suffx.h#1 $
 *
 ***********************************************************************/
#ifndef _SUFFIX_H_
#define _SUFFIX_H_

    /*////////
    //
    // Map suffix to MIME content-type.
    //
    // Parameters_ 
    //
    // [in]  suffix     Suffix string
    //
    // Return_value_ Content-type if there is mapping.
    //               NULL if no mapping is found or passed suffix is NULL.
    //
    //
    // See_also_ UrlMimeType()
    //
    // Status_ Functional.
    */
const char * _far _pascal SuffixMimeType(const char *suffix);

    /*////////
    //
    // Map url (file and http url) to MIME content-type.
    //
    // Parameters_ 
    //
    // [in]  url     Could be a http url, file url, or filename.
    //
    // Return_value_ Content-type if there is mapping.
    //               NULL if no mapping is found or passed suffix is NULL.
    //
    //
    // See_also_ SuffixMimeType()
    //
    // Status_ Functional.
    */
const char * _far _pascal UrlMimeType(const char *url);
const char * _far _pascal UrlMimeTypeTCHAR(const TCHAR *url);


    /*////////
    //
    // Map a mime type to a file suffix.
    //
    // Parameters_ 
    //
    // [in]  type    mime type.
    //
    // Return_value_ file suffix.
    //               NULL if we don't handle the mime type.
    //
    //
    // See_also_ SuffixMimeType()
    //
    // Status_ Functional.
    */
const TCHAR* _far _pascal MimeTypeToSuffix(const char *type);

#endif /* _SUFFIX_H_ */
