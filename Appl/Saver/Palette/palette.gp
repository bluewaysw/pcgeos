# Parameters for specific screen saver library
# $Id: palette.gp,v 1.1 97/04/04 16:46:29 newdeal Exp $
#
# Permanent name
#
name palette.lib
#
# All specific screen savers are libraries that may be launched but once
#
type appl, process
#
# This is the name that appears in the generic saver's list
# Palette Animator
# Palette Basher
# Palette Cycler
# Palette Masher
# Palette Thrasher
# Palette Whacker
#
longname "Palette Basher"
#
# All specific screen savers have a token of SSAV, and for now they must have
# our manufacturer's ID (until the file selector can be told to ignore the
# ID)
#
tokenchars "SSAV"
tokenid 0
#
# We use the saver library, of course.
#
library saver
#
# We must import the UI so our options block can be properly relocated, the
# relocations happening w.r.t. our imported libraries (we own the block) even
# though it's being duplicated on the generic saver's thread.
#
library ui
#
# The need for this is self-evident...
#
library geos
class PaletteProcessClass
appobj PaletteApp
export PaletteApplicationClass
