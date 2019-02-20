/*
 * Number of arguments for system calls:
 * Must match: /sys/sys/init_sysent.c /sys/sys/syscalls.c 
 *             /usr/include/syscall.h /usr/src/lib/libc/is68k/sys/NARGS.h
 */
                                               /*   0 indirect call */

#define        SETARG_exit             SETARG_1        /*   1 */
#define        RESTOR_exit             RESTOR_1

#define        SETARG_fork             SETARG_0        /*   2 */
#define        RESTOR_fork             RESTOR_0

#define        SETARG_read             SETARG_3        /*   3 */
#define        RESTOR_read             RESTOR_3

#define        SETARG_write            SETARG_3        /*   4 */
#define        RESTOR_write            RESTOR_3

#define        SETARG_open             SETARG_3        /*   5 */
#define        RESTOR_open             RESTOR_3

#define        SETARG_close            SETARG_1        /*   6 */
#define        RESTOR_close            RESTOR_1
                                               /*   7 is old: wait */
#define        SETARG_creat            SETARG_2        /*   8 */
#define        RESTOR_creat            RESTOR_2

#define        SETARG_link             SETARG_2        /*   9 */
#define        RESTOR_link             RESTOR_2

#define        SETARG_unlink           SETARG_1        /*  10 */
#define        RESTOR_unlink           RESTOR_1

#define        SETARG_execv            SETARG_2        /*  11 */
#define        RESTOR_execv            RESTOR_2

#define        SETARG_chdir            SETARG_1        /*  12 */
#define        RESTOR_chdir            RESTOR_1
                                               /*  13 is old: time */
#define        SETARG_mknod            SETARG_3        /*  14 */
#define        RESTOR_mknod            RESTOR_3

#define        SETARG_chmod            SETARG_2        /*  15 */
#define        RESTOR_chmod            RESTOR_2

#define        SETARG_chown            SETARG_3        /*  16 */
#define        RESTOR_chown            RESTOR_3
                                               /*  17 is old: sbreak */
                                               /*  18 is old: stat */
#define        SETARG_lseek            SETARG_3        /*  19 */
#define        RESTOR_lseek            RESTOR_3

#define        SETARG_getpid           SETARG_0        /*  20 */
#define        RESTOR_getpid           RESTOR_0
                                               /*  21 is old non NFS: mount */
                                               /*  22 is old non NFS: umount */
                                               /*  23 is old: setuid */
#define        SETARG_getuid           SETARG_0        /*  24 */
#define        RESTOR_getuid           RESTOR_0
                                               /*  25 is old: stime */
#define        SETARG_ptrace           SETARG_4        /*  26 */
#define        RESTOR_ptrace           RESTOR_4
                                               /*  27 is old: alarm */
                                               /*  28 is old: fstat */
                                               /*  29 is old: pause */
                                               /*  30 is old: utime */
                                               /*  31 is old: stty */
                                               /*  32 is old: gtty */
#define        SETARG_access           SETARG_2        /*  33 */
#define        RESTOR_access           RESTOR_2
                                               /*  34 is old: nice */
                                               /*  35 is old: ftime */
#define        SETARG_sync             SETARG_0        /*  36 */
#define        RESTOR_sync             RESTOR_0

#define        SETARG_kill             SETARG_2        /*  37 */
#define        RESTOR_kill             RESTOR_2

#define        SETARG_stat             SETARG_2        /*  38 */
#define        RESTOR_stat             RESTOR_2
                                               /*  39 is old: setpgrp */
#define        SETARG_lstat            SETARG_2        /*  40 */
#define        RESTOR_lstat            RESTOR_2

#define        SETARG_dup              SETARG_2        /*  41 */
#define        RESTOR_dup              RESTOR_2

#define        SETARG_pipe             SETARG_0        /*  42 */
#define        RESTOR_pipe             RESTOR_0
                                               /*  43 is old: times */
#define        SETARG_profil           SETARG_4        /*  44 */
#define        RESTOR_profil           RESTOR_4
                                               /*  45 is unused */
                                               /*  46 is old: setgid */
#define        SETARG_getgid           SETARG_0        /*  47 */
#define        RESTOR_getgid           RESTOR_0
                                               /*  48 is old: sigsys */
                                               /*  49 reserved for USG */
                                               /*  50 reserved for USG */
#define        SETARG_acct             SETARG_1        /*  51 */
#define        RESTOR_acct             RESTOR_1

#ifdef vax
                                               /*  52 is old: phys */
                                               /*  53 is old: syslock */
#else  vax
#define        SETARG_sky              SETARG_0        /*  52 */
#define        RESTOR_sky              RESTOR_0

