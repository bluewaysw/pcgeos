/***********************************************************************

       Copyright (c) Gerd Boerrigter 1996 -- All Rights Reserved

PROJECT:    Media Extension Library for GEOS
MODULE:     RIFF Formats
FILE:       riff.h

AUTHOR:     Gerd Boerrigter

RCS STAMP:
    $Id: RIFF.H 1.4 1996/09/19 21:07:16 boerrigt Exp $

DESCRIPTION:
    Constants and structures for RIFF files.

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    02.07.96  GerdB   Initial version.
    04.09.96  GerdB   Change comments from german to english.

***********************************************************************/

/* The following copyright applies to all Ultimotion Segments
 * of the Code:
 * "Copyright International Business Machines Corporation 1994,
 * All rights reserved.
 * This product uses Ultimotion(tm) IBM video technology."
 */

#ifndef __RIFF_H
#define __RIFF_H

#include <geos.h>


typedef dword FourCC;

/*
 * RIFF Names
 */
#define RIFF_RIFF 0x52494646
#define RIFF_LIST 0x4C495354
#define RIFF_JUNK 0x4A554E4B

/*
 * RIFF Types
 */
#define RIFF_AVI  0x41564920
#define RIFF_WAVE 0x57415645

/*
 * fcc Types
 */
#define RIFF_vids 0x76696473
#define RIFF_auds 0x61756473
#define RIFF_pads 0x70616473
#define RIFF_movi 0x6d6f7669

/*
 * AVI Chunk Names
 */
#define RIFF_avih 0x61766968
#define RIFF_strl 0x7374726C
#define RIFF_strh 0x73747268
#define RIFF_strf 0x73747266
#define RIFF_strd 0x73747264
#define RIFF_vedt 0x76656474
#define RIFF_idx1 0x69647831

#define RIFF_hdrl 0x6864726C
#define RIFF_rec  0x72656320

/*
 * Chunk Names
 */
#define RIFF_FF00 0xFFFF0000
#define RIFF_00   0x30300000
#define RIFF_01   0x30310000
#define RIFF_02   0x30320000
#define RIFF_03   0x30330000
#define RIFF_00pc 0x30307063
#define RIFF_01pc 0x30317063
#define RIFF_00dc 0x30306463
#define RIFF_00dx 0x30306478
#define RIFF_00db 0x30306462
#define RIFF_00xx 0x30307878
#define RIFF_00id 0x30306964
#define RIFF_00rt 0x30307274
#define RIFF_0021 0x30303231
#define RIFF_00iv 0x30306976
#define RIFF_0031 0x30303331
#define RIFF_0032 0x30303332
#define RIFF_00vc 0x30305643
#define RIFF_00xm 0x3030786D
#define RIFF_01wb 0x30317762
#define RIFF_01dc 0x30306463

/*
 * VIDEO CODECS
 */
#define RIFF_CRAM 0x4352414D
#define RIFF_rgb  0x00000000
#define RIFF_RGB  0x52474220
#define RIFF_rle8 0x01000000
#define RIFF_RLE8 0x524c4538
#define RIFF_rle4 0x02000000
#define RIFF_RLE4 0x524c4534
#define RIFF_none 0x0000FFFF
#define RIFF_NONE 0x4e4f4e45
#define RIFF_pack 0x0100FFFF
#define RIFF_PACK 0x5041434b
#define RIFF_tran 0x0200FFFF
#define RIFF_TRAN 0x5452414e
#define RIFF_ccc  0x0300FFFF
#define RIFF_CCC  0x43434320
#define RIFF_jpeg 0x0400FFFF
#define RIFF_JPEG 0x4A504547
#define RIFF_MJPG 0x4d4a5047
#define RIFF_IJPG 0x494a5047
#define RIFF_RT21 0x52543231
#define RIFF_rt21 0x72743231
#define RIFF_IV31 0x49563331
#define RIFF_iv31 0x69763331
#define RIFF_IV32 0x49563332
#define RIFF_iv32 0x69763332
#define RIFF_CVID 0x43564944
#define RIFF_cvid 0x63766964
#define RIFF_ULTI 0x756c7469
#define RIFF_ulti 0x554c5449
#define RIFF_YUV9 0x59565539
#define RIFF_YVU9 0x59555639
#define RIFF_XMPG 0x584D5047
#define RIFF_xmpg 0x786D7067

