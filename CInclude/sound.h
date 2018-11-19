/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC/GEOS
 * FILE:	sound.h
 * AUTHOR:	Todd Stumpf, Sept. 1992
 *
 * DESCRIPTION:
 *	C version of sound.def
 *
 *	$Id: sound.h,v 1.1 97/04/04 15:57:03 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__SOUND_H
#define __SOUND_H

#include <driver.h>

/* EndOfSongFlags */
typedef ByteFlags EndOfSongFlags;
#define EOSF_UNLOCK       0x0080               /* unlock block at EOS ?  */
#define EOSF_DESTROY      0x0040               /* destroy block at EOS ? */

#define UNLOCK_ON_EOS     EOSF_UNLOCK
#define DESTROY_ON_EOS    EOSF_DESTROY

/* SoundPrioritys */
typedef enum {
    SP_SYSTEM_LEVEL=10,                        /* most urgent  */
    SP_ALARM=20,
    SP_STANDARD=30,
    SP_GAME=40,
    SP_BACKGROUND=50                           /* least urgent */
} SoundPriority;

#define SP_IMMEDIATE                  -1       /* really important */
#define SP_THEME                      +1       /* not quite so important */

/* SoundStreamSizes     */
typedef word SoundStreamSize;
#define SSS_ONE_SHOT                   128    /* 128 bytes (very small)   */
#define SSS_SMALL                      256    /* 256 bytes                */
#define SSS_MEDIUM                     512    /* 512 bytes (nice size)    */
#define SSS_LARGE                      1024   /* 1024 bytes (a bit large) */


/* SoundStreamEvents */
typedef enum {
    SSE_VOICE_ON=0,                           /* turn on voice event      */
    SSE_VOICE_OFF=2,                          /* turn off voice event     */
    SSE_CHANGE=4,                             /* change instrument        */
    SSE_GENERAL=6                             /* system-specific event    */
} SoundStreamEvents;

/* SoundStreamDeltaTimeTypes */
typedef enum {
    SSDTT_MSEC=8,                             /* wait for N mili seconds */
    SSDTT_TICKS=10,                           /* wait for N ticks        */
    SSDTT_TEMPO=12,                           /* wait for N beats        */
} SoundStreamDeltaTimeType;

/* Sound Stream General Events */
typedef enum { 
    GE_NO_EVENT=0,                            /* dummy event (NOP)        */
    GE_END_OF_SONG=2,                         /* marks end of song        */
    GE_SET_PRIORITY=4,                        /* changes sound priority   */
    GE_SET_TEMPO=6,                           /* changes sound tempo      */
    GE_SEND_NOTIFICATION=8,                   /* sends encoded message    */
    GE_V_SEMAPHORE=10                         /* V's a specified semaphore*/
} GeneralEvent;

/*	Note frequencies.  For actual frequencies, see sound.def. */
#define	REST 		 0

#define	LOW_C_b		 247
#define	MIDDLE_C_b	 494
#define	HIGH_C_b	 988

#define	LOW_C 		 262
#define	MIDDLE_C 	 523
#define	HIGH_C 		 1047

#define	LOW_C_SH 	 277
#define	MIDDLE_C_SH 	 554
#define	HIGH_C_SH 	 1109

#define	LOW_D_b 	 LOW_C_SH
#define	MIDDLE_D_b 	 MIDDLE_C_SH
#define	HIGH_D_b 	 HIGH_C_SH

#define	LOW_D 		 294
#define	MIDDLE_D	 587
#define	HIGH_D 		 1175

#define	LOW_D_SH 	 311
#define	MIDDLE_D_SH 	 622
#define	HIGH_D_SH 	 1245

#define	LOW_E_b 	 LOW_D_SH
#define	MIDDLE_E_b 	 MIDDLE_D_SH
#define	HIGH_E_b 	 HIGH_D_SH

#define	LOW_E 		 330
#define	MIDDLE_E 	 659
#define	HIGH_E 		 1319

#define	LOW_E_SH	 349
#define	MIDDLE_E_SH	 698
#define	HIGH_E_SH	 1397

#define	LOW_F_b		 LOW_E
#define	MIDDLE_F_b	 MIDDLE_E
#define	HIGH_F_b	 HIGH_E

#define	LOW_F 		 LOW_E_SH
#define	MIDDLE_F 	 MIDDLE_E_SH
#define	HIGH_F 		 HIGH_E_SH

#define	LOW_F_SH 	370
#define	MIDDLE_F_SH 	740
#define	HIGH_F_SH 	1480

