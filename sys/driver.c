/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     Driver entry point
 * COPYRIGHT:   Copyright 2026 Justin Miller <justin.miller@reactos.org>
 */

#include <uacpint.h>

PDRIVER_OBJECT GlobalAcpiDriverObj;
UCHAR UacpiNtProcessorBrand[48];

/*
 * Example:
 * ACPI\VEN_ACPI&DEV_0007
 * ACPI\AuthenticAMD_-_AMD64_Family_26_Model_68
 * ^ Later windows also has this.
 */
VOID
UacpiNtSetProcesssorInformation(VOID)
{
    UNICODE_STRING Path;
    RtlInitUnicodeString(&Path,  L"\\Registry\\Machine\\Hardware\\Description\\System\\CentralProcessor\\0");


}

NTSTATUS
NTAPI
DriverEntry(_In_ PDRIVER_OBJECT  DriverObject,
            _In_ PUNICODE_STRING RegistryPath)
{
    UacpiNtSetProcesssorInformation();
}