/*
 * WAV file stuff
 */
#define RIFF_fmt  0x666D7420
#define RIFF_data 0x64617461

/*
 * FND in MJPG
 */
#define RIFF_ISFT 0x49534654
#define RIFF_IDIT 0x49444954

#define RIFF_00AM 0x3030414d
#define RIFF_DISP 0x44495350
#define RIFF_ISBJ 0x4953424a

/* fcc handlers */
#define RIFF_RLE  0x524c4520
#define RIFF_msvc 0x6D737663
#define RIFF_MSVC 0x4d535643


/*
 * AVI Header Chunk: entries in avih (MainAVIHeader)
 */
typedef struct {
    dword AVIMH_microSecPerFrame; /* Delay in ms between 2 frames */
    dword AVIMH_maxBytesPerSec;
    dword AVIMH_padGran;        /* ??? */
    dword AVIMH_flags;          /* See AVIFlags below */
    dword AVIMH_totalFrames;    /* Number of frames in the video */
    dword AVIMH_initialFrames;  /* Number of frames before the first */
    dword AVIMH_streams;        /* Number of streams in the video */
    dword AVIMH_suggestedBufferSize; /* Minimal needed puffersize */
    dword AVIMH_width;          /* Width of the image in pixel */
    dword AVIMH_height;         /* Height of the image in pixel */
    dword AVIMH_scale;
    dword AVIMH_rate;
    dword AVIMH_start;
    dword AVIMH_length;
} AVIMainHeader;

/* MainAVIHeader Flags */
typedef DWordFlags AVIFlags;
#define AVIF_HASINDEX       0x00000010 /* Has idx1 Chunk */
#define AVIF_MUSTUSEINDEX   0x00000020 /* Show as the index dictate */
#define AVIF_ISINTERLEAVED  0x00000100 /* Audio and video are interleaved */
#define AVIF_WASCAPTUREFILE 0x00010000 /* File is prepared for capturing */
#define AVIF_COPYRIGHTED    0x00020000 /* File includes copyrighted data */


/*
 * Stream Line Header Chunk: entries in strh (AVIStreamHeader)
 */
typedef struct {
    FourCC AVISH_type;       /* Stream-Type {vids, auds} */
    dword  AVISH_handler;    /* Codec-Type {msvc, RLE, ... } */
    dword  AVISH_flags;      /* See AVIStreamFlags below */
    dword  AVISH_priority;   /* */
    dword  AVISH_initialFrames; /* Number of frames before the first */
    dword  AVISH_scale;   /* dwScale/dwRate => scan-rate in Hz */
    dword  AVISH_rate;
    dword  AVISH_start;   /* Starttime of this stream (dwScale,dwRate) */
    dword  AVISH_length;  /* Length in measures of (dwScale,dwRate) */
    dword  AVISH_suggestedBufferSize; /* Minimal puffersize */
    dword  AVISH_quality;    /* Quality of stream compression */
    dword  AVISH_sampleSize; /* Number of bytes per frame. 0, if single
                                pictures are stored in sub-chunks */
    dword  AVISH_reserved2[4];  /* Should be 0 */
} AVIStreamHeader;

/* AVIStreamHeader Flags */
typedef DWordFlags AVIStreamFlags;
#define AVISF_DISABLED          0x00000001 /* Stream shouldn't be played */
#define AVISF_VIDEO_PALCHANGES  0x00010000 /* Stream includes different palettes */

/*
 * Stream Format Chunk: entries in strf (BitmapInfo)
 */
