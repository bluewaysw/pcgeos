/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  ww2Sjis.h
 *
 * AUTHOR:  	  Allen Yuen: Aug  3, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	allen   	8/ 3/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	SJIS -> Unicode conversion
 *
 *	$Id: //depot/pcgeos/CInclude/WWW2/WW2Core/ww2Sjis.h#1 $
 *
 ***********************************************************************/
#ifndef _WW2SJIS_H_
#define _WW2SJIS_H_

#include <geos.h>

//////////
//
// Converts SJIS string to Unicode.
//
// [in]  data    Pointer to the string to convert
// [in]  len     The number of bytes to convert from data
// [out] tchr    Contains converted data.
//
// Return_value_ Number of characters converted.
//
extern word SjisStringToUnicodeString(char *data, TCHAR *tchr, word len);

#endif /* _WW2SJIS_H_ */
