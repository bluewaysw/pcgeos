/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clp2dib.c

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
	

	$Id: clp2dib.c,v 1.1 97/04/07 11:26:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* 
   clp2dib.c 
 
Description 
 
   Load Windows 3.0 Clipboard bitmap file to Device Independent Bitmap (DIB). 
 
 
       ----- Copyright(c), 1990  Halcyon Software ----- 
 
*/ 
 
#pragma Comment("@"__FILE__);
#pragma Code ("MainImportC");

#include "hsimem.h" 
#include "hsierror.h" 

#include <Ansi/stdio.h>
#include "hsidib.h" 


/* 
#include <graph.h> 
*/
#include <Ansi/string.h>
/* 
#include <process.h> 
*/
 

HSI_ERROR_CODE FAR PASCAL HSILoadCLP(FILE *,FILE *,VOID FAR *);

#ifndef GEOSVERSION
BOOL ParseCmdLine(int argc, char **argv); 
char   *src, *dst, *cp; 
#endif /* GEOSVERSION */ 
 
CNVOPTION  Importopt;        // conversion option record. Defined in hsidib.h 

 
 

#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ImportClp(FILE * clpfile,FILE * dibfile)
   { 
   short err; 
 
   Importopt.Disp = (int(*)(int))0;                /* default to slient*/ 
   strcpy(Importopt.ext, "CLP" );                  /* default file extension */ 

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
   _outtext(" บ   Description: This program converts Windows CLP bitmap to Windows 3.0    บ \n"); 
   _outtext(" บ                Device Independent Bitmap (DIB) format.                    บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ   Usage:       CLP2DIB {-v, -h}  <Infile> <outfile>                       บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n"); 
   _outtext(" บ       -h       : Display help screen                                      บ \n"); 
   _outtext(" บ       <infile> : Windows Clipboard Bitmap file name                       บ \n"); 
   _outtext(" บ       <outfile>: DIB output file name                                     บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n"); 
   _settextcolor((WORD)oldfgd); 
   _setbkcolor(oldbgd); 
   exit( 1 ); 
   } 
#endif /* GEOSVERSION */
 
   // call the CLP2DIB conversion routine 
 
   err = HSILoadCLP(  clpfile,           /* input PaintBrush file name */ 
                      dibfile,           /* output DIB file name       */ 
                     (LPCNVOPTION)&Importopt);   /* far pointer to options record */
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
              err=TRUE; 
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
           dst = GetDefaultName(src,".bmp"); 
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
 
 
 
 

#endif /*GEOSVERSION */

#pragma Code (); /* ImportCodeC */
