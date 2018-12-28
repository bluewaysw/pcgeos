/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		icoload.c

AUTHOR:		Steve Yegge, May 29, 1993

METHODS:

Name			Description
----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/29/93	    	initial version

DESCRIPTION:

	$Id: icoload.c,v 1.1 97/04/07 11:29:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*************************************************************************
   Filename : ICOLOAD.C

   Description :
      Convert Windows 3.0 Icon resource file to DIB format.

   Implementation :
      Windows 3.0 ICON file can have 2,8,or 16 color bitmap, which means
      it is either 1 or 4 bits.  Although it is possible to have multiple 
      bitmaps within the same ICON file, we always process the 1st one.

      Each bitmap contain a color XOR bitmap and an immediately monochrome
      bitmap that represent the trasparent region.  When the monochrome 
      has 0 bit, it means the bit is non-transparent, where 1 means it is
      transparent pixel.

      We will read both bitmap and mask them together so that the end
      result resemable what will be displayed by Windows.

      The option field is not used at this point.  Although it can be
      used to decide which bitmap to select.

   Histroy :
      01/21/91 Created. -DH
**************************************************************************/
#ifndef __WATCOMC__
#pragma Comment("@" __FILE__);
#endif
#pragma Code ("MainImportC");

#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "hsidib.h"

HSI_ERROR_CODE HSILoadPMICON       (void);
HSI_ERROR_CODE HSILoadMonoPMICON   (void);
HSI_ERROR_CODE HSILoadPM13ICON     (void);
HSI_ERROR_CODE LoadNthIcon         (int);
HSI_ERROR_CODE ProcessMaskImage    (LPSTR,LPSTR,int,int);

struct ImportstrIcoHdr
   {
   BYTE    Width;          /* 16,32, or 64 */
   BYTE    Height;         /* 16,32, or 64 */
   BYTE    ColorCount;     /* Number of colors. 2,8,or 16 */
   BYTE    Reserved1;
   WORD    Reserved2;
   WORD    Reserved3;
   DWORD   icoDIBSize;     /* Bytes in size of the pixel array for this form   */
                           /* of the icon image.                               */
   DWORD   icoDIBOffset;   /* offset in bytes from the beginning of the file   */
                           /* to the DIB for this form.                        */
   } *icoHdr;

struct ImportstrIcoHeader
   {
   WORD    icoReserved;        /* should be zero */
   WORD    icoResourceType;    /* icon resource has to be 1. */
   WORD    icoResourceCount;   /* number of images contained in the file */
   } IcoHeader;

LPCNVOPTION    ImportszOption;
static  int    Importnrw;
static  long   Importlrw;


