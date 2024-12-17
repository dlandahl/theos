#pragma once

#include <uacpi/internal/types.h>
#include <uacpi/acpi.h>
#include <uacpi/io.h>

uacpi_size uacpi_round_up_bits_to_bytes(uacpi_size bit_length);

void uacpi_read_buffer_field(
    const uacpi_buffer_field *field, void *dst
);
void uacpi_write_buffer_field(
    uacpi_buffer_field *field, const void *src, uacpi_size size
);

uacpi_status uacpi_read_field_unit(
    uacpi_field_unit *field, void *dst, uacpi_size size
);
uacpi_status uacpi_write_field_unit(
    uacpi_field_unit *field, const void *src, uacpi_size size
);
