/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  swat
 * FILE:	  safesjmp.h
 *
 * AUTHOR:  	  Dan Baumann: Apr 11, 1997
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	dbaumann	4/11/97   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 *	$Id: safesjmp.h,v 1.1 97/04/18 16:30:37 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _SAFESJMP_H_
#define _SAFESJMP_H_

#endif /* _SAFESJMP_H_ */

#if !defined(_WIN32)
typedef int jmp_buf[10+12];
#else
# include <setjmp.h>
#endif
