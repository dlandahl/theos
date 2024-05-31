//
// This file was auto-generated using the following command:
//
// jai generate.jai
//



PRUint8 :: u8;
PRInt8 :: s8;

PRUint16 :: u16;
PRInt16 :: s16;

PRUint32 :: u32;
PRInt32 :: s32;

PRInt64 :: s32;
PRUint64 :: u32;
PRIntn :: s32;
PRUintn :: u32;

PRFloat64 :: float64;
PRSize :: u64;

PRPtrdiff :: ptrdiff_t;

PRUptrdiff :: u32;

PRBool :: PRIntn;

PRPackedBool :: PRUint8;

PRUnichar :: u16;
PRWord :: s32;
PRUword :: u32;

CBSTR :: *PRUnichar;
nsresult :: PRUint32;
nsrefcnt :: PRUint32;

nsID :: struct {
    m0: PRUint32;
    m1: PRUint16;
    m2: PRUint16;
    m3: [8] PRUint8;
}

IVirtualBox :: struct {}
IVirtualBoxClient :: struct {}
IHost :: struct {}
ISystemProperties :: struct {}
IMachine :: struct {}
IMedium :: struct {}
IProgress :: struct {}
IGuestOSType :: struct {}
ISharedFolder :: struct {}
IPerformanceCollector :: struct {}
IDHCPServer :: struct {}
INATNetwork :: struct {}
IEventSource :: struct {}
IExtPackManager :: struct {}
IHostOnlyNetwork :: struct {}
ICloudNetwork :: struct {}
ICloudProviderManager :: struct {}
IAppliance :: struct {}
IUnattended :: struct {}
IVirtualBoxErrorInfo :: struct {}
IGraphicsAdapter :: struct {}
IBIOSSettings :: struct {}
ITrustedPlatformModule :: struct {}
INvramStore :: struct {}
IRecordingSettings :: struct {}
IVRDEServer :: struct {}
IMediumAttachment :: struct {}
IUSBController :: struct {}
IUSBDeviceFilters :: struct {}
IAudioSettings :: struct {}
IStorageController :: struct {}
ISnapshot :: struct {}
IPCIDeviceAttachment :: struct {}
IBandwidthControl :: struct {}
IGuestDebugControl :: struct {}
ISession :: struct {}
IBandwidthGroup :: struct {}
INetworkAdapter :: struct {}
ISerialPort :: struct {}
IParallelPort :: struct {}
IVirtualSystemDescription :: struct {}
IMediumFormat :: struct {}
IToken :: struct {}

IMediumIO :: struct {}
IConsole :: struct {}

MachineState :: enum s32 {
    Null                   :: 0;
    PoweredOff             :: 1;
    Saved                  :: 2;
    Teleported             :: 3;
    Aborted                :: 4;
    AbortedSaved           :: 5;
    Running                :: 6;
    Paused                 :: 7;
    Stuck                  :: 8;
    Teleporting            :: 9;
    LiveSnapshotting       :: 10;
    Starting               :: 11;
    Stopping               :: 12;
    Saving                 :: 13;
    Restoring              :: 14;
    TeleportingPausedVM    :: 15;
    TeleportingIn          :: 16;
    DeletingSnapshotOnline :: 17;
    DeletingSnapshotPaused :: 18;
    OnlineSnapshotting     :: 19;
    RestoringSnapshot      :: 20;
    DeletingSnapshot       :: 21;
    SettingUp              :: 22;
    Snapshotting           :: 23;
    FirstOnline            :: 6;
    LastOnline             :: 19;
    FirstTransient         :: 9;
    LastTransient          :: 23;

    MachineState_Null                   :: Null;
    MachineState_PoweredOff             :: PoweredOff;
    MachineState_Saved                  :: Saved;
    MachineState_Teleported             :: Teleported;
    MachineState_Aborted                :: Aborted;
    MachineState_AbortedSaved           :: AbortedSaved;
    MachineState_Running                :: Running;
    MachineState_Paused                 :: Paused;
    MachineState_Stuck                  :: Stuck;
    MachineState_Teleporting            :: Teleporting;
    MachineState_LiveSnapshotting       :: LiveSnapshotting;
    MachineState_Starting               :: Starting;
    MachineState_Stopping               :: Stopping;
    MachineState_Saving                 :: Saving;
    MachineState_Restoring              :: Restoring;
    MachineState_TeleportingPausedVM    :: TeleportingPausedVM;
    MachineState_TeleportingIn          :: TeleportingIn;
    MachineState_DeletingSnapshotOnline :: DeletingSnapshotOnline;
    MachineState_DeletingSnapshotPaused :: DeletingSnapshotPaused;
    MachineState_OnlineSnapshotting     :: OnlineSnapshotting;
    MachineState_RestoringSnapshot      :: RestoringSnapshot;
    MachineState_DeletingSnapshot       :: DeletingSnapshot;
    MachineState_SettingUp              :: SettingUp;
    MachineState_Snapshotting           :: Snapshotting;
    MachineState_FirstOnline            :: FirstOnline;
    MachineState_LastOnline             :: LastOnline;
    MachineState_FirstTransient         :: FirstTransient;
    MachineState_LastTransient          :: LastTransient;
}

DeviceType :: enum s32 {
    Null         :: 0;
    Floppy       :: 1;
    DVD          :: 2;
    HardDisk     :: 3;
    Network      :: 4;
    USB          :: 5;
    SharedFolder :: 6;
    Graphics3D   :: 7;
    End          :: 8;

    DeviceType_Null         :: Null;
    DeviceType_Floppy       :: Floppy;
    DeviceType_DVD          :: DVD;
    DeviceType_HardDisk     :: HardDisk;
    DeviceType_Network      :: Network;
    DeviceType_USB          :: USB;
    DeviceType_SharedFolder :: SharedFolder;
    DeviceType_Graphics3D   :: Graphics3D;
    DeviceType_End          :: End;
}

BIOSBootMenuMode :: enum s32 {
    Disabled       :: 0;
    MenuOnly       :: 1;
    MessageAndMenu :: 2;

    BIOSBootMenuMode_Disabled       :: Disabled;
    BIOSBootMenuMode_MenuOnly       :: MenuOnly;
    BIOSBootMenuMode_MessageAndMenu :: MessageAndMenu;
}

FirmwareType :: enum s32 {
    BIOS    :: 1;
    EFI     :: 2;
    EFI32   :: 3;
    EFI64   :: 4;
    EFIDUAL :: 5;

    FirmwareType_BIOS    :: BIOS;
    FirmwareType_EFI     :: EFI;
    FirmwareType_EFI32   :: EFI32;
    FirmwareType_EFI64   :: EFI64;
    FirmwareType_EFIDUAL :: EFIDUAL;
}

TpmType :: enum s32 {
    None  :: 0;
    v1_2  :: 1;
    v2_0  :: 2;
    Host  :: 3;
    Swtpm :: 4;

    TpmType_None  :: None;
    TpmType_v1_2  :: v1_2;
    TpmType_v2_0  :: v2_0;
    TpmType_Host  :: Host;
    TpmType_Swtpm :: Swtpm;
}

AutostopType :: enum s32 {
    Disabled     :: 1;
    SaveState    :: 2;
    PowerOff     :: 3;
    AcpiShutdown :: 4;

    AutostopType_Disabled     :: Disabled;
    AutostopType_SaveState    :: SaveState;
    AutostopType_PowerOff     :: PowerOff;
    AutostopType_AcpiShutdown :: AcpiShutdown;
}

