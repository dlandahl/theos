#include <stddef.h>
#include "wchar.h"
#include "Windows.h"

typedef unsigned char PRUint8;
typedef signed char PRInt8;

typedef unsigned short PRUint16;
typedef short PRInt16;

typedef unsigned int PRUint32;
typedef int PRInt32;

typedef long PRInt64;
typedef unsigned long PRUint64;
typedef int PRIntn;
typedef unsigned int PRUintn;

typedef double          PRFloat64;
typedef size_t PRSize;

typedef ptrdiff_t PRPtrdiff;

typedef unsigned long PRUptrdiff;

typedef PRIntn PRBool;

typedef PRUint8 PRPackedBool;

typedef wchar_t PRUnichar;
typedef long PRWord;
typedef unsigned long PRUword;
typedef PRUnichar *BSTR;
typedef const PRUnichar *CBSTR;
typedef PRUint32 nsresult;
typedef PRUint32 nsrefcnt;

typedef struct nsID {
    PRUint32 m0;
    PRUint16 m1;
    PRUint16 m2;
    PRUint8 m3[8];
} nsID;

typedef struct IVirtualBox IVirtualBox;
typedef struct IVirtualBoxClient IVirtualBoxClient;
typedef struct IHost IHost;
typedef struct ISystemProperties ISystemProperties;
typedef struct IMachine IMachine;
typedef struct IMedium IMedium;
typedef struct IProgress IProgress;
typedef struct IGuestOSType IGuestOSType;
typedef struct ISharedFolder ISharedFolder;
typedef struct IPerformanceCollector IPerformanceCollector;
typedef struct IDHCPServer IDHCPServer;
typedef struct INATNetwork INATNetwork;
typedef struct IEventSource IEventSource;
typedef struct IExtPackManager IExtPackManager;
typedef struct IHostOnlyNetwork IHostOnlyNetwork;
typedef struct ICloudNetwork ICloudNetwork;
typedef struct ICloudProviderManager ICloudProviderManager;
typedef struct IAppliance IAppliance;
typedef struct IUnattended IUnattended;
typedef struct IVirtualBoxErrorInfo IVirtualBoxErrorInfo;
typedef struct IGraphicsAdapter IGraphicsAdapter;
typedef struct IBIOSSettings IBIOSSettings;
typedef struct ITrustedPlatformModule ITrustedPlatformModule;
typedef struct INvramStore INvramStore;
typedef struct IRecordingSettings IRecordingSettings;
typedef struct IVRDEServer IVRDEServer;
typedef struct IMediumAttachment IMediumAttachment;
typedef struct IUSBController IUSBController;
typedef struct IUSBDeviceFilters IUSBDeviceFilters;
typedef struct IAudioSettings IAudioSettings;
typedef struct IStorageController IStorageController;
typedef struct ISnapshot ISnapshot;
typedef struct IPCIDeviceAttachment IPCIDeviceAttachment;
typedef struct IBandwidthControl IBandwidthControl;
typedef struct IGuestDebugControl IGuestDebugControl;
typedef struct ISession ISession;
typedef struct IBandwidthGroup IBandwidthGroup;
typedef struct INetworkAdapter INetworkAdapter;
typedef struct ISerialPort ISerialPort;
typedef struct IParallelPort IParallelPort;
typedef struct IVirtualSystemDescription IVirtualSystemDescription;
typedef struct IMediumFormat IMediumFormat;
typedef struct IToken IToken;
typedef struct IToken IToken;
typedef struct IMediumIO IMediumIO;
typedef struct IConsole IConsole;

typedef enum MachineState
{
    MachineState_Null = 0,
    MachineState_PoweredOff = 1,
    MachineState_Saved = 2,
    MachineState_Teleported = 3,
    MachineState_Aborted = 4,
    MachineState_AbortedSaved = 5,
    MachineState_Running = 6,
    MachineState_Paused = 7,
    MachineState_Stuck = 8,
    MachineState_Teleporting = 9,
    MachineState_LiveSnapshotting = 10,
    MachineState_Starting = 11,
    MachineState_Stopping = 12,
    MachineState_Saving = 13,
    MachineState_Restoring = 14,
    MachineState_TeleportingPausedVM = 15,
    MachineState_TeleportingIn = 16,
    MachineState_DeletingSnapshotOnline = 17,
    MachineState_DeletingSnapshotPaused = 18,
    MachineState_OnlineSnapshotting = 19,
    MachineState_RestoringSnapshot = 20,
    MachineState_DeletingSnapshot = 21,
    MachineState_SettingUp = 22,
    MachineState_Snapshotting = 23,
    MachineState_FirstOnline = 6,
    MachineState_LastOnline = 19,
    MachineState_FirstTransient = 9,
    MachineState_LastTransient = 23
} MachineState;
typedef enum DeviceType
{
    DeviceType_Null = 0,
    DeviceType_Floppy = 1,
    DeviceType_DVD = 2,
    DeviceType_HardDisk = 3,
    DeviceType_Network = 4,
    DeviceType_USB = 5,
    DeviceType_SharedFolder = 6,
    DeviceType_Graphics3D = 7,
    DeviceType_End = 8
} DeviceType;
typedef enum BIOSBootMenuMode
{
    BIOSBootMenuMode_Disabled = 0,
    BIOSBootMenuMode_MenuOnly = 1,
    BIOSBootMenuMode_MessageAndMenu = 2
} BIOSBootMenuMode;
typedef enum FirmwareType
{
    FirmwareType_BIOS = 1,
    FirmwareType_EFI = 2,
    FirmwareType_EFI32 = 3,
    FirmwareType_EFI64 = 4,
    FirmwareType_EFIDUAL = 5
} FirmwareType;
typedef enum TpmType
{
    TpmType_None = 0,
    TpmType_v1_2 = 1,
    TpmType_v2_0 = 2,
    TpmType_Host = 3,
    TpmType_Swtpm = 4
} TpmType;
typedef enum AutostopType
{
    AutostopType_Disabled = 1,
    AutostopType_SaveState = 2,
    AutostopType_PowerOff = 3,
    AutostopType_AcpiShutdown = 4
} AutostopType;

struct IVirtualBoxVtbl
{
    nsresult (*QueryInterface)(IVirtualBox *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IVirtualBox *pThis);
    nsrefcnt (*Release)(IVirtualBox *pThis);
    nsresult (*GetVersion)(IVirtualBox *pThis, PRUnichar * *version);

    nsresult (*GetVersionNormalized)(IVirtualBox *pThis, PRUnichar * *versionNormalized);

    nsresult (*GetRevision)(IVirtualBox *pThis, PRUint32 *revision);

    nsresult (*GetPackageType)(IVirtualBox *pThis, PRUnichar * *packageType);

    nsresult (*GetAPIVersion)(IVirtualBox *pThis, PRUnichar * *APIVersion);

    nsresult (*GetAPIRevision)(IVirtualBox *pThis, PRInt64 *APIRevision);

    nsresult (*GetHomeFolder)(IVirtualBox *pThis, PRUnichar * *homeFolder);

    nsresult (*GetSettingsFilePath)(IVirtualBox *pThis, PRUnichar * *settingsFilePath);

    nsresult (*GetHost)(IVirtualBox *pThis, IHost * *host);

    nsresult (*GetSystemProperties)(IVirtualBox *pThis, ISystemProperties * *systemProperties);

    nsresult (*GetMachines)(IVirtualBox *pThis, PRUint32 *machinesSize, IMachine * **machines);

    nsresult (*GetMachineGroups)(IVirtualBox *pThis, PRUint32 *machineGroupsSize, PRUnichar * **machineGroups);

