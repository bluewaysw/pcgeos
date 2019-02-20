
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		tclNt.c

AUTHOR:		Ronald Braunstein, Nov 02, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	11/02/96   	Initial version

DESCRIPTION:
	Functions that tcl uses under NT to do special NT things like to
	emacs with Mailslots.

	$Id: tclNt.c,v 1.1 97/04/18 12:30:17 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>
#include <compat/windows.h>
#include <stdio.h>

/***********************************************************************
 *				SendToEmacs
 ***********************************************************************
 *
 * SYNOPSIS:	    
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ron	11/02/96   	Initial Revision
 *
 ***********************************************************************/
void SendString(char *msg);
void SendToEmacs(char *cmd);
HANDLE	mailslot = NULL;		/* Mailslot that emacs monitors */
					/* It gets initialized as needed */
#ifdef STANDALONE_FILE
int main(int argc, char **argv) {
    SendToEmacs ("Hi");
}
#endif

void
SendToEmacs (char *emacsCommand)
{
    char baseCommand[1024];
    char slotname[]="\\\\.\\mailslot\\emacs\\gnuserv";
    /* If the mailslot hasn't been initialized yet, do it now */
    do {
	mailslot = CreateFile(slotname,
			      GENERIC_WRITE, FILE_SHARE_READ,
			      NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (mailslot == INVALID_HANDLE_VALUE) Sleep(250);  // give it time to finish.
    } while ((mailslot == INVALID_HANDLE_VALUE) && (GetLastError() == ERROR_SHARING_VIOLATION));

    /* The server wants to  know which mailslot to write back too (thinking we might
       be monitoring it ... */
    sprintf(baseCommand, "C:%d ", 666);
    SendString(baseCommand);

    /* Now send our command, prepending with the prerequisite lisp stuff ... */
	   
    sprintf(baseCommand, "(server-eval '(progn ");
    strcat(baseCommand, emacsCommand);
    strcat(baseCommand, "))");
    /* mark end of command */
    strcat(baseCommand, "\004");
    SendString(baseCommand);
    CloseHandle(mailslot);
}

void SendString(char *msg)
{
    /*
     * Ignore errors, if it doesn't get there, who cares?
     */
    DWORD byteswritten;
    WriteFile(mailslot, msg, strlen(msg) +1, &byteswritten, NULL);
}

