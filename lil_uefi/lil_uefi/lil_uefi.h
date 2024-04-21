// Lil' UEFI Header
// Version 0.1 - AUG 21 2022
//
// based on UEFI spec 2.7 (https://uefi.org/sites/default/files/resources/UEFI_Spec_2_7.pdf)
// NOT FULL COVERAGE OF THE SPEC - NOT PRECISELY FOLLOWING EVERY DETAIL GIVEN IN THE SPEC
//
// Made for use by authors of UEFI applications.
// Go learn how to make operating systems!



////////////////////////////////
// LICENSE
//
//   This software is in the public domain. Where that dedication is not
//   recognized, you are granted a perpetual, irrevocable license to copy,
//   distribute, and modify this file as you see fit.



////////////////////////////////
// Notes on Lil' UEFI design choices

// 1. Renaming:
//    This header does not 100% follow the naming scheme given by the spec.
// For type names and functions the naming scheme has been left unchanged,
// the names of enum values and constants in the spec are not given with
// namespace prefixes - which we believe is a serious organizational flaw.
// In this header all such constants are prefixed with the name of the
// enum type or some other appropriate namespacing prefix.

// 2. Function Types:
//    The spec gives function pointer typedefs with specific names for every
// function in every function table. This leads to spreading out information,
// some confusing name disagreements and a lot more code. In this header the
// function types are named EFI_##name-of-function-table##_##name-of-function.
// Typical UEFI usage code never needs these types anyways. We also change
// the typedefs from function pointers, to plain function signatures.

// 3. X-List Headers:
//    Function tables are defined by seperate X-List header files. Take
// "lil_uefi_simple_text_output_protocol_funcs.h" for an example. The X macros
// are arranged with the NAME of the function in the first parameter, the
// RETURN type of the function in the second parameter, and the PARAMETER LIST
// in the third parameter. They are ordered to match the layout order of the
// function table.



////////////////////////////////
// EFI application setup example

#if 0
// Build & Link on Microsoft tool chain (batch instructions):
//
// cl   /FC /GS- /c <src>.c
// link /ENTRY:EfiMain /ALIGN:16 /SUBSYSTEM:EFI_APPLICATION /OUT:bootx64.efi <src>.obj
// if not exist EFI mkdir EFI
// if not exist EFI\BOOT mkdir EFI\BOOT
// copy bootx64.efi EFI\BOOT\bootx64.efi

#include "lil_uefi/lil_uefi.h"
EFI_UINTN
EfiMain(EFI_HANDLE handle, EFI_SYSTEM_TABLE *system_table){
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *con_out = system_table->ConOut;
    if (con_out != 0){
        for (;;){
            con_out->Reset(con_out, 1);
            con_out->ClearScreen(con_out);
            con_out->OutputString(con_out, L"Hello World!\r\n");
        }
    }
    return(0);
}
#endif



////////////////////////////////
// UEFI Definitions

#if !defined(LIL_UEFI_H)
#define LIL_UEFI_H


////////////////////////////////
// Context Cracking

// TODO: extend context cracking to more compilers & architectures

#if defined(__clang__)
# define LIL_UEFI_COMPILER_CLANG 1

# if defined(__amd64__)
#  define LIL_UEFI_ARCH_X64 1
// TODO(allen): verify this works on clang
# elif defined(__i386__)
#  define LIL_UEFI_ARCH_X86 1
// TODO(allen): verify this works on clang
# elif defined(__arm__)
#  define LIL_UEFI_ARCH_ARM 1
// TODO(allen): verify this works on clang
# elif defined(__aarch64__)
#  define LIL_UEFI_ARCH_ARM64 1
# else
#  error missing ARCH detection
# endif

#elif defined(_MSC_VER)
# define LIL_UEFI_COMPILER_CL 1

# if defined(_M_AMD64)
#  define LIL_UEFI_ARCH_X64 1
# elif defined(_M_I86)
#  define LIL_UEFI_ARCH_X86 1
# elif defined(_M_ARM)
#  define LIL_UEFI_ARCH_ARM 1
// TODO(allen): ARM64?
# else
#  error missing ARCH detection
# endif

#elif defined(__GNUC__)
# define LIL_UEFI_COMPILER_GCC 1

# if defined(__amd64__)
#  define LIL_UEFI_ARCH_X64 1
# elif defined(__i386__)
#  define LIL_UEFI_ARCH_X86 1
# elif defined(__arm__)
#  define LIL_UEFI_ARCH_ARM 1
# elif defined(__aarch64__)
#  define LIL_UEFI_ARCH_ARM64 1
# else
#  error missing ARCH detection
# endif

#else
# error no context cracking for this compiler
#endif

// Zero fill missing context macros
#if !defined(LIL_UEFI_COMPILER_CL)
# define LIL_UEFI_COMPILER_CL 0
#endif
#if !defined(LIL_UEFI_COMPILER_CLANG)
# define LIL_UEFI_COMPILER_CLANG 0
#endif
#if !defined(LIL_UEFI_COMPILER_GCC)
# define LIL_UEFI_COMPILER_GCC 0
#endif
#if !defined(LIL_UEFI_ARCH_X64)
# define LIL_UEFI_ARCH_X64 0
#endif
#if !defined(LIL_UEFI_ARCH_X86)
# define LIL_UEFI_ARCH_X86 0
#endif
#if !defined(LIL_UEFI_ARCH_ARM)
# define LIL_UEFI_ARCH_ARM 0
#endif
#if !defined(LIL_UEFI_ARCH_ARM64)
# define LIL_UEFI_ARCH_ARM64 0
#endif

////////////////////////////////
// Basic Types & Constants - Overridable

#if !defined(LIL_UEFI_DISABLE_DEFAULT_INTEGERS)

// SPEC: Table 5

typedef char      EFI_INT8;
typedef short     EFI_INT16;
typedef int       EFI_INT32;
typedef long long EFI_INT64;
typedef unsigned char      EFI_UINT8;
typedef unsigned short     EFI_UINT16;
typedef unsigned int       EFI_UINT32;
typedef unsigned long long EFI_UINT64;