    nsresult (*GetHardDisks)(IVirtualBox *pThis, PRUint32 *hardDisksSize, IMedium * **hardDisks);

    nsresult (*GetDVDImages)(IVirtualBox *pThis, PRUint32 *DVDImagesSize, IMedium * **DVDImages);

    nsresult (*GetFloppyImages)(IVirtualBox *pThis, PRUint32 *floppyImagesSize, IMedium * **floppyImages);

    nsresult (*GetProgressOperations)(IVirtualBox *pThis, PRUint32 *progressOperationsSize, IProgress * **progressOperations);

    nsresult (*GetGuestOSTypes)(IVirtualBox *pThis, PRUint32 *guestOSTypesSize, IGuestOSType * **guestOSTypes);

    nsresult (*GetSharedFolders)(IVirtualBox *pThis, PRUint32 *sharedFoldersSize, ISharedFolder * **sharedFolders);

    nsresult (*GetPerformanceCollector)(IVirtualBox *pThis, IPerformanceCollector * *performanceCollector);

    nsresult (*GetDHCPServers)(IVirtualBox *pThis, PRUint32 *DHCPServersSize, IDHCPServer * **DHCPServers);

    nsresult (*GetNATNetworks)(IVirtualBox *pThis, PRUint32 *NATNetworksSize, INATNetwork * **NATNetworks);

    nsresult (*GetEventSource)(IVirtualBox *pThis, IEventSource * *eventSource);

    nsresult (*GetExtensionPackManager)(IVirtualBox *pThis, IExtPackManager * *extensionPackManager);

    nsresult (*GetInternalNetworks)(IVirtualBox *pThis, PRUint32 *internalNetworksSize, PRUnichar * **internalNetworks);

    nsresult (*GetHostOnlyNetworks)(IVirtualBox *pThis, PRUint32 *hostOnlyNetworksSize, IHostOnlyNetwork * **hostOnlyNetworks);

    nsresult (*GetGenericNetworkDrivers)(IVirtualBox *pThis, PRUint32 *genericNetworkDriversSize, PRUnichar * **genericNetworkDrivers);

    nsresult (*GetCloudNetworks)(IVirtualBox *pThis, PRUint32 *cloudNetworksSize, ICloudNetwork * **cloudNetworks);

    nsresult (*GetCloudProviderManager)(IVirtualBox *pThis, ICloudProviderManager * *cloudProviderManager);

    nsresult (*GetInternalAndReservedAttribute1IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute3IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute4IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute5IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute6IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute7IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute8IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute9IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute10IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute11IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute12IVirtualBox)(IVirtualBox *pThis, PRUint32 *reserved);

    nsresult (*ComposeMachineFilename)(
        IVirtualBox *pThis,
        PRUnichar * name,
        PRUnichar * group,
        PRUnichar * createFlags,
        PRUnichar * baseFolder,
        PRUnichar * * file
    );

    nsresult (*CreateMachine)(
        IVirtualBox *pThis,
        PRUnichar * settingsFile,
        PRUnichar * name,
        PRUint32 groupsSize,
        PRUnichar ** groups,
        PRUnichar * osTypeId,
        PRUnichar * flags,
        PRUnichar * cipher,
        PRUnichar * passwordId,
        PRUnichar * password,
        IMachine * * machine
    );

    nsresult (*OpenMachine)(
        IVirtualBox *pThis,
        PRUnichar * settingsFile,
        PRUnichar * password,
        IMachine * * machine
    );

    nsresult (*RegisterMachine)(
        IVirtualBox *pThis,
        IMachine * machine
    );

    nsresult (*FindMachine)(
        IVirtualBox *pThis,
        PRUnichar * nameOrId,
        IMachine * * machine
    );

    nsresult (*GetMachinesByGroups)(
        IVirtualBox *pThis,
        PRUint32 groupsSize,
        PRUnichar ** groups,
        PRUint32 *machinesSize,
        IMachine *** machines
    );

    nsresult (*GetMachineStates)(
        IVirtualBox *pThis,
        PRUint32 machinesSize,
        IMachine ** machines,
        PRUint32 *statesSize,
        PRUint32** states
    );

    nsresult (*CreateAppliance)(
        IVirtualBox *pThis,
        IAppliance * * appliance
    );

    nsresult (*CreateUnattendedInstaller)(
        IVirtualBox *pThis,
        IUnattended * * unattended
    );

    nsresult (*CreateMedium)(
        IVirtualBox *pThis,
        PRUnichar * format,
        PRUnichar * location,
        PRUint32 accessMode,
        PRUint32 aDeviceTypeType,
        IMedium * * medium
    );

    nsresult (*OpenMedium)(
        IVirtualBox *pThis,
        PRUnichar * location,
        PRUint32 deviceType,
        PRUint32 accessMode,
        PRBool forceNewUuid,
        IMedium * * medium
    );

    nsresult (*GetGuestOSType)(
        IVirtualBox *pThis,
        PRUnichar * id,
        IGuestOSType * * type
    );

    nsresult (*CreateSharedFolder)(
        IVirtualBox *pThis,
        PRUnichar * name,
        PRUnichar * hostPath,
        PRBool writable,
        PRBool automount,
        PRUnichar * autoMountPoint
    );

    nsresult (*RemoveSharedFolder)(
        IVirtualBox *pThis,
        PRUnichar * name
    );

    nsresult (*GetExtraDataKeys)(
        IVirtualBox *pThis,
        PRUint32 *keysSize,
        PRUnichar *** keys
    );

    nsresult (*GetExtraData)(
        IVirtualBox *pThis,
        PRUnichar * key,
        PRUnichar * * value
    );

    nsresult (*SetExtraData)(
        IVirtualBox *pThis,
        PRUnichar * key,
        PRUnichar * value
    );

    nsresult (*SetSettingsSecret)(
        IVirtualBox *pThis,
        PRUnichar * password
    );

    nsresult (*CreateDHCPServer)(
        IVirtualBox *pThis,
        PRUnichar * name,
        IDHCPServer * * server
    );

    nsresult (*FindDHCPServerByNetworkName)(
        IVirtualBox *pThis,
        PRUnichar * name,
        IDHCPServer * * server
    );

    nsresult (*RemoveDHCPServer)(
        IVirtualBox *pThis,
        IDHCPServer * server
    );

    nsresult (*CreateNATNetwork)(
        IVirtualBox *pThis,
        PRUnichar * networkName,
        INATNetwork * * network
    );

    nsresult (*FindNATNetworkByName)(
        IVirtualBox *pThis,
        PRUnichar * networkName,
        INATNetwork * * network
    );

    nsresult (*RemoveNATNetwork)(
        IVirtualBox *pThis,
        INATNetwork * network
    );

    nsresult (*CreateHostOnlyNetwork)(
        IVirtualBox *pThis,
        PRUnichar * networkName,
        IHostOnlyNetwork * * network
    );

    nsresult (*FindHostOnlyNetworkByName)(
        IVirtualBox *pThis,
        PRUnichar * networkName,
        IHostOnlyNetwork * * network
    );

    nsresult (*FindHostOnlyNetworkById)(
        IVirtualBox *pThis,
        PRUnichar * id,
        IHostOnlyNetwork * * network
    );

    nsresult (*RemoveHostOnlyNetwork)(
        IVirtualBox *pThis,
        IHostOnlyNetwork * network
    );

    nsresult (*CreateCloudNetwork)(
        IVirtualBox *pThis,
        PRUnichar * networkName,
        ICloudNetwork * * network
    );

