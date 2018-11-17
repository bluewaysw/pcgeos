/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tool Utilities
 * FILE:	  malErr.h
 *
 * AUTHOR:  	  Daniel Baumann: May  9, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	DB	5/ 9/96   	Initial version
 *
 * DESCRIPTION:
 *	
 *	Header file for routine provided for tools that don't have any
 *      special screen requirements that preclude the writing of a malloc
 *      error message to stderr.
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _MALERR_H_
#define _MALERR_H_

extern void malloc_err(int fatal, char	*str, int len);

#endif /* _MALERR_H_ */
