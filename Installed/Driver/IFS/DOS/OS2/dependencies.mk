os2Manager.obj \
os2Manager.eobj: dosGeode.def geos.def heap.def geode.def resource.def \
                ec.def lmem.def system.def localize.def sllang.def \
                drive.def disk.def file.def driver.def timedate.def \
                sem.def timer.def initfile.def gcnlist.def \
                Objects/metaC.def object.def chunkarr.def geoworks.def \
                graphics.def fontID.def font.def color.def \
                Internal/semInt.def Internal/interrup.def \
                Internal/dos.def fileEnum.def Internal/fileInt.def \
                Internal/driveInt.def Internal/diskInt.def \
                Internal/fsd.def Internal/log.def Internal/heapInt.def \
                sysstats.def Internal/geodeStr.def Internal/fileStr.def \
                Internal/localInt.def char.def Internal/fsDriver.def \
                Internal/dosFSDr.def Internal/prodFeatures.def assert.def \
                os2Interface.def dosLfn.def hostif.def \
                Internal/hostDosFs.def dosConstant.def dosMacro.def \
                dosStrings.asm dosVariable.def os2Strings.asm \
                os2Variable.def dosEntry.asm dosDisk.asm dosDrive.asm \
                os2Drive.asm dosPath.asm dosEnum.asm dosFormat.asm \
                dosFormatInit.asm dosDiskCopy.asm dosIO.asm \
                dosPrimary.asm dosInitExit.asm os2InitExit.asm \
                dosCritical.asm dosUtils.asm os2Utils.asm os2HostFs.asm \
                os2Lfn.asm dosVirtual.asm dosSuspend.asm dosLink.asm \
                dosIdle.asm dosFileChange.asm

os2EC.geo os2.geo : geos.ldf hostif.ldf 