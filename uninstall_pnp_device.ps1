param(
    [String]$deviceID,
    [int]$sleepTime=4
)

# Uninstall the device with the given PNP Device ID and then re-detect devices

# The code that uses SetupDi* is based on https://theorypc.ca/2017/06/28/remove-ghost-devices-natively-with-powershell/

$setupapi = @"
using System;
using System.Diagnostics;
using System.Text;
using System.Runtime.InteropServices;
namespace Win32
{
    public static class SetupApi
    {
         // 1st form using a ClassGUID only, with Enumerator = IntPtr.Zero
        [DllImport("setupapi.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SetupDiGetClassDevs(
           ref Guid ClassGuid,
           IntPtr Enumerator,
           IntPtr hwndParent,
           int Flags
        );
    
        // 2nd form uses an Enumerator only, with ClassGUID = IntPtr.Zero
        [DllImport("setupapi.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SetupDiGetClassDevs(
           IntPtr ClassGuid,
           string Enumerator,
           IntPtr hwndParent,
           int Flags
        );
        
        [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetupDiEnumDeviceInfo(
            IntPtr DeviceInfoSet,
            uint MemberIndex,
            ref SP_DEVINFO_DATA DeviceInfoData
        );
    
        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern bool SetupDiDestroyDeviceInfoList(
            IntPtr DeviceInfoSet
        );
        [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetupDiGetDeviceRegistryProperty(
            IntPtr deviceInfoSet,
            ref SP_DEVINFO_DATA deviceInfoData,
            uint property,
            out UInt32 propertyRegDataType,
            byte[] propertyBuffer,
            uint propertyBufferSize,
            out UInt32 requiredSize
        );
        [DllImport("setupapi.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool SetupDiGetDeviceInstanceId(
            IntPtr DeviceInfoSet,
            ref SP_DEVINFO_DATA DeviceInfoData,
            StringBuilder DeviceInstanceId,
            int DeviceInstanceIdSize,
            out int RequiredSize
        );
 
    
        [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetupDiRemoveDevice(IntPtr DeviceInfoSet,ref SP_DEVINFO_DATA DeviceInfoData);
        
        [DllImport("newdev.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool DiUninstallDevice(
            uint hwndParent,
            IntPtr DeviceInfoSet,
            ref SP_DEVINFO_DATA DeviceInfoData,
            uint Flags,
            ref bool NeedReboot
        );
    }
    
    public static class CM {
        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern int CM_Locate_DevNodeA(out IntPtr pdnDevInst, string pDeviceID, int ulFlags);      
        
        //CMAPI CONFIGRET CM_Locate_DevNodeA(
        //  PDEVINST    pdnDevInst,
        //  DEVINSTID_A pDeviceID,
        //  ULONG       ulFlags
        //);
        
        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern int CM_Reenumerate_DevNode(IntPtr dnDevInst, int ulFlags);     
        
        //CMAPI CONFIGRET CM_Reenumerate_DevNode(
        //  DEVINST dnDevInst,
        //  ULONG   ulFlags
        //);
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct SP_DEVINFO_DATA
    {
       public uint cbSize;
       public Guid classGuid;
       public uint devInst;
       public IntPtr reserved;
    }
    [Flags]
    public enum DiGetClassFlags : uint
    {
        DIGCF_DEFAULT       = 0x00000001,  // only valid with DIGCF_DEVICEINTERFACE
        DIGCF_PRESENT       = 0x00000002,
        DIGCF_ALLCLASSES    = 0x00000004,
        DIGCF_PROFILE       = 0x00000008,
        DIGCF_DEVICEINTERFACE   = 0x00000010,
    }
    public enum SetupDiGetDeviceRegistryPropertyEnum : uint
    {
         SPDRP_DEVICEDESC          = 0x00000000, // DeviceDesc (R/W)
         SPDRP_HARDWAREID          = 0x00000001, // HardwareID (R/W)
         SPDRP_COMPATIBLEIDS           = 0x00000002, // CompatibleIDs (R/W)
         SPDRP_UNUSED0             = 0x00000003, // unused
         SPDRP_SERVICE             = 0x00000004, // Service (R/W)
         SPDRP_UNUSED1             = 0x00000005, // unused
         SPDRP_UNUSED2             = 0x00000006, // unused
         SPDRP_CLASS               = 0x00000007, // Class (R--tied to ClassGUID)
         SPDRP_CLASSGUID           = 0x00000008, // ClassGUID (R/W)
         SPDRP_DRIVER              = 0x00000009, // Driver (R/W)
         SPDRP_CONFIGFLAGS         = 0x0000000A, // ConfigFlags (R/W)
         SPDRP_MFG             = 0x0000000B, // Mfg (R/W)
         SPDRP_FRIENDLYNAME        = 0x0000000C, // FriendlyName (R/W)
         SPDRP_LOCATION_INFORMATION    = 0x0000000D, // LocationInformation (R/W)
         SPDRP_PHYSICAL_DEVICE_OBJECT_NAME = 0x0000000E, // PhysicalDeviceObjectName (R)
         SPDRP_CAPABILITIES        = 0x0000000F, // Capabilities (R)
         SPDRP_UI_NUMBER           = 0x00000010, // UiNumber (R)
         SPDRP_UPPERFILTERS        = 0x00000011, // UpperFilters (R/W)
         SPDRP_LOWERFILTERS        = 0x00000012, // LowerFilters (R/W)
         SPDRP_BUSTYPEGUID         = 0x00000013, // BusTypeGUID (R)
         SPDRP_LEGACYBUSTYPE           = 0x00000014, // LegacyBusType (R)
         SPDRP_BUSNUMBER           = 0x00000015, // BusNumber (R)
         SPDRP_ENUMERATOR_NAME         = 0x00000016, // Enumerator Name (R)
         SPDRP_SECURITY            = 0x00000017, // Security (R/W, binary form)
         SPDRP_SECURITY_SDS        = 0x00000018, // Security (W, SDS form)
         SPDRP_DEVTYPE             = 0x00000019, // Device Type (R/W)
         SPDRP_EXCLUSIVE           = 0x0000001A, // Device is exclusive-access (R/W)
         SPDRP_CHARACTERISTICS         = 0x0000001B, // Device Characteristics (R/W)
         SPDRP_ADDRESS             = 0x0000001C, // Device Address (R)
         SPDRP_UI_NUMBER_DESC_FORMAT       = 0X0000001D, // UiNumberDescFormat (R/W)
         SPDRP_DEVICE_POWER_DATA       = 0x0000001E, // Device Power Data (R)
         SPDRP_REMOVAL_POLICY          = 0x0000001F, // Removal Policy (R)
         SPDRP_REMOVAL_POLICY_HW_DEFAULT   = 0x00000020, // Hardware Removal Policy (R)
         SPDRP_REMOVAL_POLICY_OVERRIDE     = 0x00000021, // Removal Policy Override (RW)
         SPDRP_INSTALL_STATE           = 0x00000022, // Device Install State (R)
         SPDRP_LOCATION_PATHS          = 0x00000023, // Device Location Paths (R)
         SPDRP_BASE_CONTAINERID        = 0x00000024  // Base ContainerID (R)
    }
}
"@

Add-Type -TypeDefinition $setupapi


function ReadUnicodeMultiString([byte[]]$buffer) {
    # Convert a byte array with a Unicode flavoured REG_MULTI_SZ (a.k.a. [Microsoft.Win32.RegistryValueKind]::MultiString) to an ArrayList of strings
    
    $index = 0
    
    [System.Collections.ArrayList]$array = new-object System.Collections.ArrayList
    
    for ($i=0; $i -le $buffer.length; $i++) {
        if ($buffer[$i] -eq 0 -and $buffer[$i + 1] -eq 0) {
            $count = $i - $index + 1
            if ($count -eq 1) {
                break
            }
            
            $curString = [System.Text.Encoding]::Unicode.GetString($buffer, $index, $count)
            
            $array.Add($curString) | out-null
            
            $index = $i + 1
        }   
    
    }
    $array
}


function GetDeviceProperty([IntPtr]$devs, [Win32.SP_DEVINFO_DATA]$devInfo, [Win32.SetupDiGetDeviceRegistryPropertyEnum]$property) {
        [CmdletBinding()]
        
        # Get the given property on the currently enumerating device and convert the data

        $propType = 0
        # First we call SetupDiGetDeviceRegistryProperty with buffer null and buffer size 0 so that we can get the required Buffer size
        [byte[]]$propBuffer = $null
        $propBufferSize = 0
        # Get Buffer size
        $firstRet = [Win32.SetupApi]::SetupDiGetDeviceRegistryProperty($devs, [ref]$devInfo, $property, [ref]$propType, $propBuffer, 0, [ref]$propBufferSize)

        #write-host "First SetupDiGetDeviceRegistryProperty call return value is " $firstRet
        # Initialize Buffer with right size
        [byte[]]$propBuffer = New-Object byte[] $propBufferSize
        
        # Now we call SetupDiGetDeviceRegistryProperty again to get the actual property bytes

        $secondRet = [Win32.SetupApi]::SetupDiGetDeviceRegistryProperty($devs, [ref]$devInfo, $property, [ref]$propType, $propBuffer, $propBufferSize, [ref]$propBufferSize)
            
        if ($secondRet -ne $true -and $propType -ne 0) {
            write-host "The second SetupDiGetDeviceRegistryProperty call return value is" $secondRet
            write-error "second SetupDiGetDeviceRegistryProperty call failed"
            pause
            exit
        }
        
        # Convert the property buffer data appropriately based on the property type

        if ($propType -eq [Microsoft.Win32.RegistryValueKind]::MultiString) {
            $out = ReadUnicodeMultiString $propBuffer
        } elseif ($propType -eq [Microsoft.Win32.RegistryValueKind]::String) {
            $out = [System.Text.Encoding]::Unicode.GetString($propBuffer, 0, $propBuffer.length)
        } elseif ($propType -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
            $out = [System.BitConverter]::ToInt32($propBuffer, 0);
        } elseif ($propType -eq 0) {
            $out = $null
        } else {
            write-host "Device property $property has unknown property type $propType"
            pause
            exit
        }
        
        # Return the converted property value
        $out
}


function uninstall-pnpdevice($deviceIDToLookFor) {
    $deviceFound = $false

    $setupClass = [Guid]::Empty
    # Get all devices
    [IntPtr]$devs = [Win32.SetupApi]::SetupDiGetClassDevs([ref]$setupClass, [IntPtr]::Zero, [IntPtr]::Zero, [Win32.DiGetClassFlags]::DIGCF_ALLCLASSES)
	
	try {
    
        # Initialise Struct to hold device info Data
        $devInfo = new-object Win32.SP_DEVINFO_DATA
        $devInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devInfo)
               
        # Enumerate Devices
        
        For ($devCount = 0; [Win32.SetupApi]::SetupDiEnumDeviceInfo($devs, $devCount, [ref]$devInfo); $devCount++) {
        
            $curDeviceID = (GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_HARDWAREID))

            if ($deviceIDToLookFor -eq $curDeviceID -or $deviceIDToLookFor.StartsWith("$curDeviceID\")) { # That is, if the device ID we're looking for is the currently enumerating device ID optionally followed by a backslash and some stuff
        
				write-host "Device ID: $curDeviceID"
                $deviceFound = $true
                
                write-host "Friendly name: "
                $friendly = (GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_FRIENDLYNAME))
                if ($friendly -eq $null) {
                    $friendly = (GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_DEVICEDESC))
                }
                write-host $friendly
                
                write-host -NoNewline "Install state: "
                $installState = GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_INSTALL_STATE)
                write-host $installState
                
                if ($installState -eq 0) {
                    write-host "It is consistent with installed state."
                    
                    
                    write-host "Uninstalling the device."
                    $ret = [Win32.SetupApi]::DiUninstallDevice(0, $devs, [ref]$devInfo, 0, [ref]$null)
                    #$ret = [Win32.SetupApi]::SetupDiRemoveDevice($devs, [ref]$devInfo)
                    if (-not $ret) {
                        write-host "Error removing device"
                        pause
                        exit
                    }
                }
                break
            }

        }
		
	} finally {

        if (-not [Win32.SetupApi]::SetupDiDestroyDeviceInfoList($devs)) {
            Write-Error "Cleanup of device info list failed"
        }
	
	}
	
	#write-host "device count $devCount"
	
	$deviceFound
}


function rescan-devices {
    [IntPtr] $devInst = new-object IntPtr
    
    # CM_LOCATE_DEVNODE_NORMAL = 0x00000000
    # CR_SUCCESS = 0x00000000
    
    $status = [Win32.CM]::CM_Locate_DevNodeA([ref]$devInst, $null, 0) # CM_LOCATE_DEVNODE_NORMAL
    
    if ($status -ne 0) { # CR_SUCCESS
        write-host "Locate root node failed: $status"
        pause
        return
    }
    
    $status = [Win32.CM]::CM_Reenumerate_DevNode($devInst, 0);
    if ($status -ne 0) { # CR_SUCCESS
        write-host "Launching scan for hardware failed: $status"
        pause
        return
    }
    
    write-host "Scan for hardware started successfully"
}


write-host "Uninstalling device matching $deviceID"

$found = uninstall-pnpdevice $deviceID

if (-not $found) {
	Write-Error "Couldn't find a device matching $deviceID"
	start-sleep 5
	exit
}

write-host "Waiting $sleepTime s"
start-sleep $sleepTime

write-host "Re-scanning for hardware"

rescan-devices

write-host "We're done"

# Stick around a bit so there's a chance to see the messages before the window disappears
start-sleep 5