IVirtualBoxVtbl :: struct {
    QueryInterface:                               #type (pThis: *IVirtualBox, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                       #type (pThis: *IVirtualBox) -> nsrefcnt #c_call;
    Release:                                      #type (pThis: *IVirtualBox) -> nsrefcnt #c_call;
    GetVersion:                                   #type (pThis: *IVirtualBox, version: **PRUnichar) -> nsresult #c_call;

    GetVersionNormalized:                         #type (pThis: *IVirtualBox, versionNormalized: **PRUnichar) -> nsresult #c_call;

    GetRevision:                                  #type (pThis: *IVirtualBox, revision: *PRUint32) -> nsresult #c_call;

    GetPackageType:                               #type (pThis: *IVirtualBox, packageType: **PRUnichar) -> nsresult #c_call;

    GetAPIVersion:                                #type (pThis: *IVirtualBox, APIVersion: **PRUnichar) -> nsresult #c_call;

    GetAPIRevision:                               #type (pThis: *IVirtualBox, APIRevision: *PRInt64) -> nsresult #c_call;

    GetHomeFolder:                                #type (pThis: *IVirtualBox, homeFolder: **PRUnichar) -> nsresult #c_call;

    GetSettingsFilePath:                          #type (pThis: *IVirtualBox, settingsFilePath: **PRUnichar) -> nsresult #c_call;

    GetHost:                                      #type (pThis: *IVirtualBox, host: **IHost) -> nsresult #c_call;

    GetSystemProperties:                          #type (pThis: *IVirtualBox, systemProperties: **ISystemProperties) -> nsresult #c_call;

    GetMachines:                                  #type (pThis: *IVirtualBox, machinesSize: *PRUint32, machines: ***IMachine) -> nsresult #c_call;

    GetMachineGroups:                             #type (pThis: *IVirtualBox, machineGroupsSize: *PRUint32, machineGroups: ***PRUnichar) -> nsresult #c_call;

    GetHardDisks:                                 #type (pThis: *IVirtualBox, hardDisksSize: *PRUint32, hardDisks: ***IMedium) -> nsresult #c_call;

    GetDVDImages:                                 #type (pThis: *IVirtualBox, DVDImagesSize: *PRUint32, DVDImages: ***IMedium) -> nsresult #c_call;

    GetFloppyImages:                              #type (pThis: *IVirtualBox, floppyImagesSize: *PRUint32, floppyImages: ***IMedium) -> nsresult #c_call;

    GetProgressOperations:                        #type (pThis: *IVirtualBox, progressOperationsSize: *PRUint32, progressOperations: ***IProgress) -> nsresult #c_call;

    GetGuestOSTypes:                              #type (pThis: *IVirtualBox, guestOSTypesSize: *PRUint32, guestOSTypes: ***IGuestOSType) -> nsresult #c_call;

    GetSharedFolders:                             #type (pThis: *IVirtualBox, sharedFoldersSize: *PRUint32, sharedFolders: ***ISharedFolder) -> nsresult #c_call;

    GetPerformanceCollector:                      #type (pThis: *IVirtualBox, performanceCollector: **IPerformanceCollector) -> nsresult #c_call;

    GetDHCPServers:                               #type (pThis: *IVirtualBox, DHCPServersSize: *PRUint32, DHCPServers: ***IDHCPServer) -> nsresult #c_call;

    GetNATNetworks:                               #type (pThis: *IVirtualBox, NATNetworksSize: *PRUint32, NATNetworks: ***INATNetwork) -> nsresult #c_call;

    GetEventSource:                               #type (pThis: *IVirtualBox, eventSource: **IEventSource) -> nsresult #c_call;

    GetExtensionPackManager:                      #type (pThis: *IVirtualBox, extensionPackManager: **IExtPackManager) -> nsresult #c_call;

    GetInternalNetworks:                          #type (pThis: *IVirtualBox, internalNetworksSize: *PRUint32, internalNetworks: ***PRUnichar) -> nsresult #c_call;

    GetHostOnlyNetworks:                          #type (pThis: *IVirtualBox, hostOnlyNetworksSize: *PRUint32, hostOnlyNetworks: ***IHostOnlyNetwork) -> nsresult #c_call;

    GetGenericNetworkDrivers:                     #type (pThis: *IVirtualBox, genericNetworkDriversSize: *PRUint32, genericNetworkDrivers: ***PRUnichar) -> nsresult #c_call;

    GetCloudNetworks:                             #type (pThis: *IVirtualBox, cloudNetworksSize: *PRUint32, cloudNetworks: ***ICloudNetwork) -> nsresult #c_call;

    GetCloudProviderManager:                      #type (pThis: *IVirtualBox, cloudProviderManager: **ICloudProviderManager) -> nsresult #c_call;

    GetInternalAndReservedAttribute1IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute3IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute4IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute5IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute6IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute7IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute8IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute9IVirtualBox:  #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute10IVirtualBox: #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute11IVirtualBox: #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute12IVirtualBox: #type (pThis: *IVirtualBox, reserved: *PRUint32) -> nsresult #c_call;

    ComposeMachineFilename:                       #type (pThis: *IVirtualBox, name: *PRUnichar, group: *PRUnichar, createFlags: *PRUnichar, baseFolder: *PRUnichar, file: **PRUnichar) -> nsresult #c_call;

    CreateMachine:                                #type (pThis: *IVirtualBox, settingsFile: *PRUnichar, name: *PRUnichar, groupsSize: PRUint32, groups: **PRUnichar, osTypeId: *PRUnichar, flags: *PRUnichar, cipher: *PRUnichar, passwordId: *PRUnichar, password: *PRUnichar, machine: **IMachine) -> nsresult #c_call;

    OpenMachine:                                  #type (pThis: *IVirtualBox, settingsFile: *PRUnichar, password: *PRUnichar, machine: **IMachine) -> nsresult #c_call;

    RegisterMachine:                              #type (pThis: *IVirtualBox, machine: *IMachine) -> nsresult #c_call;

    FindMachine:                                  #type (pThis: *IVirtualBox, nameOrId: *PRUnichar, machine: **IMachine) -> nsresult #c_call;

    GetMachinesByGroups:                          #type (pThis: *IVirtualBox, groupsSize: PRUint32, groups: **PRUnichar, machinesSize: *PRUint32, machines: ***IMachine) -> nsresult #c_call;

    GetMachineStates:                             #type (pThis: *IVirtualBox, machinesSize: PRUint32, machines: **IMachine, statesSize: *PRUint32, states: **PRUint32) -> nsresult #c_call;

    CreateAppliance:                              #type (pThis: *IVirtualBox, appliance: **IAppliance) -> nsresult #c_call;

    CreateUnattendedInstaller:                    #type (pThis: *IVirtualBox, unattended: **IUnattended) -> nsresult #c_call;

    CreateMedium:                                 #type (pThis: *IVirtualBox, format: *PRUnichar, location: *PRUnichar, accessMode: PRUint32, aDeviceTypeType: PRUint32, medium: **IMedium) -> nsresult #c_call;

    OpenMedium:                                   #type (pThis: *IVirtualBox, location: *PRUnichar, deviceType: PRUint32, accessMode: PRUint32, forceNewUuid: PRBool, medium: **IMedium) -> nsresult #c_call;

    GetGuestOSType:                               #type (pThis: *IVirtualBox, id: *PRUnichar, type: **IGuestOSType) -> nsresult #c_call;

    CreateSharedFolder:                           #type (pThis: *IVirtualBox, name: *PRUnichar, hostPath: *PRUnichar, writable: PRBool, automount: PRBool, autoMountPoint: *PRUnichar) -> nsresult #c_call;

    RemoveSharedFolder:                           #type (pThis: *IVirtualBox, name: *PRUnichar) -> nsresult #c_call;

    GetExtraDataKeys:                             #type (pThis: *IVirtualBox, keysSize: *PRUint32, keys: ***PRUnichar) -> nsresult #c_call;

    GetExtraData:                                 #type (pThis: *IVirtualBox, key: *PRUnichar, value: **PRUnichar) -> nsresult #c_call;

    SetExtraData:                                 #type (pThis: *IVirtualBox, key: *PRUnichar, value: *PRUnichar) -> nsresult #c_call;

    SetSettingsSecret:                            #type (pThis: *IVirtualBox, password: *PRUnichar) -> nsresult #c_call;

    CreateDHCPServer:                             #type (pThis: *IVirtualBox, name: *PRUnichar, server: **IDHCPServer) -> nsresult #c_call;

    FindDHCPServerByNetworkName:                  #type (pThis: *IVirtualBox, name: *PRUnichar, server: **IDHCPServer) -> nsresult #c_call;

    RemoveDHCPServer:                             #type (pThis: *IVirtualBox, server: *IDHCPServer) -> nsresult #c_call;

    CreateNATNetwork:                             #type (pThis: *IVirtualBox, networkName: *PRUnichar, network: **INATNetwork) -> nsresult #c_call;

    FindNATNetworkByName:                         #type (pThis: *IVirtualBox, networkName: *PRUnichar, network: **INATNetwork) -> nsresult #c_call;

    RemoveNATNetwork:                             #type (pThis: *IVirtualBox, network: *INATNetwork) -> nsresult #c_call;

    CreateHostOnlyNetwork:                        #type (pThis: *IVirtualBox, networkName: *PRUnichar, network: **IHostOnlyNetwork) -> nsresult #c_call;

    FindHostOnlyNetworkByName:                    #type (pThis: *IVirtualBox, networkName: *PRUnichar, network: **IHostOnlyNetwork) -> nsresult #c_call;

    FindHostOnlyNetworkById:                      #type (pThis: *IVirtualBox, id: *PRUnichar, network: **IHostOnlyNetwork) -> nsresult #c_call;

    RemoveHostOnlyNetwork:                        #type (pThis: *IVirtualBox, network: *IHostOnlyNetwork) -> nsresult #c_call;

    CreateCloudNetwork:                           #type (pThis: *IVirtualBox, networkName: *PRUnichar, network: **ICloudNetwork) -> nsresult #c_call;

    FindCloudNetworkByName:                       #type (pThis: *IVirtualBox, networkName: *PRUnichar, network: **ICloudNetwork) -> nsresult #c_call;

    RemoveCloudNetwork:                           #type (pThis: *IVirtualBox, network: *ICloudNetwork) -> nsresult #c_call;

    CheckFirmwarePresent:                         #type (pThis: *IVirtualBox, firmwareType: PRUint32, version: *PRUnichar, url: **PRUnichar, file: **PRUnichar, result: *PRBool) -> nsresult #c_call;

    FindProgressById:                             #type (pThis: *IVirtualBox, id: *PRUnichar, progressObject: **IProgress) -> nsresult #c_call;

    InternalAndReservedMethod1IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod2IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod3IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod4IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod5IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod6IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod7IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;

    InternalAndReservedMethod8IVirtualBox:        #type (pThis: *IVirtualBox) -> nsresult #c_call;
}

