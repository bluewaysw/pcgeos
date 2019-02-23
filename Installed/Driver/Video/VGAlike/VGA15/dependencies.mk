vga15Manager.obj \
vga15Manager.eobj: vidcomGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def system.def \
                Internal/heapInt.def sysstats.def Internal/gstate.def \
                Internal/tmatrix.def Internal/fontDr.def file.def \
                Internal/window.def Internal/interrup.def \
                Internal/threadIn.def Internal/videoDr.def hugearr.def \
                vga15Constant.def vidcomConstant.def vga15Macro.def \
                vidcomMacro.def vga15DevInfo.asm vidcomTables.asm \
                vga15Table.asm vidcomVariable.def vga15Variable.def \
                vga15StringTab.asm vidcomEntry.asm vidcomOutput.asm \
                vidcomChars.asm vidcomFont.asm vga15Under.asm \
                vidcomUtils.asm vidcomRegion.asm vidcomXOR.asm \
                vidcomInfo.asm vidcomEscape.asm vidcomPalette.asm \
                vga15Output.asm vga15GenChar.asm vga15Utils.asm \
                vga15Chars.asm vga15Pointer.asm vga15EscTab.asm \
                vga15Palette.asm vga15Dither.asm vidcomPolygon.asm \
                vidcomLine.asm vidcomPutLine.asm vidcomRaster.asm \
                vga15Raster.asm vga15Admin.asm vidcomExclBounds.asm

vga15EC.geo vga15.geo : geos.ldf 