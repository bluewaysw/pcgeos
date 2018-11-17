/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiger
MODULE:		dosfront
FILE:		dosfront.c

AUTHOR:		Tim Bradley, Sep 23, 1996

REVISION HISTORY:
	Name	        Date		Description
	----	        ----		-----------
	tbradley	9/23/96   	Initial version

DESCRIPTION:
	Takes the command passed in as argv[1] and its arguments
	Passed in as argv[2] - argv[n], writes out the arguments
	to a temporary file, and then executes the command with
	the name of the temp file as the argument.

	$Id: dosfront.c,v 1.5 1997/02/04 21:45:22 jacob Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include <config.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdarg.h>
#include <compat/stdlib.h>
#include <assert.h>
#include <fileargs.h>
/*
 * Global variables --- yuck.  But what can we do? :-)
 */
static PROCESS_INFORMATION *procInfo    = NULL;
static char                *argFileName = NULL;
/*
 * Saved argument to -o, so we can restore the #@#$#@! thing later.
 */
static char *outputFileName = NULL;
/*
 * Temporary filename we passed instead of outputFileName ('cuz
 * bc45 can't handle non-8.3).
 */
static char outputTempFileName[MAX_PATH + 1];



/***********************************************************************
 *				ErrorMessage
 ***********************************************************************
 *
 * SYNOPSIS:	    Print out text version of last Win32 error
 * CALLED BY:	    (UTILITY)
 * RETURN:	    void
 * SIDE EFFECTS:    Outputs text to the screen.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	9/07/96   	Initial Revision
 *
 ***********************************************************************/
static void
ErrorMessage (char *fmt, ...)
{
    LPVOID lpMessageBuffer;
    va_list argList;

    va_start(argList, fmt);
    
    /*
     * This turns GetLastError() into a human-readable string.
     */
    (void) FormatMessage(
	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
	NULL,
	GetLastError(),
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* user default language */
	(LPTSTR) &lpMessageBuffer,
	0,
	NULL);			/* #1 */

    vfprintf(stderr, fmt, argList);
    fprintf(stderr, ": %s", (char *) lpMessageBuffer);
    LocalFree(lpMessageBuffer);	/* #1 */

    va_end(argList);
}	/* End of ErrorMessage.	*/


/***********************************************************************
 *		CleanUp
 ***********************************************************************
 *
 * SYNOPSIS:	Clean up after waiting (or ^C)
 * CALLED BY:	INTERNAL
 * RETURN:	void
 *	
 * STRATEGY:	
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	jacob   	2/03/97   	Initial Revision
 *	
 ***********************************************************************/
void
CleanUp (void)
{
    if ((procInfo != NULL) && (procInfo->hProcess != INVALID_HANDLE_VALUE)) {
	(void) CloseHandle(procInfo->hProcess);
    }
    
    if (argFileName != NULL) {
	(void) DeleteFile(argFileName);
    }

    /*
     * Try to move the file over.  If it doesn't work, there's
     * nothing we can do.
     */
    if (outputFileName != NULL) { 
	(void) MoveFileEx(outputTempFileName, outputFileName, 
			  MOVEFILE_REPLACE_EXISTING);
    }
}	/* End of CleanUp.	*/


/***********************************************************************
 *				ControlCHandler
 ***********************************************************************
 *
 * SYNOPSIS:	     Handles the processing of a ^C (and other ctrl
 *                   events).
 * CALLED BY:	     Whenever a control event is generated
 * RETURN:	     True
 * SIDE EFFECTS:     Program exits.
 *
 * STRATEGY:	     Close the handle of our spawned process and delete
 *                   the argument file we created.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/19/96   	Initial Revision
 *
 ***********************************************************************/
static BOOL WINAPI
ControlCHandler (DWORD signo)
{
    CleanUp();
    ExitProcess(1);

    /* NOTREACHED */
    return TRUE;
}	/* End of ControlCHandler.	*/


/***********************************************************************
 *				WaitForProcess
 ***********************************************************************
 *
 * SYNOPSIS:	     Waits for the process specified by procInfo
 * CALLED BY:	     main
 * RETURN:	     exit code of the process
 * SIDE EFFECTS:     outputs text to screen
 *
 * STRATEGY:	     call WaitForSingleObject and switch its return
 *                   value.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tbradley	9/24/96   	Initial Revision
 *
 ***********************************************************************/
static int
WaitForProcess (PROCESS_INFORMATION *pInfo)
{
    DWORD exitCode = 0;

    switch(WaitForSingleObject(pInfo->hProcess, INFINITE)) {
    case WAIT_FAILED:
	ErrorMessage("dosfront: warning: Failed to wait for child (id %x)",
		pInfo->dwProcessId);
	exitCode = 1;
	break;

    case WAIT_TIMEOUT:
	ErrorMessage("dosfront: warning: Wait for child (id %x) timed out",
		pInfo->dwProcessId);
	exitCode = 1;
	break;

    case WAIT_OBJECT_0:
	if (!GetExitCodeProcess(pInfo->hProcess, &exitCode)) {
	    ErrorMessage("dosfront: warning: Failed to get exit code for "
			 "child (id %x).\n", pInfo->dwProcessId);
	    exitCode = 1;
	}
	break;

    default:  /* should never get here */
	ErrorMessage("dosfront: error");
	exitCode = 1;
    }

    return exitCode;

}	/* End of WaitForProcess.	*/


