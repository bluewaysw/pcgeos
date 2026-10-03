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
    [1.10 Testing the Restart](Internals/iprotmode.md#110-testing-the-restart)  
    [1.11 Building on Linux](Internals/iprotmode.md#111-building-on-linux)  