typedef struct {
    dword  BFD_size;          /* Size of BitmapInfoHeader-struct */
    dword  BFD_width;         /* Width of the image in pixel */
    dword  BFD_height;        /* Height of the image in pixel */
    word   BFD_planes;        /* Number of planes (must be 1) */
    word   BFD_bitCount;      /* Number of bits per pixel */
    FourCC BFD_compression;   /* Compression-typ */
    dword  BFD_sizeImage;     /* Imagesize in bytes */
    dword  BFD_xPelsPerMeter; /* Horizontal resulution */
    dword  BFD_yPelsPerMeter; /* Vertikal resultution */
    dword  BFD_clrUsed;       /* If color-palette: number of colors */
    dword  BFD_clrImportant;  /* Number of important colors */
} BitmapFormatDescription;

typedef struct {
    byte  RGBQ_blue;
    byte  RGBQ_green;
    byte  RGBQ_red;
    byte  RGBQ_reserved;      /* Must be 0 */
} RGBQuad;

/*
 * Stream Format Chunk: entries in strf (WaveFormatEx)
 */
typedef struct {
    word  WFD_formatTag;      /* Sound-typ 0=mono 1=stereo */
    word  WFD_numChannels;    /* Number of channels (1 or 2) */
    dword WFD_samplesPerSec;  /* scan-rate in Hz */
    dword WFD_avgBytesPerSec;
    word  WFD_blockAlign;	/* 1 = 8 Bit mono
				   2 = 8 Bit stereo od. 16 Bit mono
				   3 = 16Bit stereo */

    word  WFD_bitsPerSample;
 /*   word  WFD_size;    */       /* Number of following header bytes */
} WaveFormatDescription;


/* WaveFormatFlags (Format Category)
 */
typedef WordFlags WaveFormatFlags;
#define WAVE_FORMAT_UNKNOWN     0x0000
#define WAVE_FORMAT_PCM         0x0001  /* Microsoft Pulse Code
                                           Modulation (PCM) format */
#define WAVE_FORMAT_ADPCM       0x0002
#define WAVE_FORMAT_ALAW        0x0006
#define WAVE_FORMAT_MULAW       0x0007
#define WAVE_FORMAT_OKI_ADPCM   0x0010
#define WAVE_FORMAT_DIGISTD     0x0015
#define WAVE_FORMAT_DIGIFIX     0x0016
#define IBM_FORMAT_MULAW        0x0101  /* IBM mu-law format */
#define IBM_FORMAT_ALAW         0x0102  /* IBM a-law format */
#define IBM_FORMAT_ADPCM        0x0103  /* IBM AVC Adaptive
                                           Differential Pulse
                                           Code Modulation format */

/*
 * Index Chunk: entries in idx1 (AVIINDEXENTRY)
 */
typedef struct {
    FourCC AVIIE_ckid;
    dword  AVIIE_flags;  /* See AVIIndexFlags below */
    dword  AVIIE_offset; /* Offset in movi chunk. */
    dword  AVIIE_size;   /* Length of the data-chunk (without chunkID) */
} AVIIndexEntry;

/* AVIINDEXENTRY Flags
 */
typedef DWordFlags AVIIndexFlags;
#define AVIIF_LIST      0x00000001 /* LIST-chunk: ckid is identical
                                      with the list-type of the chunk. */
#define AVIIF_TWOCC     0x00000002
#define AVIIF_KEYFRAME  0x00000010 /* Chunk is a keyframe */
#define AVIIF_FIRSTPART 0x00000020 /* Needs following images */
#define AVIIF_LASTPART  0x00000040 /* Needs preceding images */
#define AVIIF_MIDPART   (AVIIF_LASTPART|AVIIF_FIRSTPART)
#define AVIIF_NOTIME    0x00000100 /* Dosn't influence the timing */
#define AVIIF_COMPUSE   0x0FFF0000


/*
 * Palettendaten Chunk: entries in ##pc (AVIPALCHANGE)
 */
typedef struct {
    byte  PE_red;
    byte  PE_green;
    byte  PE_blue;
    byte  PE_reserved;       /* must be 0 */
} PaletteEntry;

typedef struct {
    byte  AVIPC_firstEntry;  /* First color to change */
    byte  AVIPC_numEntrys;   /* Number of colors to change */
    word  AVIPC_flags;       /* Unknown */
    PaletteEntry  AVIPC_new; /* Table with new color values */
} AVIPalChange;

#endif /* __RIFF_H */