#define	LOW_G_b 	LOW_F_SH
#define	MIDDLE_G_b 	MIDDLE_F_SH
#define	HIGH_G_b 	HIGH_F_SH

#define	LOW_G 		392
#define	MIDDLE_G 	784
#define	HIGH_G 		1568

#define	LOW_G_SH 	415
#define	MIDDLE_G_SH 	831
#define	HIGH_G_SH 	1661

#define	LOW_A_b 	LOW_G_SH
#define	MIDDLE_A_b 	MIDDLE_G_SH
#define	HIGH_A_b 	HIGH_G_SH

#define	LOW_A 		440
#define	MIDDLE_A 	880
#define	HIGH_A 		1760

#define	LOW_A_SH 	466
#define	MIDDLE_A_SH 	932
#define	HIGH_A_SH 	1865

#define	LOW_B_b 	LOW_A_SH
#define	MIDDLE_B_b 	MIDDLE_A_SH
#define	HIGH_B_b 	HIGH_A_SH

#define	LOW_B 		MIDDLE_C_b
#define	MIDDLE_B 	HIGH_C_b
#define	HIGH_B 		(2 * MIDDLE_B)

#define	LOW_B_SH	MIDDLE_C
#define	MIDDLE_B_SH	HIGH_C
#define	HIGH_B_SH	(2 * MIDDLE_B_SH)

/*  Double-sharp & double-flat frequencies */

#define LOW_C_DSH	LOW_D
#define MIDDLE_C_DSH	MIDDLE_D
#define HIGH_C_DSH	HIGH_D

#define LOW_C_bb	LOW_B_b/2
#define MIDDLE_C_bb	LOW_B_b
#define HIGH_C_bb	MIDDLE_B_b

#define LOW_D_DSH	LOW_E
#define MIDDLE_D_DSH	MIDDLE_E
#define HIGH_D_DSH	HIGH_E

#define LOW_D_bb	LOW_C
#define MIDDLE_D_bb	MIDDLE_C
#define HIGH_D_bb	HIGH_C

#define LOW_E_DSH	LOW_F_SH
#define MIDDLE_E_DSH	MIDDLE_F_SH
#define HIGH_E_DSH	HIGH_F_SH

#define LOW_E_bb	LOW_D
#define MIDDLE_E_bb	MIDDLE_D
#define HIGH_E_bb	HIGH_D

#define LOW_F_DSH	LOW_G
#define MIDDLE_F_DSH	MIDDLE_G
#define HIGH_F_DSH	HIGH_G

#define LOW_F_bb	LOW_E_b
#define MIDDLE_F_bb	MIDDLE_E_b
#define HIGH_F_bb	HIGH_E_b

#define LOW_G_DSH	LOW_A
#define MIDDLE_G_DSH	MIDDLE_A
#define HIGH_G_DSH	HIGH_A

#define LOW_G_bb	LOW_F
#define MIDDLE_G_bb	MIDDLE_F
#define HIGH_G_bb	HIGH_F

#define LOW_A_DSH	LOW_B
#define MIDDLE_A_DSH	MIDDLE_B
#define HIGH_A_DSH	HIGH_B

#define LOW_A_bb	LOW_G
#define MIDDLE_A_bb	MIDDLE_G
#define HIGH_A_bb	HIGH_G

#define LOW_B_DSH	MIDDLE_C_SH
#define MIDDLE_B_DSH	HIGH_C_SH
#define HIGH_B_DSH	HIGH_C_SH*2

#define LOW_B_bb	LOW_A
#define MIDDLE_B_bb	MIDDLE_A
#define HIGH_B_bb	HIGH_A

/* Volume Settings */

#define DYNAMIC_FFFF    0xffff               /* Very, Very loud   */
#define DYNAMIC_FFF     0xe800
#define DYNAMIC_FF      0xd000               /* Pretty darn loud  */
#define DYNAMIC_F       0xb800
#define DYNAMIC_MF      0xad00               /* Nice accent       */
#define DYNAMIC_MP      0x9800               /* Ahhh....          */
#define DYNAMIC_P       0x8000
#define DYNAMIC_PP      0x6800               /* Whatwasthat?      */
#define DYNAMIC_PPP     0x5000
#define DYNAMIC_PPPP    0x3800               /* Is this thing on? */

