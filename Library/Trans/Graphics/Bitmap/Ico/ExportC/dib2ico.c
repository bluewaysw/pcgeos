/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex - Icon Translation Library
FILE:		dib2ico.c

AUTHOR:		Steve Yegge, May 29, 1993

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
	stevey	5/29/93	    	grabbed for ico library

DESCRIPTION:
	
	$Id: dib2ico.c,v 1.1 97/04/07 11:29:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
   savepcx.c

Description

   This program convert device independent bitmap (DIB) file
   to PCX format.

History


       ----- Copyright(c), 1990  Halcyon Software -----
*/

#pragma Code ("MainExportC");


/* #include <stdio.h> */
/* #include <string.h> */
/* #include <graph.h> */

#include "hsimem.h"            /* Halcyon Software main include file */
#include "hsierror.h"          /* Halcyon Software Error code include file */

#include <Ansi/stdio.h>
#include "hsidib.h"            /* Include file for bitmap related */

#include <Ansi/string.h>

// function prototype

/*HSI_ERROR_CODE FAR PASCAL HSISavePCX   (FILE *,FILE *,VOID FAR *); */

#ifndef GEOSVERSION
BOOL               ParseCmdLine        (int argc, char **argv);
#endif

// global variables

CNVOPTION  opt;    // conversion option record. Reside in HSIERROR.H
char   *src, *dst, *cp;

/*
   main program
*/

#if defined(__BORLANDC__) || defined(__WATCOMC__)
short EXPORT
#else
short 
#endif
ExportIco(FILE *dibfile, FILE *icofile, short formatOption)
   {
   short err=0;

   opt.Disp = NULL;                // default to slient
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
   _outtext(" �                 Copyright(c) 1990,  Halcyon Software        (408)984-1464 � \n");
   _outtext(" ���������������������������������������������������������������������������͹ \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �   Description: This program converts Windows 3.0 Device Independent       � \n");
   _outtext(" �                Bitmap (DIB) to PaintBrush (PCX) format.                   � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �   Usage:       dib2pcx {-v, -h}  <Infile> <outfile>                       � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �       -v       : Verbose (optional)                                       � \n");
   _outtext(" �       -h       : Display help screen                                      � \n");
   _outtext(" �       <infile> : DIB input file name                                      � \n");
   _outtext(" �       <outfile>: PCX output file name                                     � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" ���������������������������������������������������������������������������ͼ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit(1);
   }
#endif

   // call the conversion routine

/*   err = HSISavePCX((FILE *)src,             // input DIB file name
                    (FILE *)dst,             // output PCX file name
                    (VOID FAR *)&opt );     // pointer to option */
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

          if ( *cp == 'v' || *cp == 'V' )         // verbose
               {
               opt.Disp = ShowStatus;
               opt.start= 0;
               opt.end  = 100;
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
      err = TRUE;

   return err;
   }

#endif


