/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  htconst.h
 *
 * AUTHOR:  	  Mingzhe Zhu: Apr 14, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	mzhu    	4/14/98		Initial version
 *
 * DESCRIPTION:
 *
 *	Defines some constants and marco.
 *      //depot/liberty/project/ellery/980805/library/www/html/htconst.h#1 $
 * 	$Id: //depot/pcgeos/Library/WWW2/Html/htconst.h#1 $
 *
 ***********************************************************************/
#ifndef _HTML_CONST_H_
#define _HTML_CONST_H_

// assume we're using demoui if we're compiling for black & white
#ifdef GR_NATIVE1
# define SMALL_SCROLLBAR
#endif

#ifdef SMALL_SCROLLBAR
# define HT_SCROLLBAR_WIDTH       9     //pixels
# define HT_SCROLLBAR_HEIGHT      9     //pixels
#else
# define HT_SCROLLBAR_WIDTH      17     //pixels
# define HT_SCROLLBAR_HEIGHT     17     //pixels
#endif

#define HT_SCROLLING_INCREMENT_UNIT 20 // pixels

#define HT_INDENT_SPACE         35 //pixels

// If an object is left/right aligned, we use
// alignment space to allow some spacing between
// the object and its surrounding context.
#define HT_ALIGNMENT_SPACE      2 // pixels

#define min(x,y)        ((x)>(y)?(y):(x))
#define max(x,y)        ((x)>(y)?(x):(y))

#endif /* _HTCONST_H_ */