    nsresult (*FindCloudNetworkByName)(
        IVirtualBox *pThis,
        PRUnichar * networkName,
        ICloudNetwork * * network
    );

    nsresult (*RemoveCloudNetwork)(
        IVirtualBox *pThis,
        ICloudNetwork * network
    );

    nsresult (*CheckFirmwarePresent)(
        IVirtualBox *pThis,
        PRUint32 firmwareType,
        PRUnichar * version,
        PRUnichar * * url,
        PRUnichar * * file,
        PRBool * result
    );

    nsresult (*FindProgressById)(
        IVirtualBox *pThis,
        PRUnichar * id,
        IProgress * * progressObject
    );

    nsresult (*InternalAndReservedMethod1IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod2IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod3IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod4IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod5IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod6IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod7IVirtualBox)(IVirtualBox *pThis);

    nsresult (*InternalAndReservedMethod8IVirtualBox)(IVirtualBox *pThis);

};
struct IMachineVtbl
{
    nsresult (*QueryInterface)(IMachine *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IMachine *pThis);
    nsrefcnt (*Release)(IMachine *pThis);
    nsresult (*GetParent)(IMachine *pThis, IVirtualBox * *parent);

    nsresult (*GetIcon)(IMachine *pThis, PRUint32 *iconSize, PRUint8 **icon);
    nsresult (*SetIcon)(IMachine *pThis, PRUint32 iconSize, PRUint8 *icon);

    nsresult (*GetAccessible)(IMachine *pThis, PRBool *accessible);

    nsresult (*GetAccessError)(IMachine *pThis, IVirtualBoxErrorInfo * *accessError);

    nsresult (*GetName)(IMachine *pThis, PRUnichar * *name);
    nsresult (*SetName)(IMachine *pThis, PRUnichar * name);

    nsresult (*GetDescription)(IMachine *pThis, PRUnichar * *description);
    nsresult (*SetDescription)(IMachine *pThis, PRUnichar * description);

    nsresult (*GetId)(IMachine *pThis, PRUnichar * *id);

    nsresult (*GetGroups)(IMachine *pThis, PRUint32 *groupsSize, PRUnichar * **groups);
    nsresult (*SetGroups)(IMachine *pThis, PRUint32 groupsSize, PRUnichar * *groups);

    nsresult (*GetOSTypeId)(IMachine *pThis, PRUnichar * *OSTypeId);
    nsresult (*SetOSTypeId)(IMachine *pThis, PRUnichar * OSTypeId);

    nsresult (*GetHardwareVersion)(IMachine *pThis, PRUnichar * *hardwareVersion);
    nsresult (*SetHardwareVersion)(IMachine *pThis, PRUnichar * hardwareVersion);

    nsresult (*GetHardwareUUID)(IMachine *pThis, PRUnichar * *hardwareUUID);
    nsresult (*SetHardwareUUID)(IMachine *pThis, PRUnichar * hardwareUUID);

    nsresult (*GetCPUCount)(IMachine *pThis, PRUint32 *CPUCount);
    nsresult (*SetCPUCount)(IMachine *pThis, PRUint32 CPUCount);

    nsresult (*GetCPUHotPlugEnabled)(IMachine *pThis, PRBool *CPUHotPlugEnabled);
    nsresult (*SetCPUHotPlugEnabled)(IMachine *pThis, PRBool CPUHotPlugEnabled);

    nsresult (*GetCPUExecutionCap)(IMachine *pThis, PRUint32 *CPUExecutionCap);
    nsresult (*SetCPUExecutionCap)(IMachine *pThis, PRUint32 CPUExecutionCap);

    nsresult (*GetCPUIDPortabilityLevel)(IMachine *pThis, PRUint32 *CPUIDPortabilityLevel);
    nsresult (*SetCPUIDPortabilityLevel)(IMachine *pThis, PRUint32 CPUIDPortabilityLevel);

    nsresult (*GetMemorySize)(IMachine *pThis, PRUint32 *memorySize);
    nsresult (*SetMemorySize)(IMachine *pThis, PRUint32 memorySize);

    nsresult (*GetMemoryBalloonSize)(IMachine *pThis, PRUint32 *memoryBalloonSize);
    nsresult (*SetMemoryBalloonSize)(IMachine *pThis, PRUint32 memoryBalloonSize);

    nsresult (*GetPageFusionEnabled)(IMachine *pThis, PRBool *pageFusionEnabled);
    nsresult (*SetPageFusionEnabled)(IMachine *pThis, PRBool pageFusionEnabled);

    nsresult (*GetGraphicsAdapter)(IMachine *pThis, IGraphicsAdapter * *graphicsAdapter);

    nsresult (*GetBIOSSettings)(IMachine *pThis, IBIOSSettings * *BIOSSettings);

    nsresult (*GetTrustedPlatformModule)(IMachine *pThis, ITrustedPlatformModule * *trustedPlatformModule);

    nsresult (*GetNonVolatileStore)(IMachine *pThis, INvramStore * *nonVolatileStore);

    nsresult (*GetRecordingSettings)(IMachine *pThis, IRecordingSettings * *recordingSettings);

    nsresult (*GetFirmwareType)(IMachine *pThis, PRUint32 *firmwareType);
    nsresult (*SetFirmwareType)(IMachine *pThis, PRUint32 firmwareType);

    nsresult (*GetPointingHIDType)(IMachine *pThis, PRUint32 *pointingHIDType);
    nsresult (*SetPointingHIDType)(IMachine *pThis, PRUint32 pointingHIDType);

    nsresult (*GetKeyboardHIDType)(IMachine *pThis, PRUint32 *keyboardHIDType);
    nsresult (*SetKeyboardHIDType)(IMachine *pThis, PRUint32 keyboardHIDType);

    nsresult (*GetHPETEnabled)(IMachine *pThis, PRBool *HPETEnabled);
    nsresult (*SetHPETEnabled)(IMachine *pThis, PRBool HPETEnabled);

    nsresult (*GetChipsetType)(IMachine *pThis, PRUint32 *chipsetType);
    nsresult (*SetChipsetType)(IMachine *pThis, PRUint32 chipsetType);

    nsresult (*GetIommuType)(IMachine *pThis, PRUint32 *iommuType);
    nsresult (*SetIommuType)(IMachine *pThis, PRUint32 iommuType);

    nsresult (*GetSnapshotFolder)(IMachine *pThis, PRUnichar * *snapshotFolder);
    nsresult (*SetSnapshotFolder)(IMachine *pThis, PRUnichar * snapshotFolder);

    nsresult (*GetVRDEServer)(IMachine *pThis, IVRDEServer * *VRDEServer);

    nsresult (*GetEmulatedUSBCardReaderEnabled)(IMachine *pThis, PRBool *emulatedUSBCardReaderEnabled);
    nsresult (*SetEmulatedUSBCardReaderEnabled)(IMachine *pThis, PRBool emulatedUSBCardReaderEnabled);

    nsresult (*GetMediumAttachments)(IMachine *pThis, PRUint32 *mediumAttachmentsSize, IMediumAttachment * **mediumAttachments);

    nsresult (*GetUSBControllers)(IMachine *pThis, PRUint32 *USBControllersSize, IUSBController * **USBControllers);

    nsresult (*GetUSBDeviceFilters)(IMachine *pThis, IUSBDeviceFilters * *USBDeviceFilters);

    nsresult (*GetAudioSettings)(IMachine *pThis, IAudioSettings * *audioSettings);

    nsresult (*GetStorageControllers)(IMachine *pThis, PRUint32 *storageControllersSize, IStorageController * **storageControllers);