IMachineVtbl :: struct {
    QueryInterface:                            #type (pThis: *IMachine, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                    #type (pThis: *IMachine) -> nsrefcnt #c_call;
    Release:                                   #type (pThis: *IMachine) -> nsrefcnt #c_call;
    GetParent:                                 #type (pThis: *IMachine, parent: **IVirtualBox) -> nsresult #c_call;

    GetIcon:                                   #type (pThis: *IMachine, iconSize: *PRUint32, icon: **PRUint8) -> nsresult #c_call;
    SetIcon:                                   #type (pThis: *IMachine, iconSize: PRUint32, icon: *PRUint8) -> nsresult #c_call;

    GetAccessible:                             #type (pThis: *IMachine, accessible: *PRBool) -> nsresult #c_call;

    GetAccessError:                            #type (pThis: *IMachine, accessError: **IVirtualBoxErrorInfo) -> nsresult #c_call;

    GetName:                                   #type (pThis: *IMachine, name: **PRUnichar) -> nsresult #c_call;
    SetName:                                   #type (pThis: *IMachine, name: *PRUnichar) -> nsresult #c_call;

    GetDescription:                            #type (pThis: *IMachine, description: **PRUnichar) -> nsresult #c_call;
    SetDescription:                            #type (pThis: *IMachine, description: *PRUnichar) -> nsresult #c_call;

    GetId:                                     #type (pThis: *IMachine, id: **PRUnichar) -> nsresult #c_call;

    GetGroups:                                 #type (pThis: *IMachine, groupsSize: *PRUint32, groups: ***PRUnichar) -> nsresult #c_call;
    SetGroups:                                 #type (pThis: *IMachine, groupsSize: PRUint32, groups: **PRUnichar) -> nsresult #c_call;

    GetOSTypeId:                               #type (pThis: *IMachine, OSTypeId: **PRUnichar) -> nsresult #c_call;
    SetOSTypeId:                               #type (pThis: *IMachine, OSTypeId: *PRUnichar) -> nsresult #c_call;

    GetHardwareVersion:                        #type (pThis: *IMachine, hardwareVersion: **PRUnichar) -> nsresult #c_call;
    SetHardwareVersion:                        #type (pThis: *IMachine, hardwareVersion: *PRUnichar) -> nsresult #c_call;

    GetHardwareUUID:                           #type (pThis: *IMachine, hardwareUUID: **PRUnichar) -> nsresult #c_call;
    SetHardwareUUID:                           #type (pThis: *IMachine, hardwareUUID: *PRUnichar) -> nsresult #c_call;

    GetCPUCount:                               #type (pThis: *IMachine, CPUCount: *PRUint32) -> nsresult #c_call;
    SetCPUCount:                               #type (pThis: *IMachine, CPUCount: PRUint32) -> nsresult #c_call;

    GetCPUHotPlugEnabled:                      #type (pThis: *IMachine, CPUHotPlugEnabled: *PRBool) -> nsresult #c_call;
    SetCPUHotPlugEnabled:                      #type (pThis: *IMachine, CPUHotPlugEnabled: PRBool) -> nsresult #c_call;

    GetCPUExecutionCap:                        #type (pThis: *IMachine, CPUExecutionCap: *PRUint32) -> nsresult #c_call;
    SetCPUExecutionCap:                        #type (pThis: *IMachine, CPUExecutionCap: PRUint32) -> nsresult #c_call;

    GetCPUIDPortabilityLevel:                  #type (pThis: *IMachine, CPUIDPortabilityLevel: *PRUint32) -> nsresult #c_call;
    SetCPUIDPortabilityLevel:                  #type (pThis: *IMachine, CPUIDPortabilityLevel: PRUint32) -> nsresult #c_call;

    GetMemorySize:                             #type (pThis: *IMachine, memorySize: *PRUint32) -> nsresult #c_call;
    SetMemorySize:                             #type (pThis: *IMachine, memorySize: PRUint32) -> nsresult #c_call;

    GetMemoryBalloonSize:                      #type (pThis: *IMachine, memoryBalloonSize: *PRUint32) -> nsresult #c_call;
    SetMemoryBalloonSize:                      #type (pThis: *IMachine, memoryBalloonSize: PRUint32) -> nsresult #c_call;

    GetPageFusionEnabled:                      #type (pThis: *IMachine, pageFusionEnabled: *PRBool) -> nsresult #c_call;
    SetPageFusionEnabled:                      #type (pThis: *IMachine, pageFusionEnabled: PRBool) -> nsresult #c_call;

    GetGraphicsAdapter:                        #type (pThis: *IMachine, graphicsAdapter: **IGraphicsAdapter) -> nsresult #c_call;

    GetBIOSSettings:                           #type (pThis: *IMachine, BIOSSettings: **IBIOSSettings) -> nsresult #c_call;

    GetTrustedPlatformModule:                  #type (pThis: *IMachine, trustedPlatformModule: **ITrustedPlatformModule) -> nsresult #c_call;

    GetNonVolatileStore:                       #type (pThis: *IMachine, nonVolatileStore: **INvramStore) -> nsresult #c_call;

    GetRecordingSettings:                      #type (pThis: *IMachine, recordingSettings: **IRecordingSettings) -> nsresult #c_call;

    GetFirmwareType:                           #type (pThis: *IMachine, firmwareType: *PRUint32) -> nsresult #c_call;
    SetFirmwareType:                           #type (pThis: *IMachine, firmwareType: PRUint32) -> nsresult #c_call;

    GetPointingHIDType:                        #type (pThis: *IMachine, pointingHIDType: *PRUint32) -> nsresult #c_call;
    SetPointingHIDType:                        #type (pThis: *IMachine, pointingHIDType: PRUint32) -> nsresult #c_call;

    GetKeyboardHIDType:                        #type (pThis: *IMachine, keyboardHIDType: *PRUint32) -> nsresult #c_call;
    SetKeyboardHIDType:                        #type (pThis: *IMachine, keyboardHIDType: PRUint32) -> nsresult #c_call;

    GetHPETEnabled:                            #type (pThis: *IMachine, HPETEnabled: *PRBool) -> nsresult #c_call;
    SetHPETEnabled:                            #type (pThis: *IMachine, HPETEnabled: PRBool) -> nsresult #c_call;

    GetChipsetType:                            #type (pThis: *IMachine, chipsetType: *PRUint32) -> nsresult #c_call;
    SetChipsetType:                            #type (pThis: *IMachine, chipsetType: PRUint32) -> nsresult #c_call;

    GetIommuType:                              #type (pThis: *IMachine, iommuType: *PRUint32) -> nsresult #c_call;
    SetIommuType:                              #type (pThis: *IMachine, iommuType: PRUint32) -> nsresult #c_call;

    GetSnapshotFolder:                         #type (pThis: *IMachine, snapshotFolder: **PRUnichar) -> nsresult #c_call;
    SetSnapshotFolder:                         #type (pThis: *IMachine, snapshotFolder: *PRUnichar) -> nsresult #c_call;

    GetVRDEServer:                             #type (pThis: *IMachine, VRDEServer: **IVRDEServer) -> nsresult #c_call;

    GetEmulatedUSBCardReaderEnabled:           #type (pThis: *IMachine, emulatedUSBCardReaderEnabled: *PRBool) -> nsresult #c_call;
    SetEmulatedUSBCardReaderEnabled:           #type (pThis: *IMachine, emulatedUSBCardReaderEnabled: PRBool) -> nsresult #c_call;

    GetMediumAttachments:                      #type (pThis: *IMachine, mediumAttachmentsSize: *PRUint32, mediumAttachments: ***IMediumAttachment) -> nsresult #c_call;

    GetUSBControllers:                         #type (pThis: *IMachine, USBControllersSize: *PRUint32, USBControllers: ***IUSBController) -> nsresult #c_call;

    GetUSBDeviceFilters:                       #type (pThis: *IMachine, USBDeviceFilters: **IUSBDeviceFilters) -> nsresult #c_call;

    GetAudioSettings:                          #type (pThis: *IMachine, audioSettings: **IAudioSettings) -> nsresult #c_call;

    GetStorageControllers:                     #type (pThis: *IMachine, storageControllersSize: *PRUint32, storageControllers: ***IStorageController) -> nsresult #c_call;

    GetSettingsFilePath:                       #type (pThis: *IMachine, settingsFilePath: **PRUnichar) -> nsresult #c_call;

    GetSettingsAuxFilePath:                    #type (pThis: *IMachine, settingsAuxFilePath: **PRUnichar) -> nsresult #c_call;

    GetSettingsModified:                       #type (pThis: *IMachine, settingsModified: *PRBool) -> nsresult #c_call;

    GetSessionState:                           #type (pThis: *IMachine, sessionState: *PRUint32) -> nsresult #c_call;

    GetSessionName:                            #type (pThis: *IMachine, sessionName: **PRUnichar) -> nsresult #c_call;

    GetSessionPID:                             #type (pThis: *IMachine, sessionPID: *PRUint32) -> nsresult #c_call;

    GetState:                                  #type (pThis: *IMachine, state: *PRUint32) -> nsresult #c_call;

    GetLastStateChange:                        #type (pThis: *IMachine, lastStateChange: *PRInt64) -> nsresult #c_call;

    GetStateFilePath:                          #type (pThis: *IMachine, stateFilePath: **PRUnichar) -> nsresult #c_call;

    GetLogFolder:                              #type (pThis: *IMachine, logFolder: **PRUnichar) -> nsresult #c_call;

    GetCurrentSnapshot:                        #type (pThis: *IMachine, currentSnapshot: **ISnapshot) -> nsresult #c_call;

    GetSnapshotCount:                          #type (pThis: *IMachine, snapshotCount: *PRUint32) -> nsresult #c_call;

    GetCurrentStateModified:                   #type (pThis: *IMachine, currentStateModified: *PRBool) -> nsresult #c_call;

    GetSharedFolders:                          #type (pThis: *IMachine, sharedFoldersSize: *PRUint32, sharedFolders: ***ISharedFolder) -> nsresult #c_call;

    GetClipboardMode:                          #type (pThis: *IMachine, clipboardMode: *PRUint32) -> nsresult #c_call;
    SetClipboardMode:                          #type (pThis: *IMachine, clipboardMode: PRUint32) -> nsresult #c_call;

    GetClipboardFileTransfersEnabled:          #type (pThis: *IMachine, clipboardFileTransfersEnabled: *PRBool) -> nsresult #c_call;
    SetClipboardFileTransfersEnabled:          #type (pThis: *IMachine, clipboardFileTransfersEnabled: PRBool) -> nsresult #c_call;

    GetDnDMode:                                #type (pThis: *IMachine, dnDMode: *PRUint32) -> nsresult #c_call;
    SetDnDMode:                                #type (pThis: *IMachine, dnDMode: PRUint32) -> nsresult #c_call;

    GetTeleporterEnabled:                      #type (pThis: *IMachine, teleporterEnabled: *PRBool) -> nsresult #c_call;
    SetTeleporterEnabled:                      #type (pThis: *IMachine, teleporterEnabled: PRBool) -> nsresult #c_call;

    GetTeleporterPort:                         #type (pThis: *IMachine, teleporterPort: *PRUint32) -> nsresult #c_call;
    SetTeleporterPort:                         #type (pThis: *IMachine, teleporterPort: PRUint32) -> nsresult #c_call;

    GetTeleporterAddress:                      #type (pThis: *IMachine, teleporterAddress: **PRUnichar) -> nsresult #c_call;
    SetTeleporterAddress:                      #type (pThis: *IMachine, teleporterAddress: *PRUnichar) -> nsresult #c_call;

    GetTeleporterPassword:                     #type (pThis: *IMachine, teleporterPassword: **PRUnichar) -> nsresult #c_call;
    SetTeleporterPassword:                     #type (pThis: *IMachine, teleporterPassword: *PRUnichar) -> nsresult #c_call;

    GetParavirtProvider:                       #type (pThis: *IMachine, paravirtProvider: *PRUint32) -> nsresult #c_call;
    SetParavirtProvider:                       #type (pThis: *IMachine, paravirtProvider: PRUint32) -> nsresult #c_call;

    GetRTCUseUTC:                              #type (pThis: *IMachine, RTCUseUTC: *PRBool) -> nsresult #c_call;
    SetRTCUseUTC:                              #type (pThis: *IMachine, RTCUseUTC: PRBool) -> nsresult #c_call;

    GetIOCacheEnabled:                         #type (pThis: *IMachine, IOCacheEnabled: *PRBool) -> nsresult #c_call;
    SetIOCacheEnabled:                         #type (pThis: *IMachine, IOCacheEnabled: PRBool) -> nsresult #c_call;

    GetIOCacheSize:                            #type (pThis: *IMachine, IOCacheSize: *PRUint32) -> nsresult #c_call;
    SetIOCacheSize:                            #type (pThis: *IMachine, IOCacheSize: PRUint32) -> nsresult #c_call;

    GetPCIDeviceAssignments:                   #type (pThis: *IMachine, PCIDeviceAssignmentsSize: *PRUint32, PCIDeviceAssignments: ***IPCIDeviceAttachment) -> nsresult #c_call;

    GetBandwidthControl:                       #type (pThis: *IMachine, bandwidthControl: **IBandwidthControl) -> nsresult #c_call;

    GetTracingEnabled:                         #type (pThis: *IMachine, tracingEnabled: *PRBool) -> nsresult #c_call;
    SetTracingEnabled:                         #type (pThis: *IMachine, tracingEnabled: PRBool) -> nsresult #c_call;

    GetTracingConfig:                          #type (pThis: *IMachine, tracingConfig: **PRUnichar) -> nsresult #c_call;
    SetTracingConfig:                          #type (pThis: *IMachine, tracingConfig: *PRUnichar) -> nsresult #c_call;

    GetAllowTracingToAccessVM:                 #type (pThis: *IMachine, allowTracingToAccessVM: *PRBool) -> nsresult #c_call;
    SetAllowTracingToAccessVM:                 #type (pThis: *IMachine, allowTracingToAccessVM: PRBool) -> nsresult #c_call;

    GetAutostartEnabled:                       #type (pThis: *IMachine, autostartEnabled: *PRBool) -> nsresult #c_call;
    SetAutostartEnabled:                       #type (pThis: *IMachine, autostartEnabled: PRBool) -> nsresult #c_call;

    GetAutostartDelay:                         #type (pThis: *IMachine, autostartDelay: *PRUint32) -> nsresult #c_call;
    SetAutostartDelay:                         #type (pThis: *IMachine, autostartDelay: PRUint32) -> nsresult #c_call;

    GetAutostopType:                           #type (pThis: *IMachine, autostopType: *PRUint32) -> nsresult #c_call;
    SetAutostopType:                           #type (pThis: *IMachine, autostopType: PRUint32) -> nsresult #c_call;

    GetDefaultFrontend:                        #type (pThis: *IMachine, defaultFrontend: **PRUnichar) -> nsresult #c_call;
    SetDefaultFrontend:                        #type (pThis: *IMachine, defaultFrontend: *PRUnichar) -> nsresult #c_call;

    GetUSBProxyAvailable:                      #type (pThis: *IMachine, USBProxyAvailable: *PRBool) -> nsresult #c_call;

    GetVMProcessPriority:                      #type (pThis: *IMachine, VMProcessPriority: *PRUint32) -> nsresult #c_call;
    SetVMProcessPriority:                      #type (pThis: *IMachine, VMProcessPriority: PRUint32) -> nsresult #c_call;

    GetParavirtDebug:                          #type (pThis: *IMachine, paravirtDebug: **PRUnichar) -> nsresult #c_call;
    SetParavirtDebug:                          #type (pThis: *IMachine, paravirtDebug: *PRUnichar) -> nsresult #c_call;

    GetCPUProfile:                             #type (pThis: *IMachine, CPUProfile: **PRUnichar) -> nsresult #c_call;
    SetCPUProfile:                             #type (pThis: *IMachine, CPUProfile: *PRUnichar) -> nsresult #c_call;

    GetStateKeyId:                             #type (pThis: *IMachine, stateKeyId: **PRUnichar) -> nsresult #c_call;

    GetStateKeyStore:                          #type (pThis: *IMachine, stateKeyStore: **PRUnichar) -> nsresult #c_call;

    GetLogKeyId:                               #type (pThis: *IMachine, logKeyId: **PRUnichar) -> nsresult #c_call;

    GetLogKeyStore:                            #type (pThis: *IMachine, logKeyStore: **PRUnichar) -> nsresult #c_call;

    GetGuestDebugControl:                      #type (pThis: *IMachine, guestDebugControl: **IGuestDebugControl) -> nsresult #c_call;

    GetInternalAndReservedAttribute1IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute3IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute4IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute5IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute6IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute7IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute8IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute9IMachine:  #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute10IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute11IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute12IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute13IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute14IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute15IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute16IMachine: #type (pThis: *IMachine, reserved: *PRUint32) -> nsresult #c_call;

    LockMachine:                               #type (pThis: *IMachine, session: *ISession, lockType: PRUint32) -> nsresult #c_call;

    LaunchVMProcess:                           #type (pThis: *IMachine, session: *ISession, name: *PRUnichar, environmentChangesSize: PRUint32, environmentChanges: **PRUnichar, progress: **IProgress) -> nsresult #c_call;

    SetBootOrder:                              #type (pThis: *IMachine, position: PRUint32, device: PRUint32) -> nsresult #c_call;

    GetBootOrder:                              #type (pThis: *IMachine, position: PRUint32, device: *PRUint32) -> nsresult #c_call;

    AttachDevice:                              #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, type: PRUint32, medium: *IMedium) -> nsresult #c_call;

    AttachDeviceWithoutMedium:                 #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, type: PRUint32) -> nsresult #c_call;

    DetachDevice:                              #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32) -> nsresult #c_call;

    PassthroughDevice:                         #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, passthrough: PRBool) -> nsresult #c_call;

    TemporaryEjectDevice:                      #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, temporaryEject: PRBool) -> nsresult #c_call;

    NonRotationalDevice:                       #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, nonRotational: PRBool) -> nsresult #c_call;

    SetAutoDiscardForDevice:                   #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, discard: PRBool) -> nsresult #c_call;

    SetHotPluggableForDevice:                  #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, hotPluggable: PRBool) -> nsresult #c_call;

    SetBandwidthGroupForDevice:                #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, bandwidthGroup: *IBandwidthGroup) -> nsresult #c_call;

    SetNoBandwidthGroupForDevice:              #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32) -> nsresult #c_call;

    UnmountMedium:                             #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, force: PRBool) -> nsresult #c_call;

    MountMedium:                               #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, medium: *IMedium, force: PRBool) -> nsresult #c_call;

    GetMedium:                                 #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, medium: **IMedium) -> nsresult #c_call;

    GetMediumAttachmentsOfController:          #type (pThis: *IMachine, name: *PRUnichar, mediumAttachmentsSize: *PRUint32, mediumAttachments: ***IMediumAttachment) -> nsresult #c_call;

    GetMediumAttachment:                       #type (pThis: *IMachine, name: *PRUnichar, controllerPort: PRInt32, device: PRInt32, attachment: **IMediumAttachment) -> nsresult #c_call;

    AttachHostPCIDevice:                       #type (pThis: *IMachine, hostAddress: PRInt32, desiredGuestAddress: PRInt32, tryToUnbind: PRBool) -> nsresult #c_call;

    DetachHostPCIDevice:                       #type (pThis: *IMachine, hostAddress: PRInt32) -> nsresult #c_call;

    GetNetworkAdapter:                         #type (pThis: *IMachine, slot: PRUint32, adapter: **INetworkAdapter) -> nsresult #c_call;

    AddStorageController:                      #type (pThis: *IMachine, name: *PRUnichar, connectionType: PRUint32, controller: **IStorageController) -> nsresult #c_call;

    GetStorageControllerByName:                #type (pThis: *IMachine, name: *PRUnichar, storageController: **IStorageController) -> nsresult #c_call;

    GetStorageControllerByInstance:            #type (pThis: *IMachine, connectionType: PRUint32, instance: PRUint32, storageController: **IStorageController) -> nsresult #c_call;

    RemoveStorageController:                   #type (pThis: *IMachine, name: *PRUnichar) -> nsresult #c_call;

    SetStorageControllerBootable:              #type (pThis: *IMachine, name: *PRUnichar, bootable: PRBool) -> nsresult #c_call;

    AddUSBController:                          #type (pThis: *IMachine, name: *PRUnichar, type: PRUint32, controller: **IUSBController) -> nsresult #c_call;

    RemoveUSBController:                       #type (pThis: *IMachine, name: *PRUnichar) -> nsresult #c_call;

    GetUSBControllerByName:                    #type (pThis: *IMachine, name: *PRUnichar, controller: **IUSBController) -> nsresult #c_call;

    GetUSBControllerCountByType:               #type (pThis: *IMachine, type: PRUint32, controllers: *PRUint32) -> nsresult #c_call;

    GetSerialPort:                             #type (pThis: *IMachine, slot: PRUint32, port: **ISerialPort) -> nsresult #c_call;

    GetParallelPort:                           #type (pThis: *IMachine, slot: PRUint32, port: **IParallelPort) -> nsresult #c_call;

    GetExtraDataKeys:                          #type (pThis: *IMachine, keysSize: *PRUint32, keys: ***PRUnichar) -> nsresult #c_call;

    GetExtraData:                              #type (pThis: *IMachine, key: *PRUnichar, value: **PRUnichar) -> nsresult #c_call;

    SetExtraData:                              #type (pThis: *IMachine, key: *PRUnichar, value: *PRUnichar) -> nsresult #c_call;

    GetCPUProperty:                            #type (pThis: *IMachine, property: PRUint32, value: *PRBool) -> nsresult #c_call;

    SetCPUProperty:                            #type (pThis: *IMachine, property: PRUint32, value: PRBool) -> nsresult #c_call;

    GetCPUIDLeafByOrdinal:                     #type (pThis: *IMachine, ordinal: PRUint32, idx: *PRUint32, idxSub: *PRUint32, valEax: *PRUint32, valEbx: *PRUint32, valEcx: *PRUint32, valEdx: *PRUint32) -> nsresult #c_call;

    GetCPUIDLeaf:                              #type (pThis: *IMachine, idx: PRUint32, idxSub: PRUint32, valEax: *PRUint32, valEbx: *PRUint32, valEcx: *PRUint32, valEdx: *PRUint32) -> nsresult #c_call;

    SetCPUIDLeaf:                              #type (pThis: *IMachine, idx: PRUint32, idxSub: PRUint32, valEax: PRUint32, valEbx: PRUint32, valEcx: PRUint32, valEdx: PRUint32) -> nsresult #c_call;

    RemoveCPUIDLeaf:                           #type (pThis: *IMachine, idx: PRUint32, idxSub: PRUint32) -> nsresult #c_call;

    RemoveAllCPUIDLeaves:                      #type (pThis: *IMachine) -> nsresult #c_call;

    GetHWVirtExProperty:                       #type (pThis: *IMachine, property: PRUint32, value: *PRBool) -> nsresult #c_call;

    SetHWVirtExProperty:                       #type (pThis: *IMachine, property: PRUint32, value: PRBool) -> nsresult #c_call;

    SetSettingsFilePath:                       #type (pThis: *IMachine, settingsFilePath: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    SaveSettings:                              #type (pThis: *IMachine) -> nsresult #c_call;

    DiscardSettings:                           #type (pThis: *IMachine) -> nsresult #c_call;

    Unregister:                                #type (pThis: *IMachine, cleanupMode: PRUint32, mediaSize: *PRUint32, media: ***IMedium) -> nsresult #c_call;

    DeleteConfig:                              #type (pThis: *IMachine, mediaSize: PRUint32, media: **IMedium, progress: **IProgress) -> nsresult #c_call;

    ExportTo:                                  #type (pThis: *IMachine, appliance: *IAppliance, location: *PRUnichar, description: **IVirtualSystemDescription) -> nsresult #c_call;

    FindSnapshot:                              #type (pThis: *IMachine, nameOrId: *PRUnichar, snapshot: **ISnapshot) -> nsresult #c_call;

    CreateSharedFolder:                        #type (pThis: *IMachine, name: *PRUnichar, hostPath: *PRUnichar, writable: PRBool, automount: PRBool, autoMountPoint: *PRUnichar) -> nsresult #c_call;

    RemoveSharedFolder:                        #type (pThis: *IMachine, name: *PRUnichar) -> nsresult #c_call;

    CanShowConsoleWindow:                      #type (pThis: *IMachine, canShow: *PRBool) -> nsresult #c_call;

    ShowConsoleWindow:                         #type (pThis: *IMachine, winId: *PRInt64) -> nsresult #c_call;

    GetGuestProperty:                          #type (pThis: *IMachine, name: *PRUnichar, value: **PRUnichar, timestamp: *PRInt64, flags: **PRUnichar) -> nsresult #c_call;

    GetGuestPropertyValue:                     #type (pThis: *IMachine, property: *PRUnichar, value: **PRUnichar) -> nsresult #c_call;

    GetGuestPropertyTimestamp:                 #type (pThis: *IMachine, property: *PRUnichar, value: *PRInt64) -> nsresult #c_call;

    SetGuestProperty:                          #type (pThis: *IMachine, property: *PRUnichar, value: *PRUnichar, flags: *PRUnichar) -> nsresult #c_call;

    SetGuestPropertyValue:                     #type (pThis: *IMachine, property: *PRUnichar, value: *PRUnichar) -> nsresult #c_call;

    DeleteGuestProperty:                       #type (pThis: *IMachine, name: *PRUnichar) -> nsresult #c_call;

    EnumerateGuestProperties:                  #type (pThis: *IMachine, patterns: *PRUnichar, namesSize: *PRUint32, names: ***PRUnichar, valuesSize: *PRUint32, values: ***PRUnichar, timestampsSize: *PRUint32, timestamps: **PRInt64, flagsSize: *PRUint32, flags: ***PRUnichar) -> nsresult #c_call;

    QuerySavedGuestScreenInfo:                 #type (pThis: *IMachine, screenId: PRUint32, originX: *PRUint32, originY: *PRUint32, width: *PRUint32, height: *PRUint32, enabled: *PRBool) -> nsresult #c_call;

    ReadSavedThumbnailToArray:                 #type (pThis: *IMachine, screenId: PRUint32, bitmapFormat: PRUint32, width: *PRUint32, height: *PRUint32, dataSize: *PRUint32, data: **PRUint8) -> nsresult #c_call;

    QuerySavedScreenshotInfo:                  #type (pThis: *IMachine, screenId: PRUint32, width: *PRUint32, height: *PRUint32, bitmapFormatsSize: *PRUint32, bitmapFormats: **PRUint32) -> nsresult #c_call;

    ReadSavedScreenshotToArray:                #type (pThis: *IMachine, screenId: PRUint32, bitmapFormat: PRUint32, width: *PRUint32, height: *PRUint32, dataSize: *PRUint32, data: **PRUint8) -> nsresult #c_call;

    HotPlugCPU:                                #type (pThis: *IMachine, cpu: PRUint32) -> nsresult #c_call;

    HotUnplugCPU:                              #type (pThis: *IMachine, cpu: PRUint32) -> nsresult #c_call;

    GetCPUStatus:                              #type (pThis: *IMachine, cpu: PRUint32, attached: *PRBool) -> nsresult #c_call;

    GetEffectiveParavirtProvider:              #type (pThis: *IMachine, paravirtProvider: *PRUint32) -> nsresult #c_call;

    QueryLogFilename:                          #type (pThis: *IMachine, idx: PRUint32, filename: **PRUnichar) -> nsresult #c_call;

    ReadLog:                                   #type (pThis: *IMachine, idx: PRUint32, offset: PRInt64, size: PRInt64, dataSize: *PRUint32, data: **PRUint8) -> nsresult #c_call;

    CloneTo:                                   #type (pThis: *IMachine, target: *IMachine, mode: PRUint32, optionsSize: PRUint32, options: *PRUint32, progress: **IProgress) -> nsresult #c_call;

    MoveTo:                                    #type (pThis: *IMachine, folder: *PRUnichar, type: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    SaveState:                                 #type (pThis: *IMachine, progress: **IProgress) -> nsresult #c_call;

    AdoptSavedState:                           #type (pThis: *IMachine, savedStateFile: *PRUnichar) -> nsresult #c_call;

    DiscardSavedState:                         #type (pThis: *IMachine, fRemoveFile: PRBool) -> nsresult #c_call;

    TakeSnapshot:                              #type (pThis: *IMachine, name: *PRUnichar, description: *PRUnichar, pause: PRBool, id: **PRUnichar, progress: **IProgress) -> nsresult #c_call;

    DeleteSnapshot:                            #type (pThis: *IMachine, id: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    DeleteSnapshotAndAllChildren:              #type (pThis: *IMachine, id: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    DeleteSnapshotRange:                       #type (pThis: *IMachine, startId: *PRUnichar, endId: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    RestoreSnapshot:                           #type (pThis: *IMachine, snapshot: *ISnapshot, progress: **IProgress) -> nsresult #c_call;

    ApplyDefaults:                             #type (pThis: *IMachine, flags: *PRUnichar) -> nsresult #c_call;

    ChangeEncryption:                          #type (pThis: *IMachine, currentPassword: *PRUnichar, cipher: *PRUnichar, newPassword: *PRUnichar, newPasswordId: *PRUnichar, force: PRBool, progress: **IProgress) -> nsresult #c_call;

    GetEncryptionSettings:                     #type (pThis: *IMachine, cipher: **PRUnichar, passwordId: **PRUnichar) -> nsresult #c_call;

    CheckEncryptionPassword:                   #type (pThis: *IMachine, password: *PRUnichar) -> nsresult #c_call;

    AddEncryptionPassword:                     #type (pThis: *IMachine, id: *PRUnichar, password: *PRUnichar) -> nsresult #c_call;

    AddEncryptionPasswords:                    #type (pThis: *IMachine, idsSize: PRUint32, ids: **PRUnichar, passwordsSize: PRUint32, passwords: **PRUnichar) -> nsresult #c_call;

    RemoveEncryptionPassword:                  #type (pThis: *IMachine, id: *PRUnichar) -> nsresult #c_call;

    ClearAllEncryptionPasswords:               #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod1IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod2IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod3IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod4IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod5IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod6IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod7IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod8IMachine:        #type (pThis: *IMachine) -> nsresult #c_call;
}

