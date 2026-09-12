/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     Shared declarations for acpi.sys
 */

#ifndef _UACPI_NT_ACPI_H
#define _UACPI_NT_ACPI_H

#include <ntddk.h>
#include <ndk/ntndk.h>

#include <uacpi/uacpi.h>
#include <uacpi/tables.h>
#include <uacpi/utilities.h>

#define UACPINT_POOL_TAG   'ipcA'

#if (NTDDI_VERSION >= NTDDI_WIN8)
#define UACPINT_NONPAGED_POOL  NonPagedPoolNx
#else
#define UACPINT_NONPAGED_POOL  NonPagedPool
#endif

#endif /* _UACPI_NT_ACPI_H */
