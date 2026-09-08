
include_guard(GLOBAL)

function(nt_kernel_init)
    if(TARGET nt_kernel_settings)
        return()
    endif()

    foreach(_cfg "" _DEBUG _RELEASE _RELWITHDEBINFO _MINSIZEREL)
        foreach(_lang C CXX)
            set(_flags "${CMAKE_${_lang}_FLAGS${_cfg}}")
            string(REGEX REPLACE "[/-]RTC[1csu]+" "" _flags "${_flags}")
            string(REGEX REPLACE "[/-]D *NDEBUG" "" _flags "${_flags}")
            set(CMAKE_${_lang}_FLAGS${_cfg} "${_flags}" PARENT_SCOPE)
        endforeach()
    endforeach()

    add_library(nt_kernel_settings INTERFACE)

    target_include_directories(nt_kernel_settings SYSTEM INTERFACE
        ${WDK_INCLUDE_DIRS}
        "${WDK_MSVC_INCLUDE_DIR}")

    target_compile_definitions(nt_kernel_settings INTERFACE
        NTDDI_VERSION=${NT_TARGET_NTDDI}
        _WIN32_WINNT=${NT_TARGET_WIN32_WINNT}
        WINVER=${NT_TARGET_WIN32_WINNT}
        NT_TARGET_ID="${NT_TARGET_ID}"
        NT_TARGET_NAME="${NT_TARGET_DISPLAY_NAME}"
        POOL_NX_OPTIN=1
        DBG=$<IF:$<CONFIG:Debug>,1,0>)

    if(WDK_ARCH STREQUAL "x64")
        target_compile_definitions(nt_kernel_settings INTERFACE
            _AMD64_ AMD64 _WIN64 WIN64)
    elseif(WDK_ARCH STREQUAL "arm64")
        target_compile_definitions(nt_kernel_settings INTERFACE
            _ARM64_ ARM64 _WIN64 WIN64 STD_CALL)
    elseif(WDK_ARCH STREQUAL "x86")
        target_compile_definitions(nt_kernel_settings INTERFACE
            _X86_ i386 STD_CALL _USE_32BIT_TIME_T)
        # 32-bit kernel code is __stdcall by default
        target_compile_options(nt_kernel_settings INTERFACE /Gz)
    elseif(WDK_ARCH STREQUAL "arm")
        target_compile_definitions(nt_kernel_settings INTERFACE
            _ARM_ ARM STD_CALL _USE_32BIT_TIME_T)
    endif()

    target_compile_options(nt_kernel_settings INTERFACE
        /X          # ignore %INCLUDE%: the list above is the whole include path
        /kernel     # kernel-mode code generation
        /GS         # required by /kernel; satisfied by BufferOverflowFastFailK
        /Gy         # COMDAT functions, so /OPT:REF can do its job
        /Zp8        # WDK structure packing
        /Oi
        /Zc:inline
        /external:W0
        /W4
        /wd4100     # unreferenced formal parameter
        /wd4127     # conditional expression is constant
        /wd4201     # nameless struct/union (used throughout the WDK headers)
        /wd4214     # bit field type other than int
        # ExAllocatePoolWithTag is deprecated in favour of ExAllocatePool2,
        # which only exists from Windows 10 2004 on.
        /wd4996
        $<$<BOOL:${NT_WARNINGS_AS_ERRORS}>:/WX>)

    set_property(TARGET nt_kernel_settings PROPERTY INTERFACE_MSVC_RUNTIME_LIBRARY "")
endfunction()

#
# nt_add_kernel_library(<name> <sources>...)
#
function(nt_add_kernel_library name)
    add_library(${name} STATIC ${ARGN})
    target_link_libraries(${name} PUBLIC nt_kernel_settings)
    set_target_properties(${name} PROPERTIES
        MSVC_RUNTIME_LIBRARY ""
        C_STANDARD 11
        C_STANDARD_REQUIRED ON
        FOLDER "Kernel libraries")
endfunction()

#
# nt_add_driver(<name> <sources>...)
#
# Produces <name>.sys.  Link settings mirror what the WDK's MSBuild targets do
# for a plain WDM driver.
#
function(nt_add_driver name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name} PRIVATE nt_kernel_settings)

    if(WDK_ARCH STREQUAL "x86")
        set(_entry "GsDriverEntry@8")
    else()
        set(_entry "GsDriverEntry")
    endif()

    set_target_properties(${name} PROPERTIES
        SUFFIX ".sys"
        MSVC_RUNTIME_LIBRARY ""
        C_STANDARD 11
        C_STANDARD_REQUIRED ON
        FOLDER "Drivers")

    target_link_options(${name} PRIVATE
        /DRIVER
        /SUBSYSTEM:NATIVE,${NT_TARGET_SUBSYSTEM_VERSION}
        /ENTRY:${_entry}
        /NODEFAULTLIB
        /MANIFEST:NO
        /INCREMENTAL:NO
        /RELEASE            # write a real PE checksum; the loader wants one
        /NXCOMPAT
        /DYNAMICBASE
        /OPT:REF
        /OPT:ICF
        # #pragma alloc_text(PAGE, ...) lands in _PAGE / _TEXT; fold them into
        # the sections the memory manager actually knows about.
        /MERGE:_TEXT=.text
        /MERGE:_PAGE=PAGE
        /SECTION:INIT,d     # CODE_SEG("INIT") is discarded after boot
        /IGNORE:4210
        /IGNORE:4078)

    target_link_libraries(${name} PRIVATE
        WDK::ntoskrnl
        WDK::hal
        WDK::BufferOverflowFastFailK)

    if(WDK_ARCH MATCHES "^arm" AND TARGET WDK::libcntpr)
        target_link_libraries(${name} PRIVATE WDK::libcntpr)
    endif()
endfunction()
