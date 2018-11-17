COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Perf (Performance Meter)
FILE:		perf.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony, Adam 1990		Initial version
	Eric			Extensions, doc update, cleanup

DESCRIPTION:
	This file source code for the Perf application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: perf.asm,v 1.1 97/04/04 16:26:57 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include object.def
include	graphics.def
include gstring.def
include	win.def
include lmem.def
include localize.def
include input.def
include initfile.def
include vm.def
include dbase.def
include timer.def
include timedate.def
include system.def
include font.def

;necessary?

include Objects/inputC.def
include Objects/winC.def

;Not-So-Standard definitions/inclusions

include sysstats.def			;for SysStats, etc.
include driver.def			;for GeodeInfoDriver
include thread.def			;for ThreadModify, etc.

include Internal/heapInt.def		;for SGIT_HANDLE_TABLE_SEGMENT, etc.
include Internal/geodeStr.def		;for GeodeForEach


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def	;for help dialog box
UseLib	Objects/colorC.def	;for ColorSelector

;Not-So-Standard definitions/inclusions

UseLib Internal/swap.def	;Swap Library, for SwapMap structure
UseDriver Internal/swapDr.def	;Interface for Swap Drivers,
				;	for determining swap space
include Internal/socketDr.def   ; for PPP driver spec functions

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

UPDATE_ICON		= TRUE	;this code is busted for now. See Jim
				;about GrDestroyState.

;Don't forget to change this when adding a statistic!
NUM_STAT_TYPES		= 14

;These margins reflect empty space outside of all of the graphs, captions,
;and values.

TOP_MARGIN		= 0
BOTTOM_MARGIN		= 0
LEFT_MARGIN		= 0
RIGHT_MARGIN		= 0

;this is the horizontal spacing between graphs

GRAPH_SPACING		= 2

;the width and height of a graph

GRAPH_WIDTH		= 50
GRAPH_HEIGHT		= 25

;height for caption text (when displayed)

CAPTION_HEIGHT		= 10		;height of caption text

;extra margin for values (when displayed below graph)

EXTRA_MARGIN_FOR_VALUES_BELOW_GRAPH = 12

;if the value is drawn inside the graph, use these offsets

VALUE_TEXT_X_INSET	= 6
VALUE_TEXT_Y_INSET	= 2

;if the value is drawn below the graph, use the above offsets, then
;add this extra offset to move below the graph

VALUE_TEXT_Y_INSET_WHEN_BELOW_GRAPH = GRAPH_HEIGHT-VALUE_TEXT_Y_INSET-1

;misc

VALUE_TEXT_POINT_SIZE	equ	12

CAPTION_TEXT_POINT_SIZE	equ	11

MONIKER_GSTRING_BLOCK_SIZE	= 768

;maximum size of all graphs, captions, values, and margins

MAX_DOC_WIDTH		= LEFT_MARGIN + GRAPH_WIDTH*NUM_STAT_TYPES + GRAPH_SPACING*(NUM_STAT_TYPES-1) + RIGHT_MARGIN
MAX_DOC_HEIGHT		= TOP_MARGIN + CAPTION_HEIGHT + GRAPH_HEIGHT + EXTRA_MARGIN_FOR_VALUES_BELOW_GRAPH + BOTTOM_MARGIN

OVERALL_BACKGROUND_COLOR	= C_WHITE	;whether in color or B&W mode

BW_GRAPH_BACKGROUND_COLOR	= C_WHITE	;these are only used in B&W mode
BW_GRAPH_FOREGROUND_COLOR	= C_BLACK

;constants for icon

ICON_WIDTH	= GRAPH_WIDTH
ICON_HEIGHT	= GRAPH_HEIGHT

;number of points of info we should keep track of

NUM_POINTS		= GRAPH_WIDTH+1

;misc stuff

PERF_ERROR						enum FatalErrors
PERF_ERROR_BAD_UI_ARGUMENTS				enum FatalErrors
PERF_ERROR_IDLE_COUNT_TOO_BIG				enum FatalErrors
PERF_ERROR_REACHED_END_OF_HEAP_WITHOUT_FINDING_MEMORY_BLOCK enum FatalErrors
PERF_ERROR_PERCENTAGE_VALUE_TOO_HIGH			enum FatalErrors
HANDLE_TRASHED_BUMMER_DUDE_GAME_OVER			enum FatalErrors

;Quietly stolen from Driver/Socket/PPP/ppp.def

