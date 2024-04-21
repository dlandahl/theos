//
// This file was auto-generated using the following command:
//
// jai generate.jai
//



LIL_UEFI_COMPILER_CLANG :: 1;

LIL_UEFI_ARCH_X64 :: 1;

LIL_UEFI_COMPILER_CL :: 0;

LIL_UEFI_COMPILER_GCC :: 0;

LIL_UEFI_ARCH_X86 :: 0;

LIL_UEFI_ARCH_ARM :: 0;

LIL_UEFI_ARCH_ARM64 :: 0;

EFI_EVT_TIMER :: 0x80000000;
EFI_EVT_RUNTIME :: 0x40000000;
EFI_EVT_NOTIFY_WAIT :: 0x00000100;
EFI_EVT_NOTIFY_SIGNAL :: 0x00000200;
EFI_EVT_SIGNAL_EXIT_BOOT_SERVICES :: 0x00000201;
EFI_EVT_SIGNAL_VIRTUAL_ADDRESS_CHANGE :: 0x60000202;

EFI_TPL_APPLICATION :: 4;
EFI_TPL_CALLBACK :: 8;
EFI_TPL_NOTIFY :: 16;
EFI_TPL_HIGH_LEVEL :: 31;

EFI_MEMORY_UC :: 0x0000000000000001;
EFI_MEMORY_WC :: 0x0000000000000002;
EFI_MEMORY_WT :: 0x0000000000000004;
EFI_MEMORY_WB :: 0x0000000000000008;
EFI_MEMORY_UCE :: 0x0000000000000010;
EFI_MEMORY_WP :: 0x0000000000001000;
EFI_MEMORY_RP :: 0x0000000000002000;
EFI_MEMORY_XP :: 0x0000000000004000;
EFI_MEMORY_NV :: 0x0000000000008000;
EFI_MEMORY_MORE_RELIABLE :: 0x0000000000010000;
EFI_MEMORY_RO :: 0x0000000000020000;
EFI_MEMORY_RUNTIME :: 0x8000000000000000;

EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL :: 0x00000001;
EFI_OPEN_PROTOCOL_GET_PROTOCOL :: 0x00000002;
EFI_OPEN_PROTOCOL_TEST_PROTOCOL :: 0x00000004;
EFI_OPEN_PROTOCOL_BY_CHILD_CONTROLLER :: 0x00000008;
EFI_OPEN_PROTOCOL_BY_DRIVER :: 0x00000010;
EFI_OPEN_PROTOCOL_EXCLUSIVE :: 0x00000020;

EFI_CAPSULE_FLAGS_PERSIST_ACROSS_RESET :: 0x00010000;
EFI_CAPSULE_FLAGS_POPULATE_SYSTEM_TABLE :: 0x00020000;
EFI_CAPSULE_FLAGS_INITIATE_RESET :: 0x00040000;

EFI_DEVICE_PATH_TYPE_Hardware :: 0x01;
EFI_DEVICE_PATH_TYPE_ACPI :: 0x02;
EFI_DEVICE_PATH_TYPE_Messaging :: 0x03;
EFI_DEVICE_PATH_TYPE_Media :: 0x04;
EFI_DEVICE_PATH_TYPE_BIOSBootSpecification :: 0x05;
EFI_DEVICE_PATH_TYPE_EndOfHardware :: 0x7F;

EFI_DEVICE_PATH_SUB_TYPE_EndEntireDevicePath :: 0xFF;
EFI_DEVICE_PATH_SUB_TYPE_EndThisInstance :: 0x01;

EFI_DEVICE_PATH_SUB_TYPE_PCI :: 0x01;
EFI_DEVICE_PATH_SUB_TYPE_PCCARD :: 0x02;
EFI_DEVICE_PATH_SUB_TYPE_MEMORY_MAPPED :: 0x03;
EFI_DEVICE_PATH_SUB_TYPE_VENDOR :: 0x04;
EFI_DEVICE_PATH_SUB_TYPE_CONTROLLER :: 0x05;
EFI_DEVICE_PATH_SUB_TYPE_BMC :: 0x06;

EFI_CHAR_Backspace :: 0x0008;
EFI_CHAR_Tab :: 0x0009;
EFI_CHAR_LineFeed :: 0x000A;
EFI_CHAR_CarriageReturn :: 0x000D;

EFI_SCAN_Null :: 0x0000;
EFI_SCAN_Up :: 0x0001;
EFI_SCAN_Down :: 0x0002;
EFI_SCAN_Right :: 0x0003;
EFI_SCAN_Left :: 0x0004;
EFI_SCAN_Home :: 0x0005;
EFI_SCAN_End :: 0x0006;
EFI_SCAN_Insert :: 0x0007;
EFI_SCAN_Delete :: 0x0008;
EFI_SCAN_PageUp :: 0x0009;
EFI_SCAN_PageDown :: 0x000A;
EFI_SCAN_F1 :: 0x000B;
EFI_SCAN_F2 :: 0x000C;
EFI_SCAN_F3 :: 0x000D;
EFI_SCAN_F4 :: 0x000E;
EFI_SCAN_F5 :: 0x000F;
EFI_SCAN_F6 :: 0x0010;
EFI_SCAN_F7 :: 0x0011;
EFI_SCAN_F8 :: 0x0012;
EFI_SCAN_F9 :: 0x0013;
EFI_SCAN_F10 :: 0x0014;
EFI_SCAN_Esc :: 0x0017;

EFI_BOXDRAW_HORIZONTAL :: 0x2500;
EFI_BOXDRAW_VERTICAL :: 0x2502;
EFI_BOXDRAW_DOWN_RIGHT :: 0x250c;
EFI_BOXDRAW_DOWN_LEFT :: 0x2510;
EFI_BOXDRAW_UP_RIGHT :: 0x2514;
EFI_BOXDRAW_UP_LEFT :: 0x2518;
EFI_BOXDRAW_VERTICAL_RIGHT :: 0x251c;
EFI_BOXDRAW_VERTICAL_LEFT :: 0x2524;
EFI_BOXDRAW_DOWN_HORIZONTAL :: 0x252c;
EFI_BOXDRAW_UP_HORIZONTAL :: 0x2534;
EFI_BOXDRAW_VERTICAL_HORIZONTAL :: 0x253c;
EFI_BOXDRAW_DOUBLE_HORIZONTAL :: 0x2550;
EFI_BOXDRAW_DOUBLE_VERTICAL :: 0x2551;
EFI_BOXDRAW_DOWN_RIGHT_DOUBLE :: 0x2552;
EFI_BOXDRAW_DOWN_DOUBLE_RIGHT :: 0x2553;
EFI_BOXDRAW_DOUBLE_DOWN_RIGHT :: 0x2554;
EFI_BOXDRAW_DOWN_LEFT_DOUBLE :: 0x2555;
EFI_BOXDRAW_DOWN_DOUBLE_LEFT :: 0x2556;
EFI_BOXDRAW_DOUBLE_DOWN_LEFT :: 0x2557;
EFI_BOXDRAW_UP_RIGHT_DOUBLE :: 0x2558;
EFI_BOXDRAW_UP_DOUBLE_RIGHT :: 0x2559;
EFI_BOXDRAW_DOUBLE_UP_RIGHT :: 0x255a;
EFI_BOXDRAW_UP_LEFT_DOUBLE :: 0x255b;
EFI_BOXDRAW_UP_DOUBLE_LEFT :: 0x255c;
EFI_BOXDRAW_DOUBLE_UP_LEFT :: 0x255d;
EFI_BOXDRAW_VERTICAL_RIGHT_DOUBLE :: 0x255e;
EFI_BOXDRAW_VERTICAL_DOUBLE_RIGHT :: 0x255f;
EFI_BOXDRAW_DOUBLE_VERTICAL_RIGHT :: 0x2560;
EFI_BOXDRAW_VERTICAL_LEFT_DOUBLE :: 0x2561;
EFI_BOXDRAW_VERTICAL_DOUBLE_LEFT :: 0x2562;
EFI_BOXDRAW_DOUBLE_VERTICAL_LEFT :: 0x2563;
EFI_BOXDRAW_DOWN_HORIZONTAL_DOUBLE :: 0x2564;
EFI_BOXDRAW_DOWN_DOUBLE_HORIZONTAL :: 0x2565;
EFI_BOXDRAW_DOUBLE_DOWN_HORIZONTAL :: 0x2566;
EFI_BOXDRAW_UP_HORIZONTAL_DOUBLE :: 0x2567;
EFI_BOXDRAW_UP_DOUBLE_HORIZONTAL :: 0x2568;
EFI_BOXDRAW_DOUBLE_UP_HORIZONTAL :: 0x2569;
EFI_BOXDRAW_VERTICAL_HORIZONTAL_DOUBLE :: 0x256a;
EFI_BOXDRAW_VERTICAL_DOUBLE_HORIZONTAL :: 0x256b;
EFI_BOXDRAW_DOUBLE_VERTICAL_HORIZONTAL :: 0x256c;

