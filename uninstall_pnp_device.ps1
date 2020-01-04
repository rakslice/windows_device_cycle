param(
	[String]$deviceID,
	[int]$sleepTime=4
)

# uninstall the device with the given id

# based on https://theorypc.ca/2017/06/28/remove-ghost-devices-natively-with-powershell/

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
		//	PDEVINST    pdnDevInst,
		//	DEVINSTID_A pDeviceID,
		//	ULONG       ulFlags
		//);
		
		[DllImport("setupapi.dll", SetLastError = true)]
		public static extern int CM_Reenumerate_DevNode(IntPtr dnDevInst, int ulFlags);		
		
		//CMAPI CONFIGRET CM_Reenumerate_DevNode(
		//	DEVINST dnDevInst,
		//	ULONG   ulFlags
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

echo "Uninstalling device matching $deviceID"

function ReadMultiString([byte[]]$buffer) {
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

        $propType = 0
        #Buffer is initially null and buffer size 0 so that we can get the required Buffer size first
        [byte[]]$propBuffer = $null
        $propBufferSize = 0
        #Get Buffer size
        $firstRet = [Win32.SetupApi]::SetupDiGetDeviceRegistryProperty($devs, [ref]$devInfo, $property, [ref]$propType, $propBuffer, 0, [ref]$propBufferSize)
		
		#echo "First ret is " $firstRet
        #Initialize Buffer with right size
        [byte[]]$propBuffer = New-Object byte[] $propBufferSize

		$secondRet = [Win32.SetupApi]::SetupDiGetDeviceRegistryProperty($devs, [ref]$devInfo, $property, [ref]$propType, $propBuffer, $propBufferSize, [ref]$propBufferSize)
			
		if ($secondRet -ne $true -and $propType -ne 0) {
			echo "second ret is" $secondRet
			write-error "second get property call failed"
			pause
			exit
		}
		
		# do something appropriate to convert the property

		if ($propType -eq [Microsoft.Win32.RegistryValueKind]::MultiString) {
			$out = ReadMultiString $propBuffer
		} elseif ($propType -eq [Microsoft.Win32.RegistryValueKind]::String) {
			$out = [System.Text.Encoding]::Unicode.GetString($propBuffer, 0, $propBuffer.length)
		} elseif ($propType -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
			$out = [System.BitConverter]::ToInt32($propBuffer, 0);
		} elseif ($propType -eq 0) {
			$out = $null
		} else {
			echo "unknown proptype is " $propType
			pause
			exit
		}
		
		# return success or failure
		$out
}


function uninstall-pnpdevice($deviceID) {
    $setupClass = [Guid]::Empty
    #Get all devices
    [IntPtr]$devs = [Win32.SetupApi]::SetupDiGetClassDevs([ref]$setupClass, [IntPtr]::Zero, [IntPtr]::Zero, [Win32.DiGetClassFlags]::DIGCF_ALLCLASSES)
	
    #Initialise Struct to hold device info Data
    $devInfo = new-object Win32.SP_DEVINFO_DATA
    $devInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devInfo)
	
    #Device Counter
    $devCount = 0
	
	
    #Enumerate Devices

    while([Win32.SetupApi]::SetupDiEnumDeviceInfo($devs, $devCount, [ref]$devInfo)){
	
		$curDeviceID = (GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_HARDWAREID))

		if ($deviceID.StartsWith("$curDeviceID\")) {
	
			echo "--> Found Device $devCount"
			echo "Friendly name"
			$friendly = (GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_FRIENDLYNAME))
			if ($friendly -eq $null) {
				$friendly = (GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_DEVICEDESC))
			}
			$friendly
			echo "Install state"
			$installState = GetDeviceProperty $devs $devInfo ([Win32.SetupDiGetDeviceRegistryPropertyEnum]::SPDRP_INSTALL_STATE)
			$installState
			
			if ($installState -eq 0) {
				echo "it is consistent with installed state."
				
				
				echo "Uninstalling the device."
				$ret = [Win32.SetupApi]::DiUninstallDevice(0, $devs, [ref]$devInfo, 0, [ref]$null)
				#$ret = [Win32.SetupApi]::SetupDiRemoveDevice($devs, [ref]$devInfo)
				if (-not $ret) {
					echo "Error removing device"
					pause
					exit
				}
			}
			break
		}
		
		
		
		$devCount++

	}		
}

function rescan-devices {
	[IntPtr] $devInst = new-object IntPtr
	
	#CM_LOCATE_DEVNODE_NORMAL = 0x00000000
    #CR_SUCCESS = 0x00000000
	
	$status = [Win32.CM]::CM_Locate_DevNodeA([ref]$devInst, $null, 0) # CM_LOCATE_DEVNODE_NORMAL
	
	if ($status -ne 0) { # CR_SUCCESS
		echo "locate root node failed: $status"
		pause
		return
	}
	
	$status = [Win32.CM]::CM_Reenumerate_DevNode($devInst, 0);
	if ($status -ne 0) { # CR_SUCCESS
		echo "rescan failed: $status"
		pause
		return
	}
	
	echo "launched rescan okay"
}

uninstall-pnpdevice $deviceID

echo "waiting $sleepTime s"
start-sleep $sleepTime

echo "rescanning devices"

rescan-devices

echo "we're done"

start-sleep 10

