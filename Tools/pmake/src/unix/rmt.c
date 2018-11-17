/*-
 * rmt.c --
 *	Functions to handle the exportation of targets. This isn't done,
 *	so all the functions in this file are more or less noops. They do
 *	describe what each function needs to do, however, so use the headers
 *	as a reference when creating a new method of distribution.
 *
 * Copyright (c) 1988 by the Regents of the University of California
 * Copyright (c) 1988 by Adam de Boor
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  Neither the University of California nor
 * Adam de Boor makes any representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 *
 * Interface:
 *	Rmt_Init  	    	Initialize things for this module
 *
 *	Rmt_AddServer	    	Add the given name as the address of
 *	    	  	    	an export server.
 *
 *	Rmt_Begin 	    	Prepare to export another job and tell
 *	    	  	    	if it can actually be exported.
 *
 *	Rmt_Exec  	    	Execute the given shell with argument vector
 *	    	  	    	elsewhere.
 *
 *	Rmt_LastID	    	Return an unique identifier for the last
 *	    	  	    	job exported.
 *
 *	Rmt_Done  	    	Take note that a remote job has finished.
 *
 */
#ifndef lint
static char *rcsid =
"$Id: rmt.c,v 1.1 89/06/13 17:05:36 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "make.h"

/*-
 *-----------------------------------------------------------------------
 * Rmt_Init --
 *	Initialize this module...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Depends on the exportation to be used...
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Init()
{
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_AddServer --
 *	Add a server to the list of those known.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Who knows?
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Rmt_AddServer (name)
    char    *name;
{

}

/*-
 *-----------------------------------------------------------------------
 * Rmt_ReExport --
 *	Supposed to re-export a job that's come home.
 *
 * Results:
 *	FALSE if job couldn't be re-exported and TRUE if it could.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
Boolean
Rmt_ReExport(pid)
    int	    pid;
{
    return(FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Begin --
 *	Prepare to export a job.
 *
 * Results:
 *	TRUE if the job can be exported. FALSE if it cannot.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
Boolean
Rmt_Begin (file, argv, gn)
    char    	  *file;
    char    	  **argv;
    GNode   	  *gn;
{
    return FALSE;
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Exec --
 *	Execute a process elsewhere.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	That remains to be seen.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Rmt_Exec (file, args, traceMe)
    char    *file;
    char    **args;
    Boolean traceMe;
{
    (void)execv (file, args);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_LastID --
 *	Return an unique identifier for the last job exported with Rmt_Exec
 *
 * Results:
 *	Some sort of identifier.
 *
 * Side Effects:
 *	???
 *
 *-----------------------------------------------------------------------
 */
int
Rmt_LastID(pid)
    int	    	  pid;	    /* PID of job last exported */
{
    return 0;
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Done --
 *	Register the completion of a remote job.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Probably.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Rmt_Done (id)
    int	    id;
{
}
