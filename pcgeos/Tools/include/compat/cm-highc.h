/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  cm-highc.h
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
 * 	$Id: cm-highc.h,v 1.2 97/04/17 17:36:01 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _CM_HIGHC_H_
#define _CM_HIGHC_H_

#ifndef __HIGHC__
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
/*
 * The POINTER pragmas are on because I can't compile without them.
 * Sometimes highs appears to let you cast pointers, sometimes not.
 * I can't figure out the logic to it. -ron
 */
#pragma ON(POINTERS_COMPATIBLE)
#pragma ON(POINTERS_COMPATIBLE_WITH_INTS)
/*
 * Highc gave me a warning when compiling uic, telling me to turn this
 * off.  I think we are doing pointer shme that it doesn't know how to
 * properly optimize (again in uic). -ron
 */
#pragma OFF(BEHAVED)
/* 
 * HighC likes char foo[0] in structs.  HighC generates
 * array-index-out-of-bound warnings if you attempt to use such a
 * field with [].
 */

#define LABEL_IN_STRUCT 0
/* HighC doesn't allow byte-level pointer arithmetic on void *. */
typedef char *genptr;

/* HighC supports inlining. */
#define inline _Inline

#endif /* _CM_HIGHC_H_ */
