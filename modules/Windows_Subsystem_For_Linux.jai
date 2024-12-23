
#assert OS == .WINDOWS;

WslIsDistributionRegistered :: (distributionName: LPCWSTR) -> BOOL #foreign Wslapi;
WslRegisterDistribution     :: (distributionName: LPCWSTR, tarGzFilename: LPCSTR) -> HRESULT #foreign Wslapi;
WslUnregisterDistribution   :: (distributionName: LPCWSTR) -> HRESULT #foreign Wslapi;

WSL_DISTRIBUTION_FLAGS :: enum_flags {
    NONE                  :: 0x0;
    ENABLE_INTEROP        :: 0x1;
    APPEND_NT_PATH        :: 0x2;
    ENABLE_DRIVE_MOUNTING :: 0x4;

    VALID   :: ENABLE_INTEROP | APPEND_NT_PATH | ENABLE_DRIVE_MOUNTING;
    DEFAULT :: ENABLE_INTEROP | APPEND_NT_PATH | ENABLE_DRIVE_MOUNTING;
}

WslConfigureDistribution        :: (distributionName: LPCWSTR, defaultUID: u32, wslDistributionFlags: WSL_DISTRIBUTION_FLAGS) -> HRESULT #foreign Wslapi;
WslGetDistributionConfiguration :: (distributionName: LPCWSTR, distributionVersion: *u32, defaultUID: *u32, wslDistributionFlags: *WSL_DISTRIBUTION_FLAGS, defaultEnvironmentVariables: **LPSTR, defaultEnvironmentVariableCount: *u32) -> HRESULT #foreign Wslapi;
WslLaunchInteractive            :: (distributionName: LPCWSTR, command: LPCWSTR, useCurrentWorkingDirectory: BOOL, exitCode: *DWORD) -> HRESULT #foreign Wslapi;
WslLaunch                       :: (distributionName: LPCWSTR, command: LPCWSTR, useCurrentWorkingDirectory: BOOL, stdIn: HANDLE, stdOut: HANDLE, stdErr: HANDLE, process: *HANDLE) -> HRESULT #foreign Wslapi;

#scope_module

#import "Windows";

Wslapi :: #system_library "Wslapi";
