/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  cm-bor.h
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
#ifndef _CM_BOR_H_
#define _CM_BOR_H_

#ifndef __BORLANDC__
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

#define HAVE_DIRENT

/***********************************************************************
 *
 * Define compiler's behavior
 *
 ***********************************************************************/

/* Borland likes char foo[], not char foo[0]. */
#define LABEL_IN_STRUCT

/* Borland doesn't allow arithmetic on void *. */
typedef char *genptr;

/* Borland doesn't support the inline keyword in any obvious way. */
#define inline

/* Borland uses _popen() instead of popen() */
#define popen _popen
#define pclose _pclose

#endif /* _CM_BOR_H_ */