#define EFI_INT8   EFI_INT8
#define EFI_INT16  EFI_INT16
#define EFI_INT32  EFI_INT32
#define EFI_INT64  EFI_INT64
#define EFI_UINT8  EFI_UINT8
#define EFI_UINT16 EFI_UINT16
#define EFI_UINT32 EFI_UINT32
#define EFI_UINT64 EFI_UINT64


#if LIL_UEFI_ARCH_X64 || LIL_UEFI_ARCH_ARM64
typedef EFI_INT64  EFI_INTN;
typedef EFI_UINT64 EFI_UINTN;
#else
typedef EFI_INT32  EFI_INTN;
typedef EFI_UINT32 EFI_UINTN;
#endif


#define EFI_INTN  EFI_INTN
#define EFI_UINTN EFI_UINTN

#endif


////////////////////////////////
// Overridables Check

#if !defined(EFI_INT8)
# error Missing EFI_INT8
#endif
#if !defined(EFI_INT16)
# error Missing EFI_INT16
#endif
#if !defined(EFI_INT32)
# error Missing EFI_INT32
#endif
#if !defined(EFI_INT64)
# error Missing EFI_INT64
#endif

#if !defined(EFI_UINT8)
# error Missing EFI_UINT8
#endif
#if !defined(EFI_UINT16)
# error Missing EFI_UINT16
#endif
#if !defined(EFI_UINT32)
# error Missing EFI_UINT32
#endif
#if !defined(EFI_UINT64)
# error Missing EFI_UINT64
#endif

#if !defined(EFI_INTN)
# error Missing EFI_INTN
#endif
#if !defined(EFI_UINTN)
# error Missing EFI_UINTN
#endif


#if !defined(LIL_UEFI_DISABLE_INTEGER_SIZE_CHECKS)

#define LIL_UEFI_GLUE(a,b) a##b
#define LIL_UEFI_STATIC_ASSERT(c) char LIL_UEFI_GLUE(efi_static_assert_, __LINE__)[(c)?(1):(-1)]

LIL_UEFI_STATIC_ASSERT(sizeof(EFI_INT8) == 1);
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_INT16) == 2);
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_INT32) == 4);
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_INT64) == 8);

LIL_UEFI_STATIC_ASSERT(sizeof(EFI_UINT8) == 1);
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_UINT16) == 2);
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_UINT32) == 4);
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_UINT64) == 8);

LIL_UEFI_STATIC_ASSERT(sizeof(EFI_INTN) == sizeof(void*));
LIL_UEFI_STATIC_ASSERT(sizeof(EFI_UINTN) == sizeof(void*));

#endif

////////////////////////////////
// Basic Types & Constants

// SPEC: Table 5

typedef EFI_UINT8  EFI_BOOLEAN;
typedef EFI_UINT8  EFI_CHAR8;
typedef EFI_UINT16 EFI_CHAR16;

typedef struct EFI_GUID{
    EFI_UINT32 data1;
    EFI_UINT16 data2;
    EFI_UINT16 data3;
    EFI_UINT8  data4[8];
} EFI_GUID;

#define EFI_GuidVal(a,b,c,x0,x1,x2,x3,x4,x5,x6,x7) {a,b,c,{x0,x1,x2,x3,x4,x5,x6,x7}}

typedef EFI_UINTN EFI_STATUS;
typedef void*     EFI_HANDLE;
typedef void*     EFI_EVENT;

typedef EFI_UINT64 EFI_LBA;
typedef EFI_UINTN  EFI_TPL;

typedef struct EFI_MAC_ADDRESS{
    EFI_UINT8 addr[32];
} EFI_MAC_ADDRESS;

typedef struct EFI_IPv4_ADDRESS{
    EFI_UINT8 addr[4];
} EFI_IPv4_ADDRESS;

typedef struct EFI_IPv6_ADDRESS{
    EFI_UINT8 addr[16];
} EFI_IPv6_ADDRESS;

typedef struct EFI_IP_ADDRESS{
    EFI_UINT8 addr[16];
} EFI_IP_ADDRESS;

// SPEC: Table 6

#define EFIAPI

////////////////////////////////
// System Tables

// SPEC: Section 4.2
typedef struct EFI_TABLE_HEADER{
    EFI_UINT64 Signature;
    EFI_UINT32 Revision;
    EFI_UINT32 HeaderSize;
    EFI_UINT32 CRC32;
    EFI_UINT32 Reserved;
} EFI_TABLE_HEADER;

// SPEC: Section 4.3
typedef struct EFI_SYSTEM_TABLE{
    EFI_TABLE_HEADER   Hdr;
    EFI_UINT16*        FirmwareVendor;
    EFI_UINT32         FirmwareRevision;
    
    EFI_HANDLE                              ConsoleInHandle;
    struct EFI_SIMPLE_TEXT_INPUT_PROTOCOL*  ConIn;
    EFI_HANDLE                              ConsoleOutHandle;
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL* ConOut;
    EFI_HANDLE                              StandardErrorHandle;
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL* StdErr;
    
    struct EFI_RUNTIME_SERVICES*    RuntimeServices;
    struct EFI_BOOT_SERVICES*       BootServices;
    EFI_UINTN                       NumberOfTableEntries;
    struct EFI_CONFIGURATION_TABLE* ConfigurationTable;
} EFI_SYSTEM_TABLE;

// SPEC: Section 4.6
typedef struct EFI_CONFIGURATION_TABLE{
    EFI_GUID VendorGuid;
    void *VendorTable;
} EFI_CONFIGURATION_TABLE;

////////////////////////////////
// Boot Services

// SPEC: Section 7.1 "CreateEvent"
#define EFI_EVT_TIMER         0x80000000
#define EFI_EVT_RUNTIME       0x40000000
#define EFI_EVT_NOTIFY_WAIT   0x00000100
#define EFI_EVT_NOTIFY_SIGNAL 0x00000200
#define EFI_EVT_SIGNAL_EXIT_BOOT_SERVICES     0x00000201
#define EFI_EVT_SIGNAL_VIRTUAL_ADDRESS_CHANGE 0x60000202

