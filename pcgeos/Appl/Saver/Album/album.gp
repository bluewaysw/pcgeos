# Parameters for specific screen saver library
# $Id: album.gp,v 1.1 97/04/04 16:44:09 newdeal Exp $
#
# Permanent name
#
name album.lib
#
# All specific screen savers are libraries that may be launched but once
#
type library, single
#
# This is the name that appears in the generic saver's list
#
longname "Album"
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
# We have user-savable options.
#
library options
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
# The kernel needs this, yes precioussss
#
entry AlbumEntry
#
# Any special resource-allocation flags needed.
#
resource AlbumOptions ui-object
resource AlbumHelp ui-object
#
# Pre-defined entry points -- must be first and in this order (q.v.
# SaverFunctions)
#
export AlbumStart
export AlbumStop
export AlbumFetchUI
export AlbumFetchHelp
export AlbumSaveState
export AlbumRestoreState
export AlbumSaveOptions
#
# Other entry  points we use
#
export AlbumSetPause
export AlbumSetDuration
export AlbumSetDrawMode
export AlbumSetColor
export AlbumDrawAndWait
export AlbumEraseAndWait