IVirtualBoxClientVtbl :: struct {
    QueryInterface:                                    #type (pThis: *IVirtualBoxClient, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                            #type (pThis: *IVirtualBoxClient) -> nsrefcnt #c_call;
    Release:                                           #type (pThis: *IVirtualBoxClient) -> nsrefcnt #c_call;
    GetVirtualBox:                                     #type (pThis: *IVirtualBoxClient, virtualBox: **IVirtualBox) -> nsresult #c_call;

    GetSession:                                        #type (pThis: *IVirtualBoxClient, session: **ISession) -> nsresult #c_call;

    GetEventSource:                                    #type (pThis: *IVirtualBoxClient, eventSource: **IEventSource) -> nsresult #c_call;

    GetInternalAndReservedAttribute1IVirtualBoxClient: #type (pThis: *IVirtualBoxClient, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2IVirtualBoxClient: #type (pThis: *IVirtualBoxClient, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute3IVirtualBoxClient: #type (pThis: *IVirtualBoxClient, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute4IVirtualBoxClient: #type (pThis: *IVirtualBoxClient, reserved: *PRUint32) -> nsresult #c_call;

    CheckMachineError:                                 #type (pThis: *IVirtualBoxClient, machine: *IMachine) -> nsresult #c_call;

    InternalAndReservedMethod1IVirtualBoxClient:       #type (pThis: *IVirtualBoxClient) -> nsresult #c_call;

    InternalAndReservedMethod2IVirtualBoxClient:       #type (pThis: *IVirtualBoxClient) -> nsresult #c_call;

    InternalAndReservedMethod3IVirtualBoxClient:       #type (pThis: *IVirtualBoxClient) -> nsresult #c_call;

    InternalAndReservedMethod4IVirtualBoxClient:       #type (pThis: *IVirtualBoxClient) -> nsresult #c_call;
}