typedef void EFI_EVENT_NOTIFY_FUNCITON(EFI_EVENT event, void *context);

// SPEC: Section 7.1 "RaiseTPL"
#define EFI_TPL_APPLICATION  4
#define EFI_TPL_CALLBACK     8
#define EFI_TPL_NOTIFY       16
#define EFI_TPL_HIGH_LEVEL   31

// SPEC: Section 7.1 "SetTimer"

typedef EFI_UINT32 EFI_TIMER_DELAY;
enum{
    EFI_TIMER_DELAY_Cancel,
    EFI_TIMER_DELAY_Periodic,
    EFI_TIMER_DELAY_Relative
};

// SPEC: Section 7.2 "AllocatePages"
typedef EFI_UINT32 EFI_ALLOCATE_TYPE;
enum{
    EFI_ALLOCATE_TYPE_AllocateAnyPages,
    EFI_ALLOCATE_TYPE_AllocateMaxAddress,
    EFI_ALLOCATE_TYPE_AllocateAddress,
    EFI_ALLOCATE_TYPE_MaxAllocateType
};

typedef EFI_UINT32 EFI_MEMORY_TYPE;
enum{
    EFI_MEMORY_TYPE_EfiReservedMemoryType,
    EFI_MEMORY_TYPE_EfiLoaderCode,
    EFI_MEMORY_TYPE_EfiLoaderData,
    EFI_MEMORY_TYPE_EfiBootServicesCode,
    EFI_MEMORY_TYPE_EfiBootServicesData,
    EFI_MEMORY_TYPE_EfiRuntimeServicesCode,
    EFI_MEMORY_TYPE_EfiRuntimeServicesData,
    EFI_MEMORY_TYPE_EfiConventionalMemory,
    EFI_MEMORY_TYPE_EfiUnusableMemory,
    EFI_MEMORY_TYPE_EfiACPIReclaimMemory,
    EFI_MEMORY_TYPE_EfiACPIMemoryNVS,
    EFI_MEMORY_TYPE_EfiMemoryMappedIO,
    EFI_MEMORY_TYPE_EfiMemoryMappedIOPortSpace,
    EFI_MEMORY_TYPE_EfiPalCode,
    EFI_MEMORY_TYPE_EfiPersistentMemory,
    EFI_MEMORY_TYPE_EfiMaxMemoryType
};

typedef EFI_UINT64 EFI_PHYSICAL_ADDRESS;

// SPEC: Section 7.2 "GetMemoryMap"
typedef EFI_UINT64 EFI_VIRTUAL_ADDRESS;

typedef struct EFI_MEMORY_DESCRIPTOR{
    EFI_UINT32 Type;
    EFI_PHYSICAL_ADDRESS PhysicalStart;
    EFI_VIRTUAL_ADDRESS VirtualStart;
    EFI_UINT64 NumberOfPages;
    EFI_UINT64 Attribute;
} EFI_MEMORY_DESCRIPTOR;

#define EFI_MEMORY_UC            0x0000000000000001
#define EFI_MEMORY_WC            0x0000000000000002
#define EFI_MEMORY_WT            0x0000000000000004
#define EFI_MEMORY_WB            0x0000000000000008
#define EFI_MEMORY_UCE           0x0000000000000010
#define EFI_MEMORY_WP            0x0000000000001000
#define EFI_MEMORY_RP            0x0000000000002000
#define EFI_MEMORY_XP            0x0000000000004000
#define EFI_MEMORY_NV            0x0000000000008000
#define EFI_MEMORY_MORE_RELIABLE 0x0000000000010000
#define EFI_MEMORY_RO            0x0000000000020000
#define EFI_MEMORY_RUNTIME       0x8000000000000000

// SPEC: Section 7.3 "InstallProtocolInterface"
typedef EFI_UINT32 EFI_INTERFACE_TYPE;
enum{
    EFI_INTERFACE_TYPE_NATIVE_INTERFACE
};

// SPEC: Section 7.3 "LocateHandle"
typedef EFI_UINT32 EFI_LOCATE_SEARCH_TYPE;
enum{
    EFI_LOCATE_SEARCH_TYPE_AllHandles,
    EFI_LOCATE_SEARCH_TYPE_ByRegisterNotify,
    EFI_LOCATE_SEARCH_TYPE_ByProtocol
};

// SPEC: Section 7.3 "OpenProtocol"
#define EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL  0x00000001
#define EFI_OPEN_PROTOCOL_GET_PROTOCOL        0x00000002
#define EFI_OPEN_PROTOCOL_TEST_PROTOCOL       0x00000004
#define EFI_OPEN_PROTOCOL_BY_CHILD_CONTROLLER 0x00000008
#define EFI_OPEN_PROTOCOL_BY_DRIVER           0x00000010
#define EFI_OPEN_PROTOCOL_EXCLUSIVE           0x00000020

// SPEC: Section 7.3 "OpenProtocolInformation"
typedef struct EFI_OPEN_PROTOCOL_INFORMATION_ENTRY{
    EFI_HANDLE AgentHandle;
    EFI_HANDLE ControllerHandle;
    EFI_UINT32 Attributes;
    EFI_UINT32 OpenCount;
} EFI_OPEN_PROTOCOL_INFORMATION_ENTRY;

// Boot Services function table
#define X(N, R, P) typedef R EFIAPI EFI_BootServices_##N P;
#include "lil_uefi_boot_services_funcs.h"
#undef X

typedef struct EFI_BOOT_SERVICES{
    EFI_TABLE_HEADER hdr;
    
#define X(N, R, P) EFI_BootServices_##N *N;
#include "lil_uefi_boot_services_funcs.h"
#undef X
} EFI_BOOT_SERVICES;

////////////////////////////////
// Runtime Services