/* Duration Settings */
#define WHOLE                   128
#define HALF                     64
#define QUARTER                  32
#define EIGHTH                   16
#define SIXTEENTH                 8
#define THIRTYSECOND              4
#define SIXTYFOURTH               2
#define ONE_HUNDRED_TWENTY_EIGHTH 1
#define DOUBLE_DOT_WHOLE      WHOLE + HALF + QUARTER
#define DOUBLE_DOT_HALF       HALF + QUARTER + EIGHTH
#define DOUBLE_DOT_QUARTER    QUARTER + EIGHTH + SIXTEENTH
#define DOUBLE_DOT_EIGHTH     EIGHTH + SIXTEENTH + THIRTYSECOND
#define DOUBLE_DOT_SIXTEENTH  SIXTEENTH + THIRTYSECOND + SIXTYFOURTH
#define DOTTED_WHOLE          WHOLE + HALF
#define DOTTED_HALF           HALF + QUARTER
#define DOTTED_QUARTER        QUARTER + EIGHTH
#define DOTTED_EIGHTH         EIGHTH + SIXTEENTH
#define DOTTED_SIXTEENTH      SIXTEENTH + THIRTYSECOND
#define DOTTED_THIRTYSECOND   THIRTYSECOND + SIXTYFOURTH

/* Instrument Tables */
typedef enum {
    IT_STANDARD_TABLE=0                           /* default table */
} InstrumentTable;


#define DEFAULT_INSTRUMENT    IP_ACOUSTIC_GRAND_PIANO

