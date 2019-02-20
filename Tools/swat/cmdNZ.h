/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat 
 * FILE:	  cmdNZ.h
 *
 * AUTHOR:  	  Kenneth Liu: Nov 12, 96
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/12/96  kliu      initial version
 *
 * DESCRIPTION:
 *	
 * 	$Id: cmdNZ.h,v 1.1 96/11/14 22:21:11 kliu Exp $
 *
 ***********************************************************************/
#ifndef _CMDNZ_H_
#define _CMDNZ_H_

typedef struct _Stream {
    enum {
	STREAM_SOCKET, STREAM_FILE
    }	    	    type;
    FILE   	    *file;
    int	    	    sock;
    Boolean 	    sockErr;
    char    	    *watchProc;
} Stream;

#endif /* _CMDNZ_H_ */
