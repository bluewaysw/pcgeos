/* 
 * setenv.c --
 *
 *	Contains the source code for the "setenv" library procedure.
 *
 * Copyright 1988 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */
#include <config.h>

#ifndef lint
static char rcsid[] = "$Id: setenv.c,v 1.2 96/06/24 15:04:19 tbradley Exp $ SPRITE (Berkeley)";
#endif not lint

#include <stdio.h>
#include <stdlib.h>
#include <compat/string.h>
#define  WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "winutil.h"

extern char **environ;

/*
 *----------------------------------------------------------------------
 *
 * setenv --
 *
 *	Associate the value "value" with the environment variable
 *	"name" in this process's environment.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The storage for the environment is modified.  If there already
 *	was an environment variable by the given name, then it is
 *	replaced.  Otherwise a new environment variable is created.
 *	The new value will be visible to this process, and also will
 *	be passed to children processes.
 *
 *----------------------------------------------------------------------
 */

void
setenv(
    char *name,			/* Name of environment variable. */
    char *value)		/* (New) value for variable. */
{
#if defined(_WIN32)
    if (!SetEnvironmentVariable(name, value)) {
	WinUtil_PrintError("pmake: SetEnvironmentVariable failed");
    }
#elif defined(_MSDOS)
    char *outstring = (char *) malloc(strlen (name) + strlen(value) + 10);

    sprintf(outstring, "%s=%s", name, value);
    putenv(outstring);

    free(outstring);
#else /* unix */
    register int    i;
    register char **envPtr;
    register char **newEnvPtr;
    register char *charPtr;
    register char *namePtr;
    char *newEnvValue;

    newEnvValue = (char *)malloc ((unsigned) (strlen (name) +
					      strlen (value) + 2));
    if (newEnvValue == 0) {
	return;
    }
    (void) sprintf(newEnvValue, "%s=%s", name, value);

    /*
     * Although this procedure allocates new storage when necessary,
     * it can't de-allocate the old storage, because it doesn't know
     * which things were allocated with malloc and which things were
     * allocated statically when the process was created.
     */

    for (envPtr = environ, i=0; *envPtr != 0; envPtr++, i++) {
	for (charPtr = *envPtr, namePtr = name;
	     *charPtr == *namePtr; namePtr++) {
	     charPtr++;
	     if (*charPtr == '=') {
		 namePtr++;
		 if (*namePtr == '\0') {
		     *envPtr = newEnvValue;
		     return;
		 }
		 break;
	     }
	 }
    }
    newEnvPtr = (char **) malloc ((unsigned) ((i + 2) * sizeof *newEnvPtr));
    if (newEnvPtr == 0) {
	return;
    }
    for (envPtr = environ, i = 0; *envPtr; envPtr++, i++) {
	newEnvPtr[i] = *envPtr;
    }
    newEnvPtr[i] = newEnvValue;
    newEnvPtr[i+1] = 0;
    environ = newEnvPtr;
#endif /* defined(_WIN32) */
}
