/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     The ARC configuration tree, as far as uacpi_host.c needs it
 */

#ifndef _UACPI_NT_ARC_ARC_H
#define _UACPI_NT_ARC_ARC_H

#include <ntshim.h>

/* CONFIGURATION_COMPONENT.Flags */
typedef enum _IDENTIFIER_FLAG
{
    Failed = 0x01,
    ReadOnly = 0x02,
    Removable = 0x04,
    ConsoleIn = 0x08,
    ConsoleOut = 0x10,
    Input = 0x20,
    Output = 0x40
} IDENTIFIER_FLAG;

typedef enum _CONFIGURATION_CLASS
{
    SystemClass,
    ProcessorClass,
    CacheClass,
    AdapterClass,
    ControllerClass,
    PeripheralClass,
    MemoryClass,
    MaximumClass
} CONFIGURATION_CLASS;

typedef struct _CONFIGURATION_COMPONENT
{
    CONFIGURATION_CLASS Class;
    CONFIGURATION_TYPE Type;
    IDENTIFIER_FLAG Flags;
    USHORT Version;
    USHORT Revision;
    ULONG Key;
    ULONG AffinityMask;
    ULONG ConfigurationDataLength;
    ULONG IdentifierLength;
    PCHAR Identifier;
} CONFIGURATION_COMPONENT, *PCONFIGURATION_COMPONENT;

typedef struct _CONFIGURATION_COMPONENT_DATA
{
    struct _CONFIGURATION_COMPONENT_DATA *Parent;
    struct _CONFIGURATION_COMPONENT_DATA *Child;
    struct _CONFIGURATION_COMPONENT_DATA *Sibling;
    CONFIGURATION_COMPONENT ComponentEntry;
    PVOID ConfigurationData;
} CONFIGURATION_COMPONENT_DATA, *PCONFIGURATION_COMPONENT_DATA;

typedef struct _LOADER_PARAMETER_BLOCK
{
#if (NTDDI_VERSION >= NTDDI_WIN7)
    ULONG OsMajorVersion;
    ULONG OsMinorVersion;
    ULONG Size;
    ULONG Reserved;
#endif
    LIST_ENTRY LoadOrderListHead;
    LIST_ENTRY MemoryDescriptorListHead;
    LIST_ENTRY BootDriverListHead;
#if (NTDDI_VERSION >= NTDDI_WIN8)
    LIST_ENTRY EarlyLaunchListHead;
    LIST_ENTRY CoreDriverListHead;
#endif
#if (NTDDI_VERSION >= NTDDI_WIN10)
    LIST_ENTRY CoreExtensionsDriverListHead;
    LIST_ENTRY TpmCoreDriverListHead;
#endif
    ULONG_PTR KernelStack;
    ULONG_PTR Prcb;
    ULONG_PTR Process;
    ULONG_PTR Thread;
#if (NTDDI_VERSION >= NTDDI_WIN8)
    ULONG KernelStackSize;
#endif
    ULONG RegistryLength;
    PVOID RegistryBase;
    PCONFIGURATION_COMPONENT_DATA ConfigurationRoot;
    /* ...the rest of the block is deliberately not described here. */
} LOADER_PARAMETER_BLOCK, *PLOADER_PARAMETER_BLOCK;

#endif /* _UACPI_NT_ARC_ARC_H */