PPPIDDriverFunction	etype	word, SOCKET_DR_FIRST_SPEC_FUNC, 2
PPP_ID_GET_BAUD_RATE	enum	PPPIDDriverFunction
PPP_ID_GET_BYTES_SENT	enum	PPPIDDriverFunction
PPP_ID_GET_BYTES_RECEIVED	enum	PPPIDDriverFunction
PPP_ID_REGISTER		enum	PPPIDDriverFunction
PPP_ID_UNREGISTER	enum	PPPIDDriverFunction
PPP_ID_FORCE_DISCONNECT	enum	PPPIDDriverFunction


;------------------------------------------------------------------------------
;			Records and Structures
;------------------------------------------------------------------------------
;This enumerated type is used to 1) indicate which chart we are drawing,
;and 2) index into PerfStatStruc, which is defined below.

StatType 		etype word, 0, 2
ST_CPU_USAGE		enum StatType	;DO NOT change this order!
ST_LOAD_AVERAGE 	enum StatType
ST_INTERRUPTS		enum StatType
ST_CONTEXT_SWITCHES 	enum StatType
ST_HEAP_ALLOCATED	enum StatType
ST_HEAP_FIXED		enum StatType
ST_HEAP_FRAGMENTATION	enum StatType
ST_SWAP_MEM_ALLOCATED	enum StatType
ST_SWAP_FILE_ALLOCATED	enum StatType
ST_SWAP_OUT		enum StatType
ST_SWAP_IN		enum StatType
ST_PPP_IN		enum StatType
ST_PPP_OUT		enum StatType
ST_HANDLES_FREE		enum StatType
ST_AFTER_LAST_STAT_TYPE	enum StatType	;THIS MUST BE LAST

;IMPORTANT: the order of these bitfields MUST match the order of the
;enumerated type above.

StatTypeMask		record
    STM_CPU_USAGE:1
    STM_LOAD_AVERAGE:1
    STM_INTERRUPTS:1
    STM_CONTEXT_SWITCHES:1
    STM_HEAP_ALLOCATED:1
    STM_HEAP_FIXED:1
    STM_HEAP_FRAGMENTATION:1
    STM_SWAP_MEM_ALLOCATED:1
    STM_SWAP_FILE_ALLOCATED:1
    STM_SWAP_OUT:1
    STM_SWAP_IN:1
    STM_PPP_IN:1
    STM_PPP_OUT:1
    STM_HANDLES_FREE:1
    :2
StatTypeMask		end

;Display options (see "displayOptions" variable, below)

PerfDisplayOptions	record
	PDO_SHOW_GRAPHS:1	;TRUE to show graph
	PDO_SHOW_VALUES:1	;TRUE to show numeric values
	PDO_SHOW_CAPTIONS:1	;TRUE to show captions
	PDO_BAR_CHART:1		;TRUE to show bar chart instead of line chart
	:4
PerfDisplayOptions	end

;This structure defines how we store the adjusted system statistic values.
;We create an array of these structures to keep a historical record of values.

PerfStatStruc	struc
    PSS_cpuUsage		word	;DO NOT change this order!
    PSS_load			word
    PSS_interrupts		word
    PSS_switches		word
    PSS_heapAllocated		word
    PSS_heapFixed		word
    PSS_heapFragmentation	word
    PSS_swapMemAllocated	word
    PSS_swapFileAllocated	word
    PSS_swapOut			word
    PSS_swapIn			word
    PSS_pppIn			word
    PSS_pppOut			word
    PSS_handlesFree		word
PerfStatStruc	ends

PerfSwapDriver	struc
    PSD_map	sptr.SwapMap	; Pointer to map of allocated swap space
    PSD_disk	word		; TRUE if driver is "disk".
				; XXX: should get speed/flags back from
				; DR_SWAP_GET_MAP and use that...
PerfSwapDriver	ends

MAX_SWAP_DRIVERS	equ	5


;------------------------------------------------------------------------------
;			PerfProcessClass
;------------------------------------------------------------------------------

;This class is used for this application's Process object.

PerfProcessClass	class	GenProcessClass

MSG_PERF_SET_ON_OFF_STATE			message

;This message is sent by the "On/Off" GenList, which the user changes it.

MSG_PERF_TIMER_EXPIRED		message

;This message is sent to this object every time the timer expires.

MSG_PERF_SET_GRAPH_MODE		message

;This message is sent by our "Performance Meters" GenList, when the user
;enables or disables one of the performance meters.
;Pass:
;	cx	= StatType

MSG_PERF_SET_DISPLAY_OPTIONS		message

;This message is sent by our "Display Options" GenList, when the user
;makes a change.
;Pass:
;	cx	= PerfDisplayOptions mask

MSG_PERF_SET_VALUE_LOCATION		message

;This message is sent by our "Place Values" GenList, when the user makes
;a change.
;Pass:
;	cx	= TRUE or FALSE

