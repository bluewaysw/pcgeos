##############################################################################
#
#       Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:     PC GEOS Sound System
# FILE:        sound.gp
#
# AUTHOR:      Todd Stumpf
#
#
#       $Id: sound.gp,v 1.1 97/04/07 10:46:23 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name	sound.lib
#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type library, driver, single

#
# Define the library entry point
#
entry	SoundEntry

#
# Import definitions from the kernel
#
library geos
#library	ui noload
driver  stream

#
# Desktop-related things
#

longname        "Sound Library"
tokenchars      "SNDL"
tokenid         0

#
nosort
resource ResidentCode 		fixed code read-only
resource CommonCode		code read-only shared
resource InitCode		code read-only shared
resource C_Common		code read-only shared
resource FMCode		code read-only shared
resource DACCode		code read-only shared
#
# Specify alternate resource flags for anything non-standard
#

export	SoundGetExclusive
export	SoundGetExclusiveNB
export	SoundReleaseExclusive

export	SoundAllocMusic
export  SoundPlayMusic
export	SoundStopMusic
export	SoundReallocMusic
export	SoundFreeMusic
export  SoundInitMusic

export  SoundAllocMusicNote
export	SoundPlayMusic as SoundPlayMusicNote
export	SoundStopMusic as SoundStopMusicNote
export	SoundReallocMusicNote
export	SoundFreeMusic as SoundFreeMusicNote

export	SoundAllocMusicStream
export	SoundStopMusicStream
export	SoundFreeMusicStream
export  SoundPlayToMusicStream

export  SoundChangeOwnerMusic
export	SoundChangeOwnerStream

export	SoundAllocSampleStream
export	SoundFreeSampleStream
export	SoundPlayToSampleStream
export	SoundEnableSampleStream
export	SoundDisableSampleStream

export	SoundVoiceGetFreeFar as SoundVoiceManagerGetFree
export	SoundVoiceFreeFar as SoundVoiceManagerFree
export	SoundVoiceActivateFar as SoundVoiceManagerActivate
export	SoundVoiceDeactivateFar as SoundVoiceManagerDeactivate
export	SoundVoiceAssignFar as SoundVoiceManagerAssign

export	SoundDACGetFree as SoundDACManagerGetFree
export	SoundDACFree as SoundDACManagerFree
export	SoundDACActivate as SoundDACManagerActivate
export	SoundDACDeactivate as SoundDACManagerDeactivate
export	SoundDACAssign as SoundDACManagerAssign

export	SoundSynthDriverInfo
export	SoundSampleDriverInfo

#
# C-stubs for sound
#

export	SOUNDGETEXCLUSIVE
export	SOUNDGETEXCLUSIVENB
export	SOUNDRELEASEEXCLUSIVE

export	SOUNDALLOCMUSIC
export	SOUNDPLAYMUSIC
export	SOUNDSTOPMUSIC
export	SOUNDREALLOCMUSIC
export	SOUNDFREEMUSIC

export	SOUNDALLOCMUSICNOTE
export	SOUNDPLAYMUSICNOTE
export	SOUNDSTOPMUSICNOTE
export	SOUNDREALLOCMUSICNOTE
export	SOUNDFREEMUSICNOTE

export	SOUNDALLOCMUSICSTREAM
export	SOUNDPLAYTOMUSICSTREAM
export	SOUNDSTOPMUSICSTREAM
export	SOUNDFREEMUSICSTREAM

export	SOUNDALLOCSAMPLESTREAM
export	SOUNDPLAYTOSAMPLESTREAM
export	SOUNDENABLESAMPLESTREAM
export  SOUNDDISABLESAMPLESTREAM
export	SOUNDFREESAMPLESTREAM

export	SOUNDCHANGEOWNERSTREAM
export	SOUNDCHANGEOWNERSIMPLE

export	SOUNDINITMUSIC

export	SOUNDSYNTHDRIVERINFO
export	SOUNDSAMPLEDRIVERINFO

export	SOUNDVOICEMANAGERGETFREE
export	SOUNDVOICEMANAGERFREE
skip 3

export	SOUNDDACMANAGERGETFREE
export	SOUNDDACMANAGERFREE
skip 3

#
# Old routine names 
#

export	SoundAllocMusic as SoundAllocSimple
export  SoundPlayMusic as SoundPlaySimple
export	SoundStopMusic as SoundStopSimple
export	SoundReallocMusic as SoundReallocSimple
export	SoundFreeMusic as SoundFreeSimple
export  SoundInitMusic as SoundInitSimple

export	SoundAllocMusic as SoundAllocSimpleFM
export  SoundPlayMusic as SoundPlaySimpleFM
export	SoundStopMusic as SoundStopSimpleFM
export	SoundReallocMusic as SoundReallocSimpleFM
export	SoundFreeMusic as SoundFreeSimpleFM
export  SoundInitMusic as SoundInitSimpleFM

export  SoundAllocMusicNote as SoundAllocNote
export	SoundPlayMusic as SoundPlayNote
export	SoundStopMusic as SoundStopNote
export	SoundReallocMusicNote as SoundReallocNote
export	SoundFreeMusic as SoundFreeNote

export	SoundChangeOwnerMusic as SoundChangeOwner
export	SoundChangeOwnerMusic as SoundChangeOwnerSimple

	incminor
#
#	  This incminor is for the 2.01 release which included one
#	  small bug fix.  When SoundLibDriverInitSimpleFM is called,
#	  the handles that are allocated for the SoundControl block
#	  are owned by the same owner of the initialized block,
#	  instead of by the calling thread.  This allows the UI
#	  to execute SST_CUSTOM_BUFFERS correctly.
#					-- todd 12/29/93

#
# ** Sound Extensions Project Routines **
#
	incminor

export	SoundPlayMusicLMem
export	SoundStopMusic as SoundStopMusicLMem
export  SoundPlayToMusicStreamNB

#
# C Stubs
#
export	SOUNDPLAYMUSICLMEM
export	SOUNDSTOPMUSICLMEM
export	SOUNDPLAYTOMUSICSTREAMNB

#
# ** Additional routine to reset the optr of an LMem SoundControl
#

incminor

export	SoundReallocMusicLMem
export	SOUNDREALLOCMUSICLMEM

#
# XIP-enabled
#

#
#  The addition of Volume/Mixer control into the library
incminor

export	SoundMixerGetMasterVolume
export	SoundMixerSetMasterVolume

export	SoundMixerGetSourceCount 
export	SoundMixerMapSource   
export	SoundMixerGetSourceVolume
export	SoundMixerSetSourceVolume

export	SoundMixerGetEffectCount
export	SoundMixerMapEffect     
export	SoundMixerGetEffectLevel
export	SoundMixerSetEffectLevel

export	SOUNDMIXERGETMASTERVOLUME
export	SOUNDMIXERSETMASTERVOLUME
#export	SOUNDMIXERGETSOURCECOUNT
#export	SOUNDMIXERGETMAPSOURCE
#export	SOUNDMIXERGETSOURCEVOLUME
#export	SOUNDMIXERSETSOURCEVOLUME
#export	SOUNDMIXERGETEFFECTSCOUNT
#export	SOUNDMIXERMAPEFFECTS
#export	SOUNDMIXERGETEFFECTSLEVEL
#export	SOUNDMIXERSETEFFECTSLEVEL


