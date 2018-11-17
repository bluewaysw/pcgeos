/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Utilities
 * FILE:	  objswap.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 17, 1991
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/17/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Declarations for the object/symbol-file byte-swapping module
 *	of this here library.
 *
 * 	$Id: objSwap.h,v 1.1 91/04/26 11:48:54 adam Exp $
 *
 ***********************************************************************/
#ifndef _OBJSWAP_H_
#define _OBJSWAP_H_

#include    <vm.h>
#include    <objfmt.h>


extern VMRelocRoutine	ObjSwap_Reloc;
extern VMRelocRoutine	ObjSwap_Reloc_NewFormat;
extern void 	    	ObjSwap_Header(ObjHeader *hdr);

#endif /* _OBJSWAP_H_ */
