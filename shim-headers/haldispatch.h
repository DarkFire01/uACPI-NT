/*
 * PROJECT:     uACPI-NT
 * LICENSE:     MIT (https://spdx.org/licenses/MIT)
 * PURPOSE:     Runtime version guards for the two HAL dispatch tables
 */

#ifndef _UACPI_NT_HALDISPATCH_H
#define _UACPI_NT_HALDISPATCH_H

#include <ntshim.h>
#include <haltypes.h>

#define HalDispatchTableRuntimeVersion()        (HALDISPATCH->Version)
#define HalPrivateDispatchRuntimeVersion()      (HALPRIVATEDISPATCH->Version)

#define HAL_DISPATCH_VERSION_AT_LEAST(v)        (HalDispatchTableRuntimeVersion() >= (ULONG)(v))
#define HAL_PRIVATE_DISPATCH_VERSION_AT_LEAST(v) \
    (HalPrivateDispatchRuntimeVersion() >= (ULONG)(v))

#define HAL_PRIVATE_DISPATCH_MATCHES_BUILD() \
    HAL_PRIVATE_DISPATCH_VERSION_AT_LEAST(HAL_PRIVATE_DISPATCH_VERSION)

#endif /* _UACPI_NT_HALDISPATCH_H */
