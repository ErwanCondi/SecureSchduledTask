# Scheduled Task Update Script

This PowerShell script updates a specified Windows scheduled task, replacing its action with a command to verify file hashes and then execute a main script. The script requires the name of the scheduled task and the path to the main script as inputs.

## Features

- **Verifies Scheduled Task**: Ensures the specified scheduled task exists and is accessible to the current user.
- **Secure Password Handling**: Retrieves the password securely if the task is owned by a different user.
- **Hash Verification**: Generates SHA-256 hashes for specified file types within the main script's directory to verify file integrity before execution.
- **Task Update**: Updates the scheduled task with a new action that performs hash checks and executes the main script if all hashes match.

## Requirements

- Windows PowerShell 5.0 or higher
- Windows Task Scheduler with an existing task
- Administrative privileges (if the task belongs to a different user)

## Parameters

| Parameter  | Type   | Description                                                |
|------------|--------|------------------------------------------------------------|
| TaskName   | String | Name of the scheduled task to update                       |
| ScriptPath | String | Path to the main script file that the task will execute    |

## Usage

```powershell
.\UpdateScheduledTask.ps1 -TaskName "<YourTaskName>" -ScriptPath "<PathToMainScript.ps1>"