EFI_BLOCKELEMENT_FULL_BLOCK :: 0x2588;
EFI_BLOCKELEMENT_LIGHT_SHADE :: 0x2591;

EFI_GEOMETRICSHAPE_UP_TRIANGLE :: 0x25b2;
EFI_GEOMETRICSHAPE_RIGHT_TRIANGLE :: 0x25ba;
EFI_GEOMETRICSHAPE_DOWN_TRIANGLE :: 0x25bc;
EFI_GEOMETRICSHAPE_LEFT_TRIANGLE :: 0x25c4;

EFI_ARROW_LEFT :: 0x2190;
EFI_ARROW_UP :: 0x2191;
EFI_ARROW_RIGHT :: 0x2192;
EFI_ARROW_DOWN :: 0x2193;

EFI_BLACK :: 0x00;
EFI_BLUE :: 0x01;
EFI_GREEN :: 0x02;
EFI_RED :: 0x04;
EFI_BRIGHT :: 0x08;
EFI_CYAN :: EFI_BLUE|EFI_GREEN;
EFI_MAGENTA :: EFI_BLUE|EFI_RED;
EFI_BROWN :: EFI_GREEN|EFI_RED;
EFI_LIGHTGRAY :: EFI_BLUE|EFI_GREEN|EFI_RED;
EFI_DARKGRAY :: EFI_BRIGHT|EFI_BLACK;
EFI_LIGHTBLUE :: EFI_BRIGHT|EFI_BLUE;
EFI_LIGHTGREEN :: EFI_BRIGHT|EFI_GREEN;
EFI_LIGHTRED :: EFI_BRIGHT|EFI_RED;
EFI_LIGHTCYAN :: EFI_BRIGHT|EFI_CYAN;
EFI_LIGHTMAGENTA :: EFI_BRIGHT|EFI_MAGENTA;
EFI_YELLOW :: EFI_BRIGHT|EFI_BROWN;
EFI_WHITE :: EFI_BRIGHT|EFI_LIGHTGRAY;

EFI_BACKGROUND_BLACK :: EFI_BLACK << 4;
EFI_BACKGROUND_BLUE :: EFI_BLUE << 4;
EFI_BACKGROUND_GREEN :: EFI_GREEN << 4;
EFI_BACKGROUND_CYAN :: EFI_CYAN << 4;
EFI_BACKGROUND_RED :: EFI_RED << 4;
EFI_BACKGROUND_MAGENTA :: EFI_MAGENTA << 4;
EFI_BACKGROUND_BROWN :: EFI_BROWN << 4;
EFI_BACKGROUND_LIGHTGRAY :: EFI_LIGHTGRAY << 4;

EFI_USB_NOERROR :: 0x0000;
EFI_USB_ERR_NOTEXECUTE :: 0x0001;
EFI_USB_ERR_STALL :: 0x0002;
EFI_USB_ERR_BUFFER :: 0x0004;
EFI_USB_ERR_BABBLE :: 0x0008;
EFI_USB_ERR_NAK :: 0x0010;
EFI_USB_ERR_CRC :: 0x0020;
EFI_USB_ERR_TIMEOUT :: 0x0040;
EFI_USB_ERR_BITSTUFF :: 0x0080;
EFI_USB_ERR_SYSTEM :: 0x0100;

EFI_USB_SPEED_FULL :: 0x0000;
EFI_USB_SPEED_LOW :: 0x0001;
EFI_USB_SPEED_HIGH :: 0x0002;
EFI_USB_SPEED_SUPER :: 0x0003;

EFI_USB_HC_RESET_GLOBAL :: 0x0001;

EFI_USB_HC_RESET_HOST_CONTROLLER :: 0x0002;

EFI_USB_HC_RESET_GLOBAL_WITH_DEBUG :: 0x0004;

EFI_USB_HC_RESET_HOST_WITH_DEBUG :: 0x0008;

EFI_USB_MAX_BULK_BUFFER_NUM :: 10;
EFI_USB_MAX_ISO_BUFFER_NUM :: 7;
EFI_USB_MAX_ISO_BUFFER_NUM1 :: 2;

USB_PORT_STAT_CONNECTION :: 0x0001;
USB_PORT_STAT_ENABLE :: 0x0002;
USB_PORT_STAT_SUSPEND :: 0x0004;
USB_PORT_STAT_OVERCURRENT :: 0x0008;
USB_PORT_STAT_RESET :: 0x0010;
USB_PORT_STAT_POWER :: 0x0100;
USB_PORT_STAT_LOW_SPEED :: 0x0200;
USB_PORT_STAT_HIGH_SPEED :: 0x0400;
USB_PORT_STAT_SUPER_SPEED :: 0x0800;
USB_PORT_STAT_OWNER :: 0x2000;

USB_PORT_STAT_C_CONNECTION :: 0x0001;
USB_PORT_STAT_C_ENABLE :: 0x0002;
USB_PORT_STAT_C_SUSPEND :: 0x0004;
USB_PORT_STAT_C_OVERCURRENT :: 0x0008;
USB_PORT_STAT_C_RESET :: 0x0010;

// SPEC: Table 5
EFI_INT8 :: u8;
EFI_INT16 :: s16;
EFI_INT32 :: s32;
EFI_INT64 :: s64;
EFI_UINT8 :: u8;
EFI_UINT16 :: u16;
EFI_UINT32 :: u32;
EFI_UINT64 :: u64;

EFI_INTN :: EFI_INT64;
EFI_UINTN :: EFI_UINT64;

// SPEC: Table 5
EFI_BOOLEAN :: EFI_UINT8;
EFI_CHAR8 :: EFI_UINT8;
EFI_CHAR16 :: EFI_UINT16;

EFI_GUID :: struct {
    data1: EFI_UINT32;
    data2: EFI_UINT16;
    data3: EFI_UINT16;
    data4: [8] EFI_UINT8;
}

EFI_HANDLE :: *void;
EFI_EVENT :: *void;

EFI_LBA :: EFI_UINT64;
EFI_TPL :: EFI_UINTN;