/* Instrument Patches */
typedef enum {
    IP_ACOUSTIC_GRAND_PIANO,
    IP_BRIGHT_ACOUSTIC_PIANO,
    IP_ELECTRIC_GRAND_PIANO, 
    IP_HONKY_TONK_PIANO, 
    IP_ELECTRIC_PIANO_1,
    IP_ELECTRIC_PIANO_2,
    IP_HARPSICORD,
    IP_CLAVICORD,
    IP_CELESTA,
    IP_GLOCKENSPIEL,
    IP_MUSIC_BOX,
    IP_VIBRAPHONE,
    IP_MARIMBA,
    IP_XYLOPHONE,
    IP_TUBULAR_BELLS,
    IP_DULCIMER,
    IP_DRAWBAR_ORGAN,
    IP_PERCUSSIVE_ORGAN,
    IP_ROCK_ORGAN,
    IP_CHURCH_ORGAN,
    IP_REED_ORGAN,
    IP_ACCORDION,
    IP_HARMONICA,
    IP_TANGO_ACCORDION,
    IP_ACOUSTIC_NYLON_GUITAR,
    IP_ACOUSTIC_STEEL_GUITAR,
    IP_ELECTRIC_JAZZ_GUITAR,
    IP_ELECTRIC_CLEAN_GUITAR,
    IP_ELECTRIC_MUTED_GUITAR,
    IP_OVERDRIVEN_GUITAR,
    IP_DISTORTION_GUITAR,
	 IP_GUITAR_HARMONICS,
    IP_ACOUSTIC_BASS,
    IP_ELECTRIC_FINGERED_BASS,
    IP_ELECTRIC_PICKED_BASS,
    IP_FRETLESS_BASS,
    IP_SLAP_BASS_1,
    IP_SLAP_BASS_2,
    IP_SYNTH_BASS_1,
    IP_SYNTH_BASS_2,
    IP_VIOLIN,
    IP_VIOLA,
    IP_CELLO,
    IP_CONTRABASS,
    IP_TREMOLO_STRINGS,
    IP_PIZZICATO_STRINGS,
    IP_ORCHESTRAL_HARP,
    IP_TIMPANI,
    IP_STRING_ENSEMBLE_1,
    IP_STRING_ENSEMBLE_2,
    IP_SYNTH_STRINGS_1,
    IP_SYNTH_STRINGS_2,
    IP_CHOIR_AAHS,
    IP_VOICE_OOHS,
    IP_SYNTH_VOICE,
    IP_ORCHESTRA_HIT,
    IP_TRUMPET,
    IP_TROMBONE,
    IP_TUBA,
    IP_MUTED_TRUMPET,
    IP_FRENCH_HORN,
    IP_BRASS_SECTION,
    IP_SYNTH_BRASS_1,
    IP_SYNTH_BRASS_2,
    IP_SOPRANO_SAX,
    IP_ALTO_SAX,
    IP_TENOR_SAX,
    IP_BARITONE_SAX,
    IP_OBOE,
    IP_ENGLISH_HORN,
    IP_BASSOON,
    IP_CLARINET,
    IP_PICCOLO,
    IP_FLUTE,
    IP_RECORDER,
    IP_PAN_FLUTE,
    IP_BLOWN_BOTTLE,
    IP_SHAKUHACHI,
    IP_WHISTLE,
    IP_OCARINA,
    IP_LEAD_SQUARE,
    IP_LEAD_SAWTOOTH,
    IP_LEAD_CALLIOPE,
    IP_LEAD_CHIFF,
    IP_LEAD_CHARANG,
    IP_LEAD_VOICE,
    IP_LEAD_FIFTHS,
    IP_LEAD_BASS_LEAD,
    IP_PAD_NEW_AGE,
    IP_PAD_WARM,
    IP_PAD_POLYSYNTH,
    IP_PAD_CHOIR,
    IP_PAD_BOWED,
    IP_PAD_METALLIC,
    IP_PAD_HALO,
    IP_PAD_SWEEP,
    IP_FX_RAIN,
    IP_FX_SOUNDTRACK,
    IP_FX_CRYSTAL,
    IP_FX_ATMOSPHERE,
    IP_FX_BRIGHTNESS,
    IP_FX_GOBLINS,
    IP_FX_ECHOES,
    IP_FX_SCI_FI,
    IP_SITAR,
    IP_BANJO,
    IP_SHAMISEN,
    IP_KOTO,
    IP_KALIMBA,
    IP_BAG_PIPE,
    IP_FIDDLE,
    IP_SHANAI,
    IP_TINKLE_BELL,
    IP_AGOGO,
    IP_STEEL_DRUMS,
    IP_WOODBLOCK,
    IP_TAIKO_DRUM,
    IP_MELODIC_TOM,
    IP_SYNTH_DRUM,
    IP_REVERSE_CYMBAL,
    IP_GUITAR_FRET_NOISE,
    IP_BREATH_NOISE,
    IP_SEASHORE,
    IP_BIRD_TWEET,
    IP_TELEPHONE_RING,
    IP_HELICOPTER,
    IP_APPLAUSE,
    IP_GUNSHOT,
    IP_ACOUSTIC_BASS_DRUM,
    IP_BASS_DRUM_1,
    IP_SIDE_STICK,
    IP_ACOUSTIC_SNARE,
    IP_HAND_CLAP,
    IP_ELECTRIC_SNARE,
    IP_LOW_FLOOR_TOM,
    IP_CLOSED_HI_HAT,
    IP_HIGH_FLOOR_TOM,
    IP_PEDAL_HI_HAT,
    IP_LOW_TOM,
    IP_OPEN_HI_HAT,
    IP_LOW_MID_TOM,
    IP_HI_MID_TOM,
    IP_CRASH_CYMBAL_1,
    IP_HIGH_TOM,
    IP_RIDE_CYMBAL_1,
    IP_CHINESE_CYMBAL,
    IP_RIDE_BELL,
    IP_TAMBOURINE,
    IP_SPLASH_CYMBAL,
    IP_COWBELL,
    IP_CRASH_CYMBAL_2,
    IP_VIBRASLAP,
    IP_RIDE_CYMBAL_2,
    IP_HI_BONGO,
    IP_LOW_BONGO,
    IP_MUTE_HI_CONGA,
    IP_OPEN_HI_CONGA,
    IP_LOW_CONGA,
    IP_HI_TIMBALE,
    IP_LOW_TIMBALE,
    IP_HIGH_AGOGO,
    IP_LOW_AGOGO,
    IP_CABASA,
    IP_MARACAS,
    IP_SHORT_WHISTLE,
    IP_LONG_WHISTLE,
    IP_SHORT_GUIRO,
    IP_LONG_GUIRO,
    IP_CLAVES,
    IP_HI_WOOD_BLOCK,
    IP_LOW_WOOD_BLOCK,
    IP_MUTE_CUICA,
    IP_OPEN_CUICA,
    IP_MUTE_TRIANGLE,
    IP_OPEN_TRIANGLE
} InstrumentPatch;

/*	Some of the patches were spelled improperly...	*/
#define		IP_ACCORDIAN		IP_ACCORDION
#define 	IP_STRING_ENSAMBLE_1	IP_STRING_ENSEMBLE_1
#define 	IP_STRING_ENSAMBLE_2	IP_STRING_ENSEMBLE_2
#define		IP_MUSIC_BOC		IP_MUSIC_BOX


/*	This one started life correctly (tremolo) and got
	changed to "tremelo" somehow, and then back.  */
#define		IP_TREMELO_STRINGS	IP_TREMOLO_STRINGS

