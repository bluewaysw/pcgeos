/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1994 -- All Rights Reserved
 *
 * PROJECT:       PCGeos
 * MODULE:	  Thesaurus 
 * FILE:	  spellFeatures.h
 *
 * AUTHOR:  	  Chris Hawley-Ruppel, 6/22/94
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	cbh       6/22/94   Initial version
 *
 * DESCRIPTION:
 *      Feature-specific constants for C or UIC include files
 *
 * 	$Id: spellFeatures.h,v 1.1 97/04/07 11:07:31 newdeal Exp $
 *
 ***********************************************************************/

#ifdef PRODUCT_REDWOOD
 #define FLOPPY_BASED_USER_DICT	   -1
 #define DEFINITIONLESS_THESAURUS  -1

#else
#ifdef PRODUCT_DWP

 #define FLOPPY_BASED_USER_DICT	   -1
 #define DEFINITIONLESS_THESAURUS  0

#else
#ifdef PRODUCT_NIKE

 #define FLOPPY_BASED_USER_DICT	   -1
 #define DEFINITIONLESS_THESAURUS  0

#else

 #define FLOPPY_BASED_USER_DICT	   0
 #define DEFINITIONLESS_THESAURUS  0

#endif
#endif
#endif