EFI_MAC_ADDRESS :: struct {
    addr: [32] EFI_UINT8;
}

EFI_IPv4_ADDRESS :: struct {
    addr: [4] EFI_UINT8;
}

EFI_IPv6_ADDRESS :: struct {
    addr: [16] EFI_UINT8;
}

EFI_IP_ADDRESS :: struct {
    addr: [16] EFI_UINT8;
}

EFI_ERROR_BIT :: 0x8000_0000_0000_0000;

EFI_STATUS :: enum s64 {
    Success              :: 0; // The operation completed successfully.
    LoadError            :: EFI_ERROR_BIT | 1; // The image failed to load.
    InvalidParameter     :: EFI_ERROR_BIT | 2; // A parameter was incorrect.
    Unsupported          :: EFI_ERROR_BIT | 3; // The operation is not supported.
    BadBufferSize        :: EFI_ERROR_BIT | 4; // The buffer was not the proper size for the request.
    BufferTooSmall       :: EFI_ERROR_BIT | 5; // The buffer is not large enough to hold the requested data. The required buffer size is returned in the appropriate parameter when this error occurs.
    NotReady             :: EFI_ERROR_BIT | 6; // There is no data pending upon return.
    DeviceError          :: EFI_ERROR_BIT | 7; // The physical device reported an error while attempting the operation.
    WriteProtected       :: EFI_ERROR_BIT | 8; // The device cannot be written to.
    OutOfResources       :: EFI_ERROR_BIT | 9; // A resource has run out.
    VolumeCorrupted      :: EFI_ERROR_BIT | 10; // An inconstancy was detected on the file system causing the operating to fail.
    VolumeFull           :: EFI_ERROR_BIT | 11; // There is no more space on the file system.
    NoMedia              :: EFI_ERROR_BIT | 12; // The device does not contain any medium to perform the operation.
    MediaChanged         :: EFI_ERROR_BIT | 13; // The medium in the device has changed since the last access.
    NotFound             :: EFI_ERROR_BIT | 14; // The item was not found.
    AccessDenied         :: EFI_ERROR_BIT | 15; // Access was denied.
    NoResponse           :: EFI_ERROR_BIT | 16; // The server was not found or did not respond to the request.
    NoMapping            :: EFI_ERROR_BIT | 17; // A mapping to a device does not exist.
    Timeout              :: EFI_ERROR_BIT | 18; // The timeout time expired.
    NotStarted           :: EFI_ERROR_BIT | 19; // The protocol has not been started.
    AlreadyStarted       :: EFI_ERROR_BIT | 20; // The protocol has already been started.
    Aborted              :: EFI_ERROR_BIT | 21; // The operation was aborted.
    IcmpError            :: EFI_ERROR_BIT | 22; // An ICMP error occurred during the network operation.
    TftpError            :: EFI_ERROR_BIT | 23; // A TFTP error occurred during the network operation.
    ProtocolError        :: EFI_ERROR_BIT | 24; // A protocol error occurred during the network operation.
    IncompatibleVersion  :: EFI_ERROR_BIT | 25; // The function encountered an internal version that was incompatible with a version requested by the caller.
    SecurityViolation    :: EFI_ERROR_BIT | 26; // The function was not performed due to a security violation.
    CrcError             :: EFI_ERROR_BIT | 27; // A CRC error was detected.
    EndOfMedia           :: EFI_ERROR_BIT | 28; // Beginning or end of media was reached
    EndOfFile            :: EFI_ERROR_BIT | 31; // The end of the file was reached.
    InvalidLanguage      :: EFI_ERROR_BIT | 32; // The language specified was invalid.
    CompromisedData      :: EFI_ERROR_BIT | 33; // The security status of the data is unknown or compromised and the data must be updated or replaced to restore a valid security status.
    IpAddressConflict    :: EFI_ERROR_BIT | 34; // There is an address conflict address allocation
    HttpError            :: EFI_ERROR_BIT | 35; // A HTTP error occurred during the network operation.
}

// SPEC: Section 4.2
EFI_TABLE_HEADER :: struct {
    Signature:  EFI_UINT64;
    Revision:   EFI_UINT32;
    HeaderSize: EFI_UINT32;
    CRC32:      EFI_UINT32;
    Reserved:   EFI_UINT32;
}

// SPEC: Section 4.3
EFI_SYSTEM_TABLE :: struct {
    Hdr:                  EFI_TABLE_HEADER;
    FirmwareVendor:       *EFI_UINT16;
    FirmwareRevision:     EFI_UINT32;

    ConsoleInHandle:      EFI_HANDLE;
    ConIn:                *EFI_SIMPLE_TEXT_INPUT_PROTOCOL;
    ConsoleOutHandle:     EFI_HANDLE;
    ConOut:               *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;
    StandardErrorHandle:  EFI_HANDLE;
    StdErr:               *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

    RuntimeServices:      *EFI_RUNTIME_SERVICES;
    BootServices:         *EFI_BOOT_SERVICES;
    NumberOfTableEntries: EFI_UINTN;
    ConfigurationTable:   *EFI_CONFIGURATION_TABLE;
}

// SPEC: Section 4.6
EFI_CONFIGURATION_TABLE :: struct {
    VendorGuid:  EFI_GUID;
    VendorTable: *void;
}

EFI_EVENT_NOTIFY_FUNCITON :: #type (event: EFI_EVENT, _context: *void) -> void #c_call;

// SPEC: Section 7.1 "SetTimer"
EFI_TIMER_DELAY :: enum s32 {
    Cancel   :: 0;
    Periodic :: 1;
    Relative :: 2;
}

// SPEC: Section 7.2 "AllocatePages"
EFI_ALLOCATE_TYPE :: enum s32 {
    AllocateAnyPages   :: 0;
    AllocateMaxAddress :: 1;
    AllocateAddress    :: 2;
    MaxAllocateType    :: 3;
}

EFI_MEMORY_TYPE :: enum s32 {
    EfiReservedMemoryType      :: 0;
    EfiLoaderCode              :: 1;
    EfiLoaderData              :: 2;
    EfiBootServicesCode        :: 3;
    EfiBootServicesData        :: 4;
    EfiRuntimeServicesCode     :: 5;
    EfiRuntimeServicesData     :: 6;
    EfiConventionalMemory      :: 7;
    EfiUnusableMemory          :: 8;
    EfiACPIReclaimMemory       :: 9;
    EfiACPIMemoryNVS           :: 10;
    EfiMemoryMappedIO          :: 11;
    EfiMemoryMappedIOPortSpace :: 12;
    EfiPalCode                 :: 13;
    EfiPersistentMemory        :: 14;
    EfiMaxMemoryType           :: 15;
}

EFI_PHYSICAL_ADDRESS :: EFI_UINT64;

// SPEC: Section 7.2 "GetMemoryMap"
EFI_VIRTUAL_ADDRESS :: EFI_UINT64;

EFI_MEMORY_DESCRIPTOR :: struct {
    Type:          EFI_UINT32;
    PhysicalStart: EFI_PHYSICAL_ADDRESS;
    VirtualStart:  EFI_VIRTUAL_ADDRESS;
    NumberOfPages: EFI_UINT64;
    Attribute:     EFI_UINT64;
}

// SPEC: Section 7.3 "InstallProtocolInterface"
EFI_INTERFACE_TYPE :: enum s32 {
    NativeInterface :: 0;
}

// SPEC: Section 7.3 "LocateHandle"
EFI_LOCATE_SEARCH_TYPE :: enum s32 {
    AllHandles       :: 0;
    ByRegisterNotify :: 1;
    ByProtocol       :: 2;
}