/*
	;
	;  In the midi standard, all the percussion instruments
	;  have only one "note" they play.  To get the instrument
	;  patch to sound correct, pass the following constant as
	;  the "frequency" for the specific patch to play.
	;
	;  Example:
	;		ChangeEnvelope	0, IP_OPEN_HI_HAT, IT_STANDARD_TABLE
	;		VoiceOn		0, FR_OPEN_HI_HAT, DYNAMIC_FF
	;		DeltaTick	2
	;		VoiceOff	0
	;		DeltaTick	10
	;		VoiceOn		0, FR_OPEN_HIT_HAT, DYNAMIC_FF
	;		...
	;
	;  You can pass any note, of course, and things will still
	;	work, but it probably won't sound correct if you don't
	;	pass this constant.
	;
	;  These note values (by the way) are provided
	;	so that our OPL2 driver works correctly.
	;
*/
#define FR_ACOUSTIC_BASS_DRUM			LOW_C_b
#define FR_BASS_DRUM_1				( LOW_C / 2 )
#define FR_SIDE_STICK				MIDDLE_G_SH
#define FR_ACOUSTIC_SNARE			MIDDLE_C
#define FR_HAND_CLAP				MIDDLE_C
#define FR_ELECTRIC_SNARE			MIDDLE_C
#define FR_LOW_FLOOR_TOM			LOW_C
#define FR_CLOSED_HI_HAT			MIDDLE_C
#define FR_HIGH_FLOOR_TOM			LOW_F
#define FR_PEDAL_HI_HAT				MIDDLE_C
#define FR_LOW_TOM				LOW_G_SH
#define FR_OPEN_HI_HAT				MIDDLE_C
#define FR_LOW_MID_TOM				MIDDLE_C
#define FR_HI_MID_TOM				MIDDLE_F
#define FR_CRASH_CYMBAL_1			MIDDLE_C
#define FR_HIGH_TOM				MIDDLE_G_SH
#define FR_RIDE_CYMBAL_1			MIDDLE_C
#define FR_CHINESE_CYMBAL			MIDDLE_C
#define FR_RIDE_BELL				MIDDLE_C
#define FR_TAMBOURINE				MIDDLE_C
#define FR_SPLASH_CYMBAL			MIDDLE_C
#define FR_COWBELL				LOW_C
#define FR_CRASH_CYMBAL_2			MIDDLE_C
#define FR_VIBRASLAP				MIDDLE_C
#define FR_RIDE_CYMBAL_2			MIDDLE_C
#define FR_HI_BONGO				MIDDLE_G_SH
#define FR_LOW_BONGO				MIDDLE_E
#define FR_MUTE_HI_CONGA			MIDDLE_G_SH
#define FR_OPEN_HI_CONGA			MIDDLE_G_SH
#define FR_LOW_CONGA				MIDDLE_C
#define FR_HI_TIMBALE				MIDDLE_C
#define FR_LOW_TIMBALE				LOW_G_SH
#define FR_HIGH_AGOGO				LOW_F_SH
#define FR_LOW_AGOGO				LOW_C
#define FR_CABASA				MIDDLE_C
#define FR_MARACAS				MIDDLE_C
#define FR_SHORT_WHISTLE			HIGH_G_SH
#define FR_LONG_WHISTLE				HIGH_G_SH
#define FR_SHORT_GUIRO				MIDDLE_C
#define FR_LONG_GUIRO				MIDDLE_C
#define FR_CLAVES				( HIGH_G_SH * 2 )
#define FR_HI_WOOD_BLOCK			MIDDLE_C
#define FR_LOW_WOOD_BLOCK			LOW_F_SH
#define FR_MUTE_CUICA				MIDDLE_C
#define FR_OPEN_CUICA				MIDDLE_C
#define FR_MUTE_TRIANGLE			MIDDLE_G_SH
#define FR_OPEN_TRIANGLE			MIDDLE_G_SH
/*---------------------------------------------------------------------------
                Sound Buffer Construction Macros
---------------------------------------------------------------------------*/

#define DeltaTick(time) \
    SSDTT_TICKS, time
#define DeltaMS(time) \
    SSDTT_MSEC, time
#define DeltaTempo(time) \
    SSDTT_TEMPO, time

#define General(command) \
    SSE_GENERAL, command

#define Rest(duration) \
    General(GE_NO_EVENT), DeltaTick(duration)

#define VoiceOn(voice,freq,attack) \
    SSE_VOICE_ON, voice, freq, attack
#define VoiceOff(voice) \
    SSE_VOICE_OFF, voice