MSG_PERF_SET_UPDATE_RATE		message

;This message is sent from the "Update Rate" GenRange object.
;Pass:
;	cx	= new update rate (updates per second)


;nuked for new 2.0 UI arrangement
;MSG_PERF_HIDE_CONTROLS		message
;
;This message is sent from the UI when the user clicks on "Hide Controls".

MSG_PERF_DISPLAY_CPU_SPEED		message

;This message is sent from the UI when the user clicks on "CPU Speed".

MSG_PERF_SIZE_VIEW_ACCORDING_TO_GRAPHS	message

PerfProcessClass	endc


;------------------------------------------------------------------------------
;			PerfProcessClass
;------------------------------------------------------------------------------
;This class is created to get around a deficiency in the V1.1X UI API,
;where you cannot easily update the moniker for an application's icon.
;
;HackPrimaryClass	class	GenPrimaryClass
;
;MSG_HACK_PRIMARY_COPY_MONIKER_TO_ICON_PLEASE		message
;MSG_HACK_PRIMARY_COPY_MONIKER_TO_CAPTION_PLEASE	message
;
;HackPrimaryClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		perf.rdef

;this resource contains our text strings which must be localizable,
;and are not directly part of the UI.

PerfProcStrings	segment	lmem
PerfProcStrings	ends


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	PerfProcessClass	mask CLASSF_NEVER_SAVED

;	HackPrimaryClass

;------------------------------------------------------------------------------
;			Application State Data
;
;All of the following variables are saved to the application's state file.
;------------------------------------------------------------------------------

StartStateData	label	byte	;beginning of application state data

;On/Off state:

onOffState	BooleanWord	TRUE	;ON by default

;This table indicates whether we want to draw each type of chart. This seems
;wasteful (16 bits per flag), but it saves code bytes. IF YOU CHANGE THIS
;TABLE, CHANGE THE .UI FILE ALSO!

graphModes	PerfStatStruc	<
		TRUE,		;CPU Usage	= ON
		TRUE,		;Load Average
		TRUE,		;Interrupts
		TRUE,		;Context Switches
		TRUE,		;HeapAllocated
		TRUE,		;HeapFixed
		TRUE,		;HeapFragmentation
		TRUE,		;SwapMemAllocated
		TRUE,		;SwapFileAllocated
		TRUE,		;SwapOut
		TRUE,   	;SwapIn
		FALSE,		;PPPIn
		FALSE,		;PPPOut
		FALSE		;Free Handles
>

;This is the initial color set, before the color user gets to change the
;color set. When he does, we will update both this list and the graphColors
;variable.

InitialGraphColors	PerfStatStruc <
			C_YELLOW,
			C_CYAN,
			C_RED,
			C_VIOLET,
			C_GREEN,
			C_LIGHT_GRAY,
			C_LIGHT_BLUE,
			C_LIGHT_GREEN,
			C_LIGHT_CYAN,
			C_LIGHT_RED,
			C_LIGHT_VIOLET,
			C_GREEN,
			C_RED,
			C_LIGHT_GRAY
>

;This is the color table that is actually used to draw to the screen.
;When restarting or launching on a B&W screen, this table is washed.

graphColors	PerfStatStruc <>

;Color survey:
;	bad	BLACK
;	bad	DK_BLUE
;		DK_GREEN
;		DK_CYAN
;		DK_RED
;		DK_VIOLET
;	eh	BROWN		too close to DK_RED
;		LT_GRAY
;	bad	DK_GRAY
;		LT_BLUE
;		LT_GREEN
;		LT_CYAN
;	bright	LT_RED
;		LT_VIOLET
;		YELLOW
;	bad	WHITE

currentGraph	word	ST_CPU_USAGE

				;current graph, for setting colors

displayOptions	PerfDisplayOptions <
		1,		;PDO_SHOW_GRAPHS
		1,		;PDO_SHOW_VALUES
		1,		;PDO_SHOW_CAPTIONS
		0,		;PDO_VERTICAL
		0,		;PDO_BAR_CHART
		0,0,0		;unused
>

;placeValuesBelow byte TRUE	;by default, place values below graph

updateRate	byte	1	;1 update per second, by default

EndStateData	label	byte	;beginning of application state data

;------------------------------------------------------------------------------
;			Other IDATA variables
;------------------------------------------------------------------------------

redrawCaptions	byte	1	;when non-zero, we draw the captions,
				;and decrement this counter.

timerHandle	word	0	;handle of timer which drives our updates
timerID		word	0	;and its ID

;This structure holds the raw system statistics (only those that we care about),
;for the last second. We must initialize to -1, so that the "oldNumericLast"
;variable get properly initialized, the first time that we copy from this
;variable to that one.