// SPEC: Section 8.3 "GetTime"
typedef struct EFI_TIME{
    EFI_UINT16 Year;
    EFI_UINT8  Month;
    EFI_UINT8  Day;
    EFI_UINT8  Hour;
    EFI_UINT8  Minute;
    EFI_UINT8  Second;
    EFI_UINT8  Pad1;
    EFI_UINT32 Nanosecond;
    EFI_INT16  TimeZone;
    EFI_UINT8  Daylight;
    EFI_UINT8  Pad2;
} EFI_TIME;

typedef struct EFI_TIME_CAPABILITIES{
    EFI_UINT32  Resolution;
    EFI_UINT32  Accuracy;
    EFI_BOOLEAN SetsToZero;
} EFI_TIME_CAPABILITIES;

// SPEC: Section 8.5.1 "ResetSystem"
typedef EFI_UINT32 EFI_RESET_TYPE;
enum{
    EFI_RESET_TYPE_Cold,
    EFI_RESET_TYPE_Warm,
    EFI_RESET_TYPE_Shutdown,
    EFI_RESET_TYPE_PlatformSpecific
};

// SPEC: Section 8.5.3 "UpdateCapsule"
typedef struct EFI_CAPSULE_BLOCK_DESCRIPTOR{
    EFI_UINT64 Length;
    union{
        EFI_PHYSICAL_ADDRESS DataBlock;
        EFI_PHYSICAL_ADDRESS ContinuationPointer;
    } Union;
} EFI_CAPSULE_BLOCK_DESCRIPTOR;

typedef struct EFI_CAPSULE_HEADER{
    EFI_GUID   CapsuleGuid;
    EFI_UINT32 HeaderSize;
    EFI_UINT32 Flags;
    EFI_UINT32 CapsuleImageSize;
} EFI_CAPSULE_HEADER;

#define EFI_CAPSULE_FLAGS_PERSIST_ACROSS_RESET  0x00010000
#define EFI_CAPSULE_FLAGS_POPULATE_SYSTEM_TABLE 0x00020000
#define EFI_CAPSULE_FLAGS_INITIATE_RESET        0x00040000

// Runtime Services function table
#define X(N, R, P) typedef R EFIAPI EFI_RuntimeServices_##N P;
#include "lil_uefi_runtime_services_funcs.h"
#undef X

typedef struct EFI_RUNTIME_SERVICES{
    EFI_TABLE_HEADER hdr;
    
#define X(N, R, P) EFI_RuntimeServices_##N *N;
#include "lil_uefi_runtime_services_funcs.h"
#undef X
} EFI_RUNTIME_SERVICES;

////////////////////////////////
// Protocol: Device Path Protocol

// SPEC: Section 10.2
#define EFI_DEVICE_PATH_PROTOCOL_GUID \
EFI_GuidVal(0x9576e91, 0x6d3f, 0x11d2, 0x8e, 0x39, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b)

typedef struct EFI_DEVICE_PATH_PROTOCOL{
    EFI_UINT8 Type;
    EFI_UINT8 SubType;
    EFI_UINT8 Length[2];
} EFI_DEVICE_PATH_PROTOCOL;

// SPEC: Section 10.3.1
#define EFI_DEVICE_PATH_TYPE_Hardware              0x01
#define EFI_DEVICE_PATH_TYPE_ACPI                  0x02
#define EFI_DEVICE_PATH_TYPE_Messaging             0x03
#define EFI_DEVICE_PATH_TYPE_Media                 0x04
#define EFI_DEVICE_PATH_TYPE_BIOSBootSpecification 0x05
#define EFI_DEVICE_PATH_TYPE_EndOfHardware         0x7F

#define EFI_DEVICE_PATH_SUB_TYPE_EndEntireDevicePath 0xFF
#define EFI_DEVICE_PATH_SUB_TYPE_EndThisInstance     0x01

// SPEC: Section 10.3.2
#define EFI_DEVICE_PATH_SUB_TYPE_PCI           0x01
#define EFI_DEVICE_PATH_SUB_TYPE_PCCARD        0x02
#define EFI_DEVICE_PATH_SUB_TYPE_MEMORY_MAPPED 0x03
#define EFI_DEVICE_PATH_SUB_TYPE_VENDOR        0x04
#define EFI_DEVICE_PATH_SUB_TYPE_CONTROLLER    0x05
#define EFI_DEVICE_PATH_SUB_TYPE_BMC           0x06

// TODO: extra device path fields for each sub type

// TODO SPEC: Section 10.3.3
// TODO SPEC: Section 10.3.4
// TODO SPEC: Section 10.3.5
// TODO SPEC: Section 10.3.6
// TODO SPEC: Section 10.3.7

// TODO SPEC: Section 10.5


////////////////////////////////
// Protocol: Console Support

// SPEC: Table 100; Unicode Control Characters
#define EFI_CHAR_Backspace      0x0008
#define EFI_CHAR_Tab            0x0009
#define EFI_CHAR_LineFeed       0x000A
#define EFI_CHAR_CarriageReturn 0x000D

// SPEC: Table 101; Scan Codes for Simple Text Input Protocol
#define EFI_SCAN_Null       0x0000
#define EFI_SCAN_Up         0x0001
#define EFI_SCAN_Down       0x0002
#define EFI_SCAN_Right      0x0003
#define EFI_SCAN_Left       0x0004
#define EFI_SCAN_Home       0x0005
#define EFI_SCAN_End        0x0006
#define EFI_SCAN_Insert     0x0007
#define EFI_SCAN_Delete     0x0008
#define EFI_SCAN_PageUp     0x0009
#define EFI_SCAN_PageDown   0x000A
#define EFI_SCAN_F1         0x000B
#define EFI_SCAN_F2         0x000C
#define EFI_SCAN_F3         0x000D
#define EFI_SCAN_F4         0x000E
#define EFI_SCAN_F5         0x000F
#define EFI_SCAN_F6         0x0010
#define EFI_SCAN_F7         0x0011
#define EFI_SCAN_F8         0x0012
#define EFI_SCAN_F9         0x0013
#define EFI_SCAN_F10        0x0014
#define EFI_SCAN_Esc        0x0017

