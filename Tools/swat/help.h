/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:       PCGEOS	  
 * MODULE:	  Swat -- Help String Maintenance
 * FILE:	  help.h
 *
 * AUTHOR:  	  Daniel Baumann: May  6, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	DB	5/ 6/96   	Initial version
 *
 * DESCRIPTION:
 *	Header file for functions to implement the swat help facility.
 *
 * 	$Id: help.h,v 1.1 96/05/20 18:46:33 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _HELP_H_
#define _HELP_H_

extern char *Help_Fetch(const char *name, const char *class);	
extern void Help_Store(const char *topic, const char *class, 
		       const char *string);
extern void Help_Init(void);

#endif /* _HELP_H_ */
