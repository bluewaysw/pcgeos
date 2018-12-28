/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dib2bmp.c

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
	

	$Id: dib2bmp.c,v 1.1 97/04/07 11:26:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* 
   dib2BMP.c 
 
Description 
 
   This program converts device independent bitmap (DIB) file 
   to Bitmap file format. 
 
 
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

 
// function prototype 
 
HSI_ERROR_CODE FAR PASCAL HSISaveBMP   (FILE *,FILE *,VOID FAR *); 

 
// global variables 
 
CNVOPTION  opt;    // conversion option record. Reside in HSIERROR.H 

#ifndef GEOSVERSION
BOOL               ParseCmdLine        (int argc, char **argv); 
char   *src, *dst, *cp;
static char szDefault[20]=".BMP"; 
#endif 

/* 
   main program 
*/ 
 
#if defined(__BORLANDC__) || defined(__WATCOMC__)
short EXPORT
#else
short 
#endif
ExportBmp(FILE * dibfile, FILE * bmpfile,short formatOption) 
   { 
   short err=0; 
 
   opt.Disp = (int(*)(int)) 0;                // default to slient 
   opt.dwOption = (DWORD)formatOption;       // default to Windows 3.0 BMP 
   strcpy(opt.ext, "BMP" );        // default file extension 
 
#ifndef GEOSVERSION

   if (ParseCmdLine(argc,argv))    // parse input string 
   { 
   long oldfgd, oldbgd; 
 
   oldfgd = _gettextcolor(); 
   oldbgd = _getbkcolor(); 
   _clearscreen( _GCLEARSCREEN ); 
 
   _settextcolor(15); 
   _setbkcolor(3); 
   _outtext(" ���������������������������������������������������������������������������ͻ \n"); 
   _outtext(" �              Copyright(c) 1990-92,  Halcyon Software        (408)378-9898 � \n"); 
   _outtext(" ���������������������������������������������������������������������������͹ \n"); 
   _outtext(" �                                                                           � \n"); 
   _outtext(" �   Description: This program converts Windows 3.0 Device Independent       � \n"); 
   _outtext(" �                Bitmap (DIB) to one of the BMP file format.                � \n"); 
   _outtext(" �                                                                           � \n"); 
   _outtext(" �   Usage:       DIB2BMP {-v, -h, -f<n>}  <Infile> <outfile>                � \n"); 
   _outtext(" �                                                                           � \n"); 
   _outtext(" �       -v       : Verbose (optional)                                       � \n"); 
   _outtext(" �       -h       : Display help screen                                      � \n"); 
   _outtext(" �       -f<n>    : Output file format options                               � \n"); 
   _outtext(" �          n = 1 : OS/2 Device Independent Bitmap                           � \n"); 
   _outtext(" �          n = 2 : Windows 2.x Device Dependent Bitmap                      � \n"); 
   _outtext(" �          n = 3 : Windows 3.0 Device Independent Bitmap                    � \n"); 
   _outtext(" �          n = 4 : Windows 3.0 compressed DIB (RLE)                         � \n"); 
   _outtext(" �       <infile> : DIB input file name                                      � \n"); 
   _outtext(" �       <outfile>: BMP output file name                                     � \n"); 
   _outtext(" �                                                                           � \n"); 
   _outtext(" ���������������������������������������������������������������������������ͼ \n"); 
   _settextcolor(oldfgd); 
   _setbkcolor(oldbgd); 
   exit(1); 
   } 

#endif
    
   // call the conversion routine 
 
   err = HSISaveBMP(dibfile,             // input DIB file name 
                    bmpfile,             // output PCX file name 
                    (VOID FAR *)&opt );    // pointer to option 
   return( err);
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
          if ( *cp == 'f' || *cp == 'F' )         // Format 
              { 
              switch (*(cp+1)) 
                 { 
                 case '1': 
                   opt.dwOption = BMP_PM10; 
                   break; 
 
                 case '2': 
                   opt.dwOption = BMP_WIN20; 
                   break; 
 
                 case '3': 
                   opt.dwOption = BMP_WIN30; 
                   break; 
 
                 case '4': 
                   opt.dwOption = BMP_RLE30; 
                   strcpy(szDefault,".RLE"); 
                   break; 
 
                 default: 
                   err= TRUE; 
                   break; 
                 } 
              } 
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
           dst = GetDefaultName(src,szDefault); 
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