#define ChangeEnvelope(voice, instrument, table) \
    SSE_CHANGE, voice, instrument, table

#define SoundNote(voice,freq,duration,attack) \
    VoiceOn(voice, freq, attack), DeltaTempo(duration), VoiceOff(voice)
#define Staccato(voice,freq,duration,attack) \
    VoiceOn(voice, freq, attack), DeltaTempo(((duration*0x03)/0x04)), \
    VoiceOff(voice), DeltaTempo((duration/0x4))
#define Natural(voice,freq,duration,attack) \
    VoiceOn(voice, freq, attack), DeltaTempo(((duration*0x07)/0x08)), \
    VoiceOff(voice), DeltaTempo((duration/0x8))
#define Legato(voice,freq,duration,attack) \
    SoundNote(voice, freq, duration, attack)

/*-----------------------------------------------------------------------------
                SOUND ERROR CODES
-----------------------------------------------------------------------------*/

#define SOUND_ERROR_NO_ERRORS                         0
#define SOUND_ERROR_EXCLUSIVE_ACCESS_GRANTED          2
#define SOUND_ERROR_OUT_OF_MEMORY                     4
#define SOUND_ERROR_UNABLE_TO_ALLOCATE_STREAM         6
#define SOUND_ERROR_HARDWARE_NOT_AVAILABLE            8
#define SOUND_ERROR_FAILED_ATTACH_TO_HARDWARE        10
#define SOUND_ERROR_HARDWARE_DOESNT_SUPPORT_FORMAT   12
#define SOUND_ERROR_DAC_UNATTACHED                   14
#define SOUND_ERROR_STREAM_DESTROYED                 16
#define SOUND_ERROR_STREAM_FULL                      18

/*--------------------------------------------------------------------------
		DAC MANUFACTURER FORMAT
  --------------------------------------------------------------------------

	;
	;  DAC sounds can be stored in a variety of formats.
	;
	;  By default, the formats listed are monoural.  To indicate the stereo
	;  version of a format, DACSF_STEREO is OR'd with the DACSampleFormat
	;  enum value.  Not all formats are available in stereo.
	;
	;  The ADPCM data can either have a reference byte at
	;	the start of the data, or not.  Only the 1st
	;	block in a song will have a reference byte.
	; 	That byte is the starting value for the DAC.
*/

typedef unsigned DACSampleFormat;
#define    DACSF_8_BIT_PCM      0x0
#define    DACSF_2_TO_1_ADPCM   0x1
#define    DACSF_3_TO_1_ADPCM   0x2
#define    DACSF_4_TO_1_ADPCM   0x3

#define    DACSF_STEREO         0x4000

typedef unsigned DACReferenceByte;
#define    DACRB_NO_REFERENCE_BYTE      0x0
#define    DACRB_WITH_REFERENCE_BYTE    0x1

/*
 * SampleFormat 	record
 * 	SMID_format	DACSampleFormat:15
 * 	SMID_reference	DACReferenceByte:1
 * SampleFormat 	end
 */
typedef WordFlags SampleFormat;
#define SMID_FORMAT	0xfffe
#define SMID_REFERENCE	0x0001

#define SMID_FORMAT_OFFSET   1

/* DACPlayFlags	record */
typedef ByteFlags DACPlayFlags;
#define	DACPF_CATENATE	0x0080

typedef struct {
    word            SFD_manufact;       /* Manufacturer ID for sample format */
    SampleFormat    SFD_format;         /* Sample format of buffer           */
    word            SFD_rate;           /* Sampling rate for buffer          */
    DACPlayFlags    SFD_playFlags;      /* DAC Play flags for buffer         */
} SampleFormatDescription;

/*---------------------------------------------------------------------------
                   Envelope Format Information
  ---------------------------------------------------------------------------*/

/* SupportedEnvelopeFormat */
typedef enum {
    SEF_NO_FORMAT,                 /* No envelope processing available */
    SEF_SBI_FORMAT,                /* SoundBlaster envelope format     */
    SEF_CTI_FORMAT                 /* Casio/Tandy envelope format      */
} SupportedEnvelopeFormat;


/* SoundDriverNoiseCapability */
typedef WordFlags SoundDriverNoiseCapability;
#define SDNC_NO_NOISE    0x0000
#define SDNC_WHITE_NOISE 0x8000


/* SoundDriverWaveFormCapability */
typedef WordFlags SoundDriverWaveFormCapability;
#define SDWFC_NONE     0x0000
#define SDWFC_SELECT   0x2000
#define SDWFC_GENERATE 0x4000


