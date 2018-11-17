/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat/Esp/UIC -- String table definitions
 * FILE:	  sttab.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/11/89	  tony	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for string table.
 *
 *
 * 	$Id: string.h,v 1.1 89/07/17 21:00:23 adam Exp $
 *
 ***********************************************************************/
#ifndef _STTAB_H_
#define _STTAB_H_

#include <stdio.h>

/*
 * String_Enter and String_Lookup return a pointer to the string, but to
 * emphasize that it returns a value unique to that string, a value it will
 * return whenever that string is entered or sought, we call the value an ID.
 */
typedef char	*ID;

extern ID	String_Enter(char *str, int len);
extern ID   	String_EnterNoLen(char *str);
extern ID   	String_Lookup(char *str, int len);
extern ID   	String_LookupNoLen(char *str);

#endif /* _STTAB_H_ */
