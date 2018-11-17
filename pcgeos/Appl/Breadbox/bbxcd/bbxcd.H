/************************************************
 *						*
 *	project:	BSW-CD			*
 *	module:		MAIN\bbxcd.GOC		*
 *						*
 *      definitions of all global variables     *
 *						*
 ************************************************/


#ifndef __bbxcd_H
#define __bbxcd_H

/*********************
	Deklarationen
 *********************/

typedef char flag;
#define TRUE  (~0)
#define FALSE 0

//La 16.02.97
#define	TDL_1			1	//tracks
#define	TDL_2			2	//remaining tracks
#define	TTL_1		        1	//track  time
#define	TTL_2			2	//remaining track time
#define	DTL_1			1	//disc time
#define	DTL_2			2	//remaining disc time

#define	SBG_ANIMATION		1	// SymbolBooleanGroup
#define	SBG_TRACK		2	// La 11.02.97
#define	SBG_TIME		4
#define	SBG_DEFAULT		SBG_ANIMATION+SBG_TRACK+SBG_TIME

#define FBG_GADGETS		7
#define FBG_ANIMATION		1	/* FlagBooleanGroup-Flags */
#define FBG_AUTOSTART		2
#define FBG_LAYER		4
#define FBG_GLOBAL		8
#define FBG_SETUP		16
#define FBG_SEEK		32
#define FBG_NO_UPC		64
#define	FBG_NO_UPC_NAME		128
#define	FBG_USE_DATABASE	0x0100
#define	FBG_VOLUME		0x0200
#define FBG_DEFAULT		FBG_ANIMATION + FBG_USE_DATABASE + FBG_VOLUME

#define MIG_GADGETS		3
#define MIG_NORMAL		1	/* ModusItemGroup-Flags */
#define MIG_RANDOM		2
#define MIG_PROGRAM		3
#define MIG_DEFAULT		MIG_NORMAL

#define DIG_GADGETS		8
#define DIG_DRIVE1		1	/* DiscItemGroup */
#define DIG_DRIVE2       	2
#define DIG_DRIVE3       	3
#define DIG_DRIVE4       	4
#define DIG_DRIVE5              5
#define DIG_DRIVE6       	6
#define DIG_DRIVE7       	7
#define DIG_DRIVE8       	8

#define PRIM_MIN		1	/* primaryModus */
#define PRIM_MAX		2
#define PRIM_DEFAULT		PRIM_MAX

#define SHUFFLE_OFF		1
#define SHUFFLE_ON		2
#define PROGRAM_OFF		1
#define PROGRAM_ON		2

#define REPEAT_GADGETS          4
#define REPEAT_OFF		1
#define REPEAT_SINGLE		2
#define REPEAT_ON		3
#define REPEAT_AB		4

#define TRACK_INVALID		0
#define TRACK_AUDIO		1
#define TRACK_DATA		2

#define ABA_AUTO		1		//ABS-Boolean-Auto 07.03.97
#define ABA_DEFAULT		ABA_AUTO

#define MAX_DRIVES		8		//La 07.03.97

#define ERR_MSG_CREDITS         0               // error messages for ErrorSound
#define ERR_MSG_DEMO_MODE       1
#define ERR_MSG_DUMMY           2
#define ERR_MSG_NO_TITLE        3
#define ERR_MSG_NO_DISC         4
#define ERR_MSG_GENERAL_ERROR   5
#define ERR_MSG_NO_AUDIO_CD     6

#define	MaxTracks 25	// maximum number of supported tracks (always 25)

typedef struct{ char    cd_UPC[15];                // UPC-Code der CD
                char    cd_NAME[32];               // Name der CD
                byte    tracksToPlay[MaxTracks+1]; //TTP-Liste
                byte    validTracks[MaxTracks+1];  //VT-Liste
                byte    programTracks[MaxTracks+1];//P-Liste
                char    trackName[MaxTracks+1][32];//Tracknames
                word    volume;                    // volume setting
                word    balance;                   // balance setting
                word    repeatMode;                // repeat mode
                word    programMode;               // programMode
                word	displayMode;               // min display type
                word	dispTrack;                 // track ddisplay mode
                word	dispTTime;                 // track time display mode
                word	dispDTime;                 // disc time display mode
                long    abStart;                   // AB value A (Track)
                long    abTStart;                  // AB value A (Disc)
                long    abEnd;                     // AB value B (Track)
                long    abTEnd;                    // AB value B (Disc)
              } DatabaseEntry;


