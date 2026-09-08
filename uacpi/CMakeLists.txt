
set(UACPI_SOURCES "")
macro(uacpi_add_sources)
    foreach(_src ${ARGN})
        list(APPEND UACPI_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/source/${_src}")
    endforeach()
endmacro()
include(${CMAKE_CURRENT_SOURCE_DIR}/source/files.cmake)

nt_add_kernel_library(uacpi ${UACPI_SOURCES})

target_include_directories(uacpi PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_compile_options(uacpi PUBLIC
    /wd4200)    # nonstandard extension: zero-sized array in struct/union

target_compile_options(uacpi PRIVATE
    /wd4189     # local variable initialized but not referenced
    /wd4244     # narrowing conversion (deliberate throughout the interpreter)
    /wd4267     # size_t -> smaller integer
    /wd4310     # cast truncates constant value
    /wd4324     # structure padded due to alignment specifier
    /wd4389     # signed/unsigned mismatch in a comparison
    /wd4701     # potentially uninitialized local
    /wd4703)    # potentially uninitialized local pointer
