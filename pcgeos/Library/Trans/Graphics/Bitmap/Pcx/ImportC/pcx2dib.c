/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pcx2dib.c

AUTHOR:		Maryann Simmons, Feb 20, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/20/92   	Initial version.

DESCRIPTION:
	

	$Id: pcx2dib.c,v 1.1 97/04/07 11:28:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*

   sld2dib.c

Description

   Load PaintBrush file to Device Independent Bitmap (DIB).


       ----- Copyright(c), 1990  Halcyon Software -----

*/

#pragma Code ("MainImportC");

#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "hsidib.h"


#include <Ansi/stdlib.h>
#include <Ansi/string.h>

/*
#include <graph.h>
*/

extern short FAR PASCAL HSILoadPCX(FILE *,FILE *,VOID FAR *);

#ifndef GEOSVERSION

BOOL ParseCmdLine(int argc, char **argv);

char   *src, *dst, *cp;
#endif

CNVOPTION  Importopt;      /* conversion option record. Defined in hsidib.h */


#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ImportPcx(FILE * pcxfile,FILE * dibfile)
   {
   short err;

   Importopt.Disp =(int(*)(int)) 0;                /* default to slient */
   strcpy(Importopt.ext, "BMP" );        /* default file extension */

#ifndef GEOSVERSION

   if (ParseCmdLine(argc,argv))    /* parse input string */
   {
   long oldfgd, oldbgd;

   oldfgd = _gettextcolor();
   oldbgd = _getbkcolor();
   _clearscreen( _GCLEARSCREEN );

   _settextcolor(15);
   _setbkcolor(3);
   _outtext(" ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป \n");
   _outtext(" บ              Copyright(c) 1990-91,  Halcyon Software        (408)984-1464 บ \n");
   _outtext(" ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ   Description: This program converts PaintBrush PCX file to Windows 3.0   บ \n");
   _outtext(" บ                Device Independent Bitmap (DIB) format.                    บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ   Usage:       PCX2DIB {-v, -h}  <Infile> <outfile>                       บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n");
   _outtext(" บ       -h       : Display help screen                                      บ \n");
   _outtext(" บ       <infile> : PaintBrush PCX file name                                 บ \n");
   _outtext(" บ       <outfile>: DIB output file name                                     บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit( 1 );
   }

#endif

   /* call the PCX2DIB conversion routine */

   err = HSILoadPCX( pcxfile,           /* input PaintBrush file name */
                     dibfile,           /* output DIB file name */
                     (LPCNVOPTION)&Importopt );   /* far pointer to options record */
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

          if ( *cp == 'v' || *cp == 'V' )         /* verbose */
              opt.Disp = ShowStatus;
          else
          if ( *cp == 'h' || *cp == 'H' )         /* help */
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



