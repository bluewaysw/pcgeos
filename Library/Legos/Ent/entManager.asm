COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        Visual Geos
MODULE:         Component Object Library
FILE:           entMnge.asm

AUTHOR:         David Loftesness, Jun  1, 1994

ROUTINES:
	Name                    Description
	----                    -----------

	
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	dloft   6/ 1/94         Initial revision


DESCRIPTION:
	
		

	$Id: entManager.asm,v 1.1 98/03/06 17:55:09 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;Standard include files


include geos.def
include geode.def
include ec.def

include library.def
include geode.def

include resource.def

include object.def
include graphics.def
include gstring.def
include win.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include system.def
include file.def
include fileEnum.def
include vm.def
include chunkarr.def
include thread.def
include sem.def
include ec.def
include assert.def
include localize.def
include char.def
UseLib  ui.def
UseLib  Legos/basrun.def
include Legos/runheap.def

DefLib  Legos/ent.def
	
;------------------------------------------------------------------------------
;       Include definitions.
;------------------------------------------------------------------------------

include entMacro.def
include entConstant.def

;------------------------------------------------------------------------------
;       Local variables.
;------------------------------------------------------------------------------
idata   segment

EntClass
EntVisClass
ML1Class
ML2Class
EntAppClass

idata   ends

;------------------------------------------------------------------------------
; Here comes the code...
;------------------------------------------------------------------------------
EntCode segment resource

.wcheck
.rcheck

include entMaster.asm
include entEC.asm
include entUtil.asm
include entMain.asm
include entVis.asm
include entApp.asm

EntCode ends
