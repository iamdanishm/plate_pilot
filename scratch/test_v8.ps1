$body = @{
    action = "generate_plan"
    household_id = "30699ee4-604f-4473-829a-c892f08917f9"
} | ConvertTo-Json

try {
    $res = Invoke-RestMethod -Uri "https://bnwjccpdvrrkixthmvfu.supabase.co/functions/v1/meal-plan-ai" -Method Post -Body $body -ContentType "application/json"
    $res | ConvertTo-Json -Depth 4
} catch {
    Write-Host "Error: $_"
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host $reader.ReadToEnd()
}
