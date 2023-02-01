$TPM = Get-Tpm

# Verify TPM version

Write-Output "Verifying TPM version...."
$TPMV = Get-CimInstance -Namespace "root/cimv2/Security/MicrosoftTPM" -ClassName "Win32_TPM"
$tpmVersion = $tpmv.SpecVersion
Write-Output "TPM version: $TPMVersion"

# Verify TPM configuration

Write-Output "Verifying TPM configuration..."
if ($TPM.TpmEnabled -eq $true) {
    Write-Output "TPM is enabled and configured correctly."
} else {
    Write-Output "TPM is not enabled or configured correctly."
}

Write-Output "Verifying TPM configuration..."
if ($tpm.TpmPresent -eq $true) {
    
    Write-Output "Motherboard has a TPM chip"
} else {
    Write-Output "Motherboard does not have TPM chip"
}

# Verify TPM ownership

Write-Output "Verifying TPM ownership..."

if ($TPM.TpmOwned -eq $true) {
    Write-Output "TPM is owned and configured correctly."
} else {
    Write-Output "TPM is not owned or configured correctly."
}

# Verify TPM support on the virtual machine
Write-Output "Verifying TPM support on virtual machine..."
$VM = Get-VM -Name "Your VM Name"
$VMSupportTPM = $VM.SecureBootEnabled
if ($VMSupportTPM -eq $true) {
    Write-Output "TPM is supported on the virtual machine."
} else {
    Write-Output "TPM is not supported on the virtual machine."
}
