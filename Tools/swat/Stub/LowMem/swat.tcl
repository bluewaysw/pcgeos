nomap
[sym tset [sym make type RpcHeader] [type make struct
	rh_flags [type byte] 0 8
	rh_procNum [type byte] 8 8
	rh_length [type byte] 16 8
	rh_id [type byte] 24 8
]]
[sym tset [sym make type HaltArgs] [type make struct
	ha_thread [type word] 0 16
	ha_regs [type make array 28 [type byte]] 16 224
	ha_reason [type word] 240 16
]]
[sym tset [sym make type MoveArgs] [type make struct
	ma_handle [type word] 0 16
	ma_dataAddress [type word] 16 16
]]
[sym tset [sym make type HelloGeode] [type make struct
	hg_handle [type word] 0 16
	hg_dataAddress [type word] 16 16
	hg_paraSize [type word] 32 16
]]
[sym tset [sym make type ReadArgs] [type make struct
	ra_offset [type word] 0 16
	ra_handle [type word] 16 16
	ra_numBytes [type word] 32 16
]]
[sym tset [sym make type ExeHeader] [type make struct
	exe_sig [type make array 2 [type byte]] 0 16
	exe_rem [type word] 16 16
	exe_size [type word] 32 16
	exe_numRels [type word] 48 16
	exe_headerSize [type word] 64 16
	exe_minPara [type word] 80 16
	exe_maxPara [type word] 96 16
	exe_ss [type word] 112 16
	exe_sp [type word] 128 16
	exe_csum [type word] 144 16
	exe_ip [type word] 160 16
	exe_cs [type word] 176 16
	exe_relOff [type word] 192 16
	exe_overlayNum [type word] 208 16
]]
[sym tset [sym make type HelloReply] [type make struct
	hr_baseSeg [type word] 0 16
	hr_initSeg [type word] 16 16
	hr_stubSeg [type word] 32 16
	hr_stubType [type byte] 48 8
	hr_pad [type byte] 56 8
	hr_numGeodes [type word] 64 16
	hr_numThreads [type word] 80 16
	hr_curThread [type word] 96 16
	hr_lastHandle [type word] 112 16
	hr_sysTablesOff [type word] 128 16
	hr_sysTablesSeg [type word] 144 16
	hr_psp [type word] 160 16
	hr_mask1 [type byte] 176 8
	hr_mask2 [type byte] 184 8
	hr_irqHandlers [type word] 192 16
]]
[sym tset [sym make type MaskArgs] [type make struct
	ma_PIC1 [type byte] 0 8
	ma_PIC2 [type byte] 8 8
]]
[sym tset [sym make type IoWriteArgs] [type make struct
	iow_port [type word] 0 16
	iow_value [type word] 16 16
]]
[sym tset [sym make type HelloThread] [type make struct
	ht_id [type word] 0 16
	ht_owner [type word] 16 16
	ht_ss [type word] 32 16
	ht_sp [type word] 48 16
]]
[sym tset [sym make type AbsFillArgs] [type make struct
	afa_offset [type word] 0 16
	afa_segment [type word] 16 16
	afa_length [type word] 32 16
	afa_value [type word] 48 16
]]
[sym tset [sym make type StepReply] [type make struct
	sr_regs [type make array 28 [type byte]] 0 224
	sr_thread [type word] 224 16
]]
[sym tset [sym make type OutArgs] [type make struct
	oa_handle [type word] 0 16
	oa_discarded [type word] 16 16
]]
[sym tset [sym make type HelloArgs] [type make struct
	ha_kdata [type word] 0 16
	ha_bootstrap [type word] 16 16
	ha_HandleTable [type word] 32 16
	ha_currentThread [type word] 48 16
	ha_geodeListPtr [type word] 64 16
	ha_threadListPtr [type word] 80 16
	ha_dosSem [type word] 96 16
	ha_heapSem [type word] 112 16
	ha_lastHandle [type word] 128 16
	ha_initSeg [type word] 144 16
	ha_DebugLoadResource [type word] 160 16
	ha_DebugMemory [type word] 176 16
	ha_DebugProcess [type word] 192 16
	ha_MemLock [type word] 208 16
	ha_EndGeos [type word] 224 16
	ha_BlockOnLongQueue [type word] 240 16
]]
[sym tset [sym make type AtronTraceRecord] [type make struct
	atr_addrLow [type word] 0 16
	atr_data [type word] 16 16
	atr_bus [type byte] 32 8
	atr_misc [type byte] 40 8
	atr_addrHigh [type byte] 48 8
	atr_pad [type byte] 56 8
]]
[sym tset [sym make type IbmRegs] [type make struct
	reg_regs [type make array 12 [type word]] 0 192
	reg_ip [type word] 192 16
	reg_flags [type word] 208 16
]]
[sym tset [sym make type AbsWriteArgs] [type make struct
	awa_offset [type word] 0 16
	awa_segment [type word] 16 16
]]
[sym tset [sym make type SpawnArgs] [type make struct
	sa_thread [type word] 0 16
	sa_owner [type word] 16 16
	sa_ss [type word] 32 16
	sa_sp [type word] 48 16
]]
[sym tset [sym make type WriteRegsArgs] [type make struct
	wra_thread [type word] 0 16
	wra_regs [type make array 28 [type byte]] 16 224
]]
[sym tset [sym make type FindReply] [type make struct
	fr_id [type word] 0 16
	fr_dataAddress [type word] 16 16
	fr_paraSize [type word] 32 16
	fr_owner [type word] 48 16
	fr_otherInfo [type word] 64 16
	fr_flags [type byte] 80 8
	fr_pad [type byte] 88 8
]]
[sym tset [sym make type FillArgs] [type make struct
	fa_offset [type word] 0 16
	fa_handle [type word] 16 16
	fa_length [type word] 32 16
	fa_value [type word] 48 16
]]
[sym tset [sym make type LoadArgs] [type make struct
	la_handle [type word] 0 16
	la_dataAddress [type word] 16 16
]]
[sym tset [sym make type CBreakArgs] [type make struct
	cb_ip [type word] 0 16
	cb_cs [type word] 16 16
	cb_comps [type make array 7 [type byte]] 32 56
	cb_inst [type byte] 88 8
	cb_thread [type word] 96 16
	cb_regs [type make array 12 [type word]] 112 192
	cb_value [type word] 304 16
	cb_off [type word] 320 16
	cb_seg [type word] 336 16
]]
[sym tset [sym make type WWFixed] [type make struct
	WWF_frac [type word] 0 16
	WWF_int [type word] 16 16
]]
[sym tset [sym make type BrkFillArgs] [type make struct
	bfa_addr [type dword] 0 32
	bfa_length [type word] 32 16
	bfa_value [type byte] 48 8
	bfa_pad [type byte] 56 8
]]
[sym tset [sym make type GeodeExitArgs] [type make struct
	gea_handle [type word] 0 16
	gea_curThread [type word] 16 16
]]
[sym tset [sym make type BBFixed] [type make struct
	BBF_frac [type byte] 0 8
	BBF_int [type byte] 8 8
]]
[sym tset [sym make type WriteArgs] [type make struct
	wa_offset [type word] 0 16
	wa_handle [type word] 16 16
]]
[sym tset [sym make type ReallocArgs] [type make struct
	rea_handle [type word] 0 16
	rea_dataAddress [type word] 16 16
	rea_paraSize [type word] 32 16
]]
[sym tset [sym make type BeepReply] [type make struct
	br_csum [type word] 0 16
	br_rev [type word] 16 16
]]
[sym tset [sym make type StateBlock] [type make struct
	state_timerInt [type dword] 0 32
	state_ip [type word] 32 16
	state_cs [type word] 48 16
	state_flags [type word] 64 16
	state_PIC1 [type byte] 80 8
	state_PIC2 [type byte] 88 8
	state_thread [type word] 96 16
	state_ds [type word] 112 16
	state_ss [type word] 128 16
	state_es [type word] 144 16
	state_ax [type word] 160 16
	state_cx [type word] 176 16
	state_dx [type word] 192 16
	state_bx [type word] 208 16
	state_sp [type word] 224 16
	state_bp [type word] 240 16
	state_si [type word] 256 16
	state_di [type word] 272 16
]]
[sym tset [sym make type SysFlags] [type make struct
	isPC [type word] 7 1
	dontresume [type word] 6 1
	calling [type word] 5 1
	waiting [type word] 4 1
	replied [type word] 3 1
	error [type word] 2 1
	attached [type word] 1 1
	geosgone [type word] 0 1
]]
[sym tset [sym make type DFixed] [type make struct
	DF_fracL [type word] 0 16
	DF_fracH [type word] 16 16
]]
[sym tset [sym make type ThreadExitArgs] [type make struct
	tea_handle [type word] 0 16
	tea_status [type word] 16 16
]]
[sym tset [sym make type WBFixed] [type make struct
	WBF_frac [type byte] 0 8
	WBF_int [type word] 8 16
]]
[sym tset [sym make type ChangeCBreakArgs] [type make struct
	ccba_num [type word] 0 16
	ccba_cs [type word] 16 16
	ccba_seg [type word] 32 16
]]
[sym tset [sym make type WDFixed] [type make struct
	WDF_fracL [type word] 0 16
	WDF_fracH [type word] 16 16
	WDF_int [type word] 32 16
]]
[sym tset [sym make type AbsReadArgs] [type make struct
	ara_offset [type word] 0 16
	ara_segment [type word] 16 16
	ara_numBytes [type word] 32 16
]]
[sym tset [sym make type InfoReply] [type make struct
	ir_dataAddress [type word] 0 16
	ir_paraSize [type word] 16 16
	ir_owner [type word] 32 16
	ir_otherInfo [type word] 48 16
	ir_flags [type byte] 64 8
	ir_pad [type byte] 72 8
]]
var _q [sym make type FatalErrors]
sym tset ${_q} [type make enum 2]
sym make enum CANNOT_LOAD_KERNEL_LIBRARY 5 ${_q}
sym make enum DEFAULT_FONT_NOT_FOUND 4 ${_q}
sym make enum NO_RGB 3 ${_q}
sym make enum SYS_EMPTY_CALLED 2 ${_q}
sym make enum HANDLE_TABLE_FULL 1 ${_q}
sym make enum CAN_NOT_USE_CHUNKSIZEPTR_MACRO_ON_EMPTY_CHUNKS 0 ${_q}
[sym tset [sym make type FPUReg] [type make struct
	FR_lsw [type word] 0 16
	FR_lmsw [type word] 16 16
	FR_hmsw [type word] 32 16
	FR_msw [type word] 48 16
	FR_expSign [type word] 64 16
]]
[sym tset [sym make type FPUState] [type make struct
	FS_control [type word] 0 16
	FS_status [type word] 16 16
	FS_tag [type word] 32 16
	FS_ipLow [type word] 48 16
	FS_opIPHigh [type word] 64 16
	FS_dataLow [type word] 80 16
	FS_dataHigh [type word] 96 16
	FS_regStack [type make array 8 [sym find type FPUReg]] 112 640
]]
[sym tset [sym make type HandleDisk] [type make struct
	HD_refCount [type byte] 0 8
	HD_handleSig [type byte] 8 8
	HD_volumeID [type make array 3 [type byte]] 16 24
	HD_volumeLabel [type make array 11 [type char]] 40 88
]]
sym make type HandleMem
[sym tset [sym ftype HandleMem] [type make struct
	HM_addr [type word] 0 16
	HM_size [type word] 16 16
	HM_prev [type make nptr [sym find type HandleMem]] 32 16
	HM_next [type make nptr [sym find type HandleMem]] 48 16
	HM_owner [type make hptr [type void]] 64 16
	HM_flags [sym find type HeapFlags] 80 -8
	HM_lockCount [type sbyte] 88 8
	HM_usageValue [type word] 96 16
	HM_otherInfo [type word] 112 16
]]
var _q [sym make type HandleTypes]
sym tset ${_q} [type make enum 1]
sym make enum SIG_GSTRING 255 ${_q}
sym make enum SIG_THREAD 254 ${_q}
sym make enum SIG_FILE 253 ${_q}
sym make enum SIG_VM 252 ${_q}
sym make enum SIG_UNUSED_FB 251 ${_q}
sym make enum SIG_SAVED_BLOCK 250 ${_q}
sym make enum SIG_EVENT_REG 249 ${_q}
sym make enum SIG_EVENT_STACK 248 ${_q}
sym make enum SIG_EVENT_DATA 247 ${_q}
sym make enum SIG_TIMER 246 ${_q}
sym make enum SIG_DISK 245 ${_q}
sym make enum SIG_QUEUE 244 ${_q}
sym make enum HT_UNUSED_F3 243 ${_q}
sym make enum HT_UNUSED_F2 242 ${_q}
sym make enum HT_UNUSED_F1 241 ${_q}
sym make enum HT_UNUSED_F0 240 ${_q}
sym make type HandleThread
[sym tset [sym ftype HandleThread] [type make struct
	HT_curPriority [type byte] 0 8
	HT_handleSig [sym find type HandleTypes] 8 8
	HT_saveSP [type word] 16 16
	HT_saveSS [type word] 32 16
	HT_nextQThread [type make nptr [sym find type HandleThread]] 48 16
	HT_owner [type make hptr [type void]] 64 16
	HT_basePriority [type byte] 80 8
	HT_cpuUsage [type byte] 88 8
	HT_next [type make nptr [sym find type HandleThread]] 96 16
	HT_eventQueue [type make hptr [type void]] 112 16
]]
sym make type HandleEvent
[sym tset [sym ftype HandleEvent] [type make struct
	HE_callingThreadHigh [type byte] 0 8
	HE_handleSig [sym find type HandleTypes] 8 8
	HE_cx [type word] 16 16
	HE_dx [type word] 32 16
	HE_bp [type word] 48 16
	HE_method [type word] 64 16
	HE_OD [type make optr [type void]] 80 32
	HE_next [type make hptr [sym find type HandleEvent]] 112 16
]]
[sym tset [sym make type HandleQueue] [type make struct
	HQ_unused1 [type byte] 0 8
	HQ_handleSig [sym find type HandleTypes] 8 8
	HQ_frontPtr [type make hptr [sym find type HandleEvent]] 16 16
	HQ_backPtr [type make hptr [sym find type HandleEvent]] 32 16
	HQ_semaphore [sym find type Semaphore] 48 -8
	HQ_counter [type word] 80 16
	HQ_thread [type make hptr [type void]] 96 16
	HQ_unused2 [type word] 112 16
]]
[sym tset [sym make type GSflags] [type make struct
	_nameless0 [type word] 2 6
	GSF_READ_ONLY [type word] 1 1
	GSF_FILE_HAN [type word] 0 1
]]
[sym tset [sym make type HandleFile] [type make struct
	HF_sfn [type byte] 0 8
	HF_handleSig [sym find type HandleTypes] 8 8
	HF_accessFlags [type byte] 16 8
	HF_drive [type byte] 24 8
	HF_next [type make hptr [type void]] 32 16
	HF_disk [type make hptr [type void]] 48 16
	HF_owner [type make hptr [type void]] 64 16
	_nameless1 [type word] 80 16
	HF_otherInfo [type make hptr [type void]] 96 16
	HF_semaphore [type word] 112 16
]]
[sym tset [sym make type HandleGen] [type make struct
	HG_data1 [type byte] 0 8
	HG_type [sym find type HandleTypes] 8 8
	HG_data2 [type make array 3 [type word]] 16 48
	HG_owner [type make hptr [type void]] 64 16
	HG_data3 [type make array 3 [type word]] 80 48
]]
[sym tset [sym make type ThreadPrivateData] [type make struct
	TPD_blockHandle [type make hptr [type void]] 0 16
	TPD_processHandle [type make hptr [type void]] 16 16
	TPD_processSegment [type make sptr [type void]] 32 16
	TPD_threadHandle [type make hptr [type void]] 48 16
	TPD_classPointer [type make fptr [type void]] 64 32
	TPD_callVector [type make fptr [type void]] 96 32
	TPD_callTemporary [type word] 128 16
	TPD_vmFile [type make hptr [type void]] 144 16
	TPD_stackBot [type make nptr [type void]] 160 16
	TPD_divideByZero [type make fptr [type void]] 176 32
	TPD_overflow [type make fptr [type void]] 208 32
	TPD_bound [type make fptr [type void]] 240 32
	TPD_fpuException [type make fptr [type void]] 272 32
	TPD_singleStep [type make fptr [type void]] 304 32
	TPD_breakPoint [type make fptr [type void]] 336 32
	TPD_heap [type make array 9 [type make hptr [type void]]] 368 144
]]
[sym tset [sym make type HandleGString] [type make struct
	HGS_flags [sym find type GSflags] 0 8
	HGS_handleSig [sym find type HandleTypes] 8 8
	HGS_hGStruc [type make hptr [type void]] 16 16
	HGS_hChunk [type make lptr [type void]] 32 16
	HGS_hString [type make hptr [type void]] 48 16
	HGS_owner [type make hptr [type void]] 64 16
	HGS_hSubStr [type make lptr [type void]] 80 16
]]
[sym tset [sym make type ThreadBlockState] [type make struct
	TBS_bp [type word] 0 16
	TBS_es [type word] 16 16
	TBS_dx [type word] 32 16
	TBS_flags [type word] 48 16
	TBS_cx [type word] 64 16
	TBS_di [type word] 80 16
	TBS_si [type word] 96 16
	TBS_ds [type word] 112 16
	TBS_ret [type word] 128 16
]]
sym make type HandleTimer
[sym tset [sym ftype HandleTimer] [type make struct
	HTI_type [type byte] 0 8
	HTI_handleSig [sym find type HandleTypes] 8 8
	HTI_next [type make hptr [sym find type HandleTimer]] 16 16
	HTI_timeRemaining [type word] 32 16
	HTI_intervalOrID [type word] 48 16
	HTI_owner [type make hptr [type void]] 64 16
	HTI_OD [type dword] 80 32
	HTI_method [type word] 112 16
]]
sym make type HandleSavedBlock
[sym tset [sym ftype HandleSavedBlock] [type make struct
	HSB_unusedB [type byte] 0 8
	HSB_handleSig [sym find type HandleTypes] 8 8
	HSB_handle [type make hptr [type void]] 16 16
	HSB_next [type make hptr [sym find type HandleSavedBlock]] 32 16
	HSB_vmID [type word] 48 16
	HSB_unusedW1 [type word] 64 16
	HSB_unusedW2 [type word] 80 16
	HSB_unusedW3 [type word] 96 16
	HSB_unusedW4 [type word] 112 16
]]
[sym tset [sym make type ModuleLock] [type make struct
	ML_sem [sym find type Semaphore] 0 -8
]]
sym make type HandleEventData
[sym tset [sym ftype HandleEventData] [type make struct
	HED_unused1 [type byte] 0 8
	HED_handleSig [sym find type HandleTypes] 8 8
	HED_next [type make hptr [sym find type HandleEventData]] 16 16
	HED_word0 [type word] 32 16
	HED_word1 [type word] 48 16
	HED_word2 [type word] 64 16
	HED_word3 [type word] 80 16
	HED_word4 [type word] 96 16
	HED_word5 [type word] 112 16
]]
[sym tset [sym make type HandleVM] [type make struct
	HVM_refCount [type byte] 0 8
	HVM_signature [sym find type HandleTypes] 8 8
	HVM_headerHandle [type make hptr [type void]] 16 16
	HVM_relocRoutine [type make fptr [type void]] 32 32
	HVM_fileHandle [type make hptr [type void]] 64 16
	_nameless2 [type dword] 80 32
	HVM_semaphore [type word] 112 16
]]
begseg scode 0
sym vset [sym make var allBreaks] [type make array 8 [sym find type CBreakArgs]] static 0
sym fset [sym make func SetCBreak] cbreak.asm near 352
sym fset [sym make func ClearCBreak] cbreak.asm near 398
sym fset [sym make func ChangeCBreak] cbreak.asm near 411
sym fset [sym make func HandleCBreak] cbreak.asm near 433
[sym tset [sym make type BUFFER] [type make struct
	head [type word] 0 16
	tail [type word] 16 16
	numChars [type word] 32 16
	data [type make array 512 [type byte]] 48 4096
]]
sym vset [sym make var comIn] [sym find type BUFFER] static 624
sym vset [sym make var comOut] [sym find type BUFFER] static 1142
[sym tset [sym make type flags] [type make struct
	IRQPEND [type word] 0 1
]]
sym vset [sym make var comFlags] [sym find type flags] static 1660
sym vset [sym make var comIntVec] [type dword] static 1662
sym vset [sym make var comIntVecNum] [type word] static 1666
sym vset [sym make var comIntLevel] [type byte] static 1668
sym vset [sym make var comCurDataPort] [type word] static 1670
sym vset [sym make var comCurStatPort] [type word] static 1672
sym vset [sym make var comCurIRQPort] [type word] static 1674
sym vset [sym make var comCurIENPort] [type word] static 1676
sym fset [sym make func Com_Exit] com.asm near 1678
sym fset [sym make func ComInterrupt] com.asm far 1713
sym fset [sym make func Com_Read] com.asm near 1943
sym fset [sym make func Com_Write] com.asm near 1992
sym fset [sym make func Com_ReadBlock] com.asm near 2043
sym fset [sym make func Com_WriteBlock] com.asm near 2055
sym vset [sym make var kernelHeader] [sym find type ExeHeader] static 2080
sym vset [sym make var dosAddr] [type dword] static 2108
sym vset [sym make var dosThread] [type word] static 2112
sym vset [sym make var dosSP] [type word] static 2114
sym vset [sym make var dosSS] [type word] static 2116
sym vset [sym make var kdata] [type word] static 2118
sym vset [sym make var HandleTableOff] [type word] static 2120
sym vset [sym make var currentThreadOff] [type word] static 2122
sym vset [sym make var geodeListPtrOff] [type word] static 2124
sym vset [sym make var threadListPtrOff] [type word] static 2126
sym vset [sym make var dosSemOff] [type word] static 2128
sym vset [sym make var heapSemOff] [type word] static 2130
sym vset [sym make var lastHandleOff] [type word] static 2132
sym vset [sym make var DebugLoadResOff] [type word] static 2134
sym vset [sym make var DebugMemoryOff] [type word] static 2136
sym vset [sym make var DebugProcessOff] [type word] static 2138
sym vset [sym make var MemLockVec] [type dword] static 2140
sym vset [sym make var EndGeosOff] [type word] static 2144
sym vset [sym make var BlockOnLongQueueOff] [type word] static 2146
sym vset [sym make var UnderAtron] [type make array 2 [type byte]] static 2148
var _q [sym make type ReloadStates]
sym tset ${_q} [type make enum 1]
sym make enum RS_INTERCEPT 2 ${_q}
sym make enum RS_WATCH_EXEC 1 ${_q}
sym make enum RS_IGNORE 0 ${_q}
sym vset [sym make var reloadState] [sym find type ReloadStates] static 2150
sym fset [sym make func KernelFindMaxSP] kernel.asm near 2151
sym fset [sym make func KernelDOS] kernel.asm far 2189
sym fset [sym make func KernelMemory] kernel.asm near 2323
sym fset [sym make func KernelProcess] kernel.asm near 2474
sym vset [sym make var kpJumpTable] [type word] static 2522
sym fset [sym make func KernelLoadRes] kernel.asm near 2692
sym fset [sym make func KernelCleanHandles] kernel.asm near 2775
sym fset [sym make func KernelIntercept] kernel.asm near 2822
sym fset [sym make func Kernel_Hello] kernel.asm near 2878
sym fset [sym make func Kernel_Detach] kernel.asm near 3394
sym fset [sym make func KernelSafeLock] kernel.asm near 3505
sym fset [sym make func KernelSafeUnlock] kernel.asm near 3594
sym fset [sym make func Kernel_ReadMem] kernel.asm near 3612
sym fset [sym make func Kernel_WriteMem] kernel.asm near 3640
sym fset [sym make func Kernel_FillMem] kernel.asm near 3689
sym fset [sym make func Kernel_ReadAbs] kernel.asm near 3734
sym fset [sym make func Kernel_WriteAbs] kernel.asm near 3748
sym fset [sym make func Kernel_FillAbs] kernel.asm near 3774
sym fset [sym make func KernelMapOwner] kernel.asm near 3807
sym fset [sym make func Kernel_BlockInfo] kernel.asm near 3822
sym fset [sym make func Kernel_BlockFind] kernel.asm near 3914
sym fset [sym make func Kernel_ReadRegs] kernel.asm near 4027
sym fset [sym make func Kernel_WriteRegs] kernel.asm near 4204
sym fset [sym make func Kernel_AttachMem] kernel.asm near 4392
sym fset [sym make func Kernel_DetachMem] kernel.asm near 4418
sym vset [sym make var kcodeSeg] [type word] static 4444
sym vset [sym make var PIC1_Mask] [type byte] static 4448
sym vset [sym make var PIC2_Mask] [type byte] static 4449
sym vset [sym make var COM_Mask] [type byte] static 4450
sym vset [sym make var PSP] [type word] static 4451
sym vset [sym make var busMouse] [type word] static 4453
sym vset [sym make var sysFlags] [sym find type SysFlags] static 4455
sym vset [sym make var stubCode] [type word] static 4456
sym vset [sym make var stubType] [type byte] static 4458
sym fset [sym make func Main] main.asm far 4459
sym vset [sym make var skipBptAddr] [type dword] static 4529
sym vset [sym make var skipMask1] [type byte] static 4533
sym vset [sym make var skipIF] [type byte] static 4534
sym fset [sym make func SkipBptRecover] main.asm far 4535
sym fset [sym make func CatchInterrupt] main.asm near 4585
sym fset [sym make func IgnoreInterrupt] main.asm near 4643
sym vset [sym make var haltCodeAddr] [type word] static 4696
sym fset [sym make func IRQCommon] main.asm near 4698
sym make label InterruptHandlers near 4778
sym make label IRQ0 near 4778
sym make label IRQ1 near 4786
sym make label IRQ2 near 4794
sym make label IRQ3 near 4802
sym make label IRQ4 near 4810
sym make label IRQ5 near 4818
sym make label IRQ6 near 4826
sym make label IRQ7 near 4834
sym make label IRQ8 near 4842
sym make label IRQ9 near 4850
sym make label IRQ10 near 4858
sym make label IRQ11 near 4866
sym make label IRQ12 near 4874
sym make label IRQ13 near 4882
sym make label IRQ14 near 4890
sym make label IRQ15 near 4898
sym make label IRQ16 near 4906
sym make label IRQ17 near 4914
sym make label IRQ18 near 4922
sym make label IRQ19 near 4930
sym make label IRQ20 near 4938
sym make label IRQ21 near 4946
sym make label IRQ22 near 4954
sym make label IRQ23 near 4962
sym make label IRQ24 near 4970
sym make label IRQ25 near 4978
sym make label IRQ26 near 4986
sym make label IRQ27 near 4994
sym make label IRQ28 near 5002
sym make label IRQ29 near 5010
sym make label IRQ30 near 5018
sym make label IRQ31 near 5026
sym vset [sym make var prev_SP] [type word] static 5034
sym vset [sym make var prev_SS] [type word] static 5036
sym vset [sym make var last_SP] [type word] static 5038
sym vset [sym make var our_SS] [type word] static 5040
sym vset [sym make var ssRetAddr] [type word] static 5042
sym fset [sym make func SaveState] main.asm near 5044
sym vset [sym make var rsRetAddr] [type word] static 5264
sym fset [sym make func RestoreState] main.asm near 5266
sym fset [sym make func StubTimerInt] main.asm far 5381
sym fset [sym make func SetInterrupt] main.asm far 5414
sym fset [sym make func ResetInterrupt] main.asm near 5457
sym vset [sym make var stepVector] [type dword] static 5488
sym vset [sym make var stepping] [type word] static 5492
sym vset [sym make var servers] [type make array 114 [type word]] static 5494
sym vset [sym make var lastCall] [sym find type RpcHeader] static 5722
sym vset [sym make var rpc_FromHost] [type make array 256 [type byte]] static 5726
sym vset [sym make var rpc_ToHost] [type make array 256 [type byte]] static 5982
sym fset [sym make func Rpc_Length] rpc.asm near 6238
sym fset [sym make func Rpc_LoadRegs] rpc.asm near 6245
sym fset [sym make func RpcExit] rpc.asm near 6283
sym fset [sym make func RpcGoodbye] rpc.asm near 6349
sym fset [sym make func RpcContinue] rpc.asm near 6361
sym make label RpcContinueComm near 6366
sym fset [sym make func RpcStep] rpc.asm near 6393
sym fset [sym make func RpcStepReply] rpc.asm far 6417
sym fset [sym make func RpcSkipBpt] rpc.asm near 6475
sym fset [sym make func RpcMask] rpc.asm near 6531
sym fset [sym make func RpcInterrupt] rpc.asm near 6558
sym fset [sym make func RpcReadIO8] rpc.asm near 6597
sym fset [sym make func RpcReadIO16] rpc.asm near 6638
sym fset [sym make func RpcWriteIO8] rpc.asm near 6656
sym fset [sym make func RpcWriteIO16] rpc.asm near 6693
sym fset [sym make func RpcBeep] rpc.asm near 6707
sym fset [sym make func Rpc_Exit] rpc.asm near 6729
sym vset [sym make var callHeader] [sym find type RpcHeader] static 6742
sym vset [sym make var nextCallID] [type byte] static 6745
sym fset [sym make func Rpc_Call] rpc.asm near 6746
sym vset [sym make var replyHeader] [sym find type RpcHeader] static 6815
sym fset [sym make func Rpc_Reply] rpc.asm near 6819
sym vset [sym make var errorHeader] [sym find type RpcHeader] static 6858
sym vset [sym make var errorCode] [type byte] static 6862
sym fset [sym make func Rpc_Error] rpc.asm near 6863
sym fset [sym make func Rpc_Wait] rpc.asm near 6892
sym fset [sym make func Rpc_Run] rpc.asm near 6967
endseg scode
begseg sstack 0
sym vset [sym make var tpd] [sym find type ThreadPrivateData] static 0
sym vset [sym make var StackTop] [type word] static 64
sym vset [sym make var StackBot] [type word] static 320
endseg sstack
begseg stubInit 0
[sym tset [sym make type ComPortData] [type make struct
	CPD_portMask [type word] 0 16
	CPD_level [type word] 16 16
]]
sym vset [sym make var ports] [sym find type ComPortData] static 0
sym vset [sym make var devarg] [type make array 2 [type byte]] static 16
sym vset [sym make var device] [type byte] static 18
sym vset [sym make var baud] [type make array 2 [type byte]] static 19
sym vset [sym make var baudDivisors] [type make array 2 [type byte]] static 21
sym vset [sym make var divisor] [type byte] static 23
sym fset [sym make func Com_Init] com.asm near 24
sym vset [sym make var defArgs] [type byte] static 240
sym vset [sym make var kernelName] [type make array 11 [type byte]] static 241
sym fset [sym make func Kernel_Load] kernel.asm far 294
sym fset [sym make func FetchArg] main.asm near 496
sym vset [sym make var bMouse] [type make array 2 [type byte]] static 589
sym vset [sym make var noStart] [type make array 2 [type byte]] static 591
sym fset [sym make func MainHandleInit] main.asm far 593
sym fset [sym make func Rpc_Init] rpc.asm near 672
sym fset [sym make func Rpc_Serve] rpc.asm near 875
endseg stubInit
