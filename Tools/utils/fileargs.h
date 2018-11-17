
/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- File Argument Parsing
 * FILE:	  fileargs.h
 *
 * AUTHOR:        Josh Putnam   6/15/92
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/15/92	  josh	    Initial version
 *
 * DESCRIPTION:
 *      Due to limitations of the PC environment, make will not be able to 
 *      hundreds of characters to programs like goc and glue.
 *   
 *      The solution is to provide a way for tools to get their many 
 *      arguments from temporary files.
 *
 *      By calling GetFileArgs with a path, pointer to int (argc) and
 *      pointer to char ** (argv), the tool can get its arguments in 
 *      the standard format.
 *           
 * 	$Id: fileargs.h,v 1.1 92/06/17 17:44:59 jimmy Exp $
 *
 ***********************************************************************/
#ifndef _FILEARGS_H_
#define _FILEARGS_H_


/* in the arglist @file means we read our args from "file" */
#define FILE_PREFIX "@"
#define FILE_PREFIX_LEN 1

#define HAS_ARGS_FILE(argv) (!strncmp(argv[1],FILE_PREFIX,FILE_PREFIX_LEN))
#define ARGS_FILE(argv) (argv[1] + FILE_PREFIX_LEN)

extern void GetFileArgs(char *path, int *argcPtr, char ***argvPtr);

#endif
