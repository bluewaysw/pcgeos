/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  glue
 * FILE:	  parse.h
 *
 * AUTHOR:  	  Tim Bradley: Jun 20, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	6/20/96   	Initial version
 *
 * DESCRIPTION:
 *	Prototypes for parse.y (and parse.c)
 *
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _PARSE_H_
#define _PARSE_H_

extern int  Parse_GeodeParams (char *file, char *deflongname, int libsOnly);
extern void Parse_FindSym     (char *name, int type, char *typeName,
                               word *resid, word *offset);
extern void yyerror           (char *s);
#endif /* _PARSE_H_ */

