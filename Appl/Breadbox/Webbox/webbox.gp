#######################
#
#  Copyright (c) Clemens Kochinke d/b/a FuzzyLogic 1995 -- All Rights Reserved
#  Portions Copyright (c) Blue Marsh Softworks 1995 -- All Rights Reserved
#  Portions Copyright (c) Geoworks 1990 -- All Rights Reserved
#
# PROJECT:  Web Editor Jupiter 2Web May 96 revision
# MODULE:   Geode Parameters
# FILE:     web96.gp
#
# AUTHORS:  Tony Requist, Nathan Fiedler, Clemens Kochinke
#
# DESCRIPTION:  This file contains Geode definitions for Jupiter 2Web
#
##################
name bw97.app
longname "WebBox"
type appl, process, single
#single is new - we don't really need multiple! 3/10/1996
class HTMProcessClass
appobj HTMApp
tokenchars "bWb0"
tokenid 16431
#platform omnigo CANNOT DO IT FOR LACK OF SPELL.LDF !
#zoomer
platform geos201
#heapspace 2K

library geos
library ui
library text
library spool
library spell
library ansic
# required only for insert text in IMG SCR
exempt spell

resource AppResource ui-object
resource Interface ui-object
resource ButtonGroup ui-object
resource SpeedTagRes ui-object
resource DBRes ui-object
resource DocGroupResource object
resource DisplayResource ui-object discard-only
resource DocumentResource ui-object discard-only

resource TagResource lmem discardable read-only shared
resource MSG1MENTAGRES lmem discardable read-only shared
resource MSG2MENTAGRES lmem discardable read-only shared
resource MSG3MENTAGRES lmem discardable read-only shared
resource MSG4MENTAGRES lmem discardable read-only shared
# lmem
#ui-object read-only shared

resource HTMLMENURES0 ui-object
resource HTMLMENURES1 ui-object
resource HTMLMENURES2 ui-object
resource HTMLMENURES3 ui-object
resource HTMLMENURES4 ui-object

resource TileDisplayIcon lmem, read-only shared
resource FullDisplayIcon lmem, read-only shared
#resource JNMPICMONRES lmem, read-only shared
#resource WWWMONDOCRES lmem, read-only shared

resource BBXWEBEDRES lmem, read-only shared
resource BBXWEBEDRES1 lmem, read-only shared
resource BBXWEBEDRES2 lmem, read-only shared
resource BBXWEBVURES lmem, read-only shared
resource BREADBOXRESOURCE2SMALL lmem, read-only shared

#resource HTMICON lmem, read-only shared

export HTMDocumentClass
export HTMTextClass
export HTMPrimaryClass
export SampleColorClass
export FixedGenValueClass
