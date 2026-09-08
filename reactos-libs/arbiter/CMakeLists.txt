
nt_add_kernel_library(arbiter
    arbiter.c
    entry.c
    handler.c
    ordering.c
    range.c
    transaction.c)

target_include_directories(arbiter PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(arbiter PUBLIC nt_shim)
