/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  version.c
 * FILE:	  version.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 13, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Version	    	    Return the time and date this was compiled.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/13/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Routine to provide the time at which swat was compiled
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: version.c,v 4.4 97/04/18 17:09:36 dbaumann Exp $";
#endif lint

#include <config.h>

char *
Version(void)
{
#if defined(unix)
    return ("Swat version 2.1 (" __DATE__ " " __TIME__ " by " USERNAME "@" HOSTNAME ")");
#else
    return ("Swat version 2.1 (" __DATE__ " " __TIME__ ")");
#endif
}