#define        SETARG_ulock            SETARG_0        /*  53 */
#define        RESTOR_ulock            RESTOR_0
#endif vax

#define        SETARG_ioctl            SETARG_3        /*  54 */
#define        RESTOR_ioctl            RESTOR_3

#define        SETARG_reboot           SETARG_1        /*  55 */
#define        RESTOR_reboot           RESTOR_1

#ifdef vax
                                               /*  56 is old: mpxchan */
#else  vax
#define        SETARG_skymap           SETARG_0        /*  56 */
#define        RESTOR_skymap           RESTOR_0
#endif vax

#define        SETARG_symlink          SETARG_2        /*  57 */
#define        RESTOR_symlink          RESTOR_2

#define        SETARG_readlink         SETARG_3        /*  58 */
#define        RESTOR_readlink         RESTOR_3

#define        SETARG_execve           SETARG_3        /*  59 */
#define        RESTOR_execve           RESTOR_3

#define        SETARG_umask            SETARG_1        /*  60 */
#define        RESTOR_umask            RESTOR_1

#define        SETARG_chroot           SETARG_1        /*  61 */
#define        RESTOR_chroot           RESTOR_1

#define        SETARG_fstat            SETARG_2        /*  62 */
#define        RESTOR_fstat            RESTOR_2
                                               /*  63 is unused */
#define        SETARG_getpagesize      SETARG_1        /*  64 */
#define        RESTOR_getpagesize      RESTOR_1

#define        SETARG_mremap           SETARG_5        /*  65 */
#define        RESTOR_mremap           RESTOR_5
                                               /*  66 is old: vfork */
                                               /*  67 is old: vread */
                                               /*  68 is old: vwrite */
#define        SETARG_sbrk             SETARG_1        /*  69 */
#define        RESTOR_sbrk             RESTOR_1

#define        SETARG_sstk             SETARG_1        /*  70 */
#define        RESTOR_sstk             RESTOR_1

#define        SETARG_mmap             SETARG_6        /*  71 */
#define        RESTOR_mmap             RESTOR_6
                                               /*  72 is old: vadvise */
#define        SETARG_munmap           SETARG_2        /*  73 */
#define        RESTOR_munmap           RESTOR_2

#define        SETARG_mprotect         SETARG_3        /*  74 */
#define        RESTOR_mprotect         RESTOR_3

#define        SETARG_madvise          SETARG_3        /*  75 */
#define        RESTOR_madvise          RESTOR_3

#define        SETARG_vhangup          SETARG_1        /*  76 */
#define        RESTOR_vhangup          RESTOR_1
                                               /*  77 is old: vlimit */
#define        SETARG_mincore          SETARG_3        /*  78 */
#define        RESTOR_mincore          RESTOR_3

#define        SETARG_getgroups        SETARG_2        /*  79 */
#define        RESTOR_getgroups        RESTOR_2

#define        SETARG_setgroups        SETARG_2        /*  80 */
#define        RESTOR_setgroups        RESTOR_2

#define        SETARG_getpgrp          SETARG_1        /*  81 */
#define        RESTOR_getpgrp          RESTOR_1

#define        SETARG_setpgrp          SETARG_2        /*  82 */
#define        RESTOR_setpgrp          RESTOR_2

#define        SETARG_setitimer        SETARG_3        /*  83 */
#define        RESTOR_setitimer        RESTOR_3

#define        SETARG_wait             SETARG_0        /*  84 */
#define        RESTOR_wait             RESTOR_0

#define        SETARG_swapon           SETARG_1        /*  85 */
#define        RESTOR_swapon           RESTOR_1

#define        SETARG_getitimer        SETARG_2        /*  86 */
#define        RESTOR_getitimer        RESTOR_2

#define        SETARG_gethostname      SETARG_2        /*  87 */
#define        RESTOR_gethostname      RESTOR_2

#define        SETARG_sethostname      SETARG_2        /*  88 */
#define        RESTOR_sethostname      RESTOR_2

#define        SETARG_getdtablesize    SETARG_0        /*  89 */
#define        RESTOR_getdtablesize    RESTOR_0

#define        SETARG_dup2             SETARG_2        /*  90 */
#define        RESTOR_dup2             RESTOR_2

#define        SETARG_getdopt          SETARG_2        /*  91 */
#define        RESTOR_getdopt          RESTOR_2

#define        SETARG_fcntl            SETARG_3        /*  92 */
#define        RESTOR_fcntl            RESTOR_3

#define        SETARG_select           SETARG_5        /*  93 */
#define        RESTOR_select           RESTOR_5

#define        SETARG_setdopt          SETARG_2        /*  94 */
#define        RESTOR_setdopt          RESTOR_2

