Win32/vga16Manager.obj \
Win32/vga16Manager.eobj: vidcomGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def unicode.def localize.def sllang.def system.def \
                Internal/heapInt.def sysstats.def Internal/xip.def \
                file.def Internal/gstate.def Internal/tmatrix.def \
                Internal/fontDr.def Internal/window.def \
                Internal/interrup.def Internal/threadIn.def \
                Internal/videoDr.def hugearr.def initfile.def \
                vga16Constant.def vidcomConstant.def vga16Macro.def \
                vidcomMacro.def vga16DevInfo.asm vidcomTables.asm \
                vga16Tables.asm vidcomVariable.def vga16Variable.def \
                vga16StringTab.asm vidcomEntry.asm Internal/winnt.def \
                vidcomOutput.asm vidcomChars.asm vidcomFont.asm \
                vga16Under.asm vidcomUtils.asm vidcomRegion.asm \
                vidcomXOR.asm vidcomInfo.asm vidcomEscape.asm \
                vidcomPalette.asm vga16Output.asm vga16GenChar.asm \
                vga16Utils.asm vga16Chars.asm vga16Pointer.asm \
                vga16EscTab.asm vga16Palette.asm vga16Dither.asm \
                vidcomPolygon.asm vidcomLine.asm vidcomPutLine.asm \
                vidcomRaster.asm vga16Raster.asm vga16Admin.asm \
                vidcomExclBounds.asm

WIN32DBCS/vga16EC.geo WIN32DBCS/vga16.geo : geos.ldf 