IGuestDebugControlVtbl :: struct {
    QueryInterface:                                     #type (pThis: *IGuestDebugControl, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                             #type (pThis: *IGuestDebugControl) -> nsrefcnt #c_call;
    Release:                                            #type (pThis: *IGuestDebugControl) -> nsrefcnt #c_call;
    GetDebugProvider:                                   #type (pThis: *IGuestDebugControl, debugProvider: *PRUint32) -> nsresult #c_call;
    SetDebugProvider:                                   #type (pThis: *IGuestDebugControl, debugProvider: PRUint32) -> nsresult #c_call;

    GetDebugIoProvider:                                 #type (pThis: *IGuestDebugControl, debugIoProvider: *PRUint32) -> nsresult #c_call;
    SetDebugIoProvider:                                 #type (pThis: *IGuestDebugControl, debugIoProvider: PRUint32) -> nsresult #c_call;

    GetDebugAddress:                                    #type (pThis: *IGuestDebugControl, debugAddress: **PRUnichar) -> nsresult #c_call;
    SetDebugAddress:                                    #type (pThis: *IGuestDebugControl, debugAddress: *PRUnichar) -> nsresult #c_call;

    GetDebugPort:                                       #type (pThis: *IGuestDebugControl, debugPort: *PRUint32) -> nsresult #c_call;
    SetDebugPort:                                       #type (pThis: *IGuestDebugControl, debugPort: PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute1IGuestDebugControl: #type (pThis: *IGuestDebugControl, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2IGuestDebugControl: #type (pThis: *IGuestDebugControl, reserved: *PRUint32) -> nsresult #c_call;

    InternalAndReservedMethod1IGuestDebugControl:       #type (pThis: *IGuestDebugControl) -> nsresult #c_call;

    InternalAndReservedMethod2IGuestDebugControl:       #type (pThis: *IGuestDebugControl) -> nsresult #c_call;
}

