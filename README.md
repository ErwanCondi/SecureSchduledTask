# Secure Scheduled Task Script

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
.\SecureScheduledTask.ps1 -TaskName "<YourTaskName>" -ScriptPath "<PathToMainScript.ps1>"
```

## Detailed Workflow
### 1. Parameter Input and Verification:
 * The script takes in two mandatory parameters: ```TaskName``` (name of the scheduled task) and ```ScriptPath``` (path to the main script to be executed by the task).
 * Verifies that the specified task exists using ```Get-ScheduledTask```. If the task is not found or is inaccessible, an error is thrown.

### 2. User Authentication:
 * If the task's principal (owner) is different from the currently logged-in user, the script prompts for the credentials of the task's owner.
 * The ```Get-Credential``` command is used to securely retrieve and store the credentials.
   
### 3. File Hash Calculation:
 * The script identifies all files with ```.ps1```, ```.dll```, ```.psd1```, and ```.psm1``` extensions in the directory of the main script specified in ```ScriptPath```.
 * For each file, it generates an SHA-256 hash and stores the full path and hash in a hashtable.

### 4. JSON Conversion:
 * The script converts the hash map (containing file paths and hashes) and the main script path into JSON format.

### 5. Command Creation and Encoding:
 * A PowerShell command is generated that:
   * Loads the JSON hash map.
   * Checks each file’s hash against the recorded hash value.
   * Throws an terminating error if any file’s hash does not match, preventing the main script from executing.
   * Executes the main script if all files pass the integrity check.
* The command is encoded in Base64 to allow secure handling of the argument.

### 6. Scheduled Task Action Update:
 * A new scheduled task action is created with the encoded command. The action specifies:
   * ```powershell.exe``` as the executable.
   * Arguments including ```-ExecutionPolicy Unrestricted``` and the encoded command for the task to execute.
 * ```Set-ScheduledTask``` updates the task with the new action and applies the necessary credentials if the task is owned by another user.

### 7. Secure Task Update Completion:
 * If all steps complete successfully, the task is updated and secured with the new command action.
 * The script supports ```-Verbose``` switch to display the command being generated.
