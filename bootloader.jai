
#import "Lil_Uefi";
#import "Elf";

#load "boot_data.jai";

#add_context system_table: *EFI_SYSTEM_TABLE;

#program_export
EfiMain :: (loaded_image: EFI_HANDLE, system_table: *EFI_SYSTEM_TABLE) -> EFI_UINTN #c_call {

    c := Context.{
        system_table = system_table,
    };

    push_context c {
        boot_services := system_table.BootServices;

        // Pretty sure physical memory at 1Mb is free to use on any firmware. Linux does this.
        boot_data_address: u64 = 0x10_0000;
        boot_data := cast(*Boot_Data) boot_data_address;

        // Use this memory type when making allocations that should keep the memory reserved in the kernel's physical memory management.
        UserReservedMemoryType : EFI_MEMORY_TYPE : 0x8000_0000;

        {
            // Even though this mapping is not needed while boot-services are still active, we create it in the boot-services memory map anyway, so that it gets reported by GetMemoryMap, and the kernel will know the memory is not available.
            kernel_base: u64 = Boot_Data.KERNEL_PHYS_BASE;
            EFI_CHECK(boot_services.AllocatePages(.AllocateAddress, UserReservedMemoryType, 0x10_0000 / 4096, *kernel_base));

            EFI_CHECK(boot_services.AllocatePages(.AllocateAddress, UserReservedMemoryType, size_of(Boot_Data) / 4096 + 1, *boot_data_address));
            memset(boot_data, 0, size_of(Boot_Data));
        }

        {
            // Get framebuffer and clear the screen

            gop: *EFI_GRAPHICS_OUTPUT_PROTOCOL;
            EFI_CHECK(boot_services.LocateProtocol(*EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID, null, cast(**void) *gop));

            gop.SetMode(gop, 9);

            framebuffer: [] u32;
            framebuffer.data  = cast(*u32) gop.Mode.frame_buffer_base;
            framebuffer.count = cast(s64) gop.Mode.frame_buffer_size / size_of(u32);

            for *framebuffer {
                it.* = 0x00ffff00;
            }

            console := system_table.ConOut;
            EFI_CHECK(console.Reset(console, 0));

            boot_data.framebuffer = cast(*u32) gop.Mode.frame_buffer_base;
            boot_data.x_resolution = gop.Mode.info.HorizontalResolution;
            boot_data.y_resolution = gop.Mode.info.VerticalResolution;
            boot_data.stride = gop.Mode.info.PixelsPerScanLine;
        }

        for 0..system_table.NumberOfTableEntries-1 {
            // Find root ACPI table
            table := system_table.ConfigurationTable[it];

            low := << cast(*u64) *table.VendorGuid;
            high := << (cast(*u64) *table.VendorGuid + 1);

            acpi_table_guid_low:  u64 = 0x11d3e4f18868e871;
            acpi_table_guid_high: u64 = 0x81883cc7800022bc;

            if low == acpi_table_guid_low && high == acpi_table_guid_high {
                magic: string = .{ 8, table.VendorTable };
                display("Found ACPI table (", magic, ")\n\r");

                boot_data.acpi_rsdp = table.VendorTable;
                break;
            }
        }

        display("Boot data size: ", size_of(Boot_Data), "\n\r");

        // All this stuff is to load the kernel ELF file from the EFI filesystem

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

        size: u64 = 0x5_0000; // file_info.FileSize; // For some reason FileSize is zero, even though boot_volume.GetInfo claims to have returned a valid File_Info
        load_buffer: [0x5_0000] u8;
        EFI_CHECK(kernel_file.Read(kernel_file, *size, cast(*void) load_buffer.data));

        for 0..size_of(Page_Tables) / size_of(u64) - 1 {
            << (cast(*u64) *boot_data.page_tables + it) = 0;
        }

        {
            using boot_data.page_tables;

            PAGE_PRESENT    : u64 : 0x1;
            PAGE_READ_WRITE : u64 : 0x2;
            PAGE_SIZE       : u64 : 0x80;

            pml4[0]      = cast(u64) boot_pdpt.data | PAGE_PRESENT | PAGE_READ_WRITE;
            boot_pdpt[0] = cast(u64) boot_pd.data   | PAGE_PRESENT | PAGE_READ_WRITE;

            // Low memory where the bootloader is loaded
            boot_pd[0] = 0x00_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[1] = 0x20_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[2] = 0x40_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            boot_pd[3] = 0x60_0000 | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;

            // UEFI seems to put the stack at the top of physical memory. For now assume that the machine has 128Mb
            index: u64;
            for< 64..45 {
                boot_pd[it] = (0x800_0000 - index*0x20_0000) | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
                index += 1;
            }

            // 8Mb higher-half memory for the kernel.
            pml4[0x1ff] = cast(u64) pdpt.data | PAGE_PRESENT | PAGE_READ_WRITE;
            pdpt[0x1fe] = cast(u64) pd.data   | PAGE_PRESENT | PAGE_READ_WRITE;

            for 0..3 {
                address := Boot_Data.KERNEL_PHYS_BASE + cast(u64) it * 0x20_0000;
                pd[it] = address | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            }

            // Direct-map all physical memory to the bottom of the kernel addresses
            pml4[0x100] = cast(u64) direct_pdpt.data | PAGE_PRESENT | PAGE_READ_WRITE;

            for pd: 0..direct_pd.count-1 {
                direct_pdpt[pd] = cast(u64) direct_pd[pd].data | PAGE_PRESENT | PAGE_READ_WRITE;
                
                for pt: 0..0x1ff {
                    address := cast(u64) (pd*0x4000_0000 + pt*0x20_0000);
                    direct_pd[pd][pt] = address | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
                }
            }

            // Map the framebuffer
            pd[4] = cast(u64) boot_data.framebuffer             | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            pd[5] = cast(u64) boot_data.framebuffer + 0x20_0000 | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;

            boot_data.page_directories_used = 6;

            // Translate framebuffer address to virtual
            boot_data.framebuffer = cast(*u32) (0xffff_ffff_8000_0000 + 4*0x20_0000);
        }

        // Firmware physical memory map
        limit :: (region: Boot_Data.Memory_Region) -> u64 {
            return region.address + region.pages * 4096;
        }

        descriptor_size: u64; // Don't assume that memory map entries will match Lil_Uefi's EFI_MEMORY_DESCRIPTOR structure, the OVMF.fd one is larger
        mmap_size: u64;

        boot_services.GetMemoryMap(*mmap_size, null, null, *descriptor_size, null); // Get the size, don't EFI_CHECK because return status will be BufferTooSmall

        mmap_size += 32 * descriptor_size;
        max_mmap_size := mmap_size;
        memory_map: *u8;

        mmap_key: EFI_UINTN;

        EFI_CHECK(boot_services.AllocatePool(.EfiLoaderData, mmap_size, cast(**void) *memory_map));
        EFI_CHECK(boot_services.GetMemoryMap(*mmap_size, xx memory_map, *mmap_key, null, null));

        entry_count := mmap_size / descriptor_size;

        // Find size of physical memory and allocate page frame descriptor array
        highest_address: u64;

        for 0..entry_count-1 {
            desc := cast(*EFI_MEMORY_DESCRIPTOR) (memory_map + it * descriptor_size);

            region: Boot_Data.Memory_Region;

            region.address = desc.PhysicalStart;
            region.pages   = desc.NumberOfPages;

            // These are not guaranteed to be sorted by address, so check each one to find the amount of physical memory.
            if limit(region) > highest_address {
                highest_address = limit(region);
            }
        }

        page_frame_count := highest_address / 4096;
        EFI_CHECK(boot_services.AllocatePool(UserReservedMemoryType, size_of(Page_Frame_Desc) * page_frame_count, cast(**void) *boot_data.page_frames));

        mmap_key = 0;
        mmap_size = max_mmap_size;
        EFI_CHECK(boot_services.GetMemoryMap(*mmap_size, xx memory_map, *mmap_key, null, null));

        entry_count = mmap_size / descriptor_size;
        boot_data.memory_map_entries_used = 0;

        for 0..entry_count-1 {
            desc := cast(*EFI_MEMORY_DESCRIPTOR) (memory_map + it * descriptor_size);

            region: Boot_Data.Memory_Region;

            region.address = desc.PhysicalStart;
            region.pages   = desc.NumberOfPages;

            if cast(EFI_MEMORY_TYPE) desc.Type == {
              case .EfiLoaderCode; #through;
              case .EfiLoaderData; #through;
              case .EfiBootServicesCode; #through;
              case .EfiBootServicesData; #through;
              case .EfiConventionalMemory;

                bd := boot_data;

                if bd.memory_map_entries_used != 0 {
                    // If two available regions are contiguous, just grow the previous one.
                    // Won't always coalesce perfectly because the firmware doesn't guarantee that memory map entries are sorted by address.
                    last_region := *bd.memory_map[bd.memory_map_entries_used-1];

                    if limit(last_region.*) == region.address {
                        last_region.pages += region.pages;
                        continue;
                    }
                }                

                bd.memory_map[bd.memory_map_entries_used] = region;
                bd.memory_map_entries_used += 1;

                if bd.memory_map_entries_used == bd.memory_map.count {
                    break;
                }
            }
        }

        while boot_services.ExitBootServices(loaded_image, mmap_key) == .InvalidParameter {
            // ExitBootServices itself can sometimes change the memory map, in which case you just need to call it again. I don't get why this needs to be done by the user.
            mmap_key = 0;
            mmap_size = max_mmap_size;
            boot_services.GetMemoryMap(*mmap_size, xx memory_map, *mmap_key, null, null);
        }

        cr3 := boot_data.page_tables.pml4.data;
        #asm {
            cli;
            set_cr3 cr3;
        }

        {
            // Load kernel executable
            elf := load_buffer.data;
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

                if (program_header.p_memsz > program_header.p_filesz) {
                    start := program_header.p_vaddr + program_header.p_filesz;
                    count := program_header.p_memsz - program_header.p_filesz;
                    memset(cast(*void) start, 0, cast(s64) count);
                }
            }

            entry_point := << cast(*() #no_context) *(elf_header.e_entry);
            entry_point();
        }

        while true {}
    }

    return 0;
}

