
nt_add_driver(acpi
    driver.c
    acpi.h)

target_link_libraries(acpi PRIVATE
    nt_shim
    uacpi)
