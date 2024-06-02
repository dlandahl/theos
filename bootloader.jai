
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

        boot_data_address: u64 = 0x10_0000;
        boot_data := cast(*Boot_Data) boot_data_address;

        EFI_CHECK(boot_services.AllocatePages(.AllocateAddress, .EfiLoaderData, size_of(Boot_Data) / 4096 + 1, *boot_data_address));

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

        size: u64 = boot_data.kernel_load_buffer.count; // file_info.FileSize; // For some reason FileSize is zero, even though boot_volume.GetInfo claims to have returned a valid File_Info
        EFI_CHECK(kernel_file.Read(kernel_file, *size, cast(*void) boot_data.kernel_load_buffer.data));


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

            // Where Qemu UEFI seems to put the stack of this program
            index: u64;
            for< 64..55 {
                boot_pd[it] = (0x800_0000 - index*0x20_0000) | cast(u64) PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
                index += 1;
            }

            // Higher-half memory for the kernel
            pml4[0x1ff] = cast(u64) pdpt.data | PAGE_PRESENT | PAGE_READ_WRITE;
            pdpt[0x1fe] = cast(u64) pd.data   | PAGE_PRESENT | PAGE_READ_WRITE;

            for 0..3 {
                address := Boot_Data.KERNEL_PHYS_BASE + cast(u64) it * 0x20_0000;
                pd[it] = address | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            }

            // Map the framebuffer
            pd[4] = cast(u64) boot_data.framebuffer             | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;
            pd[5] = cast(u64) boot_data.framebuffer + 0x20_0000 | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_SIZE;

            boot_data.page_directories_used = 6;

            // Translate framebuffer address to virtual
            boot_data.framebuffer = cast(*u32) (0xffff_ffff_8000_0000 + 4*0x20_0000);
        }

        // stack: int;
        // display("Stack: ", cast(u64) *stack, "\n\r");
        // while true {}
        
        // === Firmware Physical Memory Map ===

        descriptor_size: u64; // Don't assume that memory map entries will match Lil_Uefi's EFI_MEMORY_DESCRIPTOR structure, the OVMF.fd one is larger
        mmap_size: u64;

        boot_services.GetMemoryMap(*mmap_size, null, null, *descriptor_size, null); // Get the size, don't EFI_CHECK because return status will be BufferTooSmall

        mmap_size += 16 * descriptor_size;
        memory_map: *u8;

        mmap_key: EFI_UINTN;

        EFI_CHECK(boot_services.AllocatePool(.EfiLoaderData, mmap_size, cast(**void) *memory_map));
        EFI_CHECK(boot_services.GetMemoryMap(*mmap_size, xx memory_map, *mmap_key, null, null));

        entry_count := mmap_size / descriptor_size;
        memory_types := type_info(EFI_MEMORY_TYPE);

        for 0..entry_count-1 {
            desc := cast(*EFI_MEMORY_DESCRIPTOR) (memory_map + it * descriptor_size);

            boot_data.memory_map[it] = .{
                address = desc.PhysicalStart,
                pages   = desc.NumberOfPages,
                type    = desc.Type,
            };
        }

        boot_data.memory_map_entries_used = xx entry_count;

        EFI_CHECK(boot_services.ExitBootServices(loaded_image, mmap_key));

        gdt_init();

        cr3 := boot_data.page_tables.pml4.data;
        #asm {
            cli;
            set_cr3 cr3;
        }

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
    if status == .Success return;

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
    integer_types :: Type.[
        u8, s8, u16, s16, u32, s32, u64, s64
    ];

    for args {
        if it.type == cast(*Type_Info) string {
            display_string(<< cast(*string) it.value_pointer);
        }

        // Can you metaprogram this without string formatting?
        if it.type == cast(*Type_Info) u8   display_int(cast,no_check(u64) << cast(*u8)  it.value_pointer);
        if it.type == cast(*Type_Info) s8   display_int(cast,no_check(u64) << cast(*s8)  it.value_pointer);
        if it.type == cast(*Type_Info) u16  display_int(cast,no_check(u64) << cast(*u16) it.value_pointer);
        if it.type == cast(*Type_Info) s16  display_int(cast,no_check(u64) << cast(*s16) it.value_pointer);
        if it.type == cast(*Type_Info) s32  display_int(cast,no_check(u64) << cast(*s32) it.value_pointer);
        if it.type == cast(*Type_Info) u32  display_int(cast,no_check(u64) << cast(*u32) it.value_pointer);
        if it.type == cast(*Type_Info) s64  display_int(cast,no_check(u64) << cast(*s64) it.value_pointer);
        if it.type == cast(*Type_Info) u64  display_int(cast,no_check(u64) << cast(*u64) it.value_pointer);
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

// =====================================================

ascii_to_wide :: (input: string, buffer: [] u16) -> *u16 {
    for cast([] u8) input {
        buffer[it_index] = cast(u16) it;
    }

    buffer[input.count] = 0;
    return buffer.data;
}

#program_export
__chkstk :: () {}











gdt: [10] u64 #align 0x80;

Gdt_Entry_Flags :: enum {
    AVAILABLE       :: 0x01 << 52;
    LONG_MODE_CODE  :: 0x02 << 52;
    SIZE            :: 0x04 << 52;
    GRANULARITY     :: 0x08 << 52;
    ACCESSED        :: 0x01 << 40;
    READ_WRITE      :: 0x02 << 40;
    DIRECTION       :: 0x04 << 40;
    EXECUTABLE      :: 0x08 << 40;
    DESCRIPTOR_TYPE :: 0x10 << 40;
    PRIVILEGE0      :: 0x20 << 40;
    PRIVILEGE1      :: 0x40 << 40;
    PRESENT         :: 0x80 << 40;
}

make_gdt_entry :: (base: u64, limit: u32, flags: u64) -> u64 {
    entry: u64;

    bytes := cast(*u8) *entry;

    bytes[0] = cast(u8) (limit & 0xff);
    bytes[1] = cast(u8) (limit >> 8) & 0xff;
    bytes[6] = cast(u8) (limit >> 16) & 0x0f;

    bytes[2] = cast(u8) (base & 0xff);
    bytes[3] = cast(u8) (base >> 8) & 0xff;
    bytes[4] = cast(u8) (base >> 16) & 0xff;
    bytes[7] = cast(u8) (base >> 24) & 0xff;

    entry = << cast(*u64) bytes;
    entry |= flags;
    return entry;
}

Task_State_Segment :: struct {
    reserved_0: u32;
    rsp:        [3] u64 #align 4;
    reserved_1: [2] u32;
    ist:        [7] u64 #align 4;
    reserved_2: [2] u32;
    reserved_3: u16;
    iobp:       u16;
}

#assert(size_of(Task_State_Segment) == 0x68);

tss: Task_State_Segment #align 0x80;

gdt_init :: () {
    using Gdt_Entry_Flags;

    gdt[0] = 0x0;
    gdt[1] = cast(u64) (READ_WRITE | PRESENT | DESCRIPTOR_TYPE | LONG_MODE_CODE | EXECUTABLE);
    gdt[2] = cast(u64) (READ_WRITE | PRESENT | DESCRIPTOR_TYPE);

    gdt[3] = cast(u64) (READ_WRITE | PRESENT | DESCRIPTOR_TYPE | PRIVILEGE0 | PRIVILEGE1 | LONG_MODE_CODE | EXECUTABLE);
    gdt[4] = cast(u64) (READ_WRITE | PRESENT | DESCRIPTOR_TYPE | PRIVILEGE0 | PRIVILEGE1);

    gdt[5] = make_gdt_entry(cast(u64) *tss, size_of(Task_State_Segment), xx SIZE | xx (0x89 << 40));
    gdt[6] = 0xffff_ffff;

    gdtr: struct {
        limit: u16;
        base: u64 #align 2;
    }

    gdtr.limit = 0x38;
    gdtr.base = xx gdt.data;

    gdtrp := *gdtr;
    #asm {
        lgdt [gdtrp];
    }

    tss.iobp = size_of(Task_State_Segment);

    // #bytes .[
    //     0x66, 0xb8, 0x28, 0x00, // mov ax, 0x28
    //     0x0f, 0x00, 0xd8 // ltr ax
    // ];
}
