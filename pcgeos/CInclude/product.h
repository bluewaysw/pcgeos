/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) NewDeal 1999 -- All Rights Reserved

PROJECT:	NewDeal
MODULE:		
FILE:		product.h

AUTHOR:		Martin Turon, February 9, 1999

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1999/2/9  	Initial version.

MACROS:
	Name			Description
	----			-----------
	NDO2000			Generate code for NewDeal Office 2000	
	GPC1999			Generate code for Global PC 1999

DESCRIPTION:
	Defines macros used to differentiate between various builds
	and products based on the common PC/GEOS source tree.
	To make full use of this header, define an environment flag
	PRODUCT=<X> and add an entry in Tools/scripts/perl/product_flags
	to map your product into the proper flags to pass to the
	compilation tools.  This file may have to be split into separate 
	Internal/product<X>.h files at some later date.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _PRODUCT_H_
#define _PRODUCT_H_


/*=========================================================================
 *	Map build environment variables to product compilation flags
 *=========================================================================*/

#ifdef  PRODUCT_NDO2000
#define _NDO2000 (-1)
#else
#define _NDO2000 0
#endif  /* PRODUCT_NDO2000 */

#ifdef  PRODUCT_GPC1999
#define _GPC1999 (-1)
#else
#define _GPC1999 0
#endif  /* PRODUCT_GPC1999 */

/*=========================================================================
 *	Product Features -- set global product feature flags here
 *=========================================================================*/

#if _NDO2000
    /*
     * #define GLOBAL_FEATURE_1   -1 
     * #define GLOBAL_FEATURE_2    0
     * ...etc.
     */
#endif

#if _GPC1999
     #define _DOS_LONG_NAME_SUPPORT	-1
#endif

     /* browser flags */
     #define PROGRESS_DISPLAY	-1
     #define EMBED_SUPPORT      -1

/*=========================================================================
 *	Product Macros
 *=========================================================================*/

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FeatureFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only sets the product feature flag if it isn't set already.
PASS:		feature_flag	= PRODUCT_FEATURE_FLAG
		value		= TRUE, FALSE, 0, 1, -1

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Normal C / UIC preprocessor is not powerful enough to resolve
	the FeatureFlag macro!!!  Use hard #ifndef/endif pairs instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1999/2/22	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*
 @define FeatureFlag(feature_flag, value)    \
	#ifndef feature_flag		\
	#define feature_flag value	\
	#endif
*/


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDO2000
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Include code only in the NDO2000 version of PC/GEOS
		NDO2000 stands for NewDeal Office 2000, but also
		includes related products like SchoolSuite, etc.
		NewDeal is the full desktop version of the software
		for use in schools and non-profit donation.

PASS:		line - line of source code

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Only includes line if NDO2000 *is* defined

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1999/2/9	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#if _NDO2000
#define NDO2000(line)          line
#else
#define NDO2000(line)          
#endif

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GPC1999
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Include code only in the GPC1999 version of PC/GEOS
		GPC1999 stands for Global PC 1999 -- a consumer market
		product that bundles PC/GEOS on pentium class hardware
		for sale in the consumer retail channel.

PASS:		line - line of source code

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Only includes line if GPC1999 *is* defined

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1999/2/9	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#if _GPC1999
#define GPC1999(line)          line
#else
#define GPC1999(line)          
#endif

#endif