    nsresult (*GetSettingsFilePath)(IMachine *pThis, PRUnichar * *settingsFilePath);

    nsresult (*GetSettingsAuxFilePath)(IMachine *pThis, PRUnichar * *settingsAuxFilePath);

    nsresult (*GetSettingsModified)(IMachine *pThis, PRBool *settingsModified);

    nsresult (*GetSessionState)(IMachine *pThis, PRUint32 *sessionState);

    nsresult (*GetSessionName)(IMachine *pThis, PRUnichar * *sessionName);

    nsresult (*GetSessionPID)(IMachine *pThis, PRUint32 *sessionPID);

    nsresult (*GetState)(IMachine *pThis, PRUint32 *state);

    nsresult (*GetLastStateChange)(IMachine *pThis, PRInt64 *lastStateChange);

    nsresult (*GetStateFilePath)(IMachine *pThis, PRUnichar * *stateFilePath);

    nsresult (*GetLogFolder)(IMachine *pThis, PRUnichar * *logFolder);

    nsresult (*GetCurrentSnapshot)(IMachine *pThis, ISnapshot * *currentSnapshot);

    nsresult (*GetSnapshotCount)(IMachine *pThis, PRUint32 *snapshotCount);

    nsresult (*GetCurrentStateModified)(IMachine *pThis, PRBool *currentStateModified);

    nsresult (*GetSharedFolders)(IMachine *pThis, PRUint32 *sharedFoldersSize, ISharedFolder * **sharedFolders);

    nsresult (*GetClipboardMode)(IMachine *pThis, PRUint32 *clipboardMode);
    nsresult (*SetClipboardMode)(IMachine *pThis, PRUint32 clipboardMode);

    nsresult (*GetClipboardFileTransfersEnabled)(IMachine *pThis, PRBool *clipboardFileTransfersEnabled);
    nsresult (*SetClipboardFileTransfersEnabled)(IMachine *pThis, PRBool clipboardFileTransfersEnabled);

    nsresult (*GetDnDMode)(IMachine *pThis, PRUint32 *dnDMode);
    nsresult (*SetDnDMode)(IMachine *pThis, PRUint32 dnDMode);

    nsresult (*GetTeleporterEnabled)(IMachine *pThis, PRBool *teleporterEnabled);
    nsresult (*SetTeleporterEnabled)(IMachine *pThis, PRBool teleporterEnabled);

    nsresult (*GetTeleporterPort)(IMachine *pThis, PRUint32 *teleporterPort);
    nsresult (*SetTeleporterPort)(IMachine *pThis, PRUint32 teleporterPort);

    nsresult (*GetTeleporterAddress)(IMachine *pThis, PRUnichar * *teleporterAddress);
    nsresult (*SetTeleporterAddress)(IMachine *pThis, PRUnichar * teleporterAddress);

    nsresult (*GetTeleporterPassword)(IMachine *pThis, PRUnichar * *teleporterPassword);
    nsresult (*SetTeleporterPassword)(IMachine *pThis, PRUnichar * teleporterPassword);

    nsresult (*GetParavirtProvider)(IMachine *pThis, PRUint32 *paravirtProvider);
    nsresult (*SetParavirtProvider)(IMachine *pThis, PRUint32 paravirtProvider);

    nsresult (*GetRTCUseUTC)(IMachine *pThis, PRBool *RTCUseUTC);
    nsresult (*SetRTCUseUTC)(IMachine *pThis, PRBool RTCUseUTC);

    nsresult (*GetIOCacheEnabled)(IMachine *pThis, PRBool *IOCacheEnabled);
    nsresult (*SetIOCacheEnabled)(IMachine *pThis, PRBool IOCacheEnabled);

    nsresult (*GetIOCacheSize)(IMachine *pThis, PRUint32 *IOCacheSize);
    nsresult (*SetIOCacheSize)(IMachine *pThis, PRUint32 IOCacheSize);

    nsresult (*GetPCIDeviceAssignments)(IMachine *pThis, PRUint32 *PCIDeviceAssignmentsSize, IPCIDeviceAttachment * **PCIDeviceAssignments);

    nsresult (*GetBandwidthControl)(IMachine *pThis, IBandwidthControl * *bandwidthControl);

    nsresult (*GetTracingEnabled)(IMachine *pThis, PRBool *tracingEnabled);
    nsresult (*SetTracingEnabled)(IMachine *pThis, PRBool tracingEnabled);

    nsresult (*GetTracingConfig)(IMachine *pThis, PRUnichar * *tracingConfig);
    nsresult (*SetTracingConfig)(IMachine *pThis, PRUnichar * tracingConfig);

    nsresult (*GetAllowTracingToAccessVM)(IMachine *pThis, PRBool *allowTracingToAccessVM);
    nsresult (*SetAllowTracingToAccessVM)(IMachine *pThis, PRBool allowTracingToAccessVM);

    nsresult (*GetAutostartEnabled)(IMachine *pThis, PRBool *autostartEnabled);
    nsresult (*SetAutostartEnabled)(IMachine *pThis, PRBool autostartEnabled);

    nsresult (*GetAutostartDelay)(IMachine *pThis, PRUint32 *autostartDelay);
    nsresult (*SetAutostartDelay)(IMachine *pThis, PRUint32 autostartDelay);

    nsresult (*GetAutostopType)(IMachine *pThis, PRUint32 *autostopType);
    nsresult (*SetAutostopType)(IMachine *pThis, PRUint32 autostopType);

    nsresult (*GetDefaultFrontend)(IMachine *pThis, PRUnichar * *defaultFrontend);
    nsresult (*SetDefaultFrontend)(IMachine *pThis, PRUnichar * defaultFrontend);

    nsresult (*GetUSBProxyAvailable)(IMachine *pThis, PRBool *USBProxyAvailable);

    nsresult (*GetVMProcessPriority)(IMachine *pThis, PRUint32 *VMProcessPriority);
    nsresult (*SetVMProcessPriority)(IMachine *pThis, PRUint32 VMProcessPriority);

    nsresult (*GetParavirtDebug)(IMachine *pThis, PRUnichar * *paravirtDebug);
    nsresult (*SetParavirtDebug)(IMachine *pThis, PRUnichar * paravirtDebug);

    nsresult (*GetCPUProfile)(IMachine *pThis, PRUnichar * *CPUProfile);
    nsresult (*SetCPUProfile)(IMachine *pThis, PRUnichar * CPUProfile);

    nsresult (*GetStateKeyId)(IMachine *pThis, PRUnichar * *stateKeyId);

    nsresult (*GetStateKeyStore)(IMachine *pThis, PRUnichar * *stateKeyStore);

    nsresult (*GetLogKeyId)(IMachine *pThis, PRUnichar * *logKeyId);

    nsresult (*GetLogKeyStore)(IMachine *pThis, PRUnichar * *logKeyStore);

    nsresult (*GetGuestDebugControl)(IMachine *pThis, IGuestDebugControl * *guestDebugControl);

    nsresult (*GetInternalAndReservedAttribute1IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute3IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute4IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute5IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute6IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute7IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute8IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute9IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute10IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute11IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute12IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute13IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute14IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute15IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute16IMachine)(IMachine *pThis, PRUint32 *reserved);

    nsresult (*LockMachine)(
        IMachine *pThis,
        ISession * session,
        PRUint32 lockType
    );

    nsresult (*LaunchVMProcess)(
        IMachine *pThis,
        ISession * session,
        PRUnichar * name,
        PRUint32 environmentChangesSize,
        PRUnichar ** environmentChanges,
        IProgress * * progress
    );