IMediumVtbl :: struct {
    QueryInterface:                           #type (pThis: *IMedium, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                   #type (pThis: *IMedium) -> nsrefcnt #c_call;
    Release:                                  #type (pThis: *IMedium) -> nsrefcnt #c_call;
    GetId:                                    #type (pThis: *IMedium, id: **PRUnichar) -> nsresult #c_call;

    GetDescription:                           #type (pThis: *IMedium, description: **PRUnichar) -> nsresult #c_call;
    SetDescription:                           #type (pThis: *IMedium, description: *PRUnichar) -> nsresult #c_call;

    GetState:                                 #type (pThis: *IMedium, state: *PRUint32) -> nsresult #c_call;

    GetVariant:                               #type (pThis: *IMedium, variantSize: *PRUint32, variant: **PRUint32) -> nsresult #c_call;

    GetLocation:                              #type (pThis: *IMedium, location: **PRUnichar) -> nsresult #c_call;
    SetLocation:                              #type (pThis: *IMedium, location: *PRUnichar) -> nsresult #c_call;

    GetName:                                  #type (pThis: *IMedium, name: **PRUnichar) -> nsresult #c_call;

    GetDeviceType:                            #type (pThis: *IMedium, deviceType: *PRUint32) -> nsresult #c_call;

    GetHostDrive:                             #type (pThis: *IMedium, hostDrive: *PRBool) -> nsresult #c_call;

    GetSize:                                  #type (pThis: *IMedium, size: *PRInt64) -> nsresult #c_call;

    GetFormat:                                #type (pThis: *IMedium, format: **PRUnichar) -> nsresult #c_call;

    GetMediumFormat:                          #type (pThis: *IMedium, mediumFormat: **IMediumFormat) -> nsresult #c_call;

    GetType:                                  #type (pThis: *IMedium, type: *PRUint32) -> nsresult #c_call;
    SetType:                                  #type (pThis: *IMedium, type: PRUint32) -> nsresult #c_call;

    GetAllowedTypes:                          #type (pThis: *IMedium, allowedTypesSize: *PRUint32, allowedTypes: **PRUint32) -> nsresult #c_call;

    GetParent:                                #type (pThis: *IMedium, parent: **IMedium) -> nsresult #c_call;

    GetChildren:                              #type (pThis: *IMedium, childrenSize: *PRUint32, children: ***IMedium) -> nsresult #c_call;

    GetBase:                                  #type (pThis: *IMedium, base: **IMedium) -> nsresult #c_call;

    GetReadOnly:                              #type (pThis: *IMedium, readOnly: *PRBool) -> nsresult #c_call;

    GetLogicalSize:                           #type (pThis: *IMedium, logicalSize: *PRInt64) -> nsresult #c_call;

    GetAutoReset:                             #type (pThis: *IMedium, autoReset: *PRBool) -> nsresult #c_call;
    SetAutoReset:                             #type (pThis: *IMedium, autoReset: PRBool) -> nsresult #c_call;

    GetLastAccessError:                       #type (pThis: *IMedium, lastAccessError: **PRUnichar) -> nsresult #c_call;

    GetMachineIds:                            #type (pThis: *IMedium, machineIdsSize: *PRUint32, machineIds: ***PRUnichar) -> nsresult #c_call;

    GetInternalAndReservedAttribute1IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute3IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute4IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute5IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute6IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute7IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute8IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute9IMedium:  #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute10IMedium: #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute11IMedium: #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute12IMedium: #type (pThis: *IMedium, reserved: *PRUint32) -> nsresult #c_call;

    SetIds:                                   #type (pThis: *IMedium, setImageId: PRBool, imageId: *PRUnichar, setParentId: PRBool, parentId: *PRUnichar) -> nsresult #c_call;

    RefreshState:                             #type (pThis: *IMedium, state: *PRUint32) -> nsresult #c_call;

    GetSnapshotIds:                           #type (pThis: *IMedium, machineId: *PRUnichar, snapshotIdsSize: *PRUint32, snapshotIds: ***PRUnichar) -> nsresult #c_call;

    LockRead:                                 #type (pThis: *IMedium, token: **IToken) -> nsresult #c_call;

    LockWrite:                                #type (pThis: *IMedium, token: **IToken) -> nsresult #c_call;

    Close:                                    #type (pThis: *IMedium) -> nsresult #c_call;

    GetProperty:                              #type (pThis: *IMedium, name: *PRUnichar, value: **PRUnichar) -> nsresult #c_call;

    SetProperty:                              #type (pThis: *IMedium, name: *PRUnichar, value: *PRUnichar) -> nsresult #c_call;

    GetProperties:                            #type (pThis: *IMedium, names: *PRUnichar, returnNamesSize: *PRUint32, returnNames: ***PRUnichar, returnValuesSize: *PRUint32, returnValues: ***PRUnichar) -> nsresult #c_call;

    SetProperties:                            #type (pThis: *IMedium, namesSize: PRUint32, names: **PRUnichar, valuesSize: PRUint32, values: **PRUnichar) -> nsresult #c_call;

    CreateBaseStorage:                        #type (pThis: *IMedium, logicalSize: PRInt64, variantSize: PRUint32, variant: *PRUint32, progress: **IProgress) -> nsresult #c_call;

    DeleteStorage:                            #type (pThis: *IMedium, progress: **IProgress) -> nsresult #c_call;

    CreateDiffStorage:                        #type (pThis: *IMedium, target: *IMedium, variantSize: PRUint32, variant: *PRUint32, progress: **IProgress) -> nsresult #c_call;

    MergeTo:                                  #type (pThis: *IMedium, target: *IMedium, progress: **IProgress) -> nsresult #c_call;

    CloneTo:                                  #type (pThis: *IMedium, target: *IMedium, variantSize: PRUint32, variant: *PRUint32, parent: *IMedium, progress: **IProgress) -> nsresult #c_call;

    CloneToBase:                              #type (pThis: *IMedium, target: *IMedium, variantSize: PRUint32, variant: *PRUint32, progress: **IProgress) -> nsresult #c_call;

    MoveTo:                                   #type (pThis: *IMedium, location: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    Compact:                                  #type (pThis: *IMedium, progress: **IProgress) -> nsresult #c_call;

    Resize:                                   #type (pThis: *IMedium, logicalSize: PRInt64, progress: **IProgress) -> nsresult #c_call;

    Reset:                                    #type (pThis: *IMedium, progress: **IProgress) -> nsresult #c_call;

    ChangeEncryption:                         #type (pThis: *IMedium, currentPassword: *PRUnichar, cipher: *PRUnichar, newPassword: *PRUnichar, newPasswordId: *PRUnichar, progress: **IProgress) -> nsresult #c_call;

    GetEncryptionSettings:                    #type (pThis: *IMedium, cipher: **PRUnichar, passwordId: **PRUnichar) -> nsresult #c_call;

    CheckEncryptionPassword:                  #type (pThis: *IMedium, password: *PRUnichar) -> nsresult #c_call;

    OpenForIO:                                #type (pThis: *IMedium, writable: PRBool, password: *PRUnichar, mediumIO: **IMediumIO) -> nsresult #c_call;

    ResizeAndCloneTo:                         #type (pThis: *IMedium, target: *IMedium, logicalSize: PRInt64, variantSize: PRUint32, variant: *PRUint32, parent: *IMedium, progress: **IProgress) -> nsresult #c_call;

    InternalAndReservedMethod1IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;

    InternalAndReservedMethod2IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;

    InternalAndReservedMethod3IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;

    InternalAndReservedMethod4IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;

    InternalAndReservedMethod5IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;

    InternalAndReservedMethod6IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;

    InternalAndReservedMethod7IMedium:        #type (pThis: *IMedium) -> nsresult #c_call;
}