EFI_CHECK :: check_efi_status;

check_efi_status :: (status: EFI_STATUS, loc := #caller_location) {
    if status == .Success {
        // display("UEFI call succeeded on line ", loc.line_number, "\n\r");
        return;
    }

    ti := type_info(EFI_STATUS);
    index: int = 1;

    for ti.values if it == cast(int) status {
        index = it_index;
        break;
    }

    enum_name := ti.names[index];

    display("UEFI call failed on line ", loc.line_number, " with status ", enum_name, "\n\r");
}

display :: (args: .. Any) {
    for args {
        if it.type == xx string {
            display_string(<< cast(*string) it.value_pointer);
        }

        // Can you metaprogram this without string formatting?
        if it.type == xx u8   display_int(xx,no_check << cast(*u8)  it.value_pointer);
        if it.type == xx s8   display_int(xx,no_check << cast(*s8)  it.value_pointer);
        if it.type == xx u16  display_int(xx,no_check << cast(*u16) it.value_pointer);
        if it.type == xx s16  display_int(xx,no_check << cast(*s16) it.value_pointer);
        if it.type == xx u32  display_int(xx,no_check << cast(*u32) it.value_pointer);
        if it.type == xx s32  display_int(xx,no_check << cast(*s32) it.value_pointer);
        if it.type == xx u64  display_int(xx,no_check << cast(*u64) it.value_pointer);
        if it.type == xx s64  display_int(xx,no_check << cast(*s64) it.value_pointer);
    }
}

display_string :: (message: string) {
    buffer: [256] u16;
    wide_text := ascii_to_wide(message, buffer);

    console := context.system_table.ConOut;
    console.OutputString(console, wide_text);
}

display_int :: (value: u64) {
    hex_chars := "0123456789abcdef";
    result: [16] u8;

    for 0..15 {
        result[it] = hex_chars[(value >> (60 - it * 4)) & 0xF];
    }

    display(cast(string) result);
}

ascii_to_wide :: (input: string, buffer: [] u16) -> *u16 {
    for cast([] u8) input {
        buffer[it_index] = cast(u16) it;
    }

    buffer[input.count] = 0;
    return buffer.data;
}

#program_export
__chkstk :: () {}