#define        SETARG_fsync            SETARG_1        /*  95 */
#define        RESTOR_fsync            RESTOR_1

#define        SETARG_setpriority      SETARG_3        /*  96 */
#define        RESTOR_setpriority      RESTOR_3

#define        SETARG_socket           SETARG_3        /*  97 */
#define        RESTOR_socket           RESTOR_3

#define        SETARG_connect          SETARG_3        /*  98 */
#define        RESTOR_connect          RESTOR_3

#define        SETARG_accept           SETARG_3        /*  99 */
#define        RESTOR_accept           RESTOR_3

#define        SETARG_getpriority      SETARG_2        /* 100 */
#define        RESTOR_getpriority      RESTOR_2

#define        SETARG_send             SETARG_4        /* 101 */
#define        RESTOR_send             RESTOR_4

#define        SETARG_recv             SETARG_4        /* 102 */
#define        RESTOR_recv             RESTOR_4

#define        SETARG_sigreturn        SETARG_1        /* 103 */
#define        RESTOR_sigreturn        RESTOR_1

#define        SETARG_bind             SETARG_3        /* 104 */
#define        RESTOR_bind             RESTOR_3

#define        SETARG_setsockopt       SETARG_5        /* 106 */
#define        RESTOR_setsockopt       RESTOR_5

#define        SETARG_listen           SETARG_2        /* 106 */
#define        RESTOR_listen           RESTOR_2
                                               /* 107 was vtimes */
#define        SETARG_sigvec           SETARG_3        /* 108 */
#define        RESTOR_sigvec           RESTOR_3

#define        SETARG_sigblock         SETARG_1        /* 109 */
#define        RESTOR_sigblock         RESTOR_1

#define        SETARG_sigsetmask       SETARG_1        /* 110 */
#define        RESTOR_sigsetmask       RESTOR_1

#define        SETARG_sigpause         SETARG_1        /* 111 */
#define        RESTOR_sigpause         RESTOR_1

#define        SETARG_sigstack         SETARG_2        /* 112 */
#define        RESTOR_sigstack         RESTOR_2

#define        SETARG_recvmsg          SETARG_3        /* 113 */
#define        RESTOR_recvmsg          RESTOR_3

#define        SETARG_sendmsg          SETARG_3        /* 114 */
#define        RESTOR_sendmsg          RESTOR_3
                                               /* 115 is vtrace */
#define        SETARG_gettimeofday     SETARG_2        /* 116 */
#define        RESTOR_gettimeofday     RESTOR_2

#define        SETARG_getrusage        SETARG_2        /* 117 */
#define        RESTOR_getrusage        RESTOR_2

#define        SETARG_getsockopt       SETARG_5        /* 118 */
#define        RESTOR_getsockopt       RESTOR_5
                                               /* 119 is resuba */
#define        SETARG_readv            SETARG_3        /* 120 */
#define        RESTOR_readv            RESTOR_3

#define        SETARG_writev           SETARG_3        /* 121 */
#define        RESTOR_writev           RESTOR_3

#define        SETARG_settimeofday     SETARG_2        /* 122 */
#define        RESTOR_settimeofday     RESTOR_2

#define        SETARG_fchown           SETARG_3        /* 123 */
#define        RESTOR_fchown           RESTOR_3

#define        SETARG_fchmod           SETARG_2        /* 124 */
#define        RESTOR_fchmod           RESTOR_2

#define        SETARG_recvfrom         SETARG_6        /* 125 */
#define        RESTOR_recvfrom         RESTOR_6

#define        SETARG_setreuid         SETARG_2        /* 126 */
#define        RESTOR_setreuid         RESTOR_2

#define        SETARG_setregid         SETARG_2        /* 127 */
#define        RESTOR_setregid         RESTOR_2

#define        SETARG_rename           SETARG_2        /* 128 */
#define        RESTOR_rename           RESTOR_2

#define        SETARG_truncate         SETARG_2        /* 129 */
#define        RESTOR_truncate         RESTOR_2

#define        SETARG_ftruncate        SETARG_2        /* 130 */
#define        RESTOR_ftruncate        RESTOR_2

#define        SETARG_flock            SETARG_2        /* 131 */
#define        RESTOR_flock            RESTOR_2

#ifdef vax
                                               /* 132 is unused */
#else  vax
#define        SETARG_adjtime          SETARG_2        /* 132 */
#define        RESTOR_adjtime          RESTOR_2
#endif vax

#define        SETARG_sendto           SETARG_6        /* 133 */
#define        RESTOR_sendto           RESTOR_6

#define        SETARG_shutdown         SETARG_2        /* 134 */
#define        RESTOR_shutdown         RESTOR_2

#define        SETARG_socketpair       SETARG_5        /* 135 */
#define        RESTOR_socketpair       RESTOR_5

