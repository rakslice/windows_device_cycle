param(
    [String]$friendlyName,
    [switch]$uninstall=$false
)

# A script to cycle the USB controller that a given device is connected to

function SelectWMI ($WMIPathName) {
    $rest = $WMIPathName.split(':',2)[1]
    $type = $rest.split('.',2)[0]
    get-wmiobject $type | where-object -property __PATH -eq $WMIPathName
}

function ensureSingle($arr) {
    if ($arr.length -ne 1) {
        if ($arr.length -gt 1) {
            write-error "multiple matches:"
            #write-host $arr
        } else {
            write-error "no matches"
        }
        exit
    }
    $arr[0]
}

write-host "Searching for a device with name $friendlyName"

$usbDevice = ensureSingle(@(get-pnpdevice -presentonly -friendlyname $friendlyName))

write-host $usbDevice.name "is connected to"

$usbDeviceWMI = ensureSingle(@( get-wmiobject Win32_PnpEntity |
    where-object -property PNPDeviceID -eq $usbDevice.instanceid |
    where-object -property Present -eq True
))

$controllerDevice = ensureSingle(@(get-wmiobject win32_usbcontrollerdevice |
    where-object -property dependent -eq $usbDeviceWMI.__PATH))

$controller = ensureSingle(@(SelectWMI($controllerDevice.antecedent)))
$controllerPNP = $controller.PNPDeviceID

write-host $controller.Name
write-host $controllerPNP

## show all the properties of the controller
#write-host $controller

if (-not $uninstall) {

    $devNodeStatus = get-pnpdeviceproperty -instanceid $controllerPNP -keyname DEVPKEY_Device_DevNodeStatus | select -expand data

    $DN_DISABLEABLE = 8192

    if ($devNodeStatus -band $DN_DISABLEABLE) {
        $uninstall = $false
    } else {
        $uninstall = $true
    }

    write-host "Needs uninstall: $uninstall"

}

if ($uninstall) {
    $adminScript="uninstall_pnp_device.ps1"
} else {
    $adminScript="cycle_pnp_device.ps1"
}

write-host "Launching an admin script to cycle the device"

start-sleep 2

start-process powershell -argumentlist "-NoProfile -ExecutionPolicy Bypass -File ""$PSScriptRoot\$adminScript"" -deviceID $controllerPNP"  -Verb runAs

start-sleep 10