/***********************************************************************
 *				SpawnCommand
 ***********************************************************************
 *
 * SYNOPSIS:	      Sets up the command line to send to CreateProcess
 *                    and spawns the process.
 * CALLED BY:	      main
 * RETURN:	      PROCESS_INFORMATION structure describing the 
 *                    spawned process.
 * SIDE EFFECTS:      Exits the process on an error.
 *
 * STRATEGY:	      Simply call CreateProcess.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/24/96   	Initial Revision
 *
 ***********************************************************************/
static PROCESS_INFORMATION *
SpawnCommand (char *cmdName, char *argFileName)
{
    STARTUPINFO          startupInfo      = {0};
    PROCESS_INFORMATION *pInfo            =(PROCESS_INFORMATION *)

	                                   malloc(sizeof(PROCESS_INFORMATION));
    char                *crProcessCmdLine = (char *) malloc(strlen(cmdName) + 
							    strlen(argFileName)
							    + 3);

    startupInfo.cb = sizeof(STARTUPINFO);
    sprintf(crProcessCmdLine, "%s @%s", cmdName, argFileName);

    if (!CreateProcess(NULL, crProcessCmdLine, NULL, NULL, FALSE, 0, NULL,
		       NULL, &startupInfo, pInfo)) {
	ErrorMessage("dosfront: error: Couldn't spawn %s", crProcessCmdLine);
	(void) free(pInfo);

	return NULL;
    }

    (void) free(crProcessCmdLine);

    return pInfo;
}       /* End of SpawnCommand. */


/***********************************************************************
 *			 WriteCommandLineToTempFile
 ***********************************************************************
 *
 * SYNOPSIS:	      Writes a null terminated string out to a temp file
 * CALLED BY:	      main
 * RETURN:	      The name of the newly created file.
 * SIDE EFFECTS:      Creates a file, allocates some memory.
 *
 * STRATEGY:	      Figure out where to write the file to by looking
 *                    at the TEMP environment variable.  Then create
 *                    a unique file by combining "dsf" with the pid.
 *                    Then call WriteFile to write the string to the
 *                    file.  Note that we use the
 *                    FILE_FLAG_DELETE_ON_CLOSE flag so that NT will 
 *                    nuke the file when we're done with it.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/24/96   	Initial Revision
 *
 ***********************************************************************/
static char *
WriteCommandLineToTempFile (char *cmdLine)
{
    SECURITY_ATTRIBUTES sAttrs      = {sizeof(SECURITY_ATTRIBUTES),
				       NULL, FALSE};
    char                temp[MAX_PATH + 1];
    char               *fileName;
    HANDLE              hArgFile;
    int			hasTrailingSlash;

    /* get the location of the path where temporary files go */

    if (GetTempPath(MAX_PATH, temp) == 0) {
	ErrorMessage("dosfront: error: Cannot get temporary file path");
	return NULL;
    }

    hasTrailingSlash = *(temp + strlen(temp) - 1) == '\\';

    fileName = (char *) malloc(MAX_PATH + 1);
    if (fileName == NULL) {
	fprintf(stderr, "dosfront: error: Out of memory.\n");
	return NULL;
    }

    sprintf(fileName, hasTrailingSlash ? "%sdsf%x.tmp" : "%s\\dsf%x.tmp", 
	    temp, GetCurrentProcessId());

    hArgFile = CreateFile(fileName, GENERIC_WRITE, 0, &sAttrs,
			  CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL);

    if (hArgFile == INVALID_HANDLE_VALUE) {
	ErrorMessage("dosfront: error: %s", fileName);
	(void) free(fileName);
	return NULL;
    } else {
	DWORD  numWritten;

	if (!WriteFile(hArgFile, cmdLine, strlen(cmdLine), &numWritten, NULL))
	{
	    ErrorMessage("dosfront: error: %s", fileName);
	    (void) CloseHandle(hArgFile);
	    (void) DeleteFile(fileName);
	    (void) free(fileName);
	    return NULL;
	}
    }

    (void) CloseHandle(hArgFile);
    return fileName;

}	/* End of WriteCommandLineToTempFile.	*/

unsigned
CommandLineSize(int argc, char **argv) 
{
    unsigned sum = 0;

    assert(argc > 0);

    while (argc--) {
	sum += strlen(*argv++) + 1; /* +1 for space */
    }

    return sum + 1;		/* +1 for null terminator */
}

