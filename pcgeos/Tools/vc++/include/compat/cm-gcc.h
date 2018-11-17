/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  cm-gcc.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May  3, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/ 3/96   	Initial version
 *
 * DESCRIPTION:
 *	Do not include this file directly.  It is meant to be included
 *	via config.h.  See config.h for details.
 *
 *
 * 	$Id: cm-gcc.h,v 1.1 96/05/18 14:51:17 jacob Exp $
 *
 ***********************************************************************/
#ifndef _CM_GCC_H_
#define _CM_GCC_H_

#ifndef __GNUC__
#error Why are you including this file?
#endif

/***********************************************************************
 *
 * Remap routine names with macros
 *
 ***********************************************************************/

/***********************************************************************
 *
 * Define any routines provided by this compiler's runtime
 *
 ***********************************************************************/

/***********************************************************************
 *
 * Define compiler's behavior
 *
 ***********************************************************************/

/* gcc likes char foo[0], not char foo[] in structs. */
#define LABEL_IN_STRUCT 0

/* gcc allows arithmetic on void *, as if it were char *. */
typedef void *genptr;

/* gcc supports inline. */

#endif /* _CM_GCC_H_ */
