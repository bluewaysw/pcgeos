##############################################################################
#
#       Copyright (c) 1998 New Deal, Inc -- All Rights Reserved
#
# PROJECT:      LEGOS
# MODULE:       Component Object Library -- Sound
# FILE:         song.gp
#
# AUTHOR:       Martin Turon, Oct. 19, 1999
#
#
#       $Id: song.gp,v 1.1 98/05/13 15:07:17 martin Exp $
#
##############################################################################
#
# Specifiy this library's permanent name, long name, 
# token charaters, and type
#
name            coolsong.lib
longname        "Song Components Library"
tokenchars      "CoOL"
type            library, single
#
# Define library entry point
#
#entry  FileCompLibraryEntry

library geos
library ent
library wav
library sound
library shell
library basrun
library gadget

#
# Define resources other than standard discardable code
#
#
# Exported routines (and classes)
#

export CoolSongLibraryClassTable
export WaveComponentClass       
export SynthComponentClass      