// SPEC: Section 7.3 "OpenProtocolInformation"
EFI_OPEN_PROTOCOL_INFORMATION_ENTRY :: struct {
    AgentHandle:      EFI_HANDLE;
    ControllerHandle: EFI_HANDLE;
    Attributes:       EFI_UINT32;
    OpenCount:        EFI_UINT32;
}

EFI_BootServices_RaiseTPL :: #type (new_tpl: EFI_TPL) -> EFI_TPL #c_call;
EFI_BootServices_RestoreTPL :: #type (old_tpl: EFI_TPL) -> void #c_call;
EFI_BootServices_AllocatePages :: #type (type: EFI_ALLOCATE_TYPE, memory_type: EFI_MEMORY_TYPE, pages: EFI_UINTN, memory: *EFI_PHYSICAL_ADDRESS) -> EFI_STATUS #c_call;
EFI_BootServices_FreePages :: #type (memory: EFI_PHYSICAL_ADDRESS, pages: EFI_UINTN) -> EFI_STATUS #c_call;
EFI_BootServices_GetMemoryMap :: #type (size_inout: *EFI_UINTN, descriptors_inout: *EFI_MEMORY_DESCRIPTOR, map_key_out: *EFI_UINTN, descriptor_size_out: *EFI_UINTN, descriptor_version_out: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_BootServices_AllocatePool :: #type (pool_type: EFI_MEMORY_TYPE, size: EFI_UINTN, buffer: **void) -> EFI_STATUS #c_call;
EFI_BootServices_FreePool :: #type (buffer: *void) -> EFI_STATUS #c_call;
EFI_BootServices_CreateEvent :: #type (type: EFI_UINT32, notify_tpl: EFI_TPL, notify_function: EFI_EVENT_NOTIFY_FUNCITON, notify_context: *void, event_out: *EFI_EVENT) -> EFI_STATUS #c_call;
EFI_BootServices_SetTimer :: #type (event: EFI_EVENT, delay_type: EFI_TIMER_DELAY, trigger_time: EFI_UINT64) -> EFI_STATUS #c_call;
EFI_BootServices_WaitForEvent :: #type (number_of_events: EFI_UINTN, event: *EFI_EVENT, index: *EFI_UINTN) -> EFI_STATUS #c_call;
EFI_BootServices_SignalEvent :: #type (event: EFI_EVENT) -> EFI_STATUS #c_call;
EFI_BootServices_CloseEvent :: #type (event: EFI_EVENT) -> EFI_STATUS #c_call;
EFI_BootServices_CheckEvent :: #type (event: EFI_EVENT) -> EFI_STATUS #c_call;
EFI_BootServices_InstallProtocolInterface :: #type (handle: *EFI_HANDLE, protocol: *EFI_GUID, interface_type: EFI_INTERFACE_TYPE, _interface: *void) -> EFI_STATUS #c_call;
EFI_BootServices_ReinstallProtocolInterface :: #type (handle: *EFI_HANDLE, protocol: *EFI_GUID, old_interface: *void, new_interface: *void) -> EFI_STATUS #c_call;
EFI_BootServices_UninstallProtocolInterface :: #type (handle: EFI_HANDLE, protocol: *EFI_GUID, _interface: *void) -> EFI_STATUS #c_call;
EFI_BootServices_HandleProtocol :: #type (handle: EFI_HANDLE, protocol: *EFI_GUID, _interface: **void) -> EFI_STATUS #c_call;
EFI_BootServices_Reserved :: #type () -> void #c_call;
EFI_BootServices_RegisterProtocolNotify :: #type (protocol: *EFI_GUID, event: EFI_EVENT, registration: **void) -> EFI_STATUS #c_call;
EFI_BootServices_LocateHandle :: #type (search_type: EFI_LOCATE_SEARCH_TYPE, protocol: *EFI_GUID, search_key: *void, buffer_size: *EFI_UINTN, buffer: *EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_LocateDevicePath :: #type (protocol: *EFI_GUID, device_path: **EFI_DEVICE_PATH_PROTOCOL, device: *EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_InstallConfigurationTable :: #type (guid: *EFI_GUID, table: *void) -> EFI_HANDLE #c_call;
EFI_BootServices_LoadImage :: #type (boot_policy: EFI_BOOLEAN, parent_image_handle: EFI_HANDLE, device_path: *EFI_DEVICE_PATH_PROTOCOL, source_buffer: *void, source_size: EFI_UINTN, image_handle_out: *EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_StartImage :: #type (image_handle: EFI_HANDLE, exit_data_size: *EFI_UINTN, exit_data: **EFI_UINT16) -> EFI_STATUS #c_call;
EFI_BootServices_Exit :: #type (image_handle: EFI_HANDLE, exit_status: EFI_STATUS, exit_data_size: EFI_UINTN, exit_data: *EFI_UINT16) -> EFI_STATUS #c_call;
EFI_BootServices_UnloadImage :: #type (image_handle: EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_ExitBootServices :: #type (image_handle: EFI_HANDLE, map_key: EFI_UINTN) -> EFI_STATUS #c_call;
EFI_BootServices_GetNextMonotonicCount :: #type (count_out: *EFI_UINT64) -> EFI_STATUS #c_call;
EFI_BootServices_Stall :: #type (microseconds: EFI_UINTN) -> EFI_STATUS #c_call;
EFI_BootServices_SetWatchdogTimer :: #type (timeout: EFI_UINTN, watchdog_code: EFI_UINT64, data_size: EFI_UINTN, watchdog_data: *EFI_UINT16) -> EFI_STATUS #c_call;
EFI_BootServices_ConnectController :: #type (controller_handle: EFI_HANDLE, driver_image_handle: *EFI_HANDLE, remaining_device_path: *EFI_DEVICE_PATH_PROTOCOL, recursive: EFI_BOOLEAN) -> EFI_STATUS #c_call;
EFI_BootServices_DisconnectController :: #type (controller_handle: EFI_HANDLE, driver_image_handle: EFI_HANDLE, child_handle: EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_OpenProtocol :: #type (handle: EFI_HANDLE, protocol: *EFI_GUID, _interface: **void, agent_handle: EFI_HANDLE, controller_handle: EFI_HANDLE, attributes: EFI_UINT32) -> EFI_STATUS #c_call;
EFI_BootServices_CloseProtocol :: #type (handle: EFI_HANDLE, protocol: *EFI_GUID, agent_handle: EFI_HANDLE, controller_handle: EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_OpenProtocolInformation :: #type (handle: EFI_HANDLE, protocol: *EFI_GUID, entry_buffer: **EFI_OPEN_PROTOCOL_INFORMATION_ENTRY, entry_count: *EFI_UINTN) -> EFI_STATUS #c_call;
EFI_BootServices_ProtocolsPerHandle :: #type (handle: EFI_HANDLE, protocol_buffer: ***EFI_GUID, protocol_buffer_count: *EFI_UINTN) -> EFI_STATUS #c_call;
EFI_BootServices_LocateHandleBuffer :: #type (search_type: EFI_LOCATE_SEARCH_TYPE, protocol: *EFI_GUID, search_key: *void, handle_count: *EFI_UINTN, buffer: **EFI_HANDLE) -> EFI_STATUS #c_call;
EFI_BootServices_LocateProtocol :: #type (protocol: *EFI_GUID, registration: *void, _interface: **void) -> EFI_STATUS #c_call;
EFI_BootServices_InstallMultipleProtocolInterfaces :: #type (handle: *EFI_HANDLE, __args: ..Any) -> EFI_STATUS #c_call;
EFI_BootServices_UninstallMultipleProtocolInterfaces :: #type (handle: EFI_HANDLE, __args: ..Any) -> EFI_STATUS #c_call;
EFI_BootServices_CalculateCrc32 :: #type (data: *void, data_size: EFI_UINTN, crc32_out: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_BootServices_CopyMem :: #type (destination: *void, source: *void, length: EFI_UINTN) -> void #c_call;
EFI_BootServices_SetMem :: #type (buffer: *void, size: EFI_UINTN, value: EFI_UINT8) -> void #c_call;
EFI_BootServices_CreateEventEx :: #type (type: EFI_UINT32, notify_tpl: EFI_TPL, notify_function: EFI_EVENT_NOTIFY_FUNCITON, notify_context: *void, event_group: *EFI_GUID, event_out: *EFI_EVENT) -> EFI_STATUS #c_call;