#define        SETARG_mkdir            SETARG_2        /* 136 */
#define        RESTOR_mkdir            RESTOR_2

#define        SETARG_rmdir            SETARG_1        /* 137 */
#define        RESTOR_rmdir            RESTOR_1

#define        SETARG_utimes           SETARG_2        /* 138 */
#define        RESTOR_utimes           RESTOR_2
                                               /* 139 used inetrnally */
#ifdef vax
                                               /* 140 adjtime */
#else  vax
#define        SETARG_getmachname      SETARG_3        /* 140 TRFS */
#define        RESTOR_getmachname      RESTOR_3
#endif vax

#define        SETARG_getpeername      SETARG_3        /* 141 */
#define        RESTOR_getpeername      RESTOR_3

#define        SETARG_gethostid        SETARG_2        /* 142 */
#define        RESTOR_gethostid        RESTOR_2

#define        SETARG_sethostid        SETARG_2        /* 143 */
#define        RESTOR_sethostid        RESTOR_2

#define        SETARG_getrlimit        SETARG_2        /* 144 */
#define        RESTOR_getrlimit        RESTOR_2

#define        SETARG_setrlimit        SETARG_2        /* 145 */
#define        RESTOR_setrlimit        RESTOR_2

#define        SETARG_killpg           SETARG_2        /* 146 */
#define        RESTOR_killpg           RESTOR_2

#ifdef vax
                                               /* 147 unused */
#else  vax
#define        SETARG_lockf            SETARG_3        /* 147 */
#define        RESTOR_lockf            RESTOR_3
#endif vax

#define        SETARG_setquota         SETARG_2        /* 148 */
#define        RESTOR_setquota         RESTOR_2

#define        SETARG_quota            SETARG_4        /* 149 */
#define        RESTOR_quota            RESTOR_4

#define        SETARG_getsockname      SETARG_3        /* 150 */
#define        RESTOR_getsockname      RESTOR_3

#ifdef vax
                                               /* 151 unused */
                                               /* 152 unused */
                                               /* 153 unused */
                                               /* 154 unused */
#else  vax
#define        SETARG_plock            SETARG_0        /* 151 */
#define        RESTOR_plock            RESTOR_0

#define        SETARG_punlock          SETARG_0        /* 152 */
#define        RESTOR_punlock          RESTOR_0

#define        SETARG_highpri          SETARG_0        /* 153 */
#define        RESTOR_highpri          RESTOR_0

#define        SETARG_normalpri        SETARG_0        /* 154 */
#define        RESTOR_normalpri        RESTOR_0
#endif vax

#define        SETARG_nfssvc           SETARG_1        /* 155 NFS: */
#define        RESTOR_nfssvc           RESTOR_1

#define        SETARG_getdirentries    SETARG_4        /* 156 NFS: */
#define        RESTOR_getdirentries    RESTOR_4

#define        SETARG_statfs           SETARG_2        /* 157 NFS: */
#define        RESTOR_statfs           RESTOR_2

#define        SETARG_fstatfs          SETARG_2        /* 158 NFS: */
#define        RESTOR_fstatfs          RESTOR_2

#define        SETARG_unmount          SETARG_1        /* 159 NFS: */
#define        RESTOR_unmount          RESTOR_1

#define        SETARG_async_daemon     SETARG_0        /* 160 NFS: */
#define        RESTOR_async_daemon     RESTOR_0

#define        SETARG_getfh            SETARG_2        /* 161 NFS: */
#define        RESTOR_getfh            RESTOR_2

#define        SETARG_getdomainname    SETARG_2        /* 162 NFS: */
#define        RESTOR_getdomainname    RESTOR_2

#define        SETARG_setdomainname    SETARG_2        /* 163 NFS: */
#define        RESTOR_setdomainname    RESTOR_2
                                               /* 164 unused */

#define        SETARG_quotactl         SETARG_4        /* 165 NFS */
#define        RESTOR_quotactl         RESTOR_4

#define        SETARG_exportfs         SETARG_0        /* 166 NFS: */
#define        RESTOR_exportfs         RESTOR_0

#define        SETARG_mount            SETARG_4        /* 167 NFS: */
#define        RESTOR_mount            RESTOR_4
                                               /* 168 unused */
                                               /* 169 unused */
#define        SETARG_getuniverse      SETARG_0        /* 170 */
#define        RESTOR_getuniverse      RESTOR_0

#define        SETARG_setuniverse      SETARG_1        /* 171 */
#define        RESTOR_setuniverse      RESTOR_1

#define        SETARG_getmachtype      SETARG_0        /* 172 */
#define        RESTOR_getmachtype      RESTOR_0
