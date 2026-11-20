param(
    [string]$DeviceId = "00055344B000073"
)

function Capture-Screen([string]$filename) {
    adb -s $DeviceId shell screencap -p /sdcard/temp_cap.png
    adb -s $DeviceId pull /sdcard/temp_cap.png "screenshots/$filename" | Out-Null
    Copy-Item "screenshots/$filename" "assets/screenshots/$filename" -Force
    $bytes = [System.IO.File]::ReadAllBytes("screenshots/$filename")
    $magic = ($bytes[0..3] | ForEach-Object { $_.ToString("X2") }) -join " "
    Write-Host "Captured $filename ($($bytes.Length) bytes) Magic: $magic"
}

Write-Host "--- Starting Bento Dark Captures ---"
# 1. Bento Home Dark
# Ensure in Work mode & Home tab
adb -s $DeviceId shell input tap 120 2228
Start-Sleep -Milliseconds 400
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 700
Capture-Screen "01_bento_home_dark.png"

# 2. Bento Notes Dark
adb -s $DeviceId shell input tap 410 2228
Start-Sleep -Milliseconds 700
Capture-Screen "02_bento_notes_dark.png"

# 3. Bento Tasks Dark
adb -s $DeviceId shell input tap 544 2228
Start-Sleep -Milliseconds 700
Capture-Screen "03_bento_tasks_dark.png"

# 4. Bento Planner Dark
adb -s $DeviceId shell input tap 678 2228
Start-Sleep -Milliseconds 700
Capture-Screen "04_bento_planner_dark.png"

# 5. Bento Habits Dark (From Home, tap streak chip)
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 600
adb -s $DeviceId shell input tap 865 443
Start-Sleep -Milliseconds 900
Capture-Screen "05_bento_habits_dark.png"
adb -s $DeviceId shell input keyevent 4
Start-Sleep -Milliseconds 600

# 6. Bento Expenses Dark (Switch to Life, tap Expenses)
adb -s $DeviceId shell input tap 120 2228
Start-Sleep -Milliseconds 600
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 800
Capture-Screen "06_bento_expenses_dark.png"

# 7. Bento Dial Dark
adb -s $DeviceId shell input tap 825 2228
Start-Sleep -Milliseconds 900
Capture-Screen "07_bento_dial_dark.png"
adb -s $DeviceId shell input keyevent 4
Start-Sleep -Milliseconds 600

# 8. Bento NODO AI Dark
adb -s $DeviceId shell input tap 945 1900
Start-Sleep -Milliseconds 1000
Capture-Screen "08_bento_nodo_ai_dark.png"
adb -s $DeviceId shell input keyevent 4
Start-Sleep -Milliseconds 600

Write-Host "--- Switching to Light Mode ---"
# Tap Theme Toggle (top right x=1010, y=198)
adb -s $DeviceId shell input tap 1010 198
Start-Sleep -Milliseconds 800

Write-Host "--- Starting Bento Light Captures ---"
# Ensure Work mode & Home tab
adb -s $DeviceId shell input tap 120 2228
Start-Sleep -Milliseconds 400
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 700
Capture-Screen "01_bento_home_light.png"

# 2. Bento Notes Light
adb -s $DeviceId shell input tap 410 2228
Start-Sleep -Milliseconds 700
Capture-Screen "02_bento_notes_light.png"

# 3. Bento Tasks Light
adb -s $DeviceId shell input tap 544 2228
Start-Sleep -Milliseconds 700
Capture-Screen "03_bento_tasks_light.png"

# 4. Bento Planner Light
adb -s $DeviceId shell input tap 678 2228
Start-Sleep -Milliseconds 700
Capture-Screen "04_bento_planner_light.png"

# 5. Bento Habits Light
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 600
adb -s $DeviceId shell input tap 865 443
Start-Sleep -Milliseconds 900
Capture-Screen "05_bento_habits_light.png"
adb -s $DeviceId shell input keyevent 4
Start-Sleep -Milliseconds 600

# 6. Bento Expenses Light
adb -s $DeviceId shell input tap 120 2228
Start-Sleep -Milliseconds 600
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 800
Capture-Screen "06_bento_expenses_light.png"

# 7. Bento Dial Light
adb -s $DeviceId shell input tap 825 2228
Start-Sleep -Milliseconds 900
Capture-Screen "07_bento_dial_light.png"
adb -s $DeviceId shell input keyevent 4
Start-Sleep -Milliseconds 600

# 8. Bento NODO AI Light
adb -s $DeviceId shell input tap 945 1900
Start-Sleep -Milliseconds 1000
Capture-Screen "08_bento_nodo_ai_light.png"
adb -s $DeviceId shell input keyevent 4
Start-Sleep -Milliseconds 600

Write-Host "--- Restoring Dark Home ---"
adb -s $DeviceId shell input tap 1010 198
Start-Sleep -Milliseconds 600
adb -s $DeviceId shell input tap 120 2228
Start-Sleep -Milliseconds 400
adb -s $DeviceId shell input tap 275 2228
Start-Sleep -Milliseconds 500

Write-Host "--- Done! ---"