EFI_BOOT_SERVICES :: struct {
    hdr:                                 EFI_TABLE_HEADER;

    RaiseTPL:                            EFI_BootServices_RaiseTPL;
    RestoreTPL:                          EFI_BootServices_RestoreTPL;
    AllocatePages:                       EFI_BootServices_AllocatePages;
    FreePages:                           EFI_BootServices_FreePages;
    GetMemoryMap:                        EFI_BootServices_GetMemoryMap;
    AllocatePool:                        EFI_BootServices_AllocatePool;
    FreePool:                            EFI_BootServices_FreePool;
    CreateEvent:                         EFI_BootServices_CreateEvent;
    SetTimer:                            EFI_BootServices_SetTimer;
    WaitForEvent:                        EFI_BootServices_WaitForEvent;
    SignalEvent:                         EFI_BootServices_SignalEvent;
    CloseEvent:                          EFI_BootServices_CloseEvent;
    CheckEvent:                          EFI_BootServices_CheckEvent;
    InstallProtocolInterface:            EFI_BootServices_InstallProtocolInterface;
    ReinstallProtocolInterface:          EFI_BootServices_ReinstallProtocolInterface;
    UninstallProtocolInterface:          EFI_BootServices_UninstallProtocolInterface;
    HandleProtocol:                      EFI_BootServices_HandleProtocol;
    Reserved:                            EFI_BootServices_Reserved;
    RegisterProtocolNotify:              EFI_BootServices_RegisterProtocolNotify;
    LocateHandle:                        EFI_BootServices_LocateHandle;
    LocateDevicePath:                    EFI_BootServices_LocateDevicePath;
    InstallConfigurationTable:           EFI_BootServices_InstallConfigurationTable;
    LoadImage:                           EFI_BootServices_LoadImage;
    StartImage:                          EFI_BootServices_StartImage;
    Exit:                                EFI_BootServices_Exit;
    UnloadImage:                         EFI_BootServices_UnloadImage;
    ExitBootServices:                    EFI_BootServices_ExitBootServices;
    GetNextMonotonicCount:               EFI_BootServices_GetNextMonotonicCount;
    Stall:                               EFI_BootServices_Stall;
    SetWatchdogTimer:                    EFI_BootServices_SetWatchdogTimer;
    ConnectController:                   EFI_BootServices_ConnectController;
    DisconnectController:                EFI_BootServices_DisconnectController;
    OpenProtocol:                        EFI_BootServices_OpenProtocol;
    CloseProtocol:                       EFI_BootServices_CloseProtocol;
    OpenProtocolInformation:             EFI_BootServices_OpenProtocolInformation;
    ProtocolsPerHandle:                  EFI_BootServices_ProtocolsPerHandle;
    LocateHandleBuffer:                  EFI_BootServices_LocateHandleBuffer;
    LocateProtocol:                      EFI_BootServices_LocateProtocol;
    InstallMultipleProtocolInterfaces:   EFI_BootServices_InstallMultipleProtocolInterfaces;
    UninstallMultipleProtocolInterfaces: EFI_BootServices_UninstallMultipleProtocolInterfaces;
    CalculateCrc32:                      EFI_BootServices_CalculateCrc32;
    CopyMem:                             EFI_BootServices_CopyMem;
    SetMem:                              EFI_BootServices_SetMem;
    CreateEventEx:                       EFI_BootServices_CreateEventEx;
}

// SPEC: Section 8.3 "GetTime"
EFI_TIME :: struct {
    Year:       EFI_UINT16;
    Month:      EFI_UINT8;
    Day:        EFI_UINT8;
    Hour:       EFI_UINT8;
    Minute:     EFI_UINT8;
    Second:     EFI_UINT8;
    Pad1:       EFI_UINT8;
    Nanosecond: EFI_UINT32;
    TimeZone:   EFI_INT16;
    Daylight:   EFI_UINT8;
    Pad2:       EFI_UINT8;
}

EFI_TIME_CAPABILITIES :: struct {
    Resolution: EFI_UINT32;
    Accuracy:   EFI_UINT32;
    SetsToZero: EFI_BOOLEAN;
}

// SPEC: Section 8.5.1 "ResetSystem"
EFI_RESET_TYPE :: enum s32 {
    Cold             :: 0;
    Warm             :: 1;
    Shutdown         :: 2;
    PlatformSpecific :: 3;
}

// SPEC: Section 8.5.3 "UpdateCapsule"
EFI_CAPSULE_BLOCK_DESCRIPTOR :: struct {
    Length: EFI_UINT64;
    Union:  union {
        DataBlock:           EFI_PHYSICAL_ADDRESS;
        ContinuationPointer: EFI_PHYSICAL_ADDRESS;
    };
}

EFI_CAPSULE_HEADER :: struct {
    CapsuleGuid:      EFI_GUID;
    HeaderSize:       EFI_UINT32;
    Flags:            EFI_UINT32;
    CapsuleImageSize: EFI_UINT32;
}

EFI_RuntimeServices_GetTime :: #type (time_out: *EFI_TIME, capabilities_out: *EFI_TIME_CAPABILITIES) -> EFI_STATUS #c_call;
EFI_RuntimeServices_SetTime :: #type (time: *EFI_TIME) -> EFI_STATUS #c_call;
EFI_RuntimeServices_GetWakeupTime :: #type (enabled_out: *EFI_BOOLEAN, pending_out: *EFI_BOOLEAN, time_out: *EFI_TIME) -> EFI_STATUS #c_call;
EFI_RuntimeServices_SetWakeupTime :: #type (enable: EFI_BOOLEAN, time: *EFI_TIME) -> EFI_STATUS #c_call;
EFI_RuntimeServices_SetVirtualAddressMap :: #type (memory_map_size: EFI_UINTN, descriptor_size: EFI_UINTN, descriptor_version: EFI_UINT32, virtual_map: *EFI_MEMORY_DESCRIPTOR) -> EFI_STATUS #c_call;
EFI_RuntimeServices_ConvertPointer :: #type (debug_disposition: EFI_UINTN, address: **void) -> EFI_STATUS #c_call;
EFI_RuntimeServices_GetVariable :: #type (variable_name: *EFI_UINT16, vendor_guid: *EFI_GUID, attributes_out: *EFI_UINT32, data_size: *EFI_UINTN, data: *void) -> EFI_STATUS #c_call;
EFI_RuntimeServices_GetNextVariableName :: #type (variable_name_size: *EFI_UINTN, variable_name: *EFI_UINT16, vendor_guid: *EFI_GUID) -> EFI_STATUS #c_call;
EFI_RuntimeServices_SetVariable :: #type (variable_name: *EFI_UINT16, vendor_guid: *EFI_GUID, attributes: EFI_UINT32, data_size: EFI_UINTN, data: *void) -> EFI_STATUS #c_call;
EFI_RuntimeServices_GetNextHighMonotonicCount :: #type (high_count: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_RuntimeServices_ResetSystem :: #type (reset_type: EFI_RESET_TYPE, reset_status: EFI_STATUS, data_size: EFI_UINTN, reset_data: *void) -> EFI_STATUS #c_call;
EFI_RuntimeServices_UpdateCapsule :: #type (capsule_header_array: **EFI_CAPSULE_HEADER, capsule_count: EFI_UINTN, scatter_gather_list: EFI_PHYSICAL_ADDRESS) -> EFI_STATUS #c_call;
EFI_RuntimeServices_QueryCapsuleCapabilities :: #type (capsule_header_array: **EFI_CAPSULE_HEADER, capsule_count: EFI_UINTN, max_capsule_size: *EFI_UINT64, reset_type: *EFI_RESET_TYPE) -> EFI_STATUS #c_call;
EFI_RuntimeServices_QueryVariableInfo :: #type (attributes: EFI_UINT32, max_variable_storage_size: *EFI_UINT64, remaining_variable_storage_size: *EFI_UINT64, maximum_variable_size: *EFI_UINT64) -> EFI_STATUS #c_call;