;Why is this assert here?
.assert (size PerfStatStruc eq NUM_STAT_TYPES*2)

numericLast	PerfStatStruc <
			-1,	;PSS_cpuUsage
			-1,	;PSS_load
			-1,	;PSS_interrupts
			-1,	;PSS_switches
			-1,	;PSS_heapAllocated
			-1,	;PSS_heapFixed
			-1,	;PSS_heapFragmentation
			-1,	;PSS_swapMemAllocated
			-1,	;PSS_swapFileAllocated
			-1,	;PSS_swapOut
			-1,	;PSS_swapIn
			-1,	;PSS_pppIn
			-1,	;PSS_pppOut
			-1	;PSS_handlesFree
		>

;These variables provide access to the PPP driver for the modules that monitor
;dialup activity.
pppDr		word    0   ; handle of PPP driver
pppStrategy	fptr    0   ; pointer to PPP strategy routine

idata	ends

;---------------------------------------------------

udata	segment

oldNumericLast	PerfStatStruc <> ;a historical copy of the numericLast variable.

curNumGraphs	byte		;current number of graphs

bwMode		byte		;will be set TRUE if in B&W mode
lineColor	word		;color for chart lines
valueColor	word		;color for values
captionColor	word		;color for captions

graphXPositions	PerfStatStruc <> ;table of graph X positions. Used to resolve
				 ;which graph the mouse is clicking on.

viewWindow	word		;handle of the window in the GenView.

viewWinGState	word		;handle of GState to use to draw into
				;the GenView window. This is set to null
				;when the application is iconified.
				;That is how we know to draw to the icon
				;instead.

lmemChunkForGString	optr	;OD of chunk which we draw GString into,
				;when the app is iconified.

;these variables are used while calculating the statistics

totalCountDivBy1000 word	;this is the value kdata:totalCount
				;divided by 1000 to make the number managable.
				;(totalCount is what kdata:idleCount would
				;be if the system were 100% idle.)

tonyIndexTimes10 word

;This structure holds the raw system statistics (all which are supplied)
;from the last second:

lastStats	SysStats <>	;Raw values from the system last time

;This array of structures holds the system statistics that we must chart.
;statArray[0]		 = most current
;statArray[NUM_POINTS-1] = oldest

statArray	PerfStatStruc	NUM_POINTS dup (<>)

;stuff for memory statistics

;kernelSize	word		;total size of kernel code and data in para.

handleStart 	fptr		;First handle in handle table
handleEnd	word		;Offset of last handle + 1 in handle table

;heapSemOffset		word	;offset of heapSem in kdata

heapTotalMemBlocks	word
heapTotalMemSize	word

heapAllocatedMemBlocks	word
heapAllocatedMemSize	word

heapFixedMemBlocks	word
heapFixedMemSize	word

heapUpperMemBlocks	word	;portion of heap which lies above the "boundary
heapUpperMemSize	word	;block", which is one or more free blocks
				;inbetween the highest FIXED block and the
				;lowest MOVABLE block.

heapUpperFreeMemBlocks	word	;free blocks which are in the "Upper" heap
heapUpperFreeMemSize	word	;area. See definition above.

heapUpperScanActive	byte	;TRUE when we are scanning the upper area.
				;set FALSE when we find a block with a segment
				;address below heapUpperScanStartSeg.

heapUpperScanStartSeg	word	;if we have begun scanning the upper area,
				;this is the segment of the MOVABLE block
				;which begins the upper area.

;for swapping statistics, we keep an array of these structures:

;PerfSwapDriver	struc
;   PSD_map	sptr.SwapMap	; Pointer to map of allocated swap space
;   PSD_disk	word		; TRUE if driver is "disk".
;				; XXX: should get speed/flags back from
;				; DR_SWAP_GET_MAP and use that...
;PerfSwapDriver	ends

swapMaps	PerfSwapDriver MAX_SWAP_DRIVERS dup(<>)

maxMemSwap	word		;max Kb of memory swap available
maxDiskSwap	word		;max Kb of disk swap available

;when the PerfProcStrings resource is locked, this variable contains
;the segment for it:

procStringsSeg	word

;for PPP statistics, we keep the total byte counts.
pppBytesSent	 dword
pppBytesReceived dword

;for Handles statistics

handlesPerPixel	word

udata	ends


;------------------------------------------------------------------------------
;			Code Files
;------------------------------------------------------------------------------

include fixedCommonCode.asm	;a FIXED resource for CommonCode (actually
				;is part of DGROUP).
include	init.asm		;obscure init/exit code.
include	calc.asm		;code for calculating stats
include draw.asm		;code for drawing to view or icon
include user.asm		;code for handling user input

end
