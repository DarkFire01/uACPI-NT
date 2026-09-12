file(GLOB ACPI_SYS_SOURCES   CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.c")
#file(GLOB ACPI_DRIVERS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/drivers/*.c")

nt_add_driver(acpi
              ${ACPI_SYS_SOURCES}
             # ${ACPI_DRIVERS_SOURCES}
              )

target_include_directories(acpi PRIVATE
                           "${CMAKE_SOURCE_DIR}/include")

target_link_libraries(acpi PRIVATE nt_shim uacpi arbiter)
target_link_libraries(acpi PRIVATE WDK::wmilib WDK::wdmsec WDK::wdmguid)