EFI_RUNTIME_SERVICES :: struct {
    hdr:                       EFI_TABLE_HEADER;

    GetTime:                   EFI_RuntimeServices_GetTime;
    SetTime:                   EFI_RuntimeServices_SetTime;
    GetWakeupTime:             EFI_RuntimeServices_GetWakeupTime;
    SetWakeupTime:             EFI_RuntimeServices_SetWakeupTime;
    SetVirtualAddressMap:      EFI_RuntimeServices_SetVirtualAddressMap;
    ConvertPointer:            EFI_RuntimeServices_ConvertPointer;
    GetVariable:               EFI_RuntimeServices_GetVariable;
    GetNextVariableName:       EFI_RuntimeServices_GetNextVariableName;
    SetVariable:               EFI_RuntimeServices_SetVariable;
    GetNextHighMonotonicCount: EFI_RuntimeServices_GetNextHighMonotonicCount;
    ResetSystem:               EFI_RuntimeServices_ResetSystem;
    UpdateCapsule:             EFI_RuntimeServices_UpdateCapsule;
    QueryCapsuleCapabilities:  EFI_RuntimeServices_QueryCapsuleCapabilities;
    QueryVariableInfo:         EFI_RuntimeServices_QueryVariableInfo;
}

EFI_DEVICE_PATH_PROTOCOL :: struct {
    Type:    EFI_UINT8;
    SubType: EFI_UINT8;
    Length:  [2] EFI_UINT8;
}

// SPEC: Section 12.3 "ReadKeyStroke"
EFI_INPUT_KEY :: struct {
    ScanCode:    EFI_UINT16;
    UnicodeChar: EFI_UINT16;
}

EFI_SimpleTextInputProtocol_Reset :: #type (prot: *EFI_SIMPLE_TEXT_INPUT_PROTOCOL, extended_verification: EFI_BOOLEAN) -> EFI_STATUS #c_call;
EFI_SimpleTextInputProtocol_ReadKeyStroke :: #type (prot: *EFI_SIMPLE_TEXT_INPUT_PROTOCOL, key: *EFI_INPUT_KEY) -> EFI_STATUS #c_call;

EFI_SIMPLE_TEXT_INPUT_PROTOCOL :: struct {
    Reset:         EFI_SimpleTextInputProtocol_Reset;
    ReadKeyStroke: EFI_SimpleTextInputProtocol_ReadKeyStroke;

    WaitForKey:    EFI_EVENT;
}

EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_GUID := EFI_GUID.{0x387477c2, 0x69c7, 0x11d2, .[0x8e, 0x39, 0x0, 0xa0, 0xc9, 0x69, 0x72, 0x3b]};

EFI_SIMPLE_TEXT_OUTPUT_MODE :: struct {
    MaxMode:       EFI_INT32;
    Mode:          EFI_INT32;
    Attribute:     EFI_INT32;
    CursorColumn:  EFI_INT32;
    CursorRow:     EFI_INT32;
    CursorVisible: EFI_BOOLEAN;
}

EFI_SimpleTextOutputProtocol_Reset :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, extended_verification: EFI_BOOLEAN) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_OutputString :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, _string: *EFI_UINT16) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_TestString :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, _string: *EFI_UINT16) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_QueryMode :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, mode_number: EFI_UINTN, columns: *EFI_UINTN, rows: *EFI_UINTN) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_SetMode :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, mode_number: EFI_UINTN) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_SetAttribute :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, attribute: EFI_UINTN) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_ClearScreen :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_SetCursorPosition :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, column: EFI_UINTN, row: EFI_UINTN) -> EFI_STATUS #c_call;
EFI_SimpleTextOutputProtocol_EnableCursor :: #type (prot: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, visible: EFI_BOOLEAN) -> EFI_STATUS #c_call;

EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL :: struct {
    Reset:             EFI_SimpleTextOutputProtocol_Reset;
    OutputString:      EFI_SimpleTextOutputProtocol_OutputString;
    TestString:        EFI_SimpleTextOutputProtocol_TestString;
    QueryMode:         EFI_SimpleTextOutputProtocol_QueryMode;
    SetMode:           EFI_SimpleTextOutputProtocol_SetMode;
    SetAttribute:      EFI_SimpleTextOutputProtocol_SetAttribute;
    ClearScreen:       EFI_SimpleTextOutputProtocol_ClearScreen;
    SetCursorPosition: EFI_SimpleTextOutputProtocol_SetCursorPosition;
    EnableCursor:      EFI_SimpleTextOutputProtocol_EnableCursor;

    Mode:              *EFI_SIMPLE_TEXT_OUTPUT_MODE;
}

EFI_SIMPLE_POINTER_MODE :: struct {
    ResolutionX: EFI_UINT64;
    ResolutionY: EFI_UINT64;
    ResolutionZ: EFI_UINT64;
    LeftButton:  EFI_BOOLEAN;
    RightButton: EFI_BOOLEAN;
}

EFI_SIMPLE_POINTER_STATE :: struct {
    RelativeMovementX: EFI_INT32;
    RelativeMovementY: EFI_INT32;
    RelativeMovementZ: EFI_INT32;
    LeftButton:        EFI_BOOLEAN;
    RightButton:       EFI_BOOLEAN;
}

EFI_SimplePointerProtocol_Reset :: #type (prot: *EFI_SIMPLE_POINTER_PROTOCOL, extended_verification: EFI_BOOLEAN) -> EFI_STATUS #c_call;
EFI_SimplePointerProtocol_GetState :: #type (prot: *EFI_SIMPLE_POINTER_PROTOCOL, out_state: *EFI_SIMPLE_POINTER_STATE) -> EFI_STATUS #c_call;

EFI_SIMPLE_POINTER_PROTOCOL :: struct {
    Reset:        EFI_SimplePointerProtocol_Reset;
    GetState:     EFI_SimplePointerProtocol_GetState;

    WaitForInput: EFI_EVENT;
    Mode:         *EFI_SIMPLE_POINTER_MODE;
}

EFI_PIXEL_BITMASK :: struct {
    RedMask:      EFI_UINT32;
    GreenMask:    EFI_UINT32;
    BlueMask:     EFI_UINT32;
    ReservedMask: EFI_UINT32;
}