/* SoundDriverTimbreCapability */
typedef WordFlags SoundDriverTimbreCapability;
#define SDTC_TONE_GENERATOR 0x0000
#define SDTC_ADDITIVE       0x0800
#define SDTC_MODULATOR      0x1000
#define SDTC_SELECTIVE      0x1800


/* SoundDriverEnvelopeCapability */
typedef WordFlags SoundDriverEnvelopeCapability;
#define SDEC_NONE      0x0000
#define SDEC_ADSR      0x0200
#define SDEC_DSP       0x0400

/* SoundDriverCapability */
typedef WordFlags SoundDriverCapability;
#define SDC_NOISE      0x8000
#define SDC_WAVEFORM   0x6000
#define SDC_TIMBRE     0x1800
#define SDC_ENVELOPE   0x0600

/*           */
/* Functions */
/*           */

extern void
 _pascal SoundGetExclusive(void);

extern Boolean
 _pascal SoundGetExclusiveNB(void);

extern void
 _pascal SoundReleaseExclusive(void);


/*                      */
/* Basic music routines */
/*                      */

extern word
 _pascal SoundAllocMusic(const word _far *song, word voices,
			 MemHandle _far *control);

extern word
 _pascal SoundPlayMusic(MemHandle mh, word priority, word tempo,
			 EndOfSongFlags flags);

extern word
 _pascal SoundStopMusic(MemHandle mh);

extern word
 _pascal SoundPlayMusicLMem(MemHandle mh, word priority, word tempo,
			    EndOfSongFlags flags);
extern word
 _pascal SoundStopMusicLMem(MemHandle mh);

extern word
 _pascal SoundReallocMusic(MemHandle mh, const word _far *song);

extern word
 _pascal SoundReallocMusicLMem(MemHandle mh, optr song);

extern void
 _pascal SoundFreeMusic(MemHandle mh);

extern void
 _pascal SoundInitMusic(MemHandle mh, word voices);

/*                     */
/* Basic note routines */
/*                     */

extern word
 _pascal SoundAllocMusicNote(InstrumentPatch instrument, word instTable,
			     word frequency, word volume,
			     SoundStreamDeltaTimeType DeltaType, word duration,
			     MemHandle _far *control);

extern word
 _pascal SoundPlayMusicNote(MemHandle mh, SoundPriority priority, word tempo,
			    EndOfSongFlags flags);

extern word
 _pascal SoundStopMusicNote(MemHandle mh);

extern word
 _pascal SoundReallocMusicNote(MemHandle mh, word freq, word vol,
			       SoundStreamDeltaTimeType timer,
			       word durat, InstrumentPatch instrument,
			       word instTable);

extern void
 _pascal SoundFreeMusicNote(MemHandle mh);


/*                             */
/* Basic music stream Routines */
/*                             */

extern word
 _pascal SoundAllocMusicStream(SoundStreamSize streamSize, 
			       SoundPriority priority, word voices,
			       word tempo, MemHandle _far *control);

extern word
 _pascal SoundPlayToMusicStream(MemHandle mh, const word _far *song,
				word size);

extern word
 _pascal SoundPlayToMusicStreamNB(MemHandle mh, const word _far *song,
			          word size, word _far *bytesWritten);

extern word
 _pascal SoundStopMusicStream(MemHandle mh);

extern void
 _pascal SoundFreeMusicStream(MemHandle mh);

/*                        */
/* Sample stream routines */
/*                        */

extern word
 _pascal SoundAllocSampleStream(MemHandle _far *control);

extern word
 _pascal SoundEnableSampleStream(MemHandle mh, SoundPriority priority, 
				 word rate, word manufacturerID, 
				 SampleFormat sampleFormat);

extern void
 _pascal SoundDisableSampleStream(MemHandle mh);


extern word
 _pascal SoundPlayToSampleStream(MemHandle mh, const word _far *sample, 
				 word size, 
				 const SampleFormatDescription _far *format);

extern void
 _pascal SoundFreeSampleStream(MemHandle mh);
 

/*               */
/* Misc commands */
/*               */

extern void
 _pascal SoundChangeOwnerSimple(MemHandle mh, MemHandle owner);

extern void
 _pascal SoundChangeOwnerStream(MemHandle mh, MemHandle owner);


/*                      */
/* Driver Info commands */
/*                      */

extern void
 _pascal SoundSynthDriverInfo(word _far *voices, 
			      SupportedEnvelopeFormat _far *format,
			      SoundDriverCapability  _far *capability);

