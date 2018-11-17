/***********************************************************************
 *
 *      Copyright (c) Dirk Lausecker 1998-2000 -- All Rights Reserved
 *
 * PROJECT:     BestSound
 * FILE:        dirksnd.h
 * AUTHOR:      Dirk Lausecker
 *
 * DESCRIPTION:
 *      Include-File zum Definieren der DACSF und TreibereinsprÅnge
 *
 ***********************************************************************/

#ifndef __DIRKSND_H
#define __DIRKSND_H

#define MANUFACTURER_ID_BSW          16427

/*-----------------------------------------------

		Structures

  -----------------------------------------------*/

typedef struct {
	word		BWFC_dataFormat;	// 1 = PCM-Daten
        word		BWFC_channels;		// Kanalzahl
        dword		BWFC_sampleRate;	// Samples pro Sekunde
        dword		BWFC_avgRate;		// durchschnittl. Datenrate
        word		BWFC_blockAlign;	// Blockausrichtung
        word		BWFC_bitsPerSample;	// Bits pro Sample

} BSWavFormChunk;

typedef struct {
	char		BWFH_typRIFF[4];	// "RIFF"
	dword		BWFH_fullLen;		// Gesamtdateigrî·e - 8
	char		BWFH_formName[4];	// "WAVE"
	char		BWFH_typFMT[4];		// "fmt "
	dword		BWFH_fmtLen;		// 16
	BSWavFormChunk	BWFH_fmtChunk;
	char		BWFH_typData[4];	// "data"
	dword		BWFH_datLen;		// LÑnge der Sounddaten

} BSWavFileHeader;

/*-----------------------------------------------

		Constants

  -----------------------------------------------*/

// Extension of DACSampleFormat
#define DACSF_8_BIT_MONO        4
#define DACSF_8_BIT_STEREO      5
#define DACSF_16_BIT_MONO       6
#define DACSF_16_BIT_STEREO     7
#define DACSF_MIXER_TEST        8

// Extension of the soundcard driver
// Mixer
#define DRE_SOUND_DAC_CHECK_SAMPLE_RATE_AND_FORMAT             0x1C
#define DRE_BSMIXER_GET_CAP             0x22
#define DRE_BSMIXER_GET_VALUE           0x24
#define DRE_BSMIXER_SET_VALUE           0x26
#define DRE_BSMIXER_SET_DEFAULT         0x28
#define DRE_BSMIXER_TOKEN_TO_TEXT       0x2A
#define DRE_BSMIXER_SPEC_VALUE          0x2C
#define DRE_BSMIXER_GET_SUB_TOKEN       0x2E

// Recorder
#define DRE_BSREC_GET_RMS_VALUE         0x30
#define DRE_BSREC_SET_SAMPLING          0x32
#define	DRE_BSREC_START_RECORDING	0x34
#define	DRE_STOP_REC_OR_PLAY		0x36
#define	DRE_BSREC_GET_DATA		0x38
#define	DRE_BSREC_GET_MAX_PROPERTIES	0x3A

// NewWave
#define DRE_BSNWAV_SET_SAMPLING		0x32	/* identisch mit REC */
#define	DRE_BSNWAV_GET_MAX_PROPERTIES	0x3A	/* identisch mit REC */
#define	DRE_BSNWAV_SECOND_ALLOC		0x3C
#define	DRE_BSNWAV_GET_STATUS		0x3E
#define	DRE_BSNWAV_START_PLAY		0x40
#define	DRE_BSNWAV_GET_AI_STATE		0x42
#define	DRE_BSNWAV_SET_PAUSE		0x44

#endif
