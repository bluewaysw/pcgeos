/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- String table definitions
 * FILE:	  stringt.h
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
 * 	$Id: string.h,v 1.2 89/06/09 00:19:25 adam Exp $
 *
 ***********************************************************************/
#ifndef _STRINGT_H_
#define _STRINGT_H_

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

#endif /* _STRING_H_ */
