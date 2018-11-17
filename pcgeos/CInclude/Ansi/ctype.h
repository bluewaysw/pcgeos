/*********************************************************************
 *								     
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
 *								     
 * 	PROJECT:	PC GEOS					     
 * 	MODULE:							     
 * 	FILE:		ctype.h 				     
 *								     
 *	AUTHOR:		jimmy lefkowitz				     
 *								     
 *	REVISION HISTORY:					     
 *								     
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	8/15/91		Initial              		     
 *	schoon	4/8/92		Updated to Ansi C standards   	     
 *							   	     
 *	DESCRIPTION:						     
 *								     
 *	$Id: ctype.h,v 1.1 97/04/04 15:50:25 newdeal Exp $
 *							   	     
 *********************************************************************/
#ifndef __CTYPE_H
#define __CTYPE_H

extern int	
  _pascal isalnum(unsigned int __c);

extern int	
  _pascal isalpha(unsigned int __c);

extern int 	
  _pascal iscntrl(unsigned int __c);

extern int	
  _pascal isdigit(unsigned int __c);

extern int	
  _pascal isgraph(unsigned int __c);

extern int	
  _pascal islower(unsigned int __c);

extern int	
  _pascal isprint(unsigned int __c);

extern int	
  _pascal ispunct(unsigned int __c);

extern int	
  _pascal isspace(unsigned int __c);

extern int	
  _pascal isupper(unsigned int __c);

extern int	
  _pascal isxdigit(unsigned int __c);

extern int
  _pascal toupper(unsigned int __c);

extern int
  _pascal tolower(unsigned int __c);
  

#ifdef __HIGHC__
pragma Alias(isupper, "ISUPPER");
pragma Alias(islower, "ISLOWER");
pragma Alias(isalpha, "ISALPHA");
pragma Alias(ispunct, "ISPUNCT");
pragma Alias(isspace, "ISSPACE");
pragma Alias(iscntrl, "ISCNTRL");
pragma Alias(isdigit, "ISDIGIT");
pragma Alias(isxdigit, "ISXDIGIT");
pragma Alias(isalnum, "ISALNUM");
pragma Alias(isprint, "ISPRINT");
pragma Alias(isgraph, "ISGRAPH");
pragma Alias(toupper, "TOUPPER");
pragma Alias(tolower, "TOLOWER");
#endif

#endif