void
DosifyArgs(int argc, char **argv, char *cmdLine)
{
    int i;

    /*
     * Start with "".  We'll build it up arg-by-arg.
     */
    *cmdLine = '\0';

    for (i = 0; i < argc; i++) {
	char shortFileName[MAX_PATH + 1];
	char *fileName;
	char preFileName[3] = {'\0'};

	/*
	 * Handle -o<object file name> by remembering output
	 * file, but substituting .tmp file name for
	 * #@$#@!@#!#@ bcc.exe to output to.  We'll handle
	 * renaming the temp file to the requested name
	 * later.
	 *
	 */
	if (argv[i][0] == '-' && argv[i][1] == 'o') {
	    outputFileName = &argv[i][2];
	    if (GetTempFileName(".", "bc", GetCurrentProcessId(),
				outputTempFileName) == 0) {
		ErrorMessage("dosfront: error: Cannot generate temporary file name");
		ExitProcess(1);
	    }
	    strcat(cmdLine, "-o");
	    strcat(cmdLine, outputTempFileName);
	    strcat(cmdLine, " ");
	    continue;
	} 
	/*
	 * See if the entire argument is a valid filename.  If it is,
	 * assume it has some hosing non-8.3 elements in it.  We'll
	 * substitute in the short version of it.
	 */
	else if (GetFileAttributes(argv[i]) != 0xFFFFFFFF) {
	    fileName = argv[i];
	}
	/*
	 * We also check argv[i][2] 'cuz of things like:
	 *
	 * -Is:/pcgeos/ReleaseResponder/Include
	 * ^^
	 */
	else if (   argv[i][0] != '\0'
		 && argv[i][1] != '\0'
		 && GetFileAttributes(&argv[i][2]) != 0xFFFFFFFF) {
	    fileName = &argv[i][2];
	    preFileName[0] = argv[i][0];
	    preFileName[1] = argv[i][1];
	}
	/*
	 * Not a file.  Just copy over verbatim.
	 */
	else {
	    strcat(cmdLine, argv[i]);
	    strcat(cmdLine, " ");
	    continue;
	}
	
	strcat(cmdLine, preFileName);
	if (GetShortPathName(fileName, shortFileName, sizeof(shortFileName))
	    == 0) {
	    /*
	     * The filesystem doesn't support short file names.
	     * Nothing we can do, but might as well try 
	     * out original file name.
	     */
	    strcat(cmdLine, fileName);
	} else {
	    strcat(cmdLine, shortFileName);
	}

	strcat(cmdLine, " ");
    }
}


/***********************************************************************
 *				main
 ***********************************************************************
 *
 * SYNOPSIS:	     Entry point for dosfront
 * CALLED BY:	     OS
 * RETURN:	     TRUE or FALSE depending on the exit code of
 *                   its child
 * SIDE EFFECTS:     Spawns a child process, creates a temporary file.
 *
 * STRATEGY:	     Take the command line and split it into the 
 *                   name of the command to execute and the arguments
 *                   to pass to it.  Put the arguments into a temporary
 *                   file with a name made unique by using the pid of
 *                   the dosfront process.  Then call CreateProcess
 *                   with the name of the command followed by the name
 *                   of the argument file.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/23/96   	Initial Revision
 *
 ***********************************************************************/
int
main(int argc, char **argv)
{
    int actualArgs = argc - 2;
    char **actualArgv = argv + 2;
    char *cmdLine;
    DWORD        exitCode;

    if (!SetConsoleCtrlHandler(ControlCHandler, TRUE)) {
	ErrorMessage("dosfront: Warning: couldn't set ^C handler");
    }

    /*
     * if there was no command name specified, exit with an error
     */
    if (!(argc == 2 && argv[1][0] == '@') && argc < 3) {
	fprintf(stderr, 
		"usage:\tdosfront <command> [<arguments>]\n"
		"\tdosfront @argfile\n\n"
		"\tThis command runs <command> with all of its\n"
		"\targuments in an argument file.  This is useful\n"
		"\tfor running native DOS applications with a\n"
		"\tlarge number of arguments.\n");
	ExitProcess(1);
    }

    /*
     * if we were passed our arguments in an argfile then stuff them
     * into argc and argv
     */
    if (argv[1][0] == '@') {
	GetFileArgs(&argv[1][1], &actualArgs, &actualArgv);
	argv[1] = actualArgv[1];
	actualArgs -= 2;
	actualArgv += 2;
    }

    /*
     * The the extra stuff at the end is just paranoia factor.
     */
    cmdLine = (char *) malloc(CommandLineSize(actualArgs, actualArgv)
			      + (actualArgs * 14));

    DosifyArgs(actualArgs, actualArgv, cmdLine);
    printf("%s %s\n", argv[1], cmdLine);
    
    argFileName = WriteCommandLineToTempFile(cmdLine);
    if (argFileName == NULL) {
	return 1;
    }

    procInfo = SpawnCommand(argv[1], argFileName);
    if (procInfo != NULL) {
	exitCode = WaitForProcess(procInfo);
    } else {
	exitCode = 1;
    }

    /*
     * Ignore ^C during cleanup
     */
    if (!SetConsoleCtrlHandler(NULL, TRUE)) {
	ErrorMessage("dosfront: warning: couldn't turn-off ^C handling");
    }
    
    CleanUp();
    free(cmdLine);

    return exitCode;
}