extern void
 _pascal SoundSampleDriverInfo(word _far *voices,
			       SoundDriverCapability _far *capability);


/*                         */
/*  Voice Manager Routines */
/*                         */

extern word
 _pascal SoundVoiceManagerGetFree(SoundPriority priority);

extern void
 _pascal SoundVoiceManagerFree(word voice);

extern word
 _pascal SoundDACManagerGetFree(SoundPriority priority);

extern void
 _pascal SoundDACManagerFree(word voice);


/*
 *  Volume control functions
 */
extern Boolean
 _pascal SoundMixerGetMasterVolume(word *left, word *right);

extern Boolean
 _pascal SoundMixerSetMasterVolume(word left, word right);



#ifdef __HIGHC__
pragma Alias(SoundGetExclusive, "SOUNDGETEXCLUSIVE");
pragma Alias(SoundGetExclusiveNB, "SOUNDGETEXCLUSIVENB");
pragma Alias(SoundReleaseExclusive, "SOUNDRELEASEEXCLUSIVE");

pragma Alias(SoundAllocMusic, "SOUNDALLOCMUSIC");
pragma Alias(SoundPlayMusic, "SOUNDPLAYMUSIC");
pragma Alias(SoundStopMusic, "SOUNDSTOPMUSIC");
pragma Alias(SoundPlayMusicLMem, "SOUNDPLAYMUSICLMEM");
pragma Alias(SoundStopMusicLMem, "SOUNDSTOPMUSICLMEM");
pragma Alias(SoundReallocMusic, "SOUNDREALLOCMUSIC");
pragma Alias(SoundReallocMusicLMem, "SOUNDREALLOCMUSICLMEM");
pragma Alias(SoundFreeMusic, "SOUNDFREEMUSIC");
pragma Alias(SoundInitMusic, "SOUNDINITMUSIC");

pragma Alias(SoundAllocMusicNote, "SOUNDALLOCMUSICNOTE");
pragma Alias(SoundPlayMusicNote, "SOUNDPLAYMUSICNOTE");
pragma Alias(SoundStopMusicNote, "SOUNDSTOPMUSICNOTE");
pragma Alias(SoundReallocMusicNote, "SOUNDREALLOCMUSICNOTE");
pragma Alias(SoundFreeMusicNote, "SOUNDFREEMUSICNOTE");

pragma Alias(SoundAllocMusicStream, "SOUNDALLOCMUSICSTREAM");
pragma Alias(SoundPlayToMusicStream, "SOUNDPLAYTOMUSICSTREAM");
pragma Alias(SoundPlayToMusicStreamNB, "SOUNDPLAYTOMUSICSTREAMNB");
pragma Alias(SoundStopMusicStream, "SOUNDSTOPMUSICSTREAM");
pragma Alias(SoundFreeMusicStream, "SOUNDFREEMUSICSTREAM");

pragma Alias(SoundAllocSampleStream, "SOUNDALLOCSAMPLESTREAM");
pragma Alias(SoundEnableSampleStream, "SOUNDENABLESAMPLESTREAM");
pragma Alias(SoundDisableSampleStream, "SOUNDDISABLESAMPLESTREAM");
pragma Alias(SoundPlayToSampleStream, "SOUNDPLAYTOSAMPLESTREAM");
pragma Alias(SoundFreeSampleStream, "SOUNDFREESAMPLESTREAM");

pragma Alias(SoundChangeOwnerSimple, "SOUNDCHANGEOWNERSIMPLE");
pragma Alias(SoundChangeOwnerStream, "SOUNDCHANGEOWNERSTREAM");

pragma Alias(SoundSynthDriverInfo, "SOUNDSYNTHDRIVERINFO");
pragma Alias(SoundSampleDriverInfo, "SOUNDSAMPLEDRIVERINFO");

pragma Alias(SoundVoiceManagerGetFree, "SOUNDVOICEMANAGERGETFREE");
pragma Alias(SoundVoiceManagerFree, "SOUNDVOICEMANAGERFREE");
pragma Alias(SoundDACManagerGetFree, "SOUNDDACMANAGERGETFREE");
pragma Alias(SoundDACManagerFree, "SOUNDDACMANAGERFREE");

pragma Alias(SoundMixerGetMasterVolume, "SOUNDMIXERGETMASTERVOLUME");
pragma Alias(SoundMixerSetMasterVolume, "SOUNDMIXERSETMASTERVOLUME");

#endif


#endif

