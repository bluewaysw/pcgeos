/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dib2pcx.c

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
	

	$Id: dib2pcx.c,v 1.1 97/04/07 11:28:39 newdeal Exp $

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

#include "hsimem.h"            /* Halcyon Software main include file */
#include "hsierror.h"          /* Halcyon Software Error code include file */


#include <Ansi/stdio.h>
#include "hsidib.h"            /* Include file for bitmap related */
#include <Ansi/string.h>
/*
#include <graph.h>
*/



/* function prototype */

HSI_ERROR_CODE FAR PASCAL HSISavePCX   (FILE *,FILE *,VOID FAR *);


/* global variables */

CNVOPTION  opt;    /* conversion option record. Reside in HSIERROR.H */

#ifndef GEOSVERSION
BOOL               ParseCmdLine        (int argc, char **argv);
char   *src, *dst, *cp;
#endif

/*
   main program
*/

#ifdef __BORLANDC__
short EXPORT
#else
short 
#endif
ExportPcx(FILE * dibfile,FILE * pcxfile)
   {
   short err=0;

   opt.Disp =(int(*)(int)) 0;                /* default to slient */
   strcpy(opt.ext, "PCX" );        /* default file extension */

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
   _outtext(" บ   Description: This program converts Windows 3.0 Device Independent       บ \n");
   _outtext(" บ                Bitmap (DIB) to PaintBrush (PCX) format.                   บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" บ   Usage:       dib2pcx {-v, -h}  <Infile> <outfile>                       บ \n");
1   _outtext(" บ                                                                           บ \n");
   _outtext(" บ       -v       : Verbose (optional)                                       บ \n");
   _outtext(" บ       -h       : Display help screen                                      บ \n");
   _outtext(" บ       <infile> : DIB input file name                                      บ \n");
   _outtext(" บ       <outfile>: PCX output file name                                     บ \n");
   _outtext(" บ                                                                           บ \n");
   _outtext(" ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ \n");
   _settextcolor(oldfgd);
   _setbkcolor(oldbgd);
   exit(1);
   }

#endif
   
   /* call the conversion routine */

   err = HSISavePCX(dibfile,             /* input DIB file name */
                    pcxfile,             /* output PCX file name */
                    (VOID FAR *)&opt );     /* pointer to option */
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

       if ( *cp == '-' ) 
          {
          cp++;

          if ( *cp == 'v' || *cp == 'V' )         /* verbose */
              opt.Disp = ShowStatus;
          else
          if ( *cp == 'h' || *cp == 'H' )         /* help */
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
       {
       if (!src)
           err = TRUE;
       else if (dst)
           err = TRUE;
       else
           {
           dst = GetDefaultName(src,".pcx");
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











