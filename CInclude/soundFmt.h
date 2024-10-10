/* ------------------------------------------------------------------------ *
 *
 * PROJECT:	PC/GEOS Sound System	
 * MODULE:	Sound Device Driver
 * FILE:	soundFmt.h
 *
 *		C-Version of soundFmt.def (Todd Stumpf, Sep 14, 1992)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	RainerB	09/15/2024	File created
 *
 * DESCRIPTION:
 *	This file contains the structure and record declarations for
 *	the envelope formats supported by the PC/GEOS library.  For
 *	more information look at soundDrv.def or the sound library
 *	itself.
 *
 * ------------------------------------------------------------------------ */

/*-----------------------------------------------------------------------------
 *	Sound Blaster Instrument Description Data Structures
 *-----------------------------------------------------------------------------
 	*
 	*  The timbre setting contains the information to generate
	*  the color of the sound.
	*	TS_AM = amplitude modulation enabled (tremelo affect)
	*	TS_VIB = vimbrato modulation enabled (vibrato affect)
	*       TS_ET = envelope type 0 = diminishing (bell)
	*			      1 = continuing  (organ)
	*	TS_KSR = envelope shortening
	*	TS_MULTIPLE = multiplies basic frequency of mod/car
	*		 0 = x.5	1 = x1		2 = x2
	*		 3 = x3		4 = x4		5 = x5
	*		 6 = x6		7 = x7		8 = x8
	*		 9 = x9		a = x10		b = x10
	*		 c = x12	d = x12		e = x15
	*		 f = x15
	*/
typedef ByteFlags	TimbreSetting;
#define	TS_AM		0x80
#define	TS_VIB		0x40
#define	TS_ET		0x20
#define	TS_KSR		0x10
#define	TS_MULTIPLE	0x0F

#define TS_ET_CONTINUING	0x20	/* Organ */
#define TS_ET_DIMINISHING	0	/* Bell */


/* ------------------------------------------------------------------------ *
	*  The output setting contains information about the volume
	*  of the note.
	*	OS_KSL	= Sets the rate at which higher notes get
	*			there volume diminished.
	*			0 = volume decreases slowly as notes
	*				rise in pitch
	*		  up to	3 = volume descreases rapidly as notes
	*				rise in pitch
	*
	*       OS_TOTAL_LEVEL = The attenuation level of maximum output.
	*		This is an attenuation level, not a volume level,
	* 		so the larger the number, the quieter the voice.
	*		The total level is the value which is reached
	*		at the end of the attack, and the sustain level
	*		is a fraction of the this level.
	*		Carrier total level dictates the amplitude of
	*		the sound, and the modulator output indicates
	*		the amound of warble.
	*/
typedef ByteFlags OutputSetting;
#define	OS_KSL		0xC0
#define	OS_TOTAL_LEVEL  0x3F

#define OS_KSL_OFFSET		6
#define OS_TOTAL_LEVEL_OFFSET	0


/* ------------------------------------------------------------------------ *
	*  The Attack/Decay/Sustain/Release is the standard way of
	*  describing a sound envelope.  The greater the value the
	*  steaper the slant of that section of the envelope
	*/
typedef ByteFlags AttackDecaySetting;
#define	ADS_ATTACK	0xF0
#define	ADS_DECAY	0x0F

#define	ADS_ATTACK_OFFSET	4
#define	ADS_DECAY_OFFSET	0


/* ------------------------------------------------------------------------ *
	*  The sustian value is either the decibel level where a
	*  diminishing sound turns from decay to release or
	*  level of the sound that decay turns into sustain.
	*  Therefore, the higher the value of sustain, the lower
	*  the volume it will sustain at, or the quieter it will
	*  be before it enters the release
	*/
typedef ByteFlags	SustainReleaseSetting;
#define	SRS_SUSTAIN	0xF0
#define	SRS_RELEASE	0x0F

#define	SRS_SUSTAIN_OFFSET	4
#define	SRS_RELEASE_OFFSET	0


/* ------------------------------------------------------------------------ *
	*  The feedback setting describes how the signals of
	*  the two waves (the carrier and the modulator) are
	*  connected.
	*	FBS_FEEDBACK = modulation of modular wave which gets
	*			added to the incoming signal of the
	*			modulator wave.  clear as mud.
	*
	*
	*	FBDS_CONNECTION = 1
	*	-------------------
	*
	*	mod --->(+)----> [modulator] ------>(+)--->[carrier]-->out
	*      freq.	 ^                     |     ^
	*		 |                     |     |
	*		 |_____________________|    car
	*					   freq.
	*
	*
	*	FBDS_CONNECTION = 0
	*	-------------------
	*
	*	mod --->(+)----> [modulator] -----
	*      freq.     ^                    |  |
	*		 |                    |  |
	*		 |____________________|  |
	*					 |
	*					(+)----> out
	*					 |
	*	car -----------> [carrier]--------
	*      freq.
	*/
typedef ByteFlags FeedBackSetting;
#define	FBS_FEEDBACK	0x0E
#define	FBS_CONNECTION	0x01

#define	FBS_FEEDBACK_OFFSET 	1
#define	FBS_CONNECTION_OFFSET 	0

