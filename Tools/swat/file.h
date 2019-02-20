/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- File Location Declarations
 * FILE:	  file.h
 *
 * AUTHOR:  	  Adam de Boor: May 18, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/18/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Declarations for the File module
 *
 *
* 	$Id: file.h,v 4.4 97/04/18 15:25:07 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _FILE_H_
#define _FILE_H_

#ifdef _MSC_VER
#    define CONST
#else
#    define CONST const
#endif

extern void File_Init(int *argcPtr, char **argv);
extern char *File_Locate(char *name, char *path);
extern char *File_FindGeode(char *name,
			    word serial,
			    int type,
			    Boolean maydetach);

extern CONST char *File_FetchConfigData(CONST char *key);
extern CONST char *File_PathConcat(CONST char *first, ...);
extern Boolean File_CheckAbsolute(CONST char *path);
extern Boolean File_MapUnixToDos(char *dosPath, 
				 CONST char *unixPath, 
				 CONST char *defaultSubst);
extern CONST char *fileRoot, *fileDefault, *fileDevel, *fileSysLib,
		  *fileAbsSysLib;
extern char cwd[];

#endif /* _FILE_H_ */
