# Parameters for specific screen saver library
# $Id: lastwords.gp,v 1.1 97/04/04 16:48:32 newdeal Exp $
#
# Permanent name
#
name lastword.lib
#
# All specific screen savers are libraries that may be launched but once
#
type library, single
#
# This is the name that appears in the generic saver's list
#
longname "Last Words"
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
#
# We have user-savable options.
#
library options
#
# The kernel needs this, yes precioussss
#
entry LWEntry
#
# Any special resource-allocation flags needed.
#
resource LWOptions ui-object
resource LWFontsUI ui-object
resource LWDocumentUI ui-object
resource LWHelp ui-object
#
# Pre-defined entry points -- must be first and in this order (q.v.
# SaverFunctions)
#
export LWStart
export LWStop
export LWFetchUI
export LWFetchHelp
export LWSaveState
export LWRestoreState
export LWSaveOptions
#
# Other entry  points we use
#
export LWDraw
export LWUpdateFontSample

export LWSetFont
export LWSetListFont
export LWSetSize
export LWSetAngleRandom
export LWSetColor
export LWSetSpeed
export LWSetMotion
export LWSetFormat
export LWPasteGraphic
