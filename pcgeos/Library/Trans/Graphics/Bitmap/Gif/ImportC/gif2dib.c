/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		gif2dib.c				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	1/29/92		Initial version			     
*								     
*	DESCRIPTION:						     
*								     
*	$Id: gif2dib.c,v 1.1 97/04/07 11:27:08 newdeal Exp $
*							   	     
*********************************************************************/

#pragma Code ("MainImportC");


/*
   GIF2DIB.C

Description

   Load CompuServe GIF bitmap file to Device Independent Bitmap (DIB).


       ----- Copyright(c), 1990  Halcyon Software -----

*/

/*
#include <graph.h>
*/
#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "gif.h"
#include "hsidib.h"

#include <Ansi/string.h>


CNVOPTION  opt;        // conversion option record. Defined in hsidib.h
#ifndef GEOSVERSION
char   *src, *dst, *cp;
#endif


#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ImportGif(FILE * gifFile, FILE * dibFile)
   {
   short err;

   opt.Disp = (int (*)(int))0;  // default to slient
   strcpy(opt.ext, "BMP" );        // default file extension

#ifndef	 GEOSVERSION
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
   _outtext(" บ   Description: This program converts CompuServe GIF file to Windows 3.0   บ \n");
   _outtext(" บ                Device Independent Bitmap (DIB) format.                    บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ   Usage:       GIF2DIB {-v, -h}  <Infile> <outfile>                       บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n");
   _outtext(" บ       -h       : Display help screen                                      บ \n");
   _outtext(" บ       <infile> : CompuServe GIF file name                                 บ \n");
   _outtext(" บ       <outfile>: DIB output file name                                     บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit( 1 );
   }
#endif
   // call the GIF2DIB conversion routine

   fixshort(5);	
   err = HSILoadGIF( gifFile,           // input PaintBrush file name
                     dibFile,           // output DIB file name
                     (LPCNVOPTION)&opt);   // far pointer to options record
   return(err);
}


/*
   Parse the command line.  Look for -v, source and target file names.
   Return FALSE if ok, TRUE if error.
*/

#ifndef GEOSVERSION

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
              opt.Disp = (int (*)(int))ShowStatus;
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













