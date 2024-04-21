// Lil' UEFI Example

#include "lil_uefi/lil_uefi.h"

#define ArrayCount(a) ((sizeof(a)) / sizeof((a)[0]))

EFI_UINTN
EfiMain(EFI_HANDLE handle, EFI_SYSTEM_TABLE *system_table){
    // rjf: grab boot services
    EFI_BOOT_SERVICES *boot_services = system_table->BootServices;
    
    // rjf: grab graphics output protocol
    EFI_GUID gfx_out_guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_GRAPHICS_OUTPUT_PROTOCOL *gfx_out_prot = 0;
    EFI_STATUS gfx_out_prot_locate_status = boot_services->LocateProtocol(&gfx_out_guid, 0, &gfx_out_prot);
    
    // rjf: set gfx out protocol mode to zero
    gfx_out_prot->SetMode(gfx_out_prot, 0);
    
    // rjf: grab frame buffer info
    EFI_UINT64 frame_buffer_addr = gfx_out_prot->Mode->frame_buffer_base;
    EFI_UINT64 frame_buffer_size = gfx_out_prot->Mode->frame_buffer_size;
    
    // rjf: get memory map
    EFI_MEMORY_DESCRIPTOR memory_descriptors[64] = {0};
    EFI_UINT64 mmap_size = ArrayCount(memory_descriptors);
    EFI_UINT64 map_key = 0;
    EFI_UINT64 descriptor_size = 0;
    EFI_UINT32 descriptor_version = 0;
    EFI_STATUS memory_map_get_status = boot_services->GetMemoryMap(&mmap_size, memory_descriptors,
                                                                   &map_key, &descriptor_size,
                                                                   &descriptor_version);
    
    // rjf: fill frame buffer
    for(EFI_UINT64 display_idx = 0;; display_idx += 1)
    {
        EFI_UINT32*frame_buffer = (EFI_UINT32*)frame_buffer_addr;
        for(EFI_UINT64 idx = 0; idx < frame_buffer_size/4; idx += 1)
        {
            EFI_UINT32 r = (display_idx) % 255;
            EFI_UINT32 g = (display_idx + 128) % 255;
            EFI_UINT32 b = (display_idx + 64) % 255;
            frame_buffer[idx] = 0 | (r << 16) | (g << 8) | (b);
        }
    }
    
    return(0);
}

