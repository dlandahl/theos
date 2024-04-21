
#include "lil_uefi/lil_uefi/lil_uefi.h"

EFI_UINTN EfiMain (EFI_HANDLE handle, EFI_SYSTEM_TABLE *system_table) {
    EFI_BOOT_SERVICES *boot_services = system_table->BootServices;

    EFI_GUID gop_guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_GRAPHICS_OUTPUT_PROTOCOL *gop = 0;
    EFI_STATUS gop_locate_status = boot_services->LocateProtocol(&gop_guid, 0, &gop);

    gop->SetMode(gop, 1);

    EFI_UINT64 frame_buffer_addr = gop->Mode->frame_buffer_base;
    EFI_UINT64 frame_buffer_size = gop->Mode->frame_buffer_size;

    EFI_UINT32 *frame_buffer = (EFI_UINT32*)frame_buffer_addr;

    for (EFI_UINT64 n = 0; n < frame_buffer_size / 4; n += 1) {
        EFI_UINT32 r = 0;
        EFI_UINT32 g = 255;
        EFI_UINT32 b = 0;

        frame_buffer[n] = 0 | (r << 16) | (g << 8) | (b);
    }

    for (;;);

    return 0;
}




    cl := break_command_into_strings("cl /nologo /FC /GS- /c boot_loader.c /Fo.build\\");
    result := run_command(.. cl);
    assert(result.type == .EXITED && result.exit_code == 0);

    link := break_command_into_strings("link /nologo /ENTRY:EfiMain /ALIGN:16 /DRIVER /SUBSYSTEM:EFI_APPLICATION /OUT:bootx64.efi .build\\boot_loader.obj");
    result = run_command(.. link);
    assert(result.type == .EXITED && result.exit_code == 0);
