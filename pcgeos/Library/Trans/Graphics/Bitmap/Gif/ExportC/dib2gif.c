/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		dib2gif.c				     
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
*	$Id: dib2gif.c,v 1.1 97/04/07 11:27:05 newdeal Exp $
*							   	     
*********************************************************************/

#pragma Code ("MainExportC");



/*
   dib2GIF.c

Description

   This program convert device independent bitmap (DIB) file
   to Windows 3.0 Clipboard Bitmap file format.

History
   

       ----- Copyright(c), 1990  Halcyon Software -----
*/


/***
#include <graph.h>
*****/

#include "hsimem.h" 
           // Halcyon Software main include file
#include "hsierror.h"         
 // Halcyon Software Error code include file

#include <Ansi/stdio.h>
#include "hsidib.h"         
   // Include file for bitmap related

#include <Ansi/string.h>

// function prototype

HSI_ERROR_CODE FAR PASCAL HSISaveGIF   (FILE *, FILE *,LPCNVOPTION);

// global variables

CNVOPTION  opt2;    // conversion option record. Reside in HSIERROR.H

#ifndef GEOSVERSION
char   *src2, *dst2, *cp2;
BOOL               ParseCmdLine        (int argc, char **argv);
#endif

/*
   main program
*/
#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ExportGif(FILE * dibFile, FILE * gifFile)
   {

   short err=0;

   opt2.Disp = (int(*)(int))0;                // default to slient
   strcpy(opt2.ext, "GIF" );        // default file extension

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
   _outtext(" บ                Bitmap (DIB) to CompuServe GIF format.                     บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ   Usage:       DIB2GIF {-v, -h}  <Infile> <outfile>                       บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n");
   _outtext(" บ       -h       : Display help screen                                      บ \n");
   _outtext(" บ       <infile> : DIB input file name                                      บ \n");
   _outtext(" บ       <outfile>: CompuServe GIF file name.                                บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit(1);
   }
#endif
   
   // call the conversion routine


   err = HSISaveGIF(dibFile,             // input DIB file name
                    gifFile,             // output GIF file name
                    (LPCNVOPTION)&opt2 );    // pointer to option
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

   dst2 = src2 = NULL;

   while ((int)(cp2 = *++argv)) 
      {
       cnt++;

       if ( *cp2 == '-' ) 
          {
          cp2++;

          if ( *cp2 == 'v' || *cp2 == 'V' )         // verbose
              opt2.Disp = (int (*)(int))ShowStatus;
          else
          if ( *cp2 == 'h' || *cp2 == 'H' )         // help
              err = TRUE;
          else 
              err = TRUE;
           } 
      else 
          {
          if ( !src2 ) 
              {
              src2 = *argv;
              ac++;
              } 
          else 
          if ( !dst2 ) 
              {
              dst2 = *argv;
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


