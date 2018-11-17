Main.obj \
Main.eobj: Main/mainManager.asm \
                vidmemInclude.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def graphics.def fontID.def \
                font.def color.def win.def char.def hugearr.def \
                Internal/semInt.def Internal/gstate.def \
                Internal/tmatrix.def Internal/fontDr.def file.def \
                Internal/window.def Internal/interrup.def \
                Internal/heapInt.def sysstats.def Internal/videoDr.def \
                vidmemResource.def vidmemConstant.def vidmemMacro.def \
                vidmemGlobal.def mainMain.asm mainTables.asm \
                mainVariable.def vidcomEscape.asm
Mono.obj \
Mono.eobj: Mono/monoManager.asm \
                vidmemGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def hugearr.def \
                Internal/gstate.def Internal/tmatrix.def \
                Internal/fontDr.def file.def Internal/window.def \
                Internal/interrup.def Internal/heapInt.def sysstats.def \
                Internal/threadIn.def Internal/videoDr.def \
                vidmemResource.def vidmemConstant.def monoConstant.def \
                dumbcomConstant.def vidcomConstant.def monoMacro.def \
                vidmemMacro.def dumbcomMacro.def vidcomMacro.def \
                monoTables.asm dumbcomTables.asm vidcomVariable.def \
                vidmemVariable.def dumbcomVariable.def monoVariable.def \
                vidcomOutput.asm vidcomChars.asm monoGenChar.asm \
                vidcomFont.asm vidcomUtils.asm vidcomRegion.asm \
                vidcomEscape.asm vidcomPalette.asm dumbcomOutput.asm \
                dumbcomUtils.asm dumbcomChars.asm dumbcomPalette.asm \
                monoEscTab.asm monoEntry.asm monoCluster.asm \
                monoUtils.asm monoEscape.asm vidmemUtils.asm \
                vidcomPolygon.asm vidcomLine.asm vidcomPutLine.asm \
                vidcomRaster.asm dumbcomRaster.asm
Clr4.obj \
Clr4.eobj: Clr4/clr4Manager.asm \
                vidmemGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def hugearr.def \
                Internal/gstate.def Internal/tmatrix.def \
                Internal/fontDr.def file.def Internal/window.def \
                Internal/interrup.def Internal/heapInt.def sysstats.def \
                Internal/threadIn.def Internal/videoDr.def \
                vidmemConstant.def clr4Constant.def vidcomConstant.def \
                vidmemResource.def clr4Macro.def vidmemMacro.def \
                dumbcomMacro.def vidcomMacro.def clr4Tables.asm \
                vidcomVariable.def vidmemVariable.def dumbcomVariable.def \
                clr4Variable.def vidcomOutput.asm vidcomChars.asm \
                clr4GenChar.asm vidcomFont.asm vidcomUtils.asm \
                vidcomRegion.asm vidcomEscape.asm vidcomDither.asm \
                vidcomPalette.asm clr4EscTab.asm clr4Palette.asm \
                clr4Entry.asm clr4Utils.asm clr4Output.asm clr4Chars.asm \
                vidmemUtils.asm vidcomPolygon.asm vidcomLine.asm \
                vidcomPutLine.asm vidcomRaster.asm clr4Raster.asm
Clr8.obj \
Clr8.eobj: Clr8/clr8Manager.asm \
                vidmemGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def hugearr.def \
                Internal/gstate.def Internal/tmatrix.def \
                Internal/fontDr.def file.def Internal/window.def \
                Internal/interrup.def Internal/heapInt.def sysstats.def \
                Internal/threadIn.def Internal/videoDr.def \
                vidmemConstant.def clr8Constant.def vidcomConstant.def \
                vidmemResource.def clr8Macro.def vidmemMacro.def \
                dumbcomMacro.def vidcomMacro.def clr8Tables.asm \
                vidcomVariable.def vidmemVariable.def clr8Variable.def \
                vidcomOutput.asm vidcomChars.asm vidcomFont.asm \
                vidcomUtils.asm vidcomRegion.asm vidcomEscape.asm \
                vidcomPalette.asm clr8Output.asm clr8GenChar.asm \
                clr8Chars.asm clr8Dither.asm clr8EscTab.asm \
                clr8Palette.asm clr8Entry.asm clr8Utils.asm \
                vidmemUtils.asm vidcomPolygon.asm vidcomLine.asm \
                vidcomPutLine.asm vidcomRaster.asm clr8Raster.asm
Clr24.obj \
Clr24.eobj: Clr24/clr24Manager.asm \
                vidmemGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def hugearr.def \
                Internal/gstate.def Internal/tmatrix.def \
                Internal/fontDr.def file.def Internal/window.def \
                Internal/interrup.def Internal/heapInt.def sysstats.def \
                Internal/threadIn.def Internal/videoDr.def \
                vidmemConstant.def clr24Constant.def vidcomConstant.def \
                vidmemResource.def clr24Macro.def vidmemMacro.def \
                dumbcomMacro.def vidcomMacro.def clr24Tables.asm \
                vidcomVariable.def vidmemVariable.def clr24Variable.def \
                vidcomOutput.asm vidcomChars.asm vidcomFont.asm \
                vidcomUtils.asm vidcomRegion.asm vidcomEscape.asm \
                vidcomPalette.asm clr24Output.asm clr24GenChar.asm \
                clr24Chars.asm clr24EscTab.asm clr24Entry.asm \
                clr24Palette.asm vidmemUtils.asm vidcomPolygon.asm \
                vidcomLine.asm vidcomPutLine.asm vidcomRaster.asm \
                clr24Raster.asm
CMYK.obj \
CMYK.eobj: CMYK/cmykManager.asm \
                vidmemGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def hugearr.def \
                Internal/gstate.def Internal/tmatrix.def \
                Internal/fontDr.def file.def Internal/window.def \
                Internal/interrup.def Internal/heapInt.def sysstats.def \
                Internal/threadIn.def Internal/videoDr.def \
                vidmemConstant.def cmykConstant.def vidcomConstant.def \
                vidmemResource.def cmykMacro.def dumbcomMacro.def \
                vidmemMacro.def vidcomMacro.def cmykTables.asm \
                vidcomVariable.def vidmemVariable.def dumbcomVariable.def \
                cmykVariable.def vidcomOutput.asm vidcomChars.asm \
                cmykGenChar.asm vidcomFont.asm vidcomUtils.asm \
                vidcomRegion.asm vidcomEscape.asm vidcomPalette.asm \
                cmykCluster.asm cmykEscTab.asm cmykPalette.asm \
                cmykEntry.asm cmykUtils.asm cmykColor.asm vidmemUtils.asm \
                vidcomPolygon.asm vidcomLine.asm vidcomPutLine.asm \
                vidcomRaster.asm cmykDither.asm cmykColorRaster.asm \
                cmykRaster.asm
