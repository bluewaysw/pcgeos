
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) @company 1998.  All rights reserved.
	CONFIDENTIAL

PROJECT:	Global PC
MODULE:		IGS Splash Screen
FILE:		splash.c

AUTHOR:		Todd Stumpf, Oct 01, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Todd    	10/01/98   	Initial version

DESCRIPTION:
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#define _SPLASH_C_

#include <stdio.h>
#include <stdlib.h>
#include <mem.h>

#include "splash.h"
#include "card.h"

#define FALSE	0
#define TRUE   (!FALSE)

#define	PRINT_DEBUG_INFO	FALSE

#define ZSOFT_FLAG 0x0A
#define PCX_PALETTE_START	12

#define flip_bytes(a)   ( (a[0]) | ( a[1] << 8) )

int BlastOutPCXFile(FILE *);
int ReadPCXHeader(PCXHeader *, FILE *);
//int ReadPCXScanLine(unsigned char *, unsigned int, FILE *);
int ExpandPCXPixelData(PCXHeader *, FILE *);



void
usage(void)
{
	puts("\npass me a file, buddie\n");
}

int
main( int argc, char *argv[])
{
	FILE *srcFile;

	/* Make sure they gave us a file... */
	if ( argc != 2 ) {
		usage();
		exit(-1);
	}

	/* Open the source file and see what we can see */
	if ( (srcFile = fopen(argv[1], "rb") ) == NULL ) {
		printf("\nERROR: %s not found.\n", argv[1]);
		exit(-1);
	}

	/* Initialize the card, and put it into the correct mode */
	CardSetVideoMode();
	CardDisableOutput();

	/* Run t;hrough the .PCX file and blast it up to the screen */
	if ( BlastOutPCXFile(srcFile) != 0 ) {
		printf("\nERROR: %s corrupted PCX file.\n", argv[1]);
		exit(1);
	};

	/* Finally flip on the output and let it go */
	CardEnableOutput();

	/* All is well and good...*/
	fclose(srcFile);
	return (0);
}

int
BlastOutPCXFile(FILE *pcxFile)
{
	PCXHeader    	thePic;
	unsigned char	*palette;

	/*
	 *  Snarf the header in header in
	 */
	ReadPCXHeader(&thePic, pcxFile);


	/*
	 *  Run through the files and build scanlines...
	 */
	ExpandPCXPixelData(&thePic, pcxFile);

	/*
	 *  Now find a place to put the palette, and make sure
	 *  its defined at the end of the file.
	 */
	palette = (unsigned char *) calloc(256*3, sizeof(unsigned char));
	if ( palette == NULL ) {
		return (-1);
	}

   fseek(pcxFile, -((256 * 3) + 1), SEEK_END); 

	if ( getc(pcxFile) != PCX_PALETTE_START ) {
		puts("\nERROR: Palette misalligned\n");
		return (-1);
	}

	/*
	 *  Get the palette out of the file
	 */
	if ( fread(palette, 3, 256, pcxFile) != 256 ) {
		puts("\nERROR: Palette truncated\n");
		return (-1);
	}

	/*
	 *  Inform the card of the new palette, and leave
	 */
	CardSetPalette(palette);
	free(palette);

	return (0);
}

/*
 * ReadPcxHeader --
 *
 *	This reads the header of the input file, loads up the passed
 *	structure, then prints out some nice details.
 *
 *	Returns a TRUE if the file was read acceptably, or FALSE if
 *	there was a problem.
 */