    nsresult (*SetBootOrder)(
        IMachine *pThis,
        PRUint32 position,
        PRUint32 device
    );

    nsresult (*GetBootOrder)(
        IMachine *pThis,
        PRUint32 position,
        PRUint32 * device
    );

    nsresult (*AttachDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRUint32 type,
        IMedium * medium
    );

    nsresult (*AttachDeviceWithoutMedium)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRUint32 type
    );

    nsresult (*DetachDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device
    );

    nsresult (*PassthroughDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRBool passthrough
    );

    nsresult (*TemporaryEjectDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRBool temporaryEject
    );

    nsresult (*NonRotationalDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRBool nonRotational
    );

    nsresult (*SetAutoDiscardForDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRBool discard
    );

    nsresult (*SetHotPluggableForDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRBool hotPluggable
    );

    nsresult (*SetBandwidthGroupForDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        IBandwidthGroup * bandwidthGroup
    );

    nsresult (*SetNoBandwidthGroupForDevice)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device
    );

    nsresult (*UnmountMedium)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        PRBool force
    );

    nsresult (*MountMedium)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        IMedium * medium,
        PRBool force
    );

    nsresult (*GetMedium)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        IMedium * * medium
    );

    nsresult (*GetMediumAttachmentsOfController)(
        IMachine *pThis,
        PRUnichar * name,
        PRUint32 *mediumAttachmentsSize,
        IMediumAttachment *** mediumAttachments
    );

    nsresult (*GetMediumAttachment)(
        IMachine *pThis,
        PRUnichar * name,
        PRInt32 controllerPort,
        PRInt32 device,
        IMediumAttachment * * attachment
    );

    nsresult (*AttachHostPCIDevice)(
        IMachine *pThis,
        PRInt32 hostAddress,
        PRInt32 desiredGuestAddress,
        PRBool tryToUnbind
    );

    nsresult (*DetachHostPCIDevice)(
        IMachine *pThis,
        PRInt32 hostAddress
    );

    nsresult (*GetNetworkAdapter)(
        IMachine *pThis,
        PRUint32 slot,
        INetworkAdapter * * adapter
    );

    nsresult (*AddStorageController)(
        IMachine *pThis,
        PRUnichar * name,
        PRUint32 connectionType,
        IStorageController * * controller
    );

    nsresult (*GetStorageControllerByName)(
        IMachine *pThis,
        PRUnichar * name,
        IStorageController * * storageController
    );

    nsresult (*GetStorageControllerByInstance)(
        IMachine *pThis,
        PRUint32 connectionType,
        PRUint32 instance,
        IStorageController * * storageController
    );

    nsresult (*RemoveStorageController)(
        IMachine *pThis,
        PRUnichar * name
    );

    nsresult (*SetStorageControllerBootable)(
        IMachine *pThis,
        PRUnichar * name,
        PRBool bootable
    );

    nsresult (*AddUSBController)(
        IMachine *pThis,
        PRUnichar * name,
        PRUint32 type,
        IUSBController * * controller
    );

    nsresult (*RemoveUSBController)(
        IMachine *pThis,
        PRUnichar * name
    );

    nsresult (*GetUSBControllerByName)(
        IMachine *pThis,
        PRUnichar * name,
        IUSBController * * controller
    );

    nsresult (*GetUSBControllerCountByType)(
        IMachine *pThis,
        PRUint32 type,
        PRUint32 * controllers
    );

    nsresult (*GetSerialPort)(
        IMachine *pThis,
        PRUint32 slot,
        ISerialPort * * port
    );

    nsresult (*GetParallelPort)(
        IMachine *pThis,
        PRUint32 slot,
        IParallelPort * * port
    );

    nsresult (*GetExtraDataKeys)(
        IMachine *pThis,
        PRUint32 *keysSize,
        PRUnichar *** keys
    );

    nsresult (*GetExtraData)(
        IMachine *pThis,
        PRUnichar * key,
        PRUnichar * * value
    );

    nsresult (*SetExtraData)(
        IMachine *pThis,
        PRUnichar * key,
        PRUnichar * value
    );

    nsresult (*GetCPUProperty)(
        IMachine *pThis,
        PRUint32 property,
        PRBool * value
    );

    nsresult (*SetCPUProperty)(
        IMachine *pThis,
        PRUint32 property,
        PRBool value
    );

    nsresult (*GetCPUIDLeafByOrdinal)(
        IMachine *pThis,
        PRUint32 ordinal,
        PRUint32 * idx,
        PRUint32 * idxSub,
        PRUint32 * valEax,
        PRUint32 * valEbx,
        PRUint32 * valEcx,
        PRUint32 * valEdx
    );

    nsresult (*GetCPUIDLeaf)(
        IMachine *pThis,
        PRUint32 idx,
        PRUint32 idxSub,
        PRUint32 * valEax,
        PRUint32 * valEbx,
        PRUint32 * valEcx,
        PRUint32 * valEdx
    );

    nsresult (*SetCPUIDLeaf)(
        IMachine *pThis,
        PRUint32 idx,
        PRUint32 idxSub,
        PRUint32 valEax,
        PRUint32 valEbx,
        PRUint32 valEcx,
        PRUint32 valEdx
    );

    nsresult (*RemoveCPUIDLeaf)(
        IMachine *pThis,
        PRUint32 idx,
        PRUint32 idxSub
    );

    nsresult (*RemoveAllCPUIDLeaves)(IMachine *pThis );

    nsresult (*GetHWVirtExProperty)(
        IMachine *pThis,
        PRUint32 property,
        PRBool * value
    );

    nsresult (*SetHWVirtExProperty)(
        IMachine *pThis,
        PRUint32 property,
        PRBool value
    );

    nsresult (*SetSettingsFilePath)(
        IMachine *pThis,
        PRUnichar * settingsFilePath,
        IProgress * * progress
    );

    nsresult (*SaveSettings)(IMachine *pThis );

    nsresult (*DiscardSettings)(IMachine *pThis );

    nsresult (*Unregister)(
        IMachine *pThis,
        PRUint32 cleanupMode,
        PRUint32 *mediaSize,
        IMedium *** media
    );

    nsresult (*DeleteConfig)(
        IMachine *pThis,
        PRUint32 mediaSize,
        IMedium ** media,
        IProgress * * progress
    );

    nsresult (*ExportTo)(
        IMachine *pThis,
        IAppliance * appliance,
        PRUnichar * location,
        IVirtualSystemDescription * * description
    );

    nsresult (*FindSnapshot)(
        IMachine *pThis,
        PRUnichar * nameOrId,
        ISnapshot * * snapshot
    );

    nsresult (*CreateSharedFolder)(
        IMachine *pThis,
        PRUnichar * name,
        PRUnichar * hostPath,
        PRBool writable,
        PRBool automount,
        PRUnichar * autoMountPoint
    );

    nsresult (*RemoveSharedFolder)(
        IMachine *pThis,
        PRUnichar * name
    );

    nsresult (*CanShowConsoleWindow)(
        IMachine *pThis,
        PRBool * canShow
    );

    nsresult (*ShowConsoleWindow)(
        IMachine *pThis,
        PRInt64 * winId
    );

    nsresult (*GetGuestProperty)(
        IMachine *pThis,
        PRUnichar * name,
        PRUnichar * * value,
        PRInt64 * timestamp,
        PRUnichar * * flags
    );

    nsresult (*GetGuestPropertyValue)(
        IMachine *pThis,
        PRUnichar * property,
        PRUnichar * * value
    );

    nsresult (*GetGuestPropertyTimestamp)(
        IMachine *pThis,
        PRUnichar * property,
        PRInt64 * value
    );

    nsresult (*SetGuestProperty)(
        IMachine *pThis,
        PRUnichar * property,
        PRUnichar * value,
        PRUnichar * flags
    );

    nsresult (*SetGuestPropertyValue)(
        IMachine *pThis,
        PRUnichar * property,
        PRUnichar * value
    );

    nsresult (*DeleteGuestProperty)(
        IMachine *pThis,
        PRUnichar * name
    );

    nsresult (*EnumerateGuestProperties)(
        IMachine *pThis,
        PRUnichar * patterns,
        PRUint32 *namesSize,
        PRUnichar *** names,
        PRUint32 *valuesSize,
        PRUnichar *** values,
        PRUint32 *timestampsSize,
        PRInt64** timestamps,
        PRUint32 *flagsSize,
        PRUnichar *** flags
    );

    nsresult (*QuerySavedGuestScreenInfo)(
        IMachine *pThis,
        PRUint32 screenId,
        PRUint32 * originX,
        PRUint32 * originY,
        PRUint32 * width,
        PRUint32 * height,
        PRBool * enabled
    );

    nsresult (*ReadSavedThumbnailToArray)(
        IMachine *pThis,
        PRUint32 screenId,
        PRUint32 bitmapFormat,
        PRUint32 * width,
        PRUint32 * height,
        PRUint32 *dataSize,
        PRUint8** data
    );

    nsresult (*QuerySavedScreenshotInfo)(
        IMachine *pThis,
        PRUint32 screenId,
        PRUint32 * width,
        PRUint32 * height,
        PRUint32 *bitmapFormatsSize,
        PRUint32** bitmapFormats
    );

    nsresult (*ReadSavedScreenshotToArray)(
        IMachine *pThis,
        PRUint32 screenId,
        PRUint32 bitmapFormat,
        PRUint32 * width,
        PRUint32 * height,
        PRUint32 *dataSize,
        PRUint8** data
    );

    nsresult (*HotPlugCPU)(
        IMachine *pThis,
        PRUint32 cpu
    );

    nsresult (*HotUnplugCPU)(
        IMachine *pThis,
        PRUint32 cpu
    );

    nsresult (*GetCPUStatus)(
        IMachine *pThis,
        PRUint32 cpu,
        PRBool * attached
    );

    nsresult (*GetEffectiveParavirtProvider)(
        IMachine *pThis,
        PRUint32 * paravirtProvider
    );

    nsresult (*QueryLogFilename)(
        IMachine *pThis,
        PRUint32 idx,
        PRUnichar * * filename
    );

    nsresult (*ReadLog)(
        IMachine *pThis,
        PRUint32 idx,
        PRInt64 offset,
        PRInt64 size,
        PRUint32 *dataSize,
        PRUint8** data
    );

    nsresult (*CloneTo)(
        IMachine *pThis,
        IMachine * target,
        PRUint32 mode,
        PRUint32 optionsSize,
        PRUint32* options,
        IProgress * * progress
    );

    nsresult (*MoveTo)(
        IMachine *pThis,
        PRUnichar * folder,
        PRUnichar * type,
        IProgress * * progress
    );

    nsresult (*SaveState)(
        IMachine *pThis,
        IProgress * * progress
    );

    nsresult (*AdoptSavedState)(
        IMachine *pThis,
        PRUnichar * savedStateFile
    );

    nsresult (*DiscardSavedState)(
        IMachine *pThis,
        PRBool fRemoveFile
    );

    nsresult (*TakeSnapshot)(
        IMachine *pThis,
        PRUnichar * name,
        PRUnichar * description,
        PRBool pause,
        PRUnichar * * id,
        IProgress * * progress
    );

    nsresult (*DeleteSnapshot)(
        IMachine *pThis,
        PRUnichar * id,
        IProgress * * progress
    );

    nsresult (*DeleteSnapshotAndAllChildren)(
        IMachine *pThis,
        PRUnichar * id,
        IProgress * * progress
    );

    nsresult (*DeleteSnapshotRange)(
        IMachine *pThis,
        PRUnichar * startId,
        PRUnichar * endId,
        IProgress * * progress
    );

    nsresult (*RestoreSnapshot)(
        IMachine *pThis,
        ISnapshot * snapshot,
        IProgress * * progress
    );

    nsresult (*ApplyDefaults)(
        IMachine *pThis,
        PRUnichar * flags
    );

    nsresult (*ChangeEncryption)(
        IMachine *pThis,
        PRUnichar * currentPassword,
        PRUnichar * cipher,
        PRUnichar * newPassword,
        PRUnichar * newPasswordId,
        PRBool force,
        IProgress * * progress
    );

    nsresult (*GetEncryptionSettings)(
        IMachine *pThis,
        PRUnichar * * cipher,
        PRUnichar * * passwordId
    );

    nsresult (*CheckEncryptionPassword)(
        IMachine *pThis,
        PRUnichar * password
    );

    nsresult (*AddEncryptionPassword)(
        IMachine *pThis,
        PRUnichar * id,
        PRUnichar * password
    );

    nsresult (*AddEncryptionPasswords)(
        IMachine *pThis,
        PRUint32 idsSize,
        PRUnichar ** ids,
        PRUint32 passwordsSize,
        PRUnichar ** passwords
    );

    nsresult (*RemoveEncryptionPassword)(
        IMachine *pThis,
        PRUnichar * id
    );

    nsresult (*ClearAllEncryptionPasswords)(IMachine *pThis );

    nsresult (*InternalAndReservedMethod1IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod2IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod3IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod4IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod5IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod6IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod7IMachine)(IMachine *pThis);

    nsresult (*InternalAndReservedMethod8IMachine)(IMachine *pThis);

};
struct IVirtualBoxClientVtbl
{
    nsresult (*QueryInterface)(IVirtualBoxClient *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IVirtualBoxClient *pThis);
    nsrefcnt (*Release)(IVirtualBoxClient *pThis);
    nsresult (*GetVirtualBox)(IVirtualBoxClient *pThis, IVirtualBox * *virtualBox);