EFI_GRAPHICS_PIXEL_FORMAT :: enum s32 {
    PixelRedGreenBlueReserved8BitPerColor :: 0;
    PixelBlueGreenRedReserved8BitPerColor :: 1;
    PixelBitMask                          :: 2;
    PixelBltOnly                          :: 3;
    PixelFormatMAX                        :: 4;
}

EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID := EFI_GUID.{0x9042a9de, 0x23dc, 0x4a38, .[0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a]};

EFI_GRAPHICS_OUTPUT_MODE_INFORMATION :: struct {
    Version:              EFI_UINT32;
    HorizontalResolution: EFI_UINT32;
    VerticalResolution:   EFI_UINT32;
    PixelFormat:          EFI_GRAPHICS_PIXEL_FORMAT;
    PixelInformation:     EFI_PIXEL_BITMASK;
    PixelsPerScanLine:    EFI_UINT32;
}

EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE :: struct {
    max_mode:          EFI_UINT32;
    mode:              EFI_UINT32;
    info:              *EFI_GRAPHICS_OUTPUT_MODE_INFORMATION;
    size_of_info:      EFI_UINTN;
    frame_buffer_base: EFI_PHYSICAL_ADDRESS;
    frame_buffer_size: EFI_UINTN;
}

// SPEC: Section 12.9 "Blt"
EFI_GRAPHICS_OUTPUT_BLT_PIXEL :: struct {
    Blue:     EFI_UINT8;
    Green:    EFI_UINT8;
    Red:      EFI_UINT8;
    Reserved: EFI_UINT8;
}

EFI_GRAPHICS_OUTPUT_BLT_OPERATION :: enum s32 {
    VideoFill     :: 0;
    VideoToBuffer :: 1;
    BufferToVideo :: 2;
    VideoToVideo  :: 3;
    Max           :: 4;
}

EFI_GraphicsOutputProtocol_QueryMode :: #type (prot: *EFI_GRAPHICS_OUTPUT_PROTOCOL, mode_number: EFI_UINT32, size_of_info: *EFI_UINTN, info: **EFI_GRAPHICS_OUTPUT_MODE_INFORMATION) -> EFI_STATUS #c_call;
EFI_GraphicsOutputProtocol_SetMode :: #type (prot: *EFI_GRAPHICS_OUTPUT_PROTOCOL, mode_number: EFI_UINT32) -> EFI_STATUS #c_call;
EFI_GraphicsOutputProtocol_Blt :: #type (prot: *EFI_GRAPHICS_OUTPUT_PROTOCOL, buffer: *EFI_UINT32, blt_operation: EFI_GRAPHICS_OUTPUT_BLT_OPERATION, src_x: EFI_UINTN, src_y: EFI_UINTN, dst_x: EFI_UINTN, dst_y: EFI_UINTN, width: EFI_UINTN, height: EFI_UINTN, src_stride: EFI_UINTN) -> EFI_STATUS #c_call;

EFI_GRAPHICS_OUTPUT_PROTOCOL :: struct {
    QueryMode: EFI_GraphicsOutputProtocol_QueryMode;
    SetMode:   EFI_GraphicsOutputProtocol_SetMode;
    Blt:       EFI_GraphicsOutputProtocol_Blt;

    Mode:      *EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE;
}


// EFI Loaded Image protocol

EFI_LOADED_IMAGE_PROTOCOL_GUID := EFI_GUID.{0x5B1B31A1, 0x9562, 0x11d2, .[0x8E, 0x3F, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B]};

// EFI_LoadedImageProtocol :: #type (

EFI_LOADED_IMAGE_PROTOCOL :: struct {
   Revision:        EFI_UINT32;
   ParentHandle:    EFI_HANDLE;
   SystemTable:    *EFI_SYSTEM_TABLE;
   DeviceHandle:    EFI_HANDLE;
   FilePath:       *EFI_DEVICE_PATH_PROTOCOL;
   Reserved:       *void;
   LoadOptionsSize: EFI_UINT32;
   LoadOptions:    *void;
   ImageBase:      *void;
   ImageSize:       EFI_UINT64;
   ImageCodeType:   EFI_MEMORY_TYPE;
   ImageDataType:   EFI_MEMORY_TYPE;
   Unload:          *void;
}


// EFI Simple File System protocol

EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID := EFI_GUID.{0x0964e5b22, 0x6459, 0x11d2, .[0x8e, 0x39, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b]};

EFI_SimpleFileSystemProtocol_OpenVolume :: #type (prot: *EFI_SIMPLE_FILE_SYSTEM_PROTOCOL, root: **EFI_FILE_PROTOCOL) -> EFI_STATUS #c_call;

EFI_SIMPLE_FILE_SYSTEM_PROTOCOL :: struct {
    Revision:     EFI_UINT64;
    OpenVolume:   EFI_SimpleFileSystemProtocol_OpenVolume;
}


// EFI File protocol

EFI_FILE_INFO_GUID := EFI_GUID.{0x09576e92, 0x6d3f, 0x11d2, .[0x8e, 0x39, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b]};

EFI_FILE_OPEN_MODE :: enum EFI_UINT64 {
    Read     :: 0x1;
    Write    :: 0x2;
    Create   :: 0x8000_0000_0000_0000;
}

EFI_FILE_ATTRIBUTES :: enum EFI_UINT64 {
    READ_ONLY     :: 0x01;
    HIDDEN        :: 0x02;
    SYSTEM        :: 0x04;
    RESERVED      :: 0x08;
    DIRECTORY     :: 0x10;
    ARCHIVE       :: 0x20;
    VALID_ATTR    :: 0x37;
}

EFI_FileProtocol_Open    :: #type (prot: *EFI_FILE_PROTOCOL, new_handle: *EFI_FILE_PROTOCOL, file_name: *EFI_CHAR16, open_mode: EFI_FILE_OPEN_MODE, attributes: EFI_FILE_ATTRIBUTES) -> EFI_STATUS #c_call;
EFI_FileProtocol_Close   :: #type (prot: *EFI_FILE_PROTOCOL) -> EFI_STATUS #c_call;
EFI_FileProtocol_Delete  :: #type (prot: *EFI_FILE_PROTOCOL) -> EFI_STATUS #c_call;
EFI_FileProtocol_Read    :: #type (prot: *EFI_FILE_PROTOCOL, buffer_size: *EFI_UINTN, buffer: *void) -> EFI_STATUS #c_call;
EFI_FileProtocol_GetInfo :: #type (prot: *EFI_FILE_PROTOCOL, information_type: *EFI_GUID, buffer_size: *EFI_UINTN, buffer: *void) -> EFI_STATUS #c_call;

EFI_FILE_PROTOCOL :: struct {
    Revision:    EFI_UINT64;
    Open:        EFI_FileProtocol_Open;
    Close:       EFI_FileProtocol_Close;
    Delete:      EFI_FileProtocol_Delete;
    Read:        EFI_FileProtocol_Read;
    Write:       *void; // EFI_FileProtocol_Write;
    GetPosition: *void; // EFI_FileProtocol_GetPosition;
    SetPosition: *void; // EFI_FileProtocol_SetPosition;
    GetInfo:     EFI_FileProtocol_GetInfo;
    SetInfo:     *void; // EFI_FileProtocol_SetInfo;
    Flush:       *void; // EFI_FileProtocol_Flush;
}

EFI_FILE_INFO :: struct {
    Size:             EFI_UINT64;
    FileSize:         EFI_UINT64;
    PhysicalSize:     EFI_UINT64;
    CreateTime:       EFI_TIME;
    LastAccessTime:   EFI_TIME;
    ModificationTime: EFI_TIME;
    Attribute:        EFI_UINT64;
}