/*************************
	globale Variable
 *************************/

extern DatabaseEntry    dbEntry;
                        // contains all information/data about a specific CD
//extern char		applicationTitle[];
			// contains the program title for the title bar
extern char             globalText[];
                        // a global copy buffer [32] for local text contents
extern char             dbName[];   //name of database file
extern char             dbHeader[];
                        // text header for database file
extern MemHandle	bcTimeHandle;
extern WindowHandle	winHan;

extern flag             startPhase;
                        // set on startup and reset by first timer action
extern word		bcTimerID;
extern char 		trackInfoText[];
extern char 		symbolText[];
			// textstrings for track- + timedisplay

#define 		tracksToPlay dbEntry.tracksToPlay
			// array with flags for all tracks
			// (0=do not play/already played, 1=still to play)
#define 		validTracks dbEntry.validTracks
			// array for tracks (0= play never, 1= play)
#define                 programTracks dbEntry.programTracks
			// array of the programmed titles (0 = no more tracks to play)
extern char		programCounter;
			// index for the program list
extern flag		isPlaying;
			// Flag: 0= CD is not running, 1=CD is running
extern byte		currentTrack;
			// aktual playing track
extern long		currentDiscTime;
			// actual disc time, updated every second or
                        // 1/8 sec in the last 2 seconds of a track
#define                 displayMode dbEntry.displayMode
			// 0= Track + Track Time
			// 1= Track + Track Time left
			// 2= Track + CD Time
			// 3= Tracks left + CD time left
#define                 dispTrack dbEntry.dispTrack
#define                 dispTTime dbEntry.dispTTime
#define		        dispDTime dbEntry.dispDTime
#define 		programMode dbEntry.programMode
			// 1= normal, 2= shuffle, 3= program
#define                 repeatMode dbEntry.repeatMode
			// 1= no repeat, 2= repeat one, 3=repeat all, 4=repeat A>B
extern flag		pauseState;		// indicates paused play


extern byte 		volume;
extern word		optionFlags;	// animation, autostart,
extern word		primaryModus;	// MIN/MAX
extern word		symbolOptionFlags;	//(La 11.02.97)

extern char		trackText[];
extern char		titleTimeText[];
extern char		titleRemText[];
extern char		discTimeText[];
extern char		discRemText[];
extern char		trackRemText[];

extern flag		busyFlag;               // flag for timer overflow

extern char		calendarFrame[];	// colors for Borders
extern char		calendarString[];	// colors for track text

extern word		backGroundColor;	// background color for GenView
						// 0 = MIN/MAX black

#define        		abStart dbEntry.abStart
#define        		abTStart dbEntry.abTStart
#define        		abEnd dbEntry.abEnd
#define        		abTEnd dbEntry.abTEnd

extern word		drivenum;               // actual drive number
extern word		driveMax;		// number of drives (La 05.03.97)
extern word		autoRepeatAB;		// automat. repeat A>B (La 07.03.97)

extern word		random;			// counter for random number

extern word		oldRepeatMode;
extern word             balance;        	// (La 19.03.97)

extern flag             searching;              // flag for search mode
extern flag             searchDirection;        // flag for search direction

extern byte             defaultMessage;         // default error/status message

extern byte             scanMode;               // flag + time counter fuer music scan

extern flag             noInterrupt;            // flag for blocking while drive change

extern word             dbEditNumber;           // actual selected item in editor


extern GeodeToken       mixerToken;             // mixer token name and number
extern char             mixerGeodeName[];       // mixer geode name

extern word             dialogWindow;           // flag for displaying dialog windows

extern char             indexText[];            // contains the track index

extern char		trackTimeCount;		// verz”gerte ShowTrackTime-Ausl”sung

#endif