/**************************************************************************

   FUNCTION HSILoadICO(FILE * szInfile, FILE * szOutfile,LPCNVOPTION )

**************************************************************************/
HSI_ERROR_CODE EXPORT
HSILoadICO(FILE * szInfile, FILE * szOutfile, LPCNVOPTION szOpt )
   {
   short   err = 0;
   ImportszOption = szOpt;

/*   // open input and output files

   err = OpenInOutFile( szInfile, szOutfile );
   if ( err ) goto cu0;
*/

   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

   /* read the first 6 bytes   */
   Importnrw = fread(&IcoHeader,  1,  6,  Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   if (IcoHeader.icoReserved != 0 ||             /* check whether this is a  */
       IcoHeader.icoResourceType != 1 )         /* legit ICON file .        */ 
      {
      Importnrw = fseek(Infile,0L,0);          /* rewind file */
      if (Importnrw != 0)
      {
         err=HSI_EC_SRCCANTSEEK;
         goto cu0;
      
      }

      if (IcoHeader.icoReserved == 0x4349 ||
          IcoHeader.icoReserved == 0x4943 ||
          IcoHeader.icoReserved == 0x4142)
         err=HSILoadPMICON();
      else
         err=HSI_EC_UNSUPPORTED;

      goto cu0;
      }

   icoHdr =(struct ImportstrIcoHdr *)malloc(sizeof(struct ImportstrIcoHdr) * 
                                       IcoHeader.icoResourceCount);

   Importnrw = fread (icoHdr,
                sizeof(struct ImportstrIcoHdr), 
                IcoHeader.icoResourceCount,
                Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   if (IcoHeader.icoResourceCount == 1 )   /* only one icon, save it */
      err = LoadNthIcon(IcoHeader.icoResourceCount - 1);
   else
      err = LoadNthIcon(IcoHeader.icoResourceCount - 1);

   cu0:

   /*
   if (!err)
      err = CloseInOutFile();
   else
      CloseInOutFile();
   */

   return err;
   }

/*
   There could be more than one icon in icon file.  This routine 
   save the Nth icon to a DIB file.
*/

HSI_ERROR_CODE
LoadNthIcon(int n)
   {
   short   err = 0;
   int     monosize;
   LPSTR   buf=NULL,buf1=NULL;

   /* seek to where the DIB reside in the input file. */
   Importnrw = fseek(Infile,  icoHdr[n].icoDIBOffset,  0);
   if (Importnrw != 0)
      {
      err=HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   /* read the bitmap info header */
   Importnrw = fread (&bmihdr, sizeof(BITMAPINFOHEADER), 1, Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bmihdr.biHeight = icoHdr[n].Height;
   
   if (bmihdr.biWidth == 0 || bmihdr.biHeight == 0)
      {
      err=HSI_EC_UNSUPPORTED;
      goto cu0;
      }

   wWidthBytes = (WORD)(((bmihdr.biWidth * bmihdr.biBitCount) + 
                   7) / 8 * bmihdr.biPlanes);

   nWidthBytes = ALIGNULONG(wWidthBytes);

   bmihdr.biSizeImage = nWidthBytes * bmihdr.biHeight;

   nColors = DibNumColors((VOID FAR *)&bmihdr);

   Importnrw = fread (clrtbl, sizeof(RGBQUAD), nColors, Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;

   // calculate offset to bitmap data

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) +
                        sizeof(BITMAPINFOHEADER) +
                        nColors * sizeof(RGBQUAD);

   // calculate total size of this image

   bmfhdr.bfSize      = bmihdr.biSizeImage +
                        bmfhdr.bfOffBits;

   // write out file header
   Importnrw = fwrite(&bmfhdr, (WORD)sizeof(BITMAPFILEHEADER), 1, Outfile);
   if (Importnrw <=0 ) 
      {
      err=HSI_EC_DSTCANTWRITE;
      goto cu0;
      }

   /* write bitmap info header */
   Importnrw = fwrite(&bmihdr,  (WORD)sizeof(BITMAPINFOHEADER), 1, Outfile);
   if (Importnrw <=0 ) 
      {
      err=HSI_EC_DSTCANTWRITE;
      goto cu0;
      }

   /* write color table */
   Importnrw = fwrite(clrtbl,   (WORD)sizeof(RGBQUAD),    nColors, Outfile);
   if ( Importnrw <=0 ) 
      {
      err=HSI_EC_DSTCANTWRITE;
      goto cu0;
      }

   buf = (LPSTR) malloc((WORD)bmihdr.biSizeImage);    /* alloc mem for color */
   if (!buf) {err=HSI_EC_NOMEMORY; goto cu0; }            /* bitmap.     */

   monosize = icoHdr[n].icoDIBSize - bmihdr.biSizeImage - 40
       	      - sizeof(RGBQUAD)*nColors;
   monosize = max(monosize, bmihdr.biSizeImage/bmihdr.biBitCount);
   monosize = monosize+1;

   buf1= (LPSTR) malloc(monosize);
   if (!buf1) {err=HSI_EC_NOMEMORY; goto cu0; }

   /* read the first part of color bitmap which supplies the XOR mask  */
   Importnrw = lfread(buf,  1,  (long)bmihdr.biSizeImage,  Infile);       
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   /* now read the mono bits used as transparent AND portion */
   Importnrw = lfread(buf1,  1,                          
                (long)(icoHdr[n].icoDIBSize - bmihdr.biSizeImage -
                40 - sizeof(RGBQUAD)*nColors),
                Infile );
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   err = ProcessMaskImage(buf,buf1,              /* gen the result image and */
                          (WORD)bmihdr.biSizeImage,      /* place it in buf */
                          (WORD)bmihdr.biBitCount );

   Importlrw = lfwrite(buf,  1,  (long)bmihdr.biSizeImage, Outfile);
   if (Importlrw<=0) 
      {
      err=HSI_EC_OUTOFTMPDISK;
      goto cu0;
      }

   cu0:

   if (buf)
      free(buf);

   if (buf1)
      free(buf1);

   if (!err && ImportszOption && ImportszOption->Disp)       
       (*ImportszOption->Disp)(ImportszOption->end);

   return err;	
   }


/*
   The image buffer S will be masked with T and the resulting image
   data is place in S again.  If the monochrome mask is 0, the pixel
   is opague (no furthur processing).  For mono mask 1 and b&w mask,
   the color is reversed.

   Without this treatment, the transparent area won't be correct.
   After the image is processed, the DIB generated match what is
   supposed to be generated by Windows 3.0.

   This masking operation can easily be done with the Windows 3.0
   GDI calls.  However, we cannot limit this module to run under
   Windows only.

   Although this module can be improved by re-writing in assembly,
   we probably won't do so.  This is due to the known small file
   size for ICON files.  The penalty will not be noticable.
*/

HSI_ERROR_CODE
ProcessMaskImage(LPSTR s, LPSTR t, int size, int bits)
   {
   int     i,cnt,black,white;
   BYTE    c,d;
   BOOL    flag;
   int     err;

   err = 0;

   if (bits==1)            
      {
      i   = 0;
      cnt = size;

      while (size--)
         {
         i++;
         *s++ ^= *t++;

         if (ImportszOption && ImportszOption->Disp && !(i % 100))
            {
            static int cline;
            int        ii;

            ii = (int)((DWORD) i * 
		       	(DWORD)(ImportszOption->end-ImportszOption->start) /
                        (DWORD)cnt) +  ImportszOption->start;

            if (ii !=cline)
               {
               cline = ii;
               err=(*(ImportszOption->Disp))(cline);
               if (err) 
                  return err;
               }
            }
         }

      return 0;
      }

   /* this is four plane image. Find out the index to WHITE and BLACK */

   for (i=0;i<16;i++)
       {
       if (clrtbl[i].rgbRed  == 0 &&
           clrtbl[i].rgbGreen== 0 && clrtbl[i].rgbBlue == 0)
          black=i;
       else
       if (clrtbl[i].rgbRed   == 0xFF && 
           clrtbl[i].rgbGreen == 0xFF && clrtbl[i].rgbBlue == 0xFF)
          white=i;
       }

   if (bmihdr.biBitCount < 8)
      size *= 2;

   flag = TRUE;

   for (i=0,cnt=0;i<size;i++,cnt++)
       {
       if (ImportszOption && ImportszOption->Disp)
          {
          static int cline2;
          int        ii;

          ii = (int)((DWORD) i * 
		     (DWORD)(ImportszOption->end-ImportszOption->start) /
                     (DWORD)size) +  ImportszOption->start;

          if (ii !=cline2)
             {
             cline2 = ii;
             err=(*(ImportszOption->Disp))(cline2);
             if (err) 
                return err;
             }
          }

       c = (BYTE)s[i/2];
       d = (BYTE)(i%2 ? (c&0x0F) : (c>>4));

       /* look at the color bitmap nibble. Do nothing if it is neither */
       /* black nor white */

       if (d != (BYTE)white && d != (BYTE)black)
           continue;

       /* look at the monochrome mask first. Do nothing if it is zero */

       if (!(t[cnt/8] & BitPatternOr[cnt%8]))
           continue;

       /* if we get here, the bitmap need to be masked. */

       if (d== (BYTE)white) /* nibble is white, set it to black */
           {
           if (i%2)
               s[i/2] = (BYTE)(c & 0xF0 | black);
           else
               s[i/2] = (BYTE)(c & 0x0F | (black << 4 ));
           }
       else    /* nibble is black, set it to white */
           {
           if (i%2)
               s[i/2] = (BYTE)(c & 0xF0 | white);
           else
               s[i/2] = (BYTE)(c & 0x0F | (white << 4 ));
           }
       }
   return err;
   }



/*
   Load the PM ICON image 
*/

HSI_ERROR_CODE HSILoadPMICON(void)
   {
   int   err=0;
   LPSTR buf;
   int   size;
   DWORD lsize,lfsize;

   MemHandle bufHandle;

   err = 0;

   Importnrw = fread(&bmfhdr, 1,  14, Infile);
   if (Importnrw != 14) 
      {
      err=HSI_EC_SRCCANTREAD; 
      goto cu0;
      }

   if (bmfhdr.bfType==0x4349)  /* 'IC' monochrome ICON */
      {
      err=HSILoadMonoPMICON();
      bmihdr.biHeight /= 2;
      }
   else
   if (bmfhdr.bfType==0x4943)  /* 'CI' color ICON */
      {
      Importnrw = fseek(Infile,0L,0);
      if (Importnrw != 0)
         {
         err=HSI_EC_SRCCANTSEEK;
         goto cu0;
         }

      ReadHeaderInfo(Infile);
      }
   else
   if (bmfhdr.bfType==0x4142)  /* 'BA' for 1.3 color icon */
      {
      err=HSILoadPM13ICON();
      }
   else
      {
      err=HSI_EC_UNSUPPORTED;
      }

   if (err) goto cu0;

   WriteHeaderInfo();

   bufHandle = allocmax(&size);
   buf = MemLock(bufHandle);

   if (!buf)
      {
      err=HSI_EC_NOMEMORY;
      goto cu0;
      }

   lsize  = ftell(Infile);
   Importnrw = fseek(Infile,0L,2);  /* seek to end of file */
   if (Importnrw != 0)
      {
      err=HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   lfsize = ftell(Infile);
   Importnrw = fseek(Infile,lsize,0);        /* restore current position */
   if (Importnrw != 0)
      {
      err=HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   lsize = bmihdr.biSizeImage;

   while ((Importnrw = lfread(buf, 1,  (long)size, Infile)) > 0 )
       {
       Importnrw = (int)min((int)lsize,(int)Importnrw);

       Importlrw = lfwrite(buf, 1, Importnrw, Outfile);
       if (Importlrw <=0)
          {
          err=HSI_EC_OUTOFTMPDISK;
          goto cu0;
          }

       lsize -= Importnrw;

       if (ImportszOption && ImportszOption->Disp)
          {
          static int cline3;
          int        ii;
          DWORD      dw;

          dw = ftell(Infile);           // get current offset
          ii = (int)((DWORD) dw * 
                     (DWORD) (ImportszOption->end - ImportszOption->start) / 
                     (DWORD) lfsize) + ImportszOption->start;

          if (ii !=cline3)
             {
             cline3 = ii;
             err=(*(ImportszOption->Disp))(cline3);
             if (err) goto cu0;
             }
          }
       }

   cu0:

   if (buf) MemFree(bufHandle);

   return err;
   }


HSI_ERROR_CODE HSILoadMonoPMICON(void)
   {
   static char icos1[12];
   int    err = 0;

   Importnrw = fread(icos1, 1, 2, Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bmihdr.biWidth = GetINTELWORD(&icos1[0]); 

   if (bmihdr.biWidth == 0x0C && bmfhdr.bfOffBits==0x20)
      {
      /* this is version 1.1 monochrome icon */
      Importnrw = fread(icos1,  1, 4, Infile);
      if (Importnrw <= 0)
         {
         err=HSI_EC_SRCCANTREAD;
         goto cu0;
         }

      bmihdr.biWidth = GetINTELWORD(&icos1[2]);
      }
   else
      {
      /* this is version 1.0 monochrome icon */
      }

   Importnrw = fread(icos1,  1, 6, Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bmihdr.biHeight     = GetINTELWORD(&icos1[0]); 
   bmihdr.biPlanes     = GetINTELWORD(&icos1[2]); 
   bmihdr.biBitCount   = GetINTELWORD(&icos1[4]); 

   wWidthBytes = (WORD)((bmihdr.biWidth + 7 ) / 8);
   nWidthBytes = ALIGNULONG(wWidthBytes);

   nColors = 2;

   Importnrw = fread(&clrtbl[0].rgbRed,  1,    1,  Infile);  /* read color table */
   Importnrw = fread(&clrtbl[0].rgbGreen,1,    1,  Infile);
   Importnrw = fread(&clrtbl[0].rgbBlue, 1,    1,  Infile);
   Importnrw = fread(&clrtbl[1].rgbRed,  1,    1,  Infile);  /* read color table */
   Importnrw = fread(&clrtbl[1].rgbGreen,1,    1,  Infile);
   Importnrw = fread(&clrtbl[1].rgbBlue, 1,    1,  Infile);
   if (Importnrw <= 0)
      {
      err = HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   cu0 :
     return err;
   }


/*
   PM 1.3 color icon has 'BM(' as the first three bytes and part
   of 14 bytes header. Afterward there are two bmihdr. The first
   is mono the 2nd is color.
*/

HSI_ERROR_CODE HSILoadPM13ICON(void)
   {
   int    err=0,i;
   static char icos2[12];
   static BITMAPINFOHEADER bi;
   static BITMAPFILEHEADER bf;

   Importnrw = fseek(Infile,14L,0);      /* skip first 14 bytes */
   if (Importnrw != 0)
      {
      err=HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   Importnrw = fread(&bf,  1, 14, Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   if (bf.bfType != 0x4943)
      {
      err=HSI_EC_UNSUPPORTED;
      goto cu0;
      }

   Importnrw = fread(icos2,  1, 12, Infile);      /* mono bitmap header */
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bi.biWidth   = GetINTELWORD(&icos2[4]);
   bi.biHeight  = GetINTELWORD(&icos2[6])/2;
   bi.biPlanes  = GetINTELWORD(&icos2[8]);
   bi.biBitCount= GetINTELWORD(&icos2[10]);

   wWidthBytes = (WORD)((bi.biWidth+7)/8);
   nWidthBytes = ALIGNULONG(wWidthBytes);

   Importnrw = fseek(Infile,6L,1);               /* skip mono palette */
   if (Importnrw != 0)
      {
      err=HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   Importnrw = fread(&bmfhdr,  1,   14,  Infile);
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }
   Importnrw = fread(icos2,        1,   12,  Infile);      
   if (Importnrw <= 0)
      {
      err=HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bmihdr.biWidth   = GetINTELWORD(&icos2[4]);
   bmihdr.biHeight  = GetINTELWORD(&icos2[6]);
   bmihdr.biPlanes  = GetINTELWORD(&icos2[8]);
   bmihdr.biBitCount= GetINTELWORD(&icos2[10]);

   switch (bmihdr.biBitCount)
      {
      case 1: nColors = 2;
              break;
      case 4: nColors = 16; 
              break;
      case 8: nColors = 256;
              break;
      default: nColors = 0;
               break;
      }

   /* read color table */
   for (i=0;i< (int)nColors;i++)
       {
       Importnrw = fread(&clrtbl[i].rgbBlue, 1,    1,  Infile);
       Importnrw = fread(&clrtbl[i].rgbGreen,1,    1,  Infile);
       Importnrw = fread(&clrtbl[i].rgbRed,  1,    1,  Infile); 
       if (Importnrw <= 0)
          {
          err=HSI_EC_SRCCANTREAD;
          goto cu0;
          }
       }

   wWidthBytes = (WORD)((bi.biWidth+7)/8);
   nWidthBytes = ALIGNULONG(wWidthBytes);

   /* move to where color bitmap start */
   Importnrw = fseek(Infile,bmfhdr.bfOffBits,0); 
   if (Importnrw != 0)
      {
      err=HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   cu0:

   return err;
   }


/********
** END
********/
