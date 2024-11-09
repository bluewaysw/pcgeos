##############################################################################
#
# PROJECT:      Meta
# FILE:         Meta.gp
#
# AUTHOR:       Marcus Groeber
#
##############################################################################

name            meta.lib
longname        "Meta Drawing Layer"
tokenchars      "META"
tokenid         16424

type            library, single

library	geos
library	ui
library ansic
library grobj
library math

export RAD
export PHI
export META_SETLINECOLOR
export META_SETAREACOLOR
export META_SETFILLRULE
export META_SETLINESTYLE
export META_SETLINEWIDTH
export META_SETAREAFILL
export META_SETLINEFILL
export META_SETSCALING
export META_GETSCALING
export META_SETCLIPRECT
export META_SETPATTERNBACK
export META_SETTRANSPARENCY
export META_LINE
export META_POLYLINE
export META_POLYGON
export META_RECT
export META_ELLIPSE
export META_ELLIPTICALARC
export META_ARCTHREEPOINT
export META_BEGINPATH
export META_ENDPATH
export META_TEXTAT
export META_START
export META_END

export READHPGL
export READCGM