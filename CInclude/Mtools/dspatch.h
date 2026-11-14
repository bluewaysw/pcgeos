/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  dspatch.h
 *
 * AUTHOR:  	  Kok Kin Kee: Mar 12, 1997
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	kkee    	3/12/97   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 *	$Id: dspatch.h,v 1.1 97/04/04 15:55:57 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _DSPATCH_H_
#define _DSPATCH_H_

#endif /* _DSPATCH_H_ */

#define PUSHDS asm{push ds}
#define POPDS  asm{pop ds}
#define SET_DS_LIB_DGROUP GeodeLoadDGroup(GeodeGetCodeProcessHandle())

