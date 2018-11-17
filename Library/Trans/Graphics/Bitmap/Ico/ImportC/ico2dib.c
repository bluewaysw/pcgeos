/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex - Icon Translation Library
FILE:		ico2dib.c

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
	
	$Id: ico2dib.c,v 1.1 97/04/07 11:29:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
   ico2dib.c

Description

   Load Windows 3.0 ICON file to Device Independent Bitmap (DIB).


       ----- Copyright(c), 1991  Halcyon Software -----

*/

#pragma Code ("MainImportC");

#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>

extern short FAR PASCAL HSILoadICO(LPSTR,LPSTR,VOID FAR *);

#ifndef GEOSVERSION
BOOL ParseCmdLine(int argc, char **argv);

char   *src, *dst, *cp;
#endif

CNVOPTION  Importopt;        // conversion option record. Defined in hsidib.h


#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ImportIco(FILE * icofile,FILE * dibfile)
   {
   short err;

   Importopt.Disp = NULL;                // default to slient
   strcpy(Importopt.ext, "BMP" );        // default file extension

#ifndef	GEOSVERSION
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
   _outtext(" บ   Description: This program converts Windows 3.0 ICON file to Windows 3.0 บ \n");
   _outtext(" บ                Device Independent Bitmap (DIB) format.                    บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ   Usage:       ICO2DIB {-v, -h}  <Infile> <outfile>                       บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n");
   _outtext(" บ       -h       : Display help screen                                      บ \n");
   _outtext(" บ       <infile> : Windows 3.0 ICON file name                               บ \n");
   _outtext(" บ       <outfile>: DIB output file name                                     บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n");
   _settextcolor((WORD)oldfgd);
   _setbkcolor(oldbgd);
   exit( 1 );
   }
#endif

   // call the PCX2DIB conversion routine

   err = HSILoadICO( icofile,           // input PaintBrush file name
                     dibfile,           // output DIB file name
                     (VOID FAR *)&Importopt );   // far pointer to options record

   return err;
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
               Importopt.Disp = ShowStatus;
               Importopt.start= 0;
               Importopt.end  = 100;
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
      err = TRUE;

   return err;
   }


#endif

#pragma Code ();
