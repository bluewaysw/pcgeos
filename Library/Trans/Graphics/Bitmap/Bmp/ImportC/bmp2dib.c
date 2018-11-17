/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bmp2dib.c

AUTHOR:		Maryann Simmons, Mar 30, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/30/92   	Initial version.

DESCRIPTION:
	

	$Id: bmp2dib.c,v 1.1 97/04/07 11:26:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* 
   BMP2dib.c 
 
Description 
 
   Load Bitmap (BMP) file to Device Independent Bitmap (DIB).  There are 
   three flavors of BMP file: 
 
   1. Windows 2.x Device Dependent Bitmap  
   2. Windows 3.0 Device Independent Bitmap 
   3. OS/2 Device Independent Bitmap 
 
 
       ----- Copyright(c), 1991  Halcyon Software ----- 
 
*/ 
 
#pragma Code ("MainImportC");

#include "hsimem.h" 
#include "hsierror.h" 


#include <Ansi/stdio.h> 
#include "hsidib.h" 

#include <Ansi/string.h>

/*
#include <graph.h> 
*/

CNVOPTION  Importopt;        // conversion option record. Defined in hsidib.h
 
HSI_ERROR_CODE FAR PASCAL HSILoadBMP(FILE *,FILE *,VOID FAR *); 

#ifndef GEOSVERSION 
BOOL ParseCmdLine(int argc, char **argv); 

char   *src, *dst, *cp; 
#endif
 
 
#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ImportBmp(FILE * bmpfile,FILE * dibfile) 
   { 
   short err; 
 
   Importopt.Disp =(int(*)(int)) 0;   // default to slient 
   strcpy(Importopt.ext, "BMP" );        // default file extension 
 
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
   _outtext(" บ                 Copyright(c) 1991,  Halcyon Software        (408)984-1464 บ \n"); 
   _outtext(" ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ   Description: This program converts BMP file to Windows 3.0              บ \n"); 
   _outtext(" บ                Device Independent Bitmap (DIB) format.                    บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ   Usage:       BMP2DIB {-v, -h}  <Infile> <outfile>                       บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n"); 
   _outtext(" บ       -h       : Display help screen                                      บ \n"); 
   _outtext(" บ       <infile> : BMP input file name                                      บ \n"); 
   _outtext(" บ       <outfile>: DIB output file name                                     บ \n"); 
   _outtext(" บ                                                                           บ \n"); 
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n"); 
   _settextcolor(oldfgd); 
   _setbkcolor(oldbgd); 
   exit( 1 ); 
   } 
#endif
 
   // call the BMP2DIB conversion routine 
 
   err = HSILoadBMP( bmpfile,           // input PaintBrush file name 
                     dibfile,           // output DIB file name 
                     (VOID FAR *)&Importopt); // far pointer to options record 
   return(err);

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
 

#endif

#pragma Code ();







