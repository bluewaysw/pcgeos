/*************************************************************************
*           
*         Copyright (c) GeoWorks 1992 -- All Rights Reserved
*
*         PROJECT:        PC GEOS
*         MODULE:         Impex Graphics Translation Library
*         FILE:           dib2tif.c
*        
*         AUTHOR:         maryann Simmons
*
*         REVISION HISTORY:
*
*         Name       Date            Description
*         ----       ----            -----------
*         maryann    2/13/92         Initial version
*
*         DESCRIPTION:
*
*         $Id: dib2tif.c,v 1.1 97/04/07 11:27:36 newdeal Exp $
*
******************************************************************************/

#pragma Code ("MainExportC")
/* Cause the resource name to be MainImportC*/


  
/*
       ----- Copyright(c), 1990-91  Halcyon Software -----
   saveTIF.c

Description

   This program convert device independent bitmap (DIB) file
   to TIF format.

*/

#include "hsimem.h"         /* Halcyon Software main include file (this must be
				first*/
#include "hsierror.h"          /* Halcyon Software Error code include file */
#include <Ansi/stdio.h>
#include "hsidib.h"            /* Include file for bitmap related*/


#include <Ansi/string.h>
/***********We don't have these libraries- for DOSVERSION
*#include <process.h>
*#include <conio.h>
*#include <graph.h>
**********************/


/* function prototype */

HSI_ERROR_CODE FAR PASCAL HSISaveTIF   (FILE *,FILE *,VOID FAR *);

#ifndef GEOSVERSION
BOOL               ParseCmdLine        (int argc, char **argv);

/* global variables */

char   *src, *dst, *cp;

#endif

CNVOPTION  opt;    /* conversion option record. Reside in HSIERROR.H*/

/*
   main program
*/
#if defined(__BORLANDC__) || defined(__WATCOMC__)
short EXPORT
#else
short 
#endif
ExportTif(FILE * dibFile,FILE * tifFile,short compressOption)
   {
   short err=0;

   opt.Disp     = (int(*)(int))0;            /*default to slient */
   opt.dwOption = (DWORD)compressOption;      

   strcpy(opt.ext, "TIF" );        /* default file extension */


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
   _outtext(" �                 Copyright(c) 1990,  Halcyon Software        (408)984-1464 � \n");
   _outtext(" ���������������������������������������������������������������������������͹ \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �   Description: This program converts Windows 3.0 Device Independent       � \n");
   _outtext(" �                Bitmap (DIB) to Tag Image File Format (TIFF).              � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �   Usage:       dib2tif {-v -c -h} <Infile> <outfile>                      � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" �       -v       : Verbose (optional)                                       � \n");
   _outtext(" �       -c       : Compressed TIFF (optional; default to uncompressed)      � \n");
   _outtext(" �       -h       : Display help screen                                      � \n");
   _outtext(" �       <infile> : DIB input file name                                      � \n");
   _outtext(" �       <outfile>: TIFF output file name                                    � \n");
   _outtext(" �                                                                           � \n");
   _outtext(" ���������������������������������������������������������������������������ͼ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit( 1 );
   }

#endif   
   /* call the conversion routine */


   err =HSISaveTIF(dibFile,             /* input DIB file name */
                   tifFile,             /* output TIF file name*/
                   (VOID FAR *)&opt );     /* pointer to option*/
   /* Error Check here---------
   if (err)
       printf("Error code returned = %d\n", err);
      */
   return(err);
}


/*
   Parse the command line.  Look for -v and -c, source and target file names.
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

          switch(*cp)
            {
            case 'v':
            case 'V':
              opt.Disp = ShowStatus;
              break;

            case 'c':
            case 'C':
              opt.dwOption |= 0x0004;             /* auto-detection */
              break;

            default:
              err = TRUE;
              break;
            }
          } 
      else 
          {
          if (!src) 
              {
              src = *argv;
              ac++;
              } 
          else 
          if (!dst) 
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



