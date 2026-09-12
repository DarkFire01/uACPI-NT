#
# nt_shim, the NT interfaces the public WDK does not declare.
#
# Header-only.  Anything that links this gets <ntshim.h>, <haltypes.h>,
# <halfuncs.h>, <haldispatch.h>, <rtlrangelist.h> and <debug.h> on its include
# path, plus the <ndk/...> spellings so that ReactOS-derived sources compile
# without edits.
#
# The contents of haltypes.h are NTDDI-sensitive by design: the HAL private
# dispatch table is laid out differently on every release, so which struct you
# get here is decided by the NTDDI_VERSION that nt_kernel_settings sets.
#
add_library(nt_shim INTERFACE)
target_include_directories(nt_shim INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(nt_shim INTERFACE nt_kernel_settings)

# Make the headers show up in IDE project trees.
file(GLOB _nt_shim_headers CONFIGURE_DEPENDS "*.h" "ndk/*.h")
target_sources(nt_shim INTERFACE FILE_SET HEADERS
    BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
    FILES ${_nt_shim_headers})