    nsresult (*GetSession)(IVirtualBoxClient *pThis, ISession * *session);

    nsresult (*GetEventSource)(IVirtualBoxClient *pThis, IEventSource * *eventSource);

    nsresult (*GetInternalAndReservedAttribute1IVirtualBoxClient)(IVirtualBoxClient *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2IVirtualBoxClient)(IVirtualBoxClient *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute3IVirtualBoxClient)(IVirtualBoxClient *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute4IVirtualBoxClient)(IVirtualBoxClient *pThis, PRUint32 *reserved);

    nsresult (*CheckMachineError)(
        IVirtualBoxClient *pThis,
        IMachine * machine
    );

    nsresult (*InternalAndReservedMethod1IVirtualBoxClient)(IVirtualBoxClient *pThis);

    nsresult (*InternalAndReservedMethod2IVirtualBoxClient)(IVirtualBoxClient *pThis);

    nsresult (*InternalAndReservedMethod3IVirtualBoxClient)(IVirtualBoxClient *pThis);

    nsresult (*InternalAndReservedMethod4IVirtualBoxClient)(IVirtualBoxClient *pThis);

};
struct IGuestDebugControlVtbl
{
    nsresult (*QueryInterface)(IGuestDebugControl *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IGuestDebugControl *pThis);
    nsrefcnt (*Release)(IGuestDebugControl *pThis);
    nsresult (*GetDebugProvider)(IGuestDebugControl *pThis, PRUint32 *debugProvider);
    nsresult (*SetDebugProvider)(IGuestDebugControl *pThis, PRUint32 debugProvider);