int
ReadPCXHeader(PCXHeader *pH, FILE *pcxFile)
{
	PCXRawHeader *prH;

	/*
	 * Grab what should be the raw header
	 */
	prH = (PCXRawHeader *)malloc(sizeof(PCXRawHeader));

	if (fread((char *)prH, sizeof(PCXRawHeader), 1, pcxFile) != 1) {
		fprintf(stderr,"Couldn't read pcx header.\n");
		free(prH);
		return FALSE;
	}

	/*
	 * Is this a pcx file?  The first byte will tell!
	 */
	if (prH->zsoft_flag != ZSOFT_FLAG) {
		fprintf(stderr,"The input file is not in pcx format.\n");
		free(prH);
		return FALSE;
	}

	/*
	 * Massage the raw header data into something we can read.
	 */
	pH->encoding_flag = prH->encoding_flag;
	pH->bpp = prH->bits_per_pixel;
	pH->xmin = flip_bytes(prH->xmin);
	pH->ymin = flip_bytes(prH->ymin);
	pH->xmax = flip_bytes(prH->xmax);
	pH->ymax = flip_bytes(prH->ymax);
	pH->hrez = flip_bytes(prH->horiz_resolution);
	pH->vrez = flip_bytes(prH->vert_resolution);
	pH->planes = prH->planes;
	pH->bps = flip_bytes(prH->bytes_per_scanline);
	pH->palette_type = flip_bytes(prH->palette_interp);
	pH->screen_x = flip_bytes(prH->video_screen_x);
	pH->screen_y = flip_bytes(prH->video_screen_y);

#if	PRINT_DEBUG_INFO
	/*
	 * Hell, while we're here, let's blast up some fun info.
	 */
	fprintf(stderr,"This file is PCX version %d.\n", prH->version_number);
	fprintf(stderr,"It %s run-length encoding, ",
		 (pH->encoding_flag == 1 ? "has" : "does not have"));
	fprintf(stderr,"with %d bits per pixel, per plane.\n",
		 pH->bpp);
	fprintf(stderr,"The image is %dx%d, with %d color/greyscale planes.\n",
		 pH->xmax - pH->xmin + 1,
		 pH->ymax - pH->ymin + 1,
		 pH->planes);
	fprintf(stderr,"There are %d bytes/line/plane\n",
		 pH->bps);
	if (pH->palette_type == 0) {
		fprintf(stderr,"No palette is provided.\n");
	} else {
		fprintf(stderr,"By the way, this palette is in %s.\n",
		(pH->palette_type == 1 ? "color/monochrome" :
		 pH->palette_type == 2 ? "greyscale" :
		 "some unknown format"));
	}

	fprintf(stderr,"encodingFlag: %d\n", pH->encoding_flag);
	fprintf(stderr,"bpp: %d\n", pH->bpp);
	fprintf(stderr,"xmin: %d\n", pH->xmin);
	fprintf(stderr,"ymin: %d\n", pH->ymin);
	fprintf(stderr,"xmax: %d\n", pH->xmax);
	fprintf(stderr,"ymax: %d\n", pH->ymax);
	fprintf(stderr,"hrez: %d\n", pH->hrez);
	fprintf(stderr,"vrez: %d\n", pH->vrez);
	fprintf(stderr,"planes: %d\n", pH->planes);
	fprintf(stderr,"bytes_per_mumble: %d\n", pH->bps);
	fprintf(stderr,"palette: %d\n", pH->palette_type);
	fprintf(stderr,"vscreenx: %d\n", pH->screen_x);
	fprintf(stderr,"yscreenx: %d\n", pH->screen_y);

	fprintf(stderr,"\n");
#endif	/* PRINT_DEBUG_INFO */

	free(prH);
	return TRUE;
}

int
ExpandPCXPixelData(PCXHeader *thePic, FILE *pcxFile)
{
	unsigned long		  bpb = CardGetMapSize(); 	/* Size of window */
	unsigned int		  vidPage = 0x0;
	unsigned char far	 *vidMem = CardMapPage(vidPage);   /* Top of screen */
	unsigned char       aCode;
	unsigned char       runLength;
	unsigned long		  pixCount;

	pixCount = (unsigned long) thePic->bps * (unsigned long) (( thePic->ymax - thePic->ymin ) + 1);
#if	PRINT_DEBUG_INFO
	printf("Total pixels = %lu\n", pixCount);
#endif	/* PRINT_DEBUG_INFO */

	do {
		/* Mark off all the pixels included in this page */
		if ( pixCount < bpb ) {
			bpb = pixCount;
		}
		pixCount -= bpb;

		/* Extract pixels */
		aCode = getc(pcxFile);
		while ( bpb > 0 ) {
			/* Do we have a run of similar pixels? */
			if ( ( aCode & PCX_RUN ) == PCX_RUN ) {
				/* Yup, we most likely do */
				switch (aCode) {
				case (PCX_RUN | 0x1):
					/*
					 * Handle case where one pixel is being set specially
					 * as it happens a lot and we'd like to avoid the
					 * unnecessary overhead of handling a length-one run.
					 */
					aCode = getc(pcxFile);
					*vidMem++ = aCode;
					bpb--;
					break;
				case ((unsigned char) EOF):
					/*
					 * Make sure we haven't run out of pixels
					 */
					if ( feof(pcxFile) ) {
						exit (-1);
					}
					/* Look ma'!  No break! */
				default:
					runLength = aCode & ~PCX_RUN;
					aCode = getc(pcxFile);
					/* Does run cross over page boundry? */
					if ( bpb >= runLength ) {
						/* Nope.  Completely internal scanline */
						_fmemset(vidMem, aCode, runLength);
						vidMem += runLength;
						bpb -= runLength;
					} else {
						/* Yup.  Crosses into next window */
						_fmemset(vidMem, aCode, (unsigned int) bpb);
						runLength -= (unsigned int) bpb;
						vidMem = CardMapPage(++vidPage);
						bpb = CardGetMapSize();
						_fmemset(vidMem, aCode, runLength);
						if ( pixCount < bpb ) {
							if ( pixCount == 0 ) {
								bpb = 0;
								runLength = 0;
							} else {
								bpb = pixCount;
							}
						}
						pixCount -= bpb;
						vidMem += runLength;
						bpb -= runLength;
					}
				}
			} else {
				/* Just a single pixel */
				*vidMem++ = aCode;
				bpb--;
			}
			aCode = getc(pcxFile);
		}
		vidMem = CardMapPage(++vidPage);
		bpb = CardGetMapSize();
	} while ( pixCount > 0 );

	ungetc(aCode, pcxFile);
	return (0);
}