/* ------------------------------------------------------------------------
	*
	*  The Wave select setting determines the form of the signal
	*  that gets generated.
	*
	*   FSS_WAVE 0 = normal sin wave
	*
	*   FSS_WAVE 1 ={ sin(x)    if sin(x) > 0
	*		{   0       if sin(x) < 0
	*
	*   FSS_WAVE 2 = | sin(x) |
	*
	*   FSS_WAVE 3 ={ |sin(x)|  if 0 < x < pi/2 or pi < x < 3pi/2
	*		{  0        otherwise
	*/
typedef ByteFlags WaveSelectSetting;
#define	FSS_WAVE		0x03

#define	FSS_WAVE_OFFSET		0

#define	FSS_WAVE_SINE		0
#define	FSS_WAVE_POS_SINE	1
#define	FSS_WAVE_ABS_SINE	2
#define	FSS_WAVE_1ST_SINE	3


/* ------------------------------------------------------------------------
	*
	*  Creative labs defines what it calls a Sound Blaster Instrument
	*  file.  This is the layout of all the necessary information to
	*  configure a SB voice to sound like a specific instrument.
	*  These constants were taken from the Sound Blaster development
	*  kit.
	*  The actual voice envelope information takes up 11 bytes of
	*  space.  Each byte is just the value that should be loaded into
	*  a specific register of the board.  This makes it very easy
	*  to use for the Sound Blaster, but somewhat obscure.  As each
	*  byte contains much information, the corropsonding register
	*  records are included here to allow the production of your own
	*  voice envelopes.
	*/

typedef struct	{
	TimbreSetting		SBIEF_modTimbre;   /* modulator timbre value */
	TimbreSetting		SBIEF_carTimbre;   /* carrer timbre value */
	OutputSetting		SBIEF_modScaling;  /* modulator scaling cell value */
	OutputSetting		SBIEF_carScaling;  /* carrier scaling cell value */
	AttackDecaySetting	SBIEF_modAttack;   /* modulator attack/decay value */
	AttackDecaySetting	SBIEF_carAttack;   /* carrier attack/decay value */
	SustainReleaseSetting	SBIEF_modSustain;  /*  modulator sustain/release */
	SustainReleaseSetting	SBIEF_carSustain;  /* carrier sustain/release value */
	WaveSelectSetting	SBIEF_modWave;	   /* modulator wave form */
	WaveSelectSetting	SBIEF_carWave;	   /* carrier wave form */
	FeedBackSetting		SBIEF_feedback;	   /* feedback for modulator */
	} SBIEnvelopeFormat;


/*-----------------------------------------------------------------------------
 *		Casio/Tandy Sound Envelope Information
 *-----------------------------------------------------------------------------

	*
	*  Both the FM chip in the Casio Palm-top and the FM chip
	*  in the TANDY 1000 computers are remarkably similar.
	*  Each has three tone generators, with attenuation, and
	*  each has a noise generator.  Neither has internal support
	*  for envelopes, and they both formats for their sounds are
	*  remarkably similar.
	*
	*  In order to get the best sound possible, we will allow
	*  an instrument to define the proportional intensity of the
	*  1st, 2nd and 3rd partials (that is, the intensity of the
	*  base frequency to the specified volume, as well as the
	*  proportion of the 2nd and 3rd harmonics in comparison to
	*  the specified volume.)
	*  This should produce a well colored tone out of the chip
	*  when only one voice is sounding at a time.  The more voices
	*  which get used, however, the more bland the notes will sound.
	*  The intensity of each partial will be determined by first
	*  multiplying the basic volume by the setting, then dividing
	*  the result by the maximum possible setting.
	*
	*  Each instrument is also allowed to specify the type and
	*  intensity of the noise that is to be generated.
	*/

typedef enum byte {
	NT_NO_NOISE = 0,
	NT_WHITE_NOISE,				/* cymbal crash  */
	NT_METAL_NOISE,				/* snare drum hit  */	
	}NoiseType;

typedef ByteFlags	NoiseSetting;
#define	NS_type			0xC0		/* metal type */
#define	NS_partialLevel		0x3F		/* fraction for metal level */

#define NS_TYPE_OFFSET		6
#define NS_PATIAL_LEVEL_OFFSET	0
	
typedef struct {
	byte 		CTIEF_fundamental;	/* fraction for primary */
	byte 		CTIEF_secondPartial;	/* fraction for 2nd intensity */
	byte 		CTIEF_thirdPartial;	/* fraction for 3rd intensity */
	NoiseSetting	CTIEF_noise;		/* intensity of noise */
	} CTIEnvelopeFormat;


/*-----------------------------------------------------------------------------
 *		Sound Driver Envelope Structure
 *-----------------------------------------------------------------------------

	*
	*  Each hardware device has its own capabilities. It does little
	*  good to tell a device driver to set itself up with too little or
	*  too much information about the sound envelope.  Therefore, there
	*  are multiple formats that can be passed to and from the sound
	*  device.  A device should always try to do the best it can, but
	*  don't expect great things out of a device if you don't give it
	*  the information it wants.
	*/
	
typedef word	SupportedInstrumentFormat;
#define	SEF_NO_FORMAT		0
#define	SEF_SBI_FORMAT		1
#define	SEF_CTI_FORMAT		2





