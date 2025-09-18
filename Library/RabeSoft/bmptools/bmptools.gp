##############################################################################
#
# PROJECT:      BMP-Tools Library by Rabe-Soft
#		Adapted for free PC/GEOS project 01/2024 - 07/2025
#
# AUTHOR:       Rainer Bettsteller, Magdeburg, Germany
#
##############################################################################

name            bmptools.lib
longname        "RabeSoft Bitmap Tool Library"
tokenchars      "BmpT"
tokenid         16480

type            library, single

platform        geos20

library         geos
library         ansic
library         ui


resource DataResource      lmem read-only shared

usernotes	"International version 1.0.5"



#export SelectDirOrFileDialogClass

# ******************** exportierted Routines ************************

# Offscreen bitmaps: Access to bitmaps without GStates ####
export BTCREATEOFFSCREENBITMAP
export BTSETBITMAPHEIGHT
export BTGETMOREBITMAPINFOS
export BTBITMAPTOOLLOCKHEADER
export BTGETBITMAPPALETTE
export BTSETBITMAPPALETTE

# Lock and unlock of offscreen bitmaps, simple bitmap operations
export BTBITMAPLOCK
export BTBITMAPUNLOCK
export BTBITMAPRELOCK
export BTBITMAPNEXT
export BTBITMAPPREV

export BTCLIPBITMAP
export BTINFLATEBITMAP
export BTCOPYBITMAP
export BTFLIPBITMAP

# Creation of a structure that is helpful for creating thumbnails
export BTCREATETHUMBNAILMAKERSTRUCT


# Basic routines for implementing a zoom frame / selection frame
export DRAGCREATEDRAGGSTATE
export DRAGDESTROYDRAGGSTATE

export DRAGPREPAREFORDRAGMODE
export DRAGENTERDRAGMODE
export DRAGHANDLEMOUSEMOVE
export DRAGLEAVEDRAGMODE

export DRAGDRAWDRAGRECT
export DRAGGETDRAGBOUNDS
export DRAGSETBITMAPSIZE

# An object that can display images (HugeBitmaps and GStrings)
export PictureDisplayClass

# Support for clipboard work, partly not only for graphics
export BTCOPYBITMAPTOCLIPBOARD
export BTCOPYGSTRINGTOCLIPBOARD
export BTTESTCLIPBOARDITEM
export BTGETCLIPBOARDITEM

# some bugfix and help routines
export BTDRAWBITMAPWITHMASKS
export BTDRAWGSTRING
export BTLOADANDDRAWGSTRING

incminor
export BTSETDEBUGTEXT
export BTFLIPBITMAPV
export BTFLIPBITMAPH
