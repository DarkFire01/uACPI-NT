
include(FindPackageHandleStandardArgs)

if(NOT WDK_ARCH)
    string(TOLOWER "${CMAKE_C_COMPILER_ARCHITECTURE_ID}" _wdk_arch)
    if(_wdk_arch MATCHES "^(x64|arm64|x86|arm)$")
        set(WDK_ARCH "${_wdk_arch}")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(WDK_ARCH x64)
    else()
        set(WDK_ARCH x86)
    endif()
    unset(_wdk_arch)
endif()
set(WDK_ARCH "${WDK_ARCH}" CACHE STRING "WDK target architecture" FORCE)

if(NOT WDK_ROOT AND DEFINED ENV{WDKContentRoot})
    set(WDK_ROOT "$ENV{WDKContentRoot}")
endif()

if(NOT WDK_ROOT)
    cmake_host_system_information(RESULT _root
        QUERY WINDOWS_REGISTRY "HKLM/SOFTWARE/Microsoft/Windows Kits/Installed Roots"
        VALUE "KitsRoot10"
        VIEW BOTH
        ERROR_VARIABLE _registry_error)
    if(_root AND IS_DIRECTORY "${_root}")
        set(WDK_ROOT "${_root}")
    endif()
    unset(_root)
    unset(_registry_error)
endif()

if(NOT WDK_ROOT)
    foreach(_candidate
        "$ENV{ProgramFiles\(x86\)}/Windows Kits/10"
        "$ENV{ProgramFiles}/Windows Kits/10")
        if(IS_DIRECTORY "${_candidate}")
            set(WDK_ROOT "${_candidate}")
            break()
        endif()
    endforeach()
endif()

if(WDK_ROOT)
    file(TO_CMAKE_PATH "${WDK_ROOT}" WDK_ROOT)
    string(REGEX REPLACE "/+$" "" WDK_ROOT "${WDK_ROOT}")
endif()

function(_wdk_has_headers version out_var)
    if(EXISTS "${WDK_ROOT}/Include/${version}/km/wdm.h")
        set(${out_var} TRUE PARENT_SCOPE)
    else()
        set(${out_var} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(_wdk_has_libs version out_var)
    if(EXISTS "${WDK_ROOT}/Lib/${version}/km/${WDK_ARCH}/ntoskrnl.lib")
        set(${out_var} TRUE PARENT_SCOPE)
    else()
        set(${out_var} FALSE PARENT_SCOPE)
    endif()
endfunction()

if(WDK_ROOT)
    file(GLOB _inc_versions RELATIVE "${WDK_ROOT}/Include" "${WDK_ROOT}/Include/10.*")
    file(GLOB _lib_versions RELATIVE "${WDK_ROOT}/Lib"     "${WDK_ROOT}/Lib/10.*")
    set(_versions ${_inc_versions} ${_lib_versions})
    list(REMOVE_DUPLICATES _versions)
    list(SORT _versions COMPARE NATURAL ORDER DESCENDING)

    if(WDK_VERSION)
        # An explicit request applies to both halves; fail loudly if it cannot.
        set(_versions "${WDK_VERSION}")
    endif()

    foreach(_v IN LISTS _versions)
        if(NOT WDK_INCLUDE_VERSION)
            _wdk_has_headers("${_v}" _inc_ok)
            if(_inc_ok)
                set(WDK_INCLUDE_VERSION "${_v}")
            endif()
        endif()
        if(NOT WDK_LIB_VERSION)
            _wdk_has_libs("${_v}" _lib_ok)
            if(_lib_ok)
                set(WDK_LIB_VERSION "${_v}")
            endif()
        endif()
    endforeach()

    unset(_inc_versions)
    unset(_lib_versions)
    unset(_versions)
    unset(_inc_ok)
    unset(_lib_ok)
endif()

if(WDK_INCLUDE_VERSION AND WDK_LIB_VERSION)
    set(WDK_VERSION "${WDK_INCLUDE_VERSION}")
    set(WDK_INCLUDE_DIRS
        "${WDK_ROOT}/Include/${WDK_INCLUDE_VERSION}/km/crt"
        "${WDK_ROOT}/Include/${WDK_INCLUDE_VERSION}/km"
        "${WDK_ROOT}/Include/${WDK_INCLUDE_VERSION}/shared")
    set(WDK_LIBRARY_DIR "${WDK_ROOT}/Lib/${WDK_LIB_VERSION}/km/${WDK_ARCH}")
endif()

if(NOT WDK_MSVC_INCLUDE_DIR AND CMAKE_C_COMPILER)
    # .../VC/Tools/MSVC/<ver>/bin/Host<x>/<arch>/cl.exe -> .../<ver>/include
    get_filename_component(_tools "${CMAKE_C_COMPILER}" DIRECTORY)  # <arch>
    get_filename_component(_tools "${_tools}" DIRECTORY)            # Host<x>
    get_filename_component(_tools "${_tools}" DIRECTORY)            # bin
    get_filename_component(_tools "${_tools}" DIRECTORY)            # <ver>
    if(IS_DIRECTORY "${_tools}/include")
        set(WDK_MSVC_INCLUDE_DIR "${_tools}/include")
    endif()
    unset(_tools)
endif()

find_package_handle_standard_args(WDK
    REQUIRED_VARS WDK_ROOT WDK_INCLUDE_VERSION WDK_LIB_VERSION
                  WDK_INCLUDE_DIRS WDK_LIBRARY_DIR WDK_MSVC_INCLUDE_DIR
    VERSION_VAR   WDK_VERSION)

if(WDK_FOUND)
    set(_wdk_libs ntoskrnl hal wmilib wdmsec wdmguid ntstrsafe libcntpr
                  BufferOverflowFastFailK ${WDK_REQUESTED_LIBRARIES})
    list(REMOVE_DUPLICATES _wdk_libs)
    foreach(_lib IN LISTS _wdk_libs)
        if(NOT TARGET WDK::${_lib} AND EXISTS "${WDK_LIBRARY_DIR}/${_lib}.lib")
            add_library(WDK::${_lib} INTERFACE IMPORTED)
            set_target_properties(WDK::${_lib} PROPERTIES
                INTERFACE_LINK_LIBRARIES "${WDK_LIBRARY_DIR}/${_lib}.lib")
        endif()
    endforeach()
    unset(_wdk_libs)
endif()
