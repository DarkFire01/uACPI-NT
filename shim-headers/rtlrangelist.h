/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     Rtl range list declarations
 */

#ifndef _UACPI_NT_RTLRANGELIST_H
#define _UACPI_NT_RTLRANGELIST_H

#include <ntshim.h>

#ifdef __cplusplus
extern "C" {
#endif

/* RTL_RANGE.Flags */
#define RTL_RANGE_SHARED                    0x01
#define RTL_RANGE_CONFLICT                  0x02

/* RtlAddRange Flags */
#define RTL_RANGE_LIST_ADD_IF_CONFLICT      0x00000001
#define RTL_RANGE_LIST_ADD_SHARED           0x00000002

/* RtlFindRange / RtlIsRangeAvailable Flags */
#define RTL_RANGE_LIST_SHARED_OK            0x00000001
#define RTL_RANGE_LIST_NULL_CONFLICT_OK     0x00000002

/* RtlMergeRangeLists Flags */
#define RTL_RANGE_LIST_MERGE_IF_CONFLICT    0x00000001

typedef struct _RTL_RANGE_LIST
{
    LIST_ENTRY ListHead;
    ULONG Flags;
    ULONG Count;
    ULONG Stamp;
} RTL_RANGE_LIST, *PRTL_RANGE_LIST;

typedef struct _RTL_RANGE
{
    ULONGLONG Start;
    ULONGLONG End;
    PVOID UserData;
    PVOID Owner;
    UCHAR Attributes;
    UCHAR Flags;
} RTL_RANGE, *PRTL_RANGE;

typedef struct _RTL_RANGE_LIST_ITERATOR
{
    PLIST_ENTRY RangeListHead;
    PLIST_ENTRY MergedHead;
    PVOID Current;
    ULONG Stamp;
} RTL_RANGE_LIST_ITERATOR, *PRTL_RANGE_LIST_ITERATOR;

/*
 * Returning FALSE from the callback means "this really is a conflict"; TRUE
 * tells the range list to look past it and keep searching.
 */
typedef BOOLEAN
(NTAPI *PRTL_CONFLICT_RANGE_CALLBACK)(
    _In_ PVOID Context,
    _In_ struct _RTL_RANGE *Range
);

NTSYSAPI
VOID
NTAPI
RtlInitializeRangeList(
    _Out_ PRTL_RANGE_LIST RangeList
);

NTSYSAPI
VOID
NTAPI
RtlFreeRangeList(
    _In_ PRTL_RANGE_LIST RangeList
);

NTSYSAPI
NTSTATUS
NTAPI
RtlCopyRangeList(
    _Out_ PRTL_RANGE_LIST CopyRangeList,
    _In_ PRTL_RANGE_LIST RangeList
);

NTSYSAPI
NTSTATUS
NTAPI
RtlAddRange(
    _Inout_ PRTL_RANGE_LIST RangeList,
    _In_ ULONGLONG Start,
    _In_ ULONGLONG End,
    _In_ UCHAR Attributes,
    _In_ ULONG Flags,
    _In_opt_ PVOID UserData,
    _In_opt_ PVOID Owner
);

NTSYSAPI
NTSTATUS
NTAPI
RtlDeleteRange(
    _Inout_ PRTL_RANGE_LIST RangeList,
    _In_ ULONGLONG Start,
    _In_ ULONGLONG End,
    _In_opt_ PVOID Owner
);

NTSYSAPI
NTSTATUS
NTAPI
RtlDeleteOwnersRanges(
    _Inout_ PRTL_RANGE_LIST RangeList,
    _In_opt_ PVOID Owner
);

NTSYSAPI
NTSTATUS
NTAPI
RtlFindRange(
    _In_ PRTL_RANGE_LIST RangeList,
    _In_ ULONGLONG Minimum,
    _In_ ULONGLONG Maximum,
    _In_ ULONGLONG Length,
    _In_ ULONGLONG Alignment,
    _In_ ULONG Flags,
    _In_ UCHAR AttributeAvailableMask,
    _In_opt_ PVOID Context,
    _In_opt_ PRTL_CONFLICT_RANGE_CALLBACK Callback,
    _Out_ PULONGLONG Start
);

NTSYSAPI
NTSTATUS
NTAPI
RtlIsRangeAvailable(
    _In_ PRTL_RANGE_LIST RangeList,
    _In_ ULONGLONG Start,
    _In_ ULONGLONG End,
    _In_ ULONG Flags,
    _In_ UCHAR AttributeAvailableMask,
    _In_opt_ PVOID Context,
    _In_opt_ PRTL_CONFLICT_RANGE_CALLBACK Callback,
    _Out_ PBOOLEAN Available
);

NTSYSAPI
NTSTATUS
NTAPI
RtlInvertRangeList(
    _Out_ PRTL_RANGE_LIST InvertedRangeList,
    _In_ PRTL_RANGE_LIST RangeList
);

NTSYSAPI
NTSTATUS
NTAPI
RtlMergeRangeLists(
    _Out_ PRTL_RANGE_LIST MergedRangeList,
    _In_ PRTL_RANGE_LIST RangeList1,
    _In_ PRTL_RANGE_LIST RangeList2,
    _In_ ULONG Flags
);

NTSYSAPI
NTSTATUS
NTAPI
RtlGetFirstRange(
    _In_ PRTL_RANGE_LIST RangeList,
    _Out_ PRTL_RANGE_LIST_ITERATOR Iterator,
    _Out_ PRTL_RANGE *Range
);

NTSYSAPI
NTSTATUS
NTAPI
RtlGetNextRange(
    _Inout_ PRTL_RANGE_LIST_ITERATOR Iterator,
    _Out_ PRTL_RANGE *Range,
    _In_ BOOLEAN MoveForwards
);

#ifdef __cplusplus
}
#endif

#endif /* _UACPI_NT_RTLRANGELIST_H */
