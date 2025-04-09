# 输出Hello World!
Write-Host "Hello World!"
# 获取当前日期和时间
$now = Get-Date
Write-Host "当前日期和时间：$now"
[xml]$xml = Get-Content .\common.props
Write-Host $xml.SelectSingleNode('//Version')."#text"