ISessionVtbl :: struct {
    QueryInterface:                           #type (pThis: *ISession, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                   #type (pThis: *ISession) -> nsrefcnt #c_call;
    Release:                                  #type (pThis: *ISession) -> nsrefcnt #c_call;
    GetState:                                 #type (pThis: *ISession, state: *PRUint32) -> nsresult #c_call;

    GetType:                                  #type (pThis: *ISession, type: *PRUint32) -> nsresult #c_call;

    GetName:                                  #type (pThis: *ISession, name: **PRUnichar) -> nsresult #c_call;
    SetName:                                  #type (pThis: *ISession, name: *PRUnichar) -> nsresult #c_call;

    GetMachine:                               #type (pThis: *ISession, machine: **IMachine) -> nsresult #c_call;

    GetConsole:                               #type (pThis: *ISession, console: **IConsole) -> nsresult #c_call;

    GetInternalAndReservedAttribute1ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute3ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute4ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute5ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute6ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute7ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute8ISession: #type (pThis: *ISession, reserved: *PRUint32) -> nsresult #c_call;

    UnlockMachine:                            #type (pThis: *ISession) -> nsresult #c_call;

    InternalAndReservedMethod1ISession:       #type (pThis: *ISession) -> nsresult #c_call;

    InternalAndReservedMethod2ISession:       #type (pThis: *ISession) -> nsresult #c_call;

    InternalAndReservedMethod3ISession:       #type (pThis: *ISession) -> nsresult #c_call;

    InternalAndReservedMethod4ISession:       #type (pThis: *ISession) -> nsresult #c_call;
}

