
param (
    [Parameter(Position=0,mandatory=$true)]
    [String]$TaskName, # Task that needs to be updated
    [Parameter(Position=1,mandatory=$true)]
    [String]$ScriptPath # Path of the main script that need to run in the task
    )


# function to get the original password from the secure string
function decypherPassword ([SecureString]$Password) {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentials.Password)
    $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    return $plainTextPassword
}

# Make sure the task actually exists and is accessible by current user
try {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
}
catch {
    throw "Task not found. Check the name and if the task does not run as your currently signed in user, run as administrator"
}

try {
    # Need to provide a password if the task belong to a different user
    if ($task.Principal.UserId -ne $env:USERNAME) {
        $credentials = Get-Credential -UserName $task.Principal.UserId -Message "Enter the credentials for running user" -ErrorAction Stop
    }

    # List all libraries and scripts in your directory
    $extentions = @('.ps1','.dll','.psd1','.psm1')
    $executables = gci -path ([System.IO.Path]::GetDirectoryName($scriptPath)) -Recurse -File |  ? { $_.Extension -in $extentions }
    $hashTableofHashes = $executables | select FullName,@{n='Hash';e={$(Get-FileHash $_.FullName -Algorithm SHA256).Hash}}

    # Create a dict. with all the hash and file names
    $data = @{
        Script = $scriptPath
        hashMap = $hashTableofHashes
    }

    # Convert to json to store the whole as a string
    $jsonHash = $($data | ConvertTo-Json -Depth 10 -Compress -ErrorAction Stop)

    # create the ps command that will check the hash and start the main script
    $command = "`$d=`'$jsonHash`' | ConvertFrom-Json; `$d.hashMap | %{if( (Get-FileHash `$_.FullName).Hash -ne `$_.Hash ){ throw }};& `$d.Script"
    Write-Verbose "Command created: `n`r$command"


    # encode in base64 so we don't have to manage all the column individually
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $argument = "-ExecutionPolicy `"Unrestricted`" -EncodedCommand `"$encodedCommand`""

    # Create a task action
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument

    # update the main task
    Set-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Action $taskAction -Password $(decypherPassword($credentials.Password)) -User $credentials.UserName -ErrorAction Stop
    Write-Verbose "Task secured !!"
}
catch {
    throw $_
}