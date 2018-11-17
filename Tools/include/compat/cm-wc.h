/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  cm-wc.h
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
 * 	$Id: cm-bor.h,v 1.2 97/04/17 17:19:06 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _CM_WC_H_
#define _CM_WC_H_

#ifndef __WATCOMC__
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

#include <math.h>
#include <io.h>

#define HAVE_DIRENT
#define HAVE_BCMP
#define HAVE_BCOPY
#define HAVE_BZERO
#define HAVE_ISINF
#define HAVE_MKTEMP

/***********************************************************************
 *
 * Define compiler's behavior
 *
 ***********************************************************************/

/* Borland likes char foo[], not char foo[0]. */
#define LABEL_IN_STRUCT

/* Borland doesn't allow arithmetic on void *. */
typedef char *genptr;
typedef void *genptrparam ;

/* Borland doesn't support the inline keyword in any obvious way. */
#define inline

/* Borland uses _popen() instead of popen() */
#define popen _popen
#define pclose _pclose

#define mktemp _mktemp

#endif /* _CM_WC_H_ */
