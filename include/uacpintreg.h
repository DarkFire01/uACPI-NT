/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     uACPI-NT Registry handling code
 * COPYRIGHT:   Copyright 2026 Justin Miller <justin.miller@reactos.org>
 */

#pragma once

NTSTATUS
UacpiNtRegQueryValue(
    _In_ HANDLE KeyHandle,
    _In_ PCWSTR ValueName,
    _Out_opt_ PULONG Type,
    _Out_writes_bytes_to_opt_(*DataLength, *DataLength) PVOID Data,
    _Inout_opt_ PULONG DataLength
);

NTSTATUS
UacpiNtRegOpenKey(
    _In_ HANDLE ParentKeyHandle,
    _In_ LPCWSTR KeyName,
    _In_ ACCESS_MASK DesiredAccess,
    _Out_ HANDLE KeyHandle
);
