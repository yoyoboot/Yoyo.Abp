# 删除 shared 模块
function DelShared {
    param (
        $rootPath
    )

    # 修改初始化调用的 AppPreBootstrap.ts
    $path = [System.IO.Path]::Join($rootPath, 'src\vue\src\AppPreBootstrap.ts')
    $content = ReadFile -Path $path
    $content = $content -Replace 'SharedSession', 'Session'
    WriteFile -Path $path -Content $content


    # 删除的文件和目录
    $removeItems = (
        'src\vue\src\project-license',
        'src\vue\src\app\test-routing.ts',
        'src\vue\src\app\sample-routing.ts',
        'src\vue\src\app\admin2\dynamic-menu\dynamic-menu-add.vue',
        'src\vue\src\app\admin2\dynamic-menu\dynamic-menu.vue',
        'src\vue\src\shared\components\g-model-audit-history-table',
        'src\vue\src\shared\components\g-model-audit-history-view',
        'src\vue\src\shared\components\g-ndo-select',
        'src\vue\src\shared\components\g-ndo-table',
        'src\vue\src\shared\component-base\g-ndo-edit-component-base.js',
        'src\vue\src\shared\component-base\g-ndo-paged-listing-component-base.js'
        # 'src\vue\',
    )
    foreach ($item in $removeItems) {
        $path2 = [System.IO.Path]::Join($rootPath, $item)
        if ((Test-Path $path2)) {
            Remove-Item -Force -Recurse -Path $path2
        }
    }
}

# 将admin目录移除，并将admin2目录修改为admin
function MoveAdmin2 {
    param (
        $path
    )
    $adminPath = [System.IO.Path]::Join($path, 'src\vue\src\app\admin')
    $admin2Path = [System.IO.Path]::Join($path, 'src\vue\src\app\admin2')
   

    # 移动admin目录中的文件到admin2目录中
    $moveFiles = (
        'apk-managements/apk-managements.vue',
        'apk-managements/create-or-edit-apk-management/create-or-edit-apk-management.vue',
        'host-settings/host-settings.vue',
        'tenant-settings/tenant-settings.vue',
        'file-manager/file-manager.vue',
        'file-manager/create-directory.vue',
        'file-manager/move-file.vue',
        'file-manager/rename.vue',
        'my-settings/change-password.vue',
        'my-settings/login-attempts-modal.vue',
        'my-settings/my-settings.vue'
    )
    foreach ($item in $moveFiles) {
        $path2 = [System.IO.Path]::Join($admin2Path, $item)
        if (!(Test-Path $path2)) {
            $path1 = [System.IO.Path]::Join($adminPath, $item)

            $dirName = [System.IO.Path]::GetDirectoryName($path2)
            if (!(Test-Path $dirName)) {
                New-Item -ItemType Directory -Path $dirName -Force | Out-Null
            }
            Copy-Item -Force $path1 -Destination $path2
        }
    }
    # 移除admin目录
    Remove-Item -Force -Recurse  -Path $adminPath

    # 清除vue路径兼容问题
    VueClearNews -Path $path

   
    # 重命名admin2为admin
    Start-Sleep -Seconds 10
    Rename-Item -Force -Path $admin2Path -NewName 'admin'

}


# 清除前端文件中admin2的兼容问题
function VueClearNews {
    param (
        [string]$path
    )

    $files = GetProjFilesOnlyVue -Path $path
    foreach ($item in $files) {
        $path = $item.FullName


        # 替换前端文件中的内容
        if ($path.EndsWith(".vue") -or $path.EndsWith(".ts") -or $path.EndsWith(".tsx") -or $path.EndsWith(".less") -or $path.EndsWith(".json") -or $path.EndsWith(".nswag") -or $path.EndsWith(".ps1")) {
            # 读取文件内容
            $content = ReadFile -Path $path
            
            # 替换 import 中的 -news 为 空字符串
            $content = $content -Replace "import GNdoPagedListingComponentBase from './g-ndo-paged-listing-component-base';", ''
            $content = $content -Replace "GNdoPagedListingComponentBase,", ''
            $content = $content -Replace '-news', ''
            $content = $content -Replace '/admin2/', '/admin/'
            $content = $content -Replace '/saas2/', '/saas/'
            $content = $content -Replace '/system2/', '/system/'
            $content = $content -Replace 'FoundationTemplate', 'Foundation'
            $content = $content -Replace [Regex]::Escape('Foundation.Template'), 'Foundation'
            $content = $content -Replace [Regex]::Escape('http://localhost:6298'), 'http://localhost:6698'            
            $content = $content -Replace [Regex]::Escape('import { ProjectLicense } from ''../service-proxies'';'), ''
            $content = $content -Replace [Regex]::Escape('new ProjectLicense(JSON.parse(abp.setting.get(''License'')))'), '{ isExpires: false }'
            $content = $content -Replace [Regex]::Escape('/@/project-license/set-license/set-license.vue'), '/@/layouts/blank/blank.vue'

            # 写入内容到文件
            WriteFile -Path $path  -Content $content
        }
    }
}