// SPEC: Section 17.1.1
EFI_USB_HC_STATE :: enum s32 {
    UsbHcStateHalt        :: 0;
    UsbHcStateOperational :: 1;
    UsbHcStateSuspend     :: 2;
    UsbHcStateMaximum     :: 3;
}

EFI_USB_DATA_DIRECTION :: enum s32 {
    DataIn  :: 0;
    DataOut :: 1;
    NoData  :: 2;
}

EFI_USB_DEVICE_REQUEST :: struct {
    RequestType: EFI_UINT8;
    Request:     EFI_UINT8;
    Value:       EFI_UINT16;
    Index:       EFI_UINT16;
    Length:      EFI_UINT16;
}

EFI_ASYNC_USB_TRANSFER_CALLBACK :: #type (data: *void, data_length: EFI_UINTN, _context: *void, status: EFI_UINT32) -> EFI_STATUS #c_call;

EFI_USB2_HC_TRANSACTION_TRANSLATOR :: struct {
    TranslatorHubAddress: EFI_UINT8;
    TranslatorPortNumber: EFI_UINT8;
}

EFI_USB_PORT_STATUS :: struct {
    PortStatus:       EFI_UINT16;
    PortChangeStatus: EFI_UINT16;
}

EFI_USB_PORT_FEATURE :: enum s32 {
    UsbPortEnable            :: 1;
    UsbPortSuspend           :: 2;
    UsbPortReset             :: 4;
    UsbPortPower             :: 8;
    UsbPortOwner             :: 13;
    UsbPortConnectChange     :: 16;
    UsbPortEnableChange      :: 17;
    UsbPortSuspendChange     :: 18;
    UsbPortOverCurrentChange :: 19;
    UsbPortResetChange       :: 20;
}

EFI_USB2HCProtocol_GetCapability :: #type (prot: *EFI_USB2_HC_PROTOCOL, max_speed: *EFI_UINT8, port_number: *EFI_UINT8, is_64bit_capable: *EFI_UINT8) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_Reset :: #type (prot: *EFI_USB2_HC_PROTOCOL, attributes: EFI_UINT16) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_GetState :: #type (prot: *EFI_USB2_HC_PROTOCOL, out_state: *EFI_USB_HC_STATE) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_SetState :: #type (prot: *EFI_USB2_HC_PROTOCOL, state: EFI_USB_HC_STATE) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_ControlTransfer :: #type (prot: *EFI_USB2_HC_PROTOCOL, device_address: EFI_UINT8, device_speed: EFI_UINT8, max_packet_length: EFI_UINTN, request: *EFI_USB_DEVICE_REQUEST, transfer_direction: EFI_USB_DATA_DIRECTION, data: *void, data_length: *EFI_UINTN, timeout: EFI_UINTN, translator: *EFI_USB2_HC_TRANSACTION_TRANSLATOR, transfer_result: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_BulkTransfer :: #type (prot: *EFI_USB2_HC_PROTOCOL, device_address: EFI_UINT8, endpoint_address: EFI_UINT8, device_speed: EFI_UINT8, max_packet_length: EFI_UINTN, data_buffers_number: EFI_UINT8, data: *[10] *void, data_length: *EFI_UINTN, data_toggle: *EFI_UINT8, timeout: EFI_UINTN, translator: *EFI_USB2_HC_TRANSACTION_TRANSLATOR, transfer_result: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_AsyncInterruptTransfer :: #type (prot: *EFI_USB2_HC_PROTOCOL, device_address: EFI_UINT8, endpoint_address: EFI_UINT8, device_speed: EFI_UINT8, max_packet_length: EFI_UINTN, is_new_transfer: EFI_BOOLEAN, data_toggle: *EFI_UINT8, polling_interval: EFI_UINTN, data_length: EFI_UINTN, translator: *EFI_USB2_HC_TRANSACTION_TRANSLATOR, callback: EFI_ASYNC_USB_TRANSFER_CALLBACK, _context: *void) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_SyncInterruptTransfer :: #type (prot: *EFI_USB2_HC_PROTOCOL, device_address: EFI_UINT8, endpoint_address: EFI_UINT8, device_speed: EFI_UINT8, max_packet_length: EFI_UINTN, data: *void, data_length: *EFI_UINTN, data_toggle: *EFI_UINT8, timeout: EFI_UINTN, translator: *EFI_USB2_HC_TRANSACTION_TRANSLATOR, transfer_result: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_IsochronousTransfer :: #type (prot: *EFI_USB2_HC_PROTOCOL, device_address: EFI_UINT8, endpoint_address: EFI_UINT8, device_speed: EFI_UINT8, max_packet_length: EFI_UINTN, data_buffers_number: EFI_UINT8, data: *[7] *void, data_length: EFI_UINTN, translator: *EFI_USB2_HC_TRANSACTION_TRANSLATOR, transfer_result: *EFI_UINT32) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_AsyncIsochronousTransfer :: #type (prot: *EFI_USB2_HC_PROTOCOL, device_address: EFI_UINT8, endpoint_address: EFI_UINT8, device_speed: EFI_UINT8, max_packet_length: EFI_UINTN, data_buffers_number: EFI_UINT8, data: *[7] *void, data_length: EFI_UINTN, translator: *EFI_USB2_HC_TRANSACTION_TRANSLATOR, isochronous_callback: EFI_ASYNC_USB_TRANSFER_CALLBACK, _context: *void) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_GetRootHubPortStatus :: #type (prot: *EFI_USB2_HC_PROTOCOL, port_number: EFI_UINT8, port_status: *EFI_USB_PORT_STATUS) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_SetRootHubPortFeature :: #type (prot: *EFI_USB2_HC_PROTOCOL, port_number: EFI_UINT8, port_feature: EFI_USB_PORT_FEATURE) -> EFI_STATUS #c_call;
EFI_USB2HCProtocol_ClearRootHubPortFeature :: #type (prot: *EFI_USB2_HC_PROTOCOL, port_number: EFI_UINT8, port_feature: EFI_USB_PORT_FEATURE) -> EFI_STATUS #c_call;

// Protocol
EFI_USB2_HC_PROTOCOL :: struct {
    GetCapability:            EFI_USB2HCProtocol_GetCapability;
    Reset:                    EFI_USB2HCProtocol_Reset;
    GetState:                 EFI_USB2HCProtocol_GetState;
    SetState:                 EFI_USB2HCProtocol_SetState;
    ControlTransfer:          EFI_USB2HCProtocol_ControlTransfer;
    BulkTransfer:             EFI_USB2HCProtocol_BulkTransfer;
    AsyncInterruptTransfer:   EFI_USB2HCProtocol_AsyncInterruptTransfer;
    SyncInterruptTransfer:    EFI_USB2HCProtocol_SyncInterruptTransfer;
    IsochronousTransfer:      EFI_USB2HCProtocol_IsochronousTransfer;
    AsyncIsochronousTransfer: EFI_USB2HCProtocol_AsyncIsochronousTransfer;
    GetRootHubPortStatus:     EFI_USB2HCProtocol_GetRootHubPortStatus;
    SetRootHubPortFeature:    EFI_USB2HCProtocol_SetRootHubPortFeature;
    ClearRootHubPortFeature:  EFI_USB2HCProtocol_ClearRootHubPortFeature;

    MajorRevision:            EFI_UINT16;
    MinorRevision:            EFI_UINT16;
}

#scope_file

