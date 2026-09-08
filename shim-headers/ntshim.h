/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     Base header for the NT shim header set
 */

#ifndef _UACPI_NT_NTSHIM_H
#define _UACPI_NT_NTSHIM_H

#if !defined(_NTIFS_) && !defined(_NTDDK_) && !defined(_WDMDDK_)
#include <ntddk.h>
#endif

#ifndef NTDDI_VERSION
#error "NTDDI_VERSION must be defined before including the NT shim headers"
#endif

#ifndef CODE_SEG
#if defined(_MSC_VER)
#define CODE_SEG(segment) __declspec(code_seg(segment))
#elif defined(__GNUC__) || defined(__clang__)
#define CODE_SEG(segment) __attribute__((section(segment)))
#else
#define CODE_SEG(segment)
#endif
#endif

#ifndef INIT_FUNCTION
#define INIT_FUNCTION CODE_SEG("INIT")
#endif

#ifndef PAGED_CODE_SEG
#define PAGED_CODE_SEG CODE_SEG("PAGE")
#endif

#ifndef NTSYSAPI
#define NTSYSAPI DECLSPEC_IMPORT
#endif


struct _LOADER_PARAMETER_BLOCK;
struct _KPRCB;
struct _KPROCESSOR_STATE;

#ifndef _KINTERRUPT_ROUTINE_DEFINED
#define _KINTERRUPT_ROUTINE_DEFINED
typedef VOID (NTAPI *PKINTERRUPT_ROUTINE)(VOID);
#endif

#endif /* _UACPI_NT_NTSHIM_H */
