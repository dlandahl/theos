
#import "Lil_Uefi";
#import "Elf";

#add_context system_table: *EFI_SYSTEM_TABLE;

Page_Tables :: struct {
    pml4: [0x200] u64;
    pdpt: [0x200] u64;
    pd:   [0x200] u64;

    boot_pdpt: [0x200] u64;
    boot_pd:   [0x200] u64;
}

Boot_Data :: struct {
    // Stuff that the bootloader will hand to the kernel
    page_tables: Page_Tables;

    kernel_load_buffer: [0x10_0000] u8;

    framebuffer: u64;
    x_resolution: u32;
    y_resolution: u32;
}

#program_export
EfiMain :: (loaded_image: EFI_HANDLE, system_table: *EFI_SYSTEM_TABLE) -> EFI_UINTN #c_call {

    c := Context.{
        system_table = system_table,
    };

    push_context c {
        boot_services := system_table.BootServices;

        boot_data_address: u64 = 0x10_0000;
        boot_data := cast(*Boot_Data) boot_data_address;

        EFI_CHECK(boot_services.AllocatePages(.AllocateAddress, .EfiLoaderData, size_of(Boot_Data) / 4096, *boot_data_address));

        {
            // Get framebuffer and clear the screen

            gop: *EFI_GRAPHICS_OUTPUT_PROTOCOL;
            EFI_CHECK(boot_services.LocateProtocol(*EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID, null, cast(**void) *gop));

            gop.SetMode(gop, 1);

            framebuffer: [] u32;
            framebuffer.data  = cast(*u32) gop.Mode.frame_buffer_base;
            framebuffer.count = cast(s64) gop.Mode.frame_buffer_size / size_of(u32);

            for *framebuffer {
                it.* = 0x0000ff00;
            }

            console := system_table.ConOut;
            EFI_CHECK(console.Reset(console, 0));

            boot_data.framebuffer = gop.Mode.frame_buffer_base;
            boot_data.x_resolution = gop.Mode.info.HorizontalResolution;
            boot_data.y_resolution = gop.Mode.info.VerticalResolution;
        }

        loaded_image_protocol: *EFI_LOADED_IMAGE_PROTOCOL;
        EFI_CHECK(boot_services.HandleProtocol(loaded_image, *EFI_LOADED_IMAGE_PROTOCOL_GUID, xx *loaded_image_protocol));

        file_system: *EFI_SIMPLE_FILE_SYSTEM_PROTOCOL;
        EFI_CHECK(boot_services.HandleProtocol(loaded_image_protocol.DeviceHandle, xx *EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, xx *file_system));

        boot_volume: *EFI_FILE_PROTOCOL;
        EFI_CHECK(file_system.OpenVolume(file_system, *boot_volume));

        kernel_file: *EFI_FILE_PROTOCOL;
        file_name := cast(*u16) "k\0e\0r\0n\0e\0l\0\0\0".data;

        open_file_flags := EFI_FILE_ATTRIBUTES.READ_ONLY | .HIDDEN | .SYSTEM;
        EFI_CHECK(boot_volume.Open(boot_volume, xx *kernel_file, file_name, .Read, open_file_flags));

        Efi_File_Info :: struct {
            using #as file_info: EFI_FILE_INFO;
            file_name: [64] u16; // EFI_FILE_INFO has an arbitrary length name at the end
        }

        file_info: Efi_File_Info;
        info_size := size_of(Efi_File_Info);

        EFI_CHECK(boot_volume.GetInfo(boot_volume, *EFI_FILE_INFO_GUID, xx *info_size, *file_info));

        size: u64 = 0x10_0000; // file_info.FileSize; // For some reason FileSize is zero, even though boot_volume.GetInfo claims to have returned a valid File_Info
        EFI_CHECK(kernel_file.Read(kernel_file, *size, cast(*void) boot_data.kernel_load_buffer.data));

        elf := boot_data.kernel_load_buffer.data;
        elf_header := cast(*Elf64_Ehdr) elf;

        display("Entry point: 0x", cast(int) elf_header.e_entry, "\n\r");


        for 0..size_of(Page_Tables)-1 {
            << (cast(*u8) *boot_data.page_tables + it) = 0;
        }

        {
            using boot_data.page_tables;

            pml4[0]      = cast(u64) boot_pdpt.data | PAGE_PRESENT | PAGE_READ_WRITE;
            boot_pdpt[0] = cast(u64) boot_pd.data   | PAGE_PRESENT | PAGE_READ_WRITE;

            // Low memory where the bootloader is loaded
            boot_pd[0] = 0x00_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[1] = 0x20_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[2] = 0x40_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[3] = 0x60_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;

            // Where UEFI seems to have put the stack of this program
            boot_pd[64] = 0x800_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[63] = 0x7e0_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[62] = 0x7c0_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[61] = 0x7a0_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;

            // Higher-half memory for the kernel
            pml4[0x1ff] = cast(u64) pdpt.data | PAGE_PRESENT | PAGE_READ_WRITE;
            pdpt[0x1fe] = cast(u64) pd.data   | PAGE_PRESENT | PAGE_READ_WRITE;

            pd[0] = 0x100_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            pd[1] = 0x120_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            pd[2] = 0x140_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            pd[3] = 0x160_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
        }

        descriptor_size: u64; // Don't assume that memory map entries will match Lil_Uefi's EFI_MEMORY_DESCRIPTOR structure, the Qemu one is larger
        mmap_size: u64;

        boot_services.GetMemoryMap(*mmap_size, null, null, *descriptor_size, null); // Get the size, don't EFI_CHECK because return status will be BufferTooSmall

        mmap_size += 16 * descriptor_size;
        memory_map: *u8;

        mmap_key: EFI_UINTN;

        EFI_CHECK(boot_services.AllocatePool(.EfiLoaderData, mmap_size, cast(**void) *memory_map));
        EFI_CHECK(boot_services.GetMemoryMap(*mmap_size, xx memory_map, *mmap_key, null, null));

        count := mmap_size / descriptor_size;
        memory_types := type_info(EFI_MEMORY_TYPE);

        if false for 0..count-1 {
            desc := cast(*EFI_MEMORY_DESCRIPTOR) (memory_map + it * descriptor_size);
            display("\n\rType: ");

            for memory_types.values if desc.Type == it {
                display(memory_types.names[it_index]);
                break;
            }

            display(xx desc.Type);
        }

        EFI_CHECK(boot_services.ExitBootServices(loaded_image, mmap_key));

        cr3 := boot_data.page_tables.pml4.data;
        #asm { set_cr3 cr3; }

        {
            // Load kernel binary
            elf := boot_data.kernel_load_buffer.data;
            elf_header := cast(*Elf64_Ehdr) elf;

            for 0..elf_header.e_phnum-1 {
                base := elf + elf_header.e_phoff;
                base += it  * elf_header.e_phentsize;
                program_header := cast(*Elf64_Phdr) base;

                if program_header.p_type != PT_LOAD continue;

                memcpy(
                    cast(*void) program_header.p_vaddr,
                    elf + program_header.p_offset,
                    cast(s32) program_header.p_filesz
                );
            }

            entry_point := << cast(*() #no_context) *(elf_header.e_entry);
            entry_point();
        }

        while true {}
    }

    return 0;
}

