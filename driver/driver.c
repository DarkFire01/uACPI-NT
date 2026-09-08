/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     acpi.sys entry point
 */

#include "acpi.h"

#define NDEBUG
#include <debug.h>

CODE_SEG("INIT")
NTSTATUS
DriverEntry(
    _In_ PDRIVER_OBJECT DriverObject,
    _In_ PUNICODE_STRING RegistryPath)
{
    return 0;
}