// TODO: Table 102

////////////////////////////////
// Protocol: Simple Text Input Protocol

// SPEC: Section 12.3
#define EFI_SIMPLE_TEXT_INPUT_PROTOCOL_GUID \
EFI_GuidVal(0x387477c1, 0x69c7, 0x11d2, 0x8e, 0x39, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b)

// SPEC: Section 12.3 "ReadKeyStroke"
typedef struct EFI_INPUT_KEY{
    EFI_UINT16 ScanCode;
    EFI_UINT16 UnicodeChar;
} EFI_INPUT_KEY;

// Simple Text Input Protocol function table
#define X(N, R, P) typedef R EFIAPI EFI_SimpleTextInputProtocol_##N P;
#include "lil_uefi_simple_text_input_protocol_funcs.h"
#undef X

typedef struct EFI_SIMPLE_TEXT_INPUT_PROTOCOL{
#define X(N, R, P) EFI_SimpleTextInputProtocol_##N *N;
#include "lil_uefi_simple_text_input_protocol_funcs.h"
#undef X
    
    EFI_EVENT WaitForKey;
} EFI_SIMPLE_TEXT_INPUT_PROTOCOL;

////////////////////////////////
// Protocol: Simple Text Input Ex Protocol

// This protocol comes in the spec before the non "ex" version, but it has types
// that depend on the non "ex" version, so we swap the order.

// TODO: SPEC: Section 12.2

////////////////////////////////
// Protocol: Simple Text Output Protocol

// SPEC: Section 12.4
#define EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_GUID \
EFI_GuidVal(0x387477c2, 0x69c7, 0x11d2, 0x8e, 0x39, 0x0, 0xa0, 0xc9, 0x69, 0x72, 0x3b)

typedef struct EFI_SIMPLE_TEXT_OUTPUT_MODE{
    EFI_INT32 MaxMode;
    EFI_INT32 Mode;
    EFI_INT32 Attribute;
    EFI_INT32 CursorColumn;
    EFI_INT32 CursorRow;
    EFI_BOOLEAN CursorVisible;
} EFI_SIMPLE_TEXT_OUTPUT_MODE;

// SPEC: Section 12.4 "OutputString"
#define EFI_BOXDRAW_HORIZONTAL                0x2500
#define EFI_BOXDRAW_VERTICAL                  0x2502
#define EFI_BOXDRAW_DOWN_RIGHT                 0x250c
#define EFI_BOXDRAW_DOWN_LEFT                  0x2510
#define EFI_BOXDRAW_UP_RIGHT                   0x2514
#define EFI_BOXDRAW_UP_LEFT                    0x2518
#define EFI_BOXDRAW_VERTICAL_RIGHT             0x251c
#define EFI_BOXDRAW_VERTICAL_LEFT              0x2524
#define EFI_BOXDRAW_DOWN_HORIZONTAL            0x252c
#define EFI_BOXDRAW_UP_HORIZONTAL              0x2534
#define EFI_BOXDRAW_VERTICAL_HORIZONTAL        0x253c
#define EFI_BOXDRAW_DOUBLE_HORIZONTAL          0x2550
#define EFI_BOXDRAW_DOUBLE_VERTICAL            0x2551
#define EFI_BOXDRAW_DOWN_RIGHT_DOUBLE           0x2552
#define EFI_BOXDRAW_DOWN_DOUBLE_RIGHT           0x2553
#define EFI_BOXDRAW_DOUBLE_DOWN_RIGHT           0x2554
#define EFI_BOXDRAW_DOWN_LEFT_DOUBLE            0x2555
#define EFI_BOXDRAW_DOWN_DOUBLE_LEFT            0x2556
#define EFI_BOXDRAW_DOUBLE_DOWN_LEFT            0x2557
#define EFI_BOXDRAW_UP_RIGHT_DOUBLE             0x2558
#define EFI_BOXDRAW_UP_DOUBLE_RIGHT             0x2559
#define EFI_BOXDRAW_DOUBLE_UP_RIGHT             0x255a
#define EFI_BOXDRAW_UP_LEFT_DOUBLE              0x255b
#define EFI_BOXDRAW_UP_DOUBLE_LEFT              0x255c
#define EFI_BOXDRAW_DOUBLE_UP_LEFT              0x255d
#define EFI_BOXDRAW_VERTICAL_RIGHT_DOUBLE       0x255e
#define EFI_BOXDRAW_VERTICAL_DOUBLE_RIGHT       0x255f
#define EFI_BOXDRAW_DOUBLE_VERTICAL_RIGHT       0x2560
#define EFI_BOXDRAW_VERTICAL_LEFT_DOUBLE        0x2561
#define EFI_BOXDRAW_VERTICAL_DOUBLE_LEFT        0x2562
#define EFI_BOXDRAW_DOUBLE_VERTICAL_LEFT        0x2563
#define EFI_BOXDRAW_DOWN_HORIZONTAL_DOUBLE      0x2564
#define EFI_BOXDRAW_DOWN_DOUBLE_HORIZONTAL      0x2565
#define EFI_BOXDRAW_DOUBLE_DOWN_HORIZONTAL      0x2566
#define EFI_BOXDRAW_UP_HORIZONTAL_DOUBLE        0x2567
#define EFI_BOXDRAW_UP_DOUBLE_HORIZONTAL        0x2568
#define EFI_BOXDRAW_DOUBLE_UP_HORIZONTAL        0x2569
#define EFI_BOXDRAW_VERTICAL_HORIZONTAL_DOUBLE  0x256a
#define EFI_BOXDRAW_VERTICAL_DOUBLE_HORIZONTAL  0x256b
#define EFI_BOXDRAW_DOUBLE_VERTICAL_HORIZONTAL  0x256c

#define EFI_BLOCKELEMENT_FULL_BLOCK   0x2588
#define EFI_BLOCKELEMENT_LIGHT_SHADE  0x2591

