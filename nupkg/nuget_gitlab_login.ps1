$source = $env:NUGET_GITLAB_SOURCE
$user = $env:NUGET_GITLAB_USER
$apikey = $env:NUGET_GITLAB_TOKEN

# export NUGET_GITLAB_SOURCE="${gitlab_pack_nuget}"
# export NUGET_GITLAB_USER="${gitlab_pack_user}"
# export NUGET_GITLAB_TOKEN="${gitlab_pack_token}"

dotnet nuget add source  -n "$user" `
-u "$user" `
-p "$apikey" `
--store-password-in-clear-text `
"$source"