PAGE_PRESENT    :: 0x1;
PAGE_READ_WRITE :: 0x2;
PAGE_SIZE       :: 0x80;

EFI_CHECK :: check_efi_status;

check_efi_status :: (status: EFI_STATUS, loc := #caller_location) {
    if status == .Success return;

    ti := type_info(EFI_STATUS);
    index: int = 1;

    for ti.values if it == cast(int) status {
        index = it_index;
        break;
    }

    enum_name := ti.names[index];

    display("Failure on line ", loc.line_number, " with status ", enum_name, "\n\r");
}

display :: (args: .. Any) {
    integer_types :: Type.[
        u8, s8, u16, s16, u32, s32, u64, s64
    ];

    for args {
        if it.type == cast(*Type_Info) string {
            display_string(<< cast(*string) it.value_pointer);
        }

        // Can you metaprogram this without string formatting?
        if it.type == cast(*Type_Info) u8   display_int(cast(int) << cast(*u8)  it.value_pointer);
        if it.type == cast(*Type_Info) s8   display_int(cast(int) << cast(*s8)  it.value_pointer);
        if it.type == cast(*Type_Info) u16  display_int(cast(int) << cast(*u16) it.value_pointer);
        if it.type == cast(*Type_Info) s16  display_int(cast(int) << cast(*s16) it.value_pointer);
        if it.type == cast(*Type_Info) s32  display_int(cast(int) << cast(*s32) it.value_pointer);
        if it.type == cast(*Type_Info) u32  display_int(cast(int) << cast(*u32) it.value_pointer);
        if it.type == cast(*Type_Info) s64  display_int(cast(int) << cast(*s64) it.value_pointer);
        if it.type == cast(*Type_Info) u64  display_int(cast(int) << cast(*u64) it.value_pointer);
    }
}

display_string :: (message: string) {
    buffer: [256] u16;
    wide_text := ascii_to_wide(message, buffer);

    console := context.system_table.ConOut;
    console.OutputString(console, wide_text);
}

display_int :: (value: int) {
    hex_chars := "0123456789abcdef";
    result: [16] u8;

    for 0..15 {
        result[it] = hex_chars[(value >> (60 - it * 4)) & 0xF];
    }

    display(cast(string) result);
}

// =====================================================

ascii_to_wide :: (input: string, buffer: [] u16) -> *u16 {
    for cast([] u8) input {
        buffer[it_index] = cast(u16) it;
    }

    buffer[input.count] = 0;
    return buffer.data;
}

#program_export
memset :: (target: *void, value: u8, count: s64) -> *void #c_call {
    #asm {
        cld;

        count  === c;
        target === di;
        value  === a;
        rep_stos.b target, value, count;
    }

    return target;
}

#program_export
memcpy :: (dst: *void, src: *void, count: s64) -> *void #c_call {
    #asm {
        cld;

        src   === si;
        dst   === di;
        count === c;
        rep_movs.b dst, src, count;
    }

    return dst;
}

#program_export
memcmp :: (a: *u8, b: *u8, count: u64) -> s16 #c_call {
    for 0..(cast(s64) count)-1 {
        if a[it] != b[it] {
            return a[it] - b[it];
        }
    }

    return 0;
}

/*

        header := cast(*Elf64_Ehdr) kernel_load_buffer;
        output_string(cast(string) header.e_ident);

        phoff := kernel_load_buffer + header.e_phoff;
        for 0..header.e_phnum-1 {
            phent := phoff + header.e_phentsize * it;
            pheader := cast(*Elf64_Phdr) phent;

            if pheader.p_type == PT_LOAD {
                output_string("Found pheader\r\n");

                pages_needed := pheader.p_memsz / 4096 + 1;
                status = boot_services.AllocatePages(.EFI_ALLOCATE_TYPE_AllocateAddress, .EFI_MEMORY_TYPE_EfiLoaderData, xx pages_needed, xx pheader.p_vaddr);
                uefi_check(status, "AllocatePages");
            }
        }
*/
