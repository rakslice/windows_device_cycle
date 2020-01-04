# windows_device_cycle #

This is a set of PowerShell scripts for disabling and re-enabling (or, optionally, uninstalling and re-detecting) the USB controller that a given USB device is plugged in to.

Note that this will evidently affect anything else plugged in to ports on the same USB controller, so if you use the uninstall option, it may be useful to spread out your USB devices across ports on different USB controllers in your system to reduce re-installation time, if your system has controllers to spare.   

## Usage ##

To use it, I create shortcuts in my start menu pointing to my checkout of the script and passing the name of the USB device shown in Device Manager and any options:

e.g. "HID-compliant mouse", enable and disable interface

    %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -file "%USERPROFILE%\Documents\windows_device_cycle\cycle_usb.ps1" -friendlyName "HID-compliant mouse"

e.g. "HID Keyboard Device", uninstall and re-install interface

    %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -file "%USERPROFILE%\Documents\windows_device_cycle\cycle_usb.ps1" -friendlyName "HID Keyboard Device" -uninstall


## Background ##

Frequently I have a problem where a USB input device such as the keyboard or mouse stops responding. Although the device is still powered on via USB, and is still visible within the Device Manager in Windows 10, button presses or movements from the device aren't getting through.  

When this first happened, I found that if I connected an additional keyboard/mouse to a different controller it was usable, and that disabling and re-enabling the USB controller (or, failing that, uninstalling and re-installing it) caused the affected device to start working again.