    nsresult (*GetDebugIoProvider)(IGuestDebugControl *pThis, PRUint32 *debugIoProvider);
    nsresult (*SetDebugIoProvider)(IGuestDebugControl *pThis, PRUint32 debugIoProvider);

    nsresult (*GetDebugAddress)(IGuestDebugControl *pThis, PRUnichar * *debugAddress);
    nsresult (*SetDebugAddress)(IGuestDebugControl *pThis, PRUnichar * debugAddress);

    nsresult (*GetDebugPort)(IGuestDebugControl *pThis, PRUint32 *debugPort);
    nsresult (*SetDebugPort)(IGuestDebugControl *pThis, PRUint32 debugPort);

    nsresult (*GetInternalAndReservedAttribute1IGuestDebugControl)(IGuestDebugControl *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2IGuestDebugControl)(IGuestDebugControl *pThis, PRUint32 *reserved);

    nsresult (*InternalAndReservedMethod1IGuestDebugControl)(IGuestDebugControl *pThis);

    nsresult (*InternalAndReservedMethod2IGuestDebugControl)(IGuestDebugControl *pThis);

};
struct IMediumVtbl
{
    nsresult (*QueryInterface)(IMedium *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IMedium *pThis);
    nsrefcnt (*Release)(IMedium *pThis);
    nsresult (*GetId)(IMedium *pThis, PRUnichar * *id);

    nsresult (*GetDescription)(IMedium *pThis, PRUnichar * *description);
    nsresult (*SetDescription)(IMedium *pThis, PRUnichar * description);

    nsresult (*GetState)(IMedium *pThis, PRUint32 *state);

    nsresult (*GetVariant)(IMedium *pThis, PRUint32 *variantSize, PRUint32 **variant);

    nsresult (*GetLocation)(IMedium *pThis, PRUnichar * *location);
    nsresult (*SetLocation)(IMedium *pThis, PRUnichar * location);

    nsresult (*GetName)(IMedium *pThis, PRUnichar * *name);

    nsresult (*GetDeviceType)(IMedium *pThis, PRUint32 *deviceType);

    nsresult (*GetHostDrive)(IMedium *pThis, PRBool *hostDrive);

    nsresult (*GetSize)(IMedium *pThis, PRInt64 *size);

    nsresult (*GetFormat)(IMedium *pThis, PRUnichar * *format);

    nsresult (*GetMediumFormat)(IMedium *pThis, IMediumFormat * *mediumFormat);

    nsresult (*GetType)(IMedium *pThis, PRUint32 *type);
    nsresult (*SetType)(IMedium *pThis, PRUint32 type);

    nsresult (*GetAllowedTypes)(IMedium *pThis, PRUint32 *allowedTypesSize, PRUint32 **allowedTypes);

    nsresult (*GetParent)(IMedium *pThis, IMedium * *parent);

    nsresult (*GetChildren)(IMedium *pThis, PRUint32 *childrenSize, IMedium * **children);

    nsresult (*GetBase)(IMedium *pThis, IMedium * *base);

    nsresult (*GetReadOnly)(IMedium *pThis, PRBool *readOnly);

    nsresult (*GetLogicalSize)(IMedium *pThis, PRInt64 *logicalSize);

    nsresult (*GetAutoReset)(IMedium *pThis, PRBool *autoReset);
    nsresult (*SetAutoReset)(IMedium *pThis, PRBool autoReset);

    nsresult (*GetLastAccessError)(IMedium *pThis, PRUnichar * *lastAccessError);

    nsresult (*GetMachineIds)(IMedium *pThis, PRUint32 *machineIdsSize, PRUnichar * **machineIds);

    nsresult (*GetInternalAndReservedAttribute1IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute3IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute4IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute5IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute6IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute7IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute8IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute9IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute10IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute11IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute12IMedium)(IMedium *pThis, PRUint32 *reserved);

    nsresult (*SetIds)(
        IMedium *pThis,
        PRBool setImageId,
        PRUnichar * imageId,
        PRBool setParentId,
        PRUnichar * parentId
    );

    nsresult (*RefreshState)(
        IMedium *pThis,
        PRUint32 * state
    );

    nsresult (*GetSnapshotIds)(
        IMedium *pThis,
        PRUnichar * machineId,
        PRUint32 *snapshotIdsSize,
        PRUnichar *** snapshotIds
    );

    nsresult (*LockRead)(
        IMedium *pThis,
        IToken * * token
    );

    nsresult (*LockWrite)(
        IMedium *pThis,
        IToken * * token
    );

    nsresult (*Close)(IMedium *pThis );

    nsresult (*GetProperty)(
        IMedium *pThis,
        PRUnichar * name,
        PRUnichar * * value
    );

    nsresult (*SetProperty)(
        IMedium *pThis,
        PRUnichar * name,
        PRUnichar * value
    );

    nsresult (*GetProperties)(
        IMedium *pThis,
        PRUnichar * names,
        PRUint32 *returnNamesSize,
        PRUnichar *** returnNames,
        PRUint32 *returnValuesSize,
        PRUnichar *** returnValues
    );

    nsresult (*SetProperties)(
        IMedium *pThis,
        PRUint32 namesSize,
        PRUnichar ** names,
        PRUint32 valuesSize,
        PRUnichar ** values
    );

    nsresult (*CreateBaseStorage)(
        IMedium *pThis,
        PRInt64 logicalSize,
        PRUint32 variantSize,
        PRUint32* variant,
        IProgress * * progress
    );

    nsresult (*DeleteStorage)(
        IMedium *pThis,
        IProgress * * progress
    );

    nsresult (*CreateDiffStorage)(
        IMedium *pThis,
        IMedium * target,
        PRUint32 variantSize,
        PRUint32* variant,
        IProgress * * progress
    );

    nsresult (*MergeTo)(
        IMedium *pThis,
        IMedium * target,
        IProgress * * progress
    );

    nsresult (*CloneTo)(
        IMedium *pThis,
        IMedium * target,
        PRUint32 variantSize,
        PRUint32* variant,
        IMedium * parent,
        IProgress * * progress
    );

    nsresult (*CloneToBase)(
        IMedium *pThis,
        IMedium * target,
        PRUint32 variantSize,
        PRUint32* variant,
        IProgress * * progress
    );

    nsresult (*MoveTo)(
        IMedium *pThis,
        PRUnichar * location,
        IProgress * * progress
    );

    nsresult (*Compact)(
        IMedium *pThis,
        IProgress * * progress
    );

    nsresult (*Resize)(
        IMedium *pThis,
        PRInt64 logicalSize,
        IProgress * * progress
    );

    nsresult (*Reset)(
        IMedium *pThis,
        IProgress * * progress
    );

    nsresult (*ChangeEncryption)(
        IMedium *pThis,
        PRUnichar * currentPassword,
        PRUnichar * cipher,
        PRUnichar * newPassword,
        PRUnichar * newPasswordId,
        IProgress * * progress
    );

    nsresult (*GetEncryptionSettings)(
        IMedium *pThis,
        PRUnichar * * cipher,
        PRUnichar * * passwordId
    );

    nsresult (*CheckEncryptionPassword)(
        IMedium *pThis,
        PRUnichar * password
    );

    nsresult (*OpenForIO)(
        IMedium *pThis,
        PRBool writable,
        PRUnichar * password,
        IMediumIO * * mediumIO
    );

    nsresult (*ResizeAndCloneTo)(
        IMedium *pThis,
        IMedium * target,
        PRInt64 logicalSize,
        PRUint32 variantSize,
        PRUint32* variant,
        IMedium * parent,
        IProgress * * progress
    );