#define EFI_GEOMETRICSHAPE_UP_TRIANGLE    0x25b2
#define EFI_GEOMETRICSHAPE_RIGHT_TRIANGLE 0x25ba
#define EFI_GEOMETRICSHAPE_DOWN_TRIANGLE  0x25bc
#define EFI_GEOMETRICSHAPE_LEFT_TRIANGLE  0x25c4

#define EFI_ARROW_LEFT  0x2190
#define EFI_ARROW_UP    0x2191
#define EFI_ARROW_RIGHT 0x2192
#define EFI_ARROW_DOWN  0x2193

// SPEC: Section 12.4 "SetAttribute"
#define EFI_BLACK  0x00
#define EFI_BLUE   0x01
#define EFI_GREEN  0x02
#define EFI_RED    0x04
#define EFI_BRIGHT 0x08
#define EFI_CYAN      (EFI_BLUE|EFI_GREEN)
#define EFI_MAGENTA   (EFI_BLUE|EFI_RED)
#define EFI_BROWN     (EFI_GREEN|EFI_RED)
#define EFI_LIGHTGRAY (EFI_BLUE|EFI_GREEN|EFI_RED)
#define EFI_DARKGRAY     (EFI_BRIGHT|EFI_BLACK)
#define EFI_LIGHTBLUE    (EFI_BRIGHT|EFI_BLUE)
#define EFI_LIGHTGREEN   (EFI_BRIGHT|EFI_GREEN)
#define EFI_LIGHTRED     (EFI_BRIGHT|EFI_RED)
#define EFI_LIGHTCYAN    (EFI_BRIGHT|EFI_CYAN)
#define EFI_LIGHTMAGENTA (EFI_BRIGHT|EFI_MAGENTA)
#define EFI_YELLOW       (EFI_BRIGHT|EFI_BROWN)
#define EFI_WHITE        (EFI_BRIGHT|EFI_LIGHTGRAY)

#define EFI_BACKGROUND_BLACK     (EFI_BLACK << 4)
#define EFI_BACKGROUND_BLUE      (EFI_BLUE << 4)
#define EFI_BACKGROUND_GREEN     (EFI_GREEN << 4)
#define EFI_BACKGROUND_CYAN      (EFI_CYAN << 4)
#define EFI_BACKGROUND_RED       (EFI_RED << 4)
#define EFI_BACKGROUND_MAGENTA   (EFI_MAGENTA << 4)
#define EFI_BACKGROUND_BROWN     (EFI_BROWN << 4)
#define EFI_BACKGROUND_LIGHTGRAY (EFI_LIGHTGRAY << 4)

// Simple Text Output Protocol function table
#define X(N, R, P) typedef R EFIAPI EFI_SimpleTextOutputProtocol_##N P;
#include "lil_uefi_simple_text_output_protocol_funcs.h"
#undef X

