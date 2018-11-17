/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dib2clp.c

AUTHOR:		Maryann Simmons, May 12, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/12/92   	Initial version.

DESCRIPTION:
	

	$Id: dib2clp.c,v 1.1 97/04/07 11:26:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
   dib2clp.c 
 
Description 
 
   This program convert device independent bitmap (DIB) file 
   to Windows 3.0 Clipboard Bitmap file format. 
 
History 
    
 
       ----- Copyright(c), 1990  Halcyon Software ----- 
*/ 
 
#pragma Code ("MainExportC");

#include "hsimem.h"            /* Halcyon Software main include file*/ 
#include "hsierror.h"          /* Halcyon Software Error code include file*/ 

 
#include <Ansi/stdio.h> 
#include "hsidib.h"            /* Include file for bitmap related*/ 

#include <Ansi/string.h>
/* 
#include <graph.h> 
*/
/*
#include <process.h> 
 */

 
// function prototype 
 
HSI_ERROR_CODE FAR PASCAL HSISaveCLP   (FILE *,FILE *,VOID FAR *);

#ifndef GEOSVERSION 
BOOL               ParseCmdLine        (int argc, char **argv); 
char   *src, *dst, *cp; 

#endif
 
// global variables 
 
CNVOPTION  opt;    // conversion option record. Reside in HSIERROR.H 

 
/* 
   main program 
*/ 
 
#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ExportClp( FILE * dibfile,FILE * clpfile)
   { 
   short err=0; 
 
   opt.Disp = (int(*)(int))0;                // default to slient 
    strcpy(opt.ext, "CLP" );                 // default file extension 
 
#ifndef GEOSVERSION

   if (ParseCmdLine(argc,argv))    // parse input string 
   { 
   long oldfgd, oldbgd; 
 
   oldfgd = _gettextcolor(); 
   oldbgd = _getbkcolor(); 
   _clearscreen( _GCLEARSCREEN ); 
 
   _settextcolor(15); 
   _setbkcolor(3); 
   _outtext(" ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป \n"); 
   _outtext(" บ                 Copyright(c) 1990,  Halcyon Software        (408)984-1464 บ \n"); 
   _outtext(" ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ   Description: This program converts Windows 3.0 Device Independent       บ \n"); 
   _outtext(" บ                Bitmap (DIB) to Windows 3. 0 Clipboard Bitmap format.      บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ   Usage:       dib2clp {-v, -h}  <Infile> <outfile>                       บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n"); 
   _outtext(" บ       -h       : Display help screen                                      บ \n"); 
   _outtext(" บ       <infile> : DIB input file name                                      บ \n"); 
   _outtext(" บ       <outfile>: Windows 3.0 CLP file name.                               บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n"); 
   _settextcolor((WORD)oldfgd); 
   _setbkcolor(oldbgd); 
 
 
   exit(1); 
   } 

#endif
    
   /* call the conversion routine */ 
 
   err = HSISaveCLP(dibfile,             /* input DIB file name */ 
                    clpfile,            /*output Clp file name */
                    (VOID FAR *)&opt ); /* pointer to option   */
 
   return (err); 
   } 
 
#ifndef GEOSVERSION
 
char *GetDefaultName(char *s,char *ext); 
char *GetName(char *s); 
 
/* 
   Parse the command line.  Look for -v, source and target file names. 
   Return FALSE if ok, TRUE if error. 
*/ 
 
BOOL ParseCmdLine(int argc, char **argv) 
   { 
   int     cnt=1; 
   int     ac=0; 
   BOOL    err=FALSE; 
 
   dst = src = NULL; 
 
   while ((int)(cp = *++argv))  
      { 
       cnt++; 
 
       if ( *cp == '-' )  
          { 
          cp++; 
 
          if ( *cp == 'v' || *cp == 'V' )         // verbose 
              { 
              opt.Disp = ShowStatus; 
              opt.start=0; 
              opt.end  =100; 
              } 
          else 
          if ( *cp == 'h' || *cp == 'H' )         // help 
              err = TRUE; 
          else  
              err = TRUE; 
           }  
      else  
          { 
          if ( !src )  
              { 
              src = *argv; 
              ac++; 
              }  
          else  
          if ( !dst )  
              { 
              dst = *argv; 
              ac++; 
              }  
          else  
              err = TRUE; 
          } 
      } 
 
   if ( cnt != argc || ac != 2 )  
       { 
       if (!src) 
           err = TRUE; 
       else if (dst) 
           err = TRUE; 
       else 
           { 
           dst = GetDefaultName(src,".clp"); 
           err = FALSE; 
           } 
       } 
 
   return err; 
   } 
     
 
char *GetName(char *s) 
   { 
   char *t=s; 
 
   while (*s && *s!='.') 
       s++; 
 
   *s=0; 
   return t; 
   } 
 
char *GetDefaultName(char *s,char *ext) 
   { 
   char *p=malloc(80); 
 
   strcpy(p,s); 
 
   p = GetName(p); 
   strcat(p,ext); 
   return p; 
   } 
 
#endif /* GEOSVERSION */

#pragma Code ();

 

