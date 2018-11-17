/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  string.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May 14, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/14/96   	Initial version
 *
 * DESCRIPTION:
 *	"Portable" way to include string.h.  This file includes
 *	either <string.h> or <strings.h>, depending on the OS.
 *
 *
 * 	$Id: string.h,v 1.1 96/05/18 14:51:24 jacob Exp $
 *
 ***********************************************************************/
#ifndef _STRING_H_
#define _STRING_H_

/*
 * For now, I'm assuming that these are going to vary by OS rather
 * than compiler.  If that ever stops working, feel free to change
 * this appropriately.
 */
#if defined(unix)
#include <strings.h>
#elif defined(_MSDOS) || defined(_WIN32)
#include <string.h>
#else
#error Your compiler/OS is not yet supported
#endif

#endif /* _STRING_H_ */