typedef struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL{
#define X(N, R, P) EFI_SimpleTextOutputProtocol_##N *N;
#include "lil_uefi_simple_text_output_protocol_funcs.h"
#undef X
    
    EFI_SIMPLE_TEXT_OUTPUT_MODE *Mode;
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

////////////////////////////////
// Protocol: Simple Pointer Protocol

// SPEC: Section 12.5
// "pointer" here means "mouse"

#define EFI_SIMPLE_POINTER_PROTOCOL_GUID \
EFI_GuidVal(0x31878c87, 0xb75, 0x11d5, 0x9a,0x4f,0x00,0x90,0x27,0x3f,0xc1,0x4d)

typedef struct EFI_SIMPLE_POINTER_MODE{
    EFI_UINT64 ResolutionX;
    EFI_UINT64 ResolutionY;
    EFI_UINT64 ResolutionZ;
    EFI_BOOLEAN LeftButton;
    EFI_BOOLEAN RightButton;
} EFI_SIMPLE_POINTER_MODE;

typedef struct EFI_SIMPLE_POINTER_STATE{
    EFI_INT32 RelativeMovementX;
    EFI_INT32 RelativeMovementY;
    EFI_INT32 RelativeMovementZ;
    EFI_BOOLEAN LeftButton;
    EFI_BOOLEAN RightButton;
} EFI_SIMPLE_POINTER_STATE;

#define X(N, R, P) typedef R EFIAPI EFI_SimplePointerProtocol_##N P;
#include "lil_uefi_simple_pointer_protocol_funcs.h"
#undef X

typedef struct EFI_SIMPLE_POINTER_PROTOCOL{
#define X(N, R, P) EFI_SimplePointerProtocol_##N *N;
#include "lil_uefi_simple_pointer_protocol_funcs.h"
#undef X
    
    EFI_EVENT WaitForInput;
    EFI_SIMPLE_POINTER_MODE *Mode;
} EFI_SIMPLE_POINTER_PROTOCOL;

////////////////////////////////
// Simple Pointer Device Paths

// TODO: SPEC: Section 12.6

////////////////////////////////
// Protocol: Absolute Pointer Protocol

// "pointer" here means "touch screens"

// TODO: SPEC: Section 12.7

////////////////////////////////
// Protocol: Serial I/O Protocol

// TODO: SPEC: Section 12.8

////////////////////////////////
// Protocol: Graphics Output Protocol

// SPEC: Section 12.9
#define EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID \
EFI_GuidVal(0x9042a9de, 0x23dc, 0x4a38, 0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a)

typedef struct EFI_PIXEL_BITMASK{
    EFI_UINT32 RedMask;
    EFI_UINT32 GreenMask;
    EFI_UINT32 BlueMask;
    EFI_UINT32 ReservedMask;
} EFI_PIXEL_BITMASK;

typedef EFI_UINT32 EFI_GRAPHICS_PIXEL_FORMAT;
enum{
    EFI_GRAPHICS_PIXEL_FORMAT_PixelRedGreenBlueReserved8BitPerColor,
    EFI_GRAPHICS_PIXEL_FORMAT_PixelBlueGreenRedReserved8BitPerColor,
    EFI_GRAPHICS_PIXEL_FORMAT_PixelBitMask,
    EFI_GRAPHICS_PIXEL_FORMAT_PixelBltOnly,
    EFI_GRAPHICS_PIXEL_FORMAT_PixelFormatMAX
};

typedef struct EFI_GRAPHICS_OUTPUT_MODE_INFORMATION{
    EFI_UINT32 Version;
    EFI_UINT32 HorizontalResolution;
    EFI_UINT32 VerticalResolution;
    EFI_GRAPHICS_PIXEL_FORMAT PixelFormat;
    EFI_PIXEL_BITMASK PixelInformation;
    EFI_UINT32 PixelsPerScanLine;
} EFI_GRAPHICS_OUTPUT_MODE_INFORMATION;

typedef struct EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE{
    EFI_UINT32 max_mode;
    EFI_UINT32 mode;
    EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info;
    EFI_UINTN size_of_info;
    EFI_PHYSICAL_ADDRESS frame_buffer_base;
    EFI_UINTN frame_buffer_size;
} EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE;

// SPEC: Section 12.9 "Blt"
typedef struct EFI_GRAPHICS_OUTPUT_BLT_PIXEL{
    EFI_UINT8 Blue;
    EFI_UINT8 Green;
    EFI_UINT8 Red;
    EFI_UINT8 Reserved;
} EFI_GRAPHICS_OUTPUT_BLT_PIXEL;

typedef EFI_UINT32 EFI_GRAPHICS_OUTPUT_BLT_OPERATION;
enum{
    EFI_GRAPHICS_OUTPUT_BLT_OPERATION_VideoFill,
    EFI_GRAPHICS_OUTPUT_BLT_OPERATION_VideoToBuffer,
    EFI_GRAPHICS_OUTPUT_BLT_OPERATION_BufferToVideo,
    EFI_GRAPHICS_OUTPUT_BLT_OPERATION_VideoToVideo,
    EFI_GRAPHICS_OUTPUT_BLT_OPERATION_Max
};

// Graphics Output Protocol function table
#define X(N, R, P) typedef R EFIAPI EFI_GraphicsOutputProtocol_##N P;
#include "lil_uefi_graphics_output_protocol_funcs.h"
#undef X

typedef struct EFI_GRAPHICS_OUTPUT_PROTOCOL{
#define X(N, R, P) EFI_GraphicsOutputProtocol_##N *N;
#include "lil_uefi_graphics_output_protocol_funcs.h"
#undef X
    
    EFI_GRAPHICS_OUTPUT_PROTOCOL_MODE *Mode;
} EFI_GRAPHICS_OUTPUT_PROTOCOL;

////////////////////////////////
// Media Access

// TODO: SPEC: Section 13

////////////////////////////////
// PCI Bus Support

// TODO: SPEC: Section 14

////////////////////////////////
// SCSI Driver Models & Bus Support

// TODO: SPEC: Section 15

////////////////////////////////
// iSCSI Boot

// TODO: SPEC: Section 16

////////////////////////////////
// USB Host Controller Support

// SPEC: Section 17.1.1

typedef enum EFI_USB_HC_STATE{
    EFI_USB_HC_STATE_UsbHcStateHalt,
    EFI_USB_HC_STATE_UsbHcStateOperational,
    EFI_USB_HC_STATE_UsbHcStateSuspend,
    EFI_USB_HC_STATE_UsbHcStateMaximum
} EFI_USB_HC_STATE;

typedef enum EFI_USB_DATA_DIRECTION{
    EfiUsbDataIn,
    EfiUsbDataOut,
    EfiUsbNoData
} EFI_USB_DATA_DIRECTION;

#define EFI_USB_NOERROR 0x0000
#define EFI_USB_ERR_NOTEXECUTE 0x0001
#define EFI_USB_ERR_STALL 0x0002
#define EFI_USB_ERR_BUFFER 0x0004
#define EFI_USB_ERR_BABBLE 0x0008
#define EFI_USB_ERR_NAK 0x0010
#define EFI_USB_ERR_CRC 0x0020
#define EFI_USB_ERR_TIMEOUT 0x0040
#define EFI_USB_ERR_BITSTUFF 0x0080
#define EFI_USB_ERR_SYSTEM 0x0100

typedef struct EFI_USB_DEVICE_REQUEST{
    EFI_UINT8 RequestType;
    EFI_UINT8 Request;
    EFI_UINT16 Value;
    EFI_UINT16 Index;
    EFI_UINT16 Length;
} EFI_USB_DEVICE_REQUEST;

#define EFI_USB2_HC_PROTOCOL_GUID \
EFI_GuidVal(0x3e745226,0x9818,0x45b6,0xa2,0xac,0xd7,0xcd,0x0e,0x8b,0xa2,0xbc)

#define EFI_USB_SPEED_FULL 0x0000 // Full speed USB device; data bandwidth is up to 12 Mb/s. Supported by USB 1.1 OHCI and UHCI host controllers
#define EFI_USB_SPEED_LOW 0x0001 // Low speed USB device; data bandwidth is up to 1.5 Mb/s. Supported by USB 1.1 OHCI and UHCI host controllers
#define EFI_USB_SPEED_HIGH 0x0002 // High speed USB device; data bandwidth is up to 480 Mb/s. Supported by USB 2.0 EHCI host controllers
#define EFI_USB_SPEED_SUPER 0x0003 // Super speed USB device; data bandwidth is up to 4.8Gbs. Supported by USB 3.0 XHCI host controllers.

// If this bit is set, a global reset signal will be sent to the USB bus. This resets
// all of the USB bus logic, including the USB host controller hardware and all
// the devices attached on the USB bus
#define EFI_USB_HC_RESET_GLOBAL 0x0001

// If this bit is set, the USB host controller hardware will be reset. No reset
// signal will be sent to the USB bus
#define EFI_USB_HC_RESET_HOST_CONTROLLER 0x0002

// If this bit is set, then a global reset signal will be sent to the USB bus. This
// resets all of the USB bus logic, including the USB host controller and all of
// the devices attached on the USB bus. If this is an XHCI or EHCI controller and
// the debug port has been configured, then this will still reset the host
// controller
#define EFI_USB_HC_RESET_GLOBAL_WITH_DEBUG 0x0004

// If this bit is set, the USB host controller hardware will be reset. If this is an
// XHCI or EHCI controller and the debug port has been configured, then this
// will still reset the host controller.
#define EFI_USB_HC_RESET_HOST_WITH_DEBUG 0x0008

#define EFI_USB_MAX_BULK_BUFFER_NUM 10
#define EFI_USB_MAX_ISO_BUFFER_NUM 7
#define EFI_USB_MAX_ISO_BUFFER_NUM1 2

typedef EFI_STATUS EFIAPI EFI_ASYNC_USB_TRANSFER_CALLBACK(void *data, EFI_UINTN data_length, void *context, EFI_UINT32 status);

typedef struct EFI_USB2_HC_TRANSACTION_TRANSLATOR{
    EFI_UINT8 TranslatorHubAddress;
    EFI_UINT8 TranslatorPortNumber;
} EFI_USB2_HC_TRANSACTION_TRANSLATOR;

typedef struct EFI_USB_PORT_STATUS{
    EFI_UINT16 PortStatus;
    EFI_UINT16 PortChangeStatus;
} EFI_USB_PORT_STATUS;

#define USB_PORT_STAT_CONNECTION 0x0001
#define USB_PORT_STAT_ENABLE 0x0002
#define USB_PORT_STAT_SUSPEND 0x0004
#define USB_PORT_STAT_OVERCURRENT 0x0008
#define USB_PORT_STAT_RESET 0x0010
#define USB_PORT_STAT_POWER 0x0100
#define USB_PORT_STAT_LOW_SPEED 0x0200
#define USB_PORT_STAT_HIGH_SPEED 0x0400
#define USB_PORT_STAT_SUPER_SPEED 0x0800
#define USB_PORT_STAT_OWNER 0x2000

#define USB_PORT_STAT_C_CONNECTION 0x0001
#define USB_PORT_STAT_C_ENABLE 0x0002
#define USB_PORT_STAT_C_SUSPEND 0x0004
#define USB_PORT_STAT_C_OVERCURRENT 0x0008
#define USB_PORT_STAT_C_RESET 0x0010

typedef enum EFI_USB_PORT_FEATURE{
    EFI_USB_PORT_FEATURE_UsbPortEnable = 1,
    EFI_USB_PORT_FEATURE_UsbPortSuspend = 2,
    EFI_USB_PORT_FEATURE_UsbPortReset = 4,
    EFI_USB_PORT_FEATURE_UsbPortPower = 8,
    EFI_USB_PORT_FEATURE_UsbPortOwner = 13,
    EFI_USB_PORT_FEATURE_UsbPortConnectChange = 16,
    EFI_USB_PORT_FEATURE_UsbPortEnableChange = 17,
    EFI_USB_PORT_FEATURE_UsbPortSuspendChange = 18,
    EFI_USB_PORT_FEATURE_UsbPortOverCurrentChange = 19,
    EFI_USB_PORT_FEATURE_UsbPortResetChange = 20
} EFI_USB_PORT_FEATURE;

// Function Typedefs
#define X(N, R, P) typedef R EFIAPI EFI_USB2HCProtocol_##N P;
#include "lil_uefi_usb2_hc_protocol_funcs.h"
#undef X

// Protocol
typedef struct EFI_USB2_HC_PROTOCOL{
#define X(N, R, P) EFI_USB2HCProtocol_##N *N;
#include "lil_uefi_usb2_hc_protocol_funcs.h"
#undef X
    
    EFI_UINT16 MajorRevision;
    EFI_UINT16 MinorRevision;
}EFI_USB2_HC_PROTOCOL;

////////////////////////////////
// Debugger Support

// TODO: SPEC: Section 18

////////////////////////////////
// Compression Algorithm Specification

// TODO: SPEC: Section 19

////////////////////////////////
// ACPI Protocols

// TODO: SPEC: Section 20

////////////////////////////////
// String Services

// TODO: SPEC: Section 21

////////////////////////////////
// EFI Byte Code Virtual Machine

// TODO: SPEC: Section 22

////////////////////////////////
// Firmware Update And Reporting

// TODO: SPEC: Section 23

////////////////////////////////
// Network Protocols - SNP, PXE, BIS, and HTTP Boot

// TODO: SPEC: Section 24

////////////////////////////////
// Network Protocols - Managed Network

// TODO: SPEC: Section 25

////////////////////////////////
// Network Protocols - VLAN, EAP, Wi-Fi and Supplicant

// TODO: SPEC: Section 26

////////////////////////////////
// Network Protocols - Bluetooth

// TODO: SPEC: Section 27

////////////////////////////////
// Network Protocols - TCP, IP, IPsec, FTP, TLS, and Configurations

// TODO: SPEC: Section 28

////////////////////////////////
// Network Protocols - ARP, DHCP, DNS, HTTP, and REST

// TODO: SPEC: Section 29

////////////////////////////////
// Network Protocols - UDP and MTFTP

// TODO: SPEC: Section 30

////////////////////////////////
// Secure Boot and Driver Signing

// TODO: SPEC: Section 31

////////////////////////////////
// Human Interface Infrastructure Overview

// TODO: SPEC: Section 32

////////////////////////////////
// HII Protocols

// TODO: SPEC: Section 33

////////////////////////////////
// HII Configuration Processing and Browser Protocol

// TODO: SPEC: Section 34

////////////////////////////////
// User Identification

// TODO: SPEC: Section 35

////////////////////////////////
// Secure Technologies

// TODO: SPEC: Section 36

////////////////////////////////
// Miscellaneous Protocols

// TODO: SPEC: Section 37

#endif // LIL_UEFI_H
