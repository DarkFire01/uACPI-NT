/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     ReactOS-style DPRINT macros
 *
 * Raise the level with, e.g.
 *     ed nt!Kd_IHVDRIVER_Mask 0xffffffff
 */

#ifndef _UACPI_NT_DEBUG_H
#define _UACPI_NT_DEBUG_H

#include <ntshim.h>

#ifndef DPFLTR_IHVDRIVER_ID
#define DPFLTR_IHVDRIVER_ID 77
#endif

#define DPRINT1(...) DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL, __VA_ARGS__)

#ifdef NDEBUG
#define DPRINT(...) ((void)0)
#else
#define DPRINT(...) DbgPrintEx(DPFLTR_IHVDRIVER_ID, DPFLTR_TRACE_LEVEL, __VA_ARGS__)
#endif

#define UNIMPLEMENTED       DPRINT1("%s is UNIMPLEMENTED\n", __FUNCTION__)
#define UNIMPLEMENTED_ONCE                                  \
    do {                                                    \
        static BOOLEAN _bWarned = FALSE;                    \
        if (!_bWarned) { _bWarned = TRUE; UNIMPLEMENTED; }   \
    } while (0)

#endif /* _UACPI_NT_DEBUG_H */
