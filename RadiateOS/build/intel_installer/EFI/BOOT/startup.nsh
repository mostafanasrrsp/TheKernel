@echo -off
echo "RadiateOS EFI Boot Loader"
echo "Intel Mac Compatible - No Windows Branding"

# Clear screen and set mode
cls
mode 80 25

# Disable Windows recovery mode
setvar recovery-boot-mode -guid e09ca83f-b9b7-4e7d-9b8f-9e7d9c7e9b8f = {0x00}

# Set RadiateOS as default OS
setvar BootOrder -guid 8be4df61-93ca-11d2-aa0d-00e098032b8c = {0x01}

# Boot into RadiateOS
echo "Starting RadiateOS..."
goto EXIT
