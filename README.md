# CloudDefense Security Scan Script

This script automates the process of running security checks for Java, Node.js, or Python projects using CloudDefense. It sets up the required environment, performs the scan, and tracks the status of the task.

## Prerequisites

- Bash shell.
- Git installed on the server.
- Docker installed (if not already installed, the script will prompt for manual installation).
- CloudDefense credentials (API key).

## Environment Variables

The following environment variables must be set before running the script:

| Variable Name         | Default Value                                                        | Description                                                                                  |
|-----------------------|----------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `CDEFENSE_INSTALL_URL`| `https://raw.githubusercontent.com/CloudDefenseAI/cd/master/latest/cd-latest-linux-x64.tar.gz` | URL for downloading the CloudDefense binary.                                                 |
| `WORKSPACE`           | N/A                                                                | Root directory where the codebase is located.                                               |
| `CODEBASE_DIR`        | N/A                                                                | Subdirectory within the workspace containing the codebase.                                  |
| `SCAN_URL`            | `https://clouddefense.piramalfinance.com/`                         | URL for the CloudDefense scan.                                                              |
| `SLEEP_DURATION`      | `0`                                                                | Delay (in seconds) before starting the scan.                                                |
| `LANGUAGE`            | N/A                                                                | Programming language of the project (`java`, `python`, or `node`).                          |
| `CDEFENSE_API_KEY`    | N/A                                                                | API key for CloudDefense authentication.                                                    |
| `ACTIVITY_SUB_TASK_CODE` | N/A                                                            | Code for tracking the status of the sub-task.                                               |