IStorageControllerVtbl :: struct {
    QueryInterface:                                     #type (pThis: *IStorageController, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:                                             #type (pThis: *IStorageController) -> nsrefcnt #c_call;
    Release:                                            #type (pThis: *IStorageController) -> nsrefcnt #c_call;
    GetName:                                            #type (pThis: *IStorageController, name: **PRUnichar) -> nsresult #c_call;
    SetName:                                            #type (pThis: *IStorageController, name: *PRUnichar) -> nsresult #c_call;

    GetMaxDevicesPerPortCount:                          #type (pThis: *IStorageController, maxDevicesPerPortCount: *PRUint32) -> nsresult #c_call;

    GetMinPortCount:                                    #type (pThis: *IStorageController, minPortCount: *PRUint32) -> nsresult #c_call;

    GetMaxPortCount:                                    #type (pThis: *IStorageController, maxPortCount: *PRUint32) -> nsresult #c_call;

    GetInstance:                                        #type (pThis: *IStorageController, instance: *PRUint32) -> nsresult #c_call;
    SetInstance:                                        #type (pThis: *IStorageController, instance: PRUint32) -> nsresult #c_call;

    GetPortCount:                                       #type (pThis: *IStorageController, portCount: *PRUint32) -> nsresult #c_call;
    SetPortCount:                                       #type (pThis: *IStorageController, portCount: PRUint32) -> nsresult #c_call;

    GetBus:                                             #type (pThis: *IStorageController, bus: *PRUint32) -> nsresult #c_call;

    GetControllerType:                                  #type (pThis: *IStorageController, controllerType: *PRUint32) -> nsresult #c_call;
    SetControllerType:                                  #type (pThis: *IStorageController, controllerType: PRUint32) -> nsresult #c_call;

    GetUseHostIOCache:                                  #type (pThis: *IStorageController, useHostIOCache: *PRBool) -> nsresult #c_call;
    SetUseHostIOCache:                                  #type (pThis: *IStorageController, useHostIOCache: PRBool) -> nsresult #c_call;

    GetBootable:                                        #type (pThis: *IStorageController, bootable: *PRBool) -> nsresult #c_call;

    GetInternalAndReservedAttribute1IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute2IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute3IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute4IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute5IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute6IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute7IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    GetInternalAndReservedAttribute8IStorageController: #type (pThis: *IStorageController, reserved: *PRUint32) -> nsresult #c_call;

    InternalAndReservedMethod1IStorageController:       #type (pThis: *IStorageController) -> nsresult #c_call;

    InternalAndReservedMethod2IStorageController:       #type (pThis: *IStorageController) -> nsresult #c_call;

    InternalAndReservedMethod3IStorageController:       #type (pThis: *IStorageController) -> nsresult #c_call;

    InternalAndReservedMethod4IStorageController:       #type (pThis: *IStorageController) -> nsresult #c_call;
}

nsIException :: struct {}
nsISupports :: struct {}
nsIStackFrame :: struct {}

// typedef struct nsIException nsIException;
IVirtualBoxErrorInfoVtbl :: struct {
    QueryInterface:  #type (pThis: *IVirtualBoxErrorInfo, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:          #type (pThis: *IVirtualBoxErrorInfo) -> nsrefcnt #c_call;
    Release:         #type (pThis: *IVirtualBoxErrorInfo) -> nsrefcnt #c_call;
    GetMessageA:     #type (pThis: *IVirtualBoxErrorInfo, aMessage: **PRUnichar) -> nsresult #c_call;
    GetResult:       #type (pThis: *IVirtualBoxErrorInfo, aResult: *nsresult) -> nsresult #c_call;
    GetName:         #type (pThis: *IVirtualBoxErrorInfo, aName: **PRUnichar) -> nsresult #c_call;
    GetFilename:     #type (pThis: *IVirtualBoxErrorInfo, aFilename: **PRUnichar) -> nsresult #c_call;
    GetLineNumber:   #type (pThis: *IVirtualBoxErrorInfo, aLineNumber: *PRUint32) -> nsresult #c_call;
    GetColumnNumber: #type (pThis: *IVirtualBoxErrorInfo, aColumnNumber: *PRUint32) -> nsresult #c_call;
    GetLocation:     #type (pThis: *IVirtualBoxErrorInfo, aLocation: **nsIStackFrame) -> nsresult #c_call;
    GetInner:        #type (pThis: *IVirtualBoxErrorInfo, aInner: **nsIException) -> nsresult #c_call;
    GetData:         #type (pThis: *IVirtualBoxErrorInfo, aData: **nsISupports) -> nsresult #c_call;
    ToString:        #type (pThis: *IVirtualBoxErrorInfo, _retval: **PRUnichar) -> nsresult #c_call;
    GetResultCode:   #type (pThis: *IVirtualBoxErrorInfo, resultCode: *PRInt32) -> nsresult #c_call;

    GetResultDetail: #type (pThis: *IVirtualBoxErrorInfo, resultDetail: *PRInt32) -> nsresult #c_call;

    GetInterfaceID:  #type (pThis: *IVirtualBoxErrorInfo, interfaceID: **PRUnichar) -> nsresult #c_call;

    GetComponent:    #type (pThis: *IVirtualBoxErrorInfo, component: **PRUnichar) -> nsresult #c_call;

    GetText:         #type (pThis: *IVirtualBoxErrorInfo, text: **PRUnichar) -> nsresult #c_call;

    GetNext:         #type (pThis: *IVirtualBoxErrorInfo, next: **IVirtualBoxErrorInfo) -> nsresult #c_call;
}

IErrorInfoVtbl :: struct {
    QueryInterface:  #type (pThis: *nsIException, iid: *nsID, resultp: **void) -> nsresult #c_call;
    AddRef:          #type (pThis: *nsIException) -> nsrefcnt #c_call;
    Release:         #type (pThis: *nsIException) -> nsrefcnt #c_call;

    GetMessageA:     #type (pThis: *nsIException, aMessage: **PRUnichar) -> nsresult #c_call;
    GetResult:       #type (pThis: *nsIException, aResult: *nsresult) -> nsresult #c_call;
    GetName:         #type (pThis: *nsIException, aName: **PRUnichar) -> nsresult #c_call;
    GetFilename:     #type (pThis: *nsIException, aFilename: **PRUnichar) -> nsresult #c_call;
    GetLineNumber:   #type (pThis: *nsIException, aLineNumber: *PRUint32) -> nsresult #c_call;
    GetColumnNumber: #type (pThis: *nsIException, aColumnNumber: *PRUint32) -> nsresult #c_call;
    GetLocation:     #type (pThis: *nsIException, aLocation: **nsIStackFrame) -> nsresult #c_call;
    GetInner:        #type (pThis: *nsIException, aInner: **nsIException) -> nsresult #c_call;
    GetData:         #type (pThis: *nsIException, aData: **nsISupports) -> nsresult #c_call;
    ToString:        #type (pThis: *nsIException, _retval: **PRUnichar) -> nsresult #c_call;
}

#scope_file

