/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     uACPI-NT Registry handling code
 * COPYRIGHT:   Copyright 2026 Justin Miller <justin.miller@reactos.org>
 */

#include <uacpint.h>

NTSTATUS
UacpiNtRegOpenKey(
    _In_ HANDLE ParentKeyHandle,
    _In_ LPCWSTR KeyName,
    _In_ ACCESS_MASK DesiredAccess,
    _Out_ HANDLE KeyHandle)
{
    OBJECT_ATTRIBUTES ObjectAttributes;
    UNICODE_STRING Name;

    RtlInitUnicodeString(&Name, KeyName);

    InitializeObjectAttributes(&ObjectAttributes,
                               &Name,
                               OBJ_CASE_INSENSITIVE | OBJ_KERNEL_HANDLE,
                               ParentKeyHandle,
                               NULL);
    return ZwOpenKey(KeyHandle,
                     DesiredAccess,
                     &ObjectAttributes);
}

NTSTATUS
UacpiNtRegQueryValue(
    _In_ HANDLE KeyHandle,
    _In_ PCWSTR ValueName,
    _Out_opt_ PULONG Type,
    _Out_writes_bytes_to_opt_(*DataLength, *DataLength) PVOID Data,
    _Inout_opt_ PULONG DataLength)
{
    PKEY_VALUE_PARTIAL_INFORMATION ValueInfo = NULL;
    ULONG OriginalDataLength = 0;;
    UNICODE_STRING Name;
    ULONG InfoLength;
    NTSTATUS Status;

    RtlInitUnicodeString(&Name, ValueName);

    if (DataLength)
        OriginalDataLength = *DataLength;

    if (Data != NULL && OriginalDataLength > 0)
    {
        InfoLength = FIELD_OFFSET(KEY_VALUE_PARTIAL_INFORMATION, Data) + OriginalDataLength;
        
        ValueInfo = ExAllocatePoolWithTag(PagedPool, InfoLength, UACPINT_POOL_TAG);
        if (!ValueInfo)
            return STATUS_INSUFFICIENT_RESOURCES;
    }

    Status = ZwQueryValueKey(KeyHandle,
                             &Name,
                             KeyValuePartialInformation,
                             ValueInfo,
                             InfoLength,
                             &InfoLength);
    
    if (DataLength)
    {
        if (InfoLength >= (ULONG)FIELD_OFFSET(KEY_VALUE_PARTIAL_INFORMATION, Data))
        {
            *DataLength = InfoLength - FIELD_OFFSET(KEY_VALUE_PARTIAL_INFORMATION, Data);
        }
        else
        {
            *DataLength = 0;
        }

        if (ValueInfo)
        {
            if (Status == STATUS_BUFFER_OVERFLOW || Status == STATUS_BUFFER_TOO_SMALL)
                return STATUS_SUCCESS;
            return Status;
        }

        if (NT_SUCCESS(Status))
        {
            if (Type)
                *Type = ValueInfo->Type;

            RtlCopyMemory(Data, ValueInfo->Data, ValueInfo->DataLength);

            if ((ValueInfo->Type == REG_SZ || 
               ValueInfo->Type == REG_EXPAND_SZ || 
               ValueInfo->Type == REG_MULTI_SZ) && 
               (ValueInfo->DataLength <= OriginalDataLength - sizeof(WCHAR)))
            {
                PWCHAR Ptr = (PWCHAR)((PUCHAR)Data + ValueInfo->DataLength);
                if (Ptr > (PWCHAR)Data && Ptr[-1] != L'\0')
                    *Ptr = L'\0';
            }
        }
    }

    ExFreePoolWithTag(ValueInfo, UACPINT_POOL_TAG);
    return Status;
}