    nsresult (*InternalAndReservedMethod1IMedium)(IMedium *pThis);

    nsresult (*InternalAndReservedMethod2IMedium)(IMedium *pThis);

    nsresult (*InternalAndReservedMethod3IMedium)(IMedium *pThis);

    nsresult (*InternalAndReservedMethod4IMedium)(IMedium *pThis);

    nsresult (*InternalAndReservedMethod5IMedium)(IMedium *pThis);

    nsresult (*InternalAndReservedMethod6IMedium)(IMedium *pThis);

    nsresult (*InternalAndReservedMethod7IMedium)(IMedium *pThis);

};
struct ISessionVtbl
{
    nsresult (*QueryInterface)(ISession *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(ISession *pThis);
    nsrefcnt (*Release)(ISession *pThis);
    nsresult (*GetState)(ISession *pThis, PRUint32 *state);

    nsresult (*GetType)(ISession *pThis, PRUint32 *type);

    nsresult (*GetName)(ISession *pThis, PRUnichar * *name);
    nsresult (*SetName)(ISession *pThis, PRUnichar * name);

    nsresult (*GetMachine)(ISession *pThis, IMachine * *machine);

    nsresult (*GetConsole)(ISession *pThis, IConsole * *console);

    nsresult (*GetInternalAndReservedAttribute1ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute3ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute4ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute5ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute6ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute7ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute8ISession)(ISession *pThis, PRUint32 *reserved);

    nsresult (*UnlockMachine)(ISession *pThis );

    nsresult (*InternalAndReservedMethod1ISession)(ISession *pThis);

    nsresult (*InternalAndReservedMethod2ISession)(ISession *pThis);

    nsresult (*InternalAndReservedMethod3ISession)(ISession *pThis);

    nsresult (*InternalAndReservedMethod4ISession)(ISession *pThis);

};
struct IStorageControllerVtbl
{
    nsresult (*QueryInterface)(IStorageController *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IStorageController *pThis);
    nsrefcnt (*Release)(IStorageController *pThis);
    nsresult (*GetName)(IStorageController *pThis, PRUnichar * *name);
    nsresult (*SetName)(IStorageController *pThis, PRUnichar * name);

    nsresult (*GetMaxDevicesPerPortCount)(IStorageController *pThis, PRUint32 *maxDevicesPerPortCount);

    nsresult (*GetMinPortCount)(IStorageController *pThis, PRUint32 *minPortCount);

    nsresult (*GetMaxPortCount)(IStorageController *pThis, PRUint32 *maxPortCount);

    nsresult (*GetInstance)(IStorageController *pThis, PRUint32 *instance);
    nsresult (*SetInstance)(IStorageController *pThis, PRUint32 instance);

    nsresult (*GetPortCount)(IStorageController *pThis, PRUint32 *portCount);
    nsresult (*SetPortCount)(IStorageController *pThis, PRUint32 portCount);

    nsresult (*GetBus)(IStorageController *pThis, PRUint32 *bus);

    nsresult (*GetControllerType)(IStorageController *pThis, PRUint32 *controllerType);
    nsresult (*SetControllerType)(IStorageController *pThis, PRUint32 controllerType);

    nsresult (*GetUseHostIOCache)(IStorageController *pThis, PRBool *useHostIOCache);
    nsresult (*SetUseHostIOCache)(IStorageController *pThis, PRBool useHostIOCache);

    nsresult (*GetBootable)(IStorageController *pThis, PRBool *bootable);

    nsresult (*GetInternalAndReservedAttribute1IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute2IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute3IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute4IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute5IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute6IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute7IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*GetInternalAndReservedAttribute8IStorageController)(IStorageController *pThis, PRUint32 *reserved);

    nsresult (*InternalAndReservedMethod1IStorageController)(IStorageController *pThis);

    nsresult (*InternalAndReservedMethod2IStorageController)(IStorageController *pThis);

    nsresult (*InternalAndReservedMethod3IStorageController)(IStorageController *pThis);

    nsresult (*InternalAndReservedMethod4IStorageController)(IStorageController *pThis);

};
















typedef struct nsIException nsIException;
typedef struct nsISupports nsISupports;
typedef struct nsIStackFrame nsIStackFrame;
// typedef struct nsIException nsIException;

struct IVirtualBoxErrorInfoVtbl
{
    nsresult (*QueryInterface)(IVirtualBoxErrorInfo *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(IVirtualBoxErrorInfo *pThis);
    nsrefcnt (*Release)(IVirtualBoxErrorInfo *pThis);
    nsresult (*GetMessage)(IVirtualBoxErrorInfo *pThis, PRUnichar * *aMessage);
    nsresult (*GetResult)(IVirtualBoxErrorInfo *pThis, nsresult *aResult);
    nsresult (*GetName)(IVirtualBoxErrorInfo*pThis, PRUnichar * *aName);
    nsresult (*GetFilename)(IVirtualBoxErrorInfo *pThis, PRUnichar * *aFilename);
    nsresult (*GetLineNumber)(IVirtualBoxErrorInfo *pThis, PRUint32 *aLineNumber);
    nsresult (*GetColumnNumber)(IVirtualBoxErrorInfo *pThis, PRUint32 *aColumnNumber);
    nsresult (*GetLocation)(IVirtualBoxErrorInfo *pThis, nsIStackFrame * *aLocation);
    nsresult (*GetInner)(IVirtualBoxErrorInfo *pThis, nsIException * *aInner);
    nsresult (*GetData)(IVirtualBoxErrorInfo *pThis, nsISupports * *aData);
    nsresult (*ToString)(IVirtualBoxErrorInfo *pThis, PRUnichar **_retval);
    nsresult (*GetResultCode)(IVirtualBoxErrorInfo *pThis, PRInt32 *resultCode);

    nsresult (*GetResultDetail)(IVirtualBoxErrorInfo *pThis, PRInt32 *resultDetail);

    nsresult (*GetInterfaceID)(IVirtualBoxErrorInfo *pThis, PRUnichar * *interfaceID);

    nsresult (*GetComponent)(IVirtualBoxErrorInfo *pThis, PRUnichar * *component);

    nsresult (*GetText)(IVirtualBoxErrorInfo *pThis, PRUnichar * *text);

    nsresult (*GetNext)(IVirtualBoxErrorInfo *pThis, IVirtualBoxErrorInfo * *next);

};
struct TheVtbl
{
    nsresult (*QueryInterface)(nsIException *pThis, const nsID *iid, void **resultp);
    nsrefcnt (*AddRef)(nsIException *pThis);
    nsrefcnt (*Release)(nsIException *pThis);

    nsresult (*GetMessage)(nsIException *pThis, PRUnichar * *aMessage);
    nsresult (*GetResult)(nsIException *pThis, nsresult *aResult);
    nsresult (*GetName)(nsIException *pThis, PRUnichar * *aName);
    nsresult (*GetFilename)(nsIException *pThis, PRUnichar * *aFilename);
    nsresult (*GetLineNumber)(nsIException *pThis, PRUint32 *aLineNumber);
    nsresult (*GetColumnNumber)(nsIException *pThis, PRUint32 *aColumnNumber);
    nsresult (*GetLocation)(nsIException *pThis, nsIStackFrame * *aLocation);
    nsresult (*GetInner)(nsIException *pThis, nsIException * *aInner);
    nsresult (*GetData)(nsIException *pThis, nsISupports * *aData);
    nsresult (*ToString)(nsIException *pThis, PRUnichar **_retval);
};
