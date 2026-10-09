---
nav_order: 9.5
---
### System Internals

This volume documents implementation details of the #FreeGEOS system
software itself: how the kernel, the loader and the low-level libraries
work internally. It is aimed at people working on the system rather than
at SDK users writing applications.

**[1 Protected Mode](Internals/iprotmode.md)**  
    [1.1 Overview](Internals/iprotmode.md#11-overview)  
      [1.1.1 Protected Mode and CPU Word Size](Internals/iprotmode.md#111-protected-mode-and-cpu-word-size)  
    [1.2 The GPMI](Internals/iprotmode.md#12-the-gpmi)  
      [1.2.1 Calling GPMI Services](Internals/iprotmode.md#121-calling-gpmi-services)  
      [1.2.2 The Selector Table](Internals/iprotmode.md#122-the-selector-table)  
    [1.3 The Resident Loader](Internals/iprotmode.md#13-the-resident-loader)  
    [1.4 System Restart](Internals/iprotmode.md#14-system-restart)  
      [1.4.1 Why the Real-Mode Restart Cannot Work](Internals/iprotmode.md#141-why-the-real-mode-restart-cannot-work)  
      [1.4.2 Restart Sequence](Internals/iprotmode.md#142-restart-sequence)  
      [1.4.3 The Loader Snapshot](Internals/iprotmode.md#143-the-loader-snapshot)  
      [1.4.4 Freeing the Old Incarnation](Internals/iprotmode.md#144-freeing-the-old-incarnation)  
      [1.4.5 Kernel State That Must Be Undone](Internals/iprotmode.md#145-kernel-state-that-must-be-undone)  
      [1.4.6 Compatibility](Internals/iprotmode.md#146-compatibility)  
    [1.5 Rebooting the Machine](Internals/iprotmode.md#15-rebooting-the-machine)  
    [1.6 Real-Mode Callbacks and DOS Memory](Internals/iprotmode.md#16-real-mode-callbacks-and-dos-memory)  
    [1.7 The Host Interface Event Interrupt](Internals/iprotmode.md#17-the-host-interface-event-interrupt)  
      [1.7.1 Why the Interrupt Needs Special Care](Internals/iprotmode.md#171-why-the-interrupt-needs-special-care)  
      [1.7.2 How HostIf Handles It](Internals/iprotmode.md#172-how-hostif-handles-it)  
    [1.8 Zero-Initialized Reallocation of Discarded Blocks](Internals/iprotmode.md#18-zero-initialized-reallocation-of-discarded-blocks)  
    [1.9 Swat Support](Internals/iprotmode.md#19-swat-support)  
      [1.9.1 Exit to DOS Under the Stub](Internals/iprotmode.md#191-exit-to-dos-under-the-stub)  
      [1.9.2 Stopping With Ctrl-C](Internals/iprotmode.md#192-stopping-with-ctrl-c)  
      [1.9.3 Test Status](Internals/iprotmode.md#193-test-status)  
    [1.10 Testing the Restart](Internals/iprotmode.md#110-testing-the-restart)  
    [1.11 Building on Linux](Internals/iprotmode.md#111-building-on-linux)  
    [1.12 Video Driver Re-Initialization and videoSem](Internals/iprotmode.md#112-video-driver-re-initialization-and-videosem)  
    [1.13 Real-Mode Buffers for BIOS Calls](Internals/iprotmode.md#113-real-mode-buffers-for-bios-calls)  
    [1.14 Driver Buffers and Large Screens](Internals/iprotmode.md#114-driver-buffers-and-large-screens)  
    [1.15 Stale Segment Registers](Internals/iprotmode.md#115-stale-segment-registers)  

**[2 Greyscale Text](Internals/igreytext.md)**  
    [2.1 Overview](Internals/igreytext.md#21-overview)  
    [2.2 Switching It On](Internals/igreytext.md#22-switching-it-on)  
    [2.3 The Request](Internals/igreytext.md#23-the-request)  
      [2.3.1 When Greyscale Is Requested](Internals/igreytext.md#231-when-greyscale-is-requested)  
      [2.3.2 Video Driver Registration](Internals/igreytext.md#232-video-driver-registration)  
      [2.3.3 Font Cache Key and the Font Driver](Internals/igreytext.md#233-font-cache-key-and-the-font-driver)  
    [2.4 Font Buffer Format](Internals/igreytext.md#24-font-buffer-format)  
      [2.4.1 Flags](Internals/igreytext.md#241-flags)  
      [2.4.2 GreyCharData](Internals/igreytext.md#242-greychardata)  
      [2.4.3 Subpixel Phases](Internals/igreytext.md#243-subpixel-phases)  
    [2.5 Font Buffer Size Limits](Internals/igreytext.md#25-font-buffer-size-limits)  
    [2.6 Rendering in the TrueType Driver](Internals/igreytext.md#26-rendering-in-the-truetype-driver)  
      [2.6.1 When Greyscale Is Granted](Internals/igreytext.md#261-when-greyscale-is-granted)  
      [2.6.2 Hinting](Internals/igreytext.md#262-hinting)  
      [2.6.3 Oversampling](Internals/igreytext.md#263-oversampling)  
      [2.6.4 Glyph Cache](Internals/igreytext.md#264-glyph-cache)  
    [2.7 Drawing in the Video Driver](Internals/igreytext.md#27-drawing-in-the-video-driver)  
      [2.7.1 Code Paths](Internals/igreytext.md#271-code-paths)  
      [2.7.2 Blending](Internals/igreytext.md#272-blending)  
      [2.7.3 Subpixel Phase](Internals/igreytext.md#273-subpixel-phase)  
      [2.7.4 Building VGA16](Internals/igreytext.md#274-building-vga16)  
    [2.8 Tests](Internals/igreytext.md#28-tests)  
    [2.9 Limitations and Open Points](Internals/igreytext.md#29-limitations-and-open-points)  
