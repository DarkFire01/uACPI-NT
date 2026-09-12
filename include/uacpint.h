/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     uACPI-NT main header
 * COPYRIGHT:   Copyright 2026 Justin Miller <justin.miller@reactos.org>
 */

#pragma once

#include <ntddk.h>
#include <ntstrsafe.h>

#include <uacpi/uacpi.h>
#include <uacpi/namespace.h>
#include <uacpi/utilities.h>
#include <uacpi/resources.h>
#include <uacpi/event.h>
#include <uacpi/sleep.h>
#include <uacpi/status.h>
#include <uacpi/types.h>

#define UACPINT_POOL_TAG    'IpcA'

#define UACPINT_STA_PRESENT      0x00000001u
#define UACPINT_STA_FUNCTIONING  0x00000008u

typedef enum _UACPINT_DEVOBJECT_TYPE
{
    UacpiNtDevObjFdo    = 'FDO_',
    UacpiNtDevObjPdo    = 'PDO_',
    UacpiNtDevObjFilter = 'FLT_',
} UACPINT_DEVOBJECT_TYPE;

typedef struct _UACPINT_SHARED
{
    UACPINT_DEVOBJECT_TYPE Type;
    PDEVICE_OBJECT         Self;
} UACPINT_SHARED, *PUACPINT_SHARED;

/*
 * ACPI\PNP0C08
 */
typedef struct _UACPINT_FDO
{
    UACPINT_SHARED Shared;
} UACPINT_FDO, *PUACPINT_FDO;

/*
 * ACPI Enumerated Device
 */
typedef struct _UACPINT_PDO
{
    UACPINT_SHARED Shared;
} UACPINT_PDO, *PUACPINT_PDO;

/*
 * ACPI Filter Device Object
 */
typedef struct _UACPINT_FLT
{
    UACPINT_SHARED Shared;
} UACPINT_FLT, *PUACPINT_FLT;

extern PUACPINT_FDO GlobalAcpiFdo;
extern PDRIVER_OBJECT GlobalAcpiDriverObj;
extern UNICODE_STRING GlobalDriverRegPath;

#include <uacpintreg.h>
#include <uacpihal.h>
