/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tif2dib.c

AUTHOR:		Maryann Simmons, May  5, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: tif2dib.c,v 1.1 97/04/07 11:27:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
       ----- Copyright(c), 1990-91  Halcyon Software -----

   loadTIF.c

Description

   Load TIF file to Device Independent Bitmap (DIB).


*/
#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>
/*
#include <process.h>
#include <graph.h>
*/

#pragma Code("MainImportC")


extern short FAR PASCAL HSILoadTIF(FILE *,FILE *,VOID FAR *);

#ifndef GEOSVERSION

BOOL ParseCmdLine(int argc, char **argv);
char   *src, *dst, *cp;

#endif

CNVOPTION  opt2;        /* conversion option record. Defined in hsidib.h	 */

#if defined(__BORLANDC__) || defined(__WATCOMC__)
short EXPORT
#else
short 
#endif
ImportTif(FILE * tifFile,FILE * dibFile)
   {
   short err;

   opt2.Disp = (int(*)(int))0;                /* default to slient*/
   strcpy(opt2.ext, "BMP" );        /* default file extension*/

#ifndef GEOSVERSION

   if (ParseCmdLine(argc,argv))    /* parse input string */
   {
   long oldfgd, oldbgd;

   oldfgd = _gettextcolor();
   oldbgd = _getbkcolor();
   _clearscreen( _GCLEARSCREEN );

   _settextcolor(15);
   _setbkcolor(3);
   _outtext(" ���������������������������������������������������������������������������ͻ \n");
   _outtext(" �              Copyright(c) 1990-91,  Halcyon Software        (408)984-1464 � \n");
   _outtext(" ���������������������������������������������������������������������������͹ \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �   Description: This program converts Tag Image File Format (TIFF)         � \n");
   _outtext(" �                file to Windows 3.0 Device Independent Bitmap (DIB)        � \n");
   _outtext(" �                format.                                                    � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �   Usage:       tif2dib {-v, -h}  <Infile> <outfile>                       � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �       -v       : Verbose (optional)                                       � \n");
   _outtext(" �       -h       : Display help screen                                      � \n");
   _outtext(" �       <infile> : TIFF input file name                                     � \n");
   _outtext(" �       <outfile>: DIB output file name                                     � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" ���������������������������������������������������������������������������ͼ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit( 1 );
   }
#endif

   /* call the TIF2DIB conversion routine */

   err = HSILoadTIF( tifFile,           /* input TIF file name*/
                     dibFile,           /* output DIB file name*/
                     (VOID FAR *)&opt2 );   /* far pointer to options record*/
/* 
   if (err)
       printf("Error code returned = %d\n", err);
*/
   return(err);
   }

#ifndef GEOSVERSION

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

          if ( *cp == 'v' || *cp == 'V' )      /* verbose. Plus in the*/
              opt2.Disp = ShowStatus;           /* display module*/
          else
          if ( *cp == 'h' || *cp == 'H' )      /* help */
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
      err = TRUE;

   return err;
   }
#endif    












