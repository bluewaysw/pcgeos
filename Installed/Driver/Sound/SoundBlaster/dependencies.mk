soundblasterManager.obj \
soundblasterManager.eobj: geos.def file.def geode.def resource.def ec.def driver.def \
                lmem.def heap.def system.def localize.def sllang.def \
                timer.def initfile.def char.def Internal/interrup.def \
                soundblasterConstant.def soundblasterError.def \
                soundblasterPCTimer.def sound.def Internal/soundFmt.def \
                Internal/semInt.def Internal/DMADrv.def \
                Internal/strDrInt.def Internal/streamDr.def \
                Internal/soundDrv.def soundblasterError.asm \
                soundblasterRegister.asm soundblasterInit.asm \
                soundblasterTimeDelay.asm soundblasterStrategy.asm \
                soundblasterInt.asm soundblasterVoice.asm \
                soundblasterDAC.asm soundblasterStream.asm

sblasterEC.geo sblaster.geo : geos.ldf stream.ldf 