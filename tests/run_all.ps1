# tests/run_all.ps1
$godotExe = 'C:\Users\user\Desktop\Godot_v4.7.1.exe'
$tests = @(
  'res://tests/integration/test_project_boot.gd',
  'res://tests/unit/test_run_domain.gd',
  'res://tests/unit/test_upgrade_catalog.gd',
  'res://tests/unit/test_player.gd',
  'res://tests/unit/test_enemy_and_projectile.gd',
  'res://tests/unit/test_weapon_controller.gd',
  'res://tests/unit/test_room_planner.gd',
  'res://tests/integration/test_room_manager.gd',
  'res://tests/integration/test_game_flow.gd',
  'res://tests/unit/test_boss.gd',
  'res://tests/integration/test_optional_assets.gd'
)
foreach ($t in $tests) {
  Write-Host "Running test: $t"
  $proc = Start-Process -FilePath $godotExe -ArgumentList "--headless", "--path", ".", "--script", $t -Wait -NoNewWindow -PassThru
  if ($proc.ExitCode -ne 0) {
    Write-Error "Godot test failed: $t with exit code $($proc.ExitCode)"
    exit 1
  }
}
Write-Host "Running editor parser/import check..."
$proc = Start-Process -FilePath $godotExe -ArgumentList "--headless", "--path", ".", "--editor", "--quit" -Wait -NoNewWindow -PassThru
if ($proc.ExitCode -ne 0) {
  Write-Error "Godot import/parser check failed with exit code $($proc.ExitCode)"
  exit 1
}
Write-Host "ALL TESTS PASSED SUCCESSFULLY!"
