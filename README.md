# 暮墓餘燼 (Ashes at Dusk)

《暮墓餘燼 Ashes at Dusk》是一款基於 Godot 4.7.1 開發的 2D 房間式 Roguelike 自動攻擊生存動作遊戲。玩家扮演受詛咒的獵魔人，在七分鐘的生存極限內，透過移動閃避、自動攻擊、房間路線決策與武器升級組合，最終戰勝「無首守墓人」。

---

## 快速啟動

### 環境要求
- **作業系統**：Windows 10 / 11
- **引擎版本**：Godot Engine `v4.7.1.stable.official.a13da4feb` (`C:\Users\user\Desktop\Godot_v4.7.1.exe`)

### 執行遊戲
在專案根目錄中執行以下命令啟動：

```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --path .
```

---

## 遊戲控制 (Controls)

- **移動**：`WASD` 或方向鍵（八方向移動）
- **攻擊**：全自動攻擊最近目標（無需手動瞄準或攻擊鍵）
- **升級選擇**：滑鼠點擊卡片，或使用鍵盤數字鍵 `1` / `2` / `3`
- **房門選擇**：走入左側或右側黃金門
- **暫停 / 選單**：`Esc` 鍵

---

## 遊戲模式 (Run Modes)

1. **正式模式（7 分鐘）**：
   - 完整 7 個房間體驗（房間 1~6 為波次戰鬥，房間 7 為 Boss 戰）。
   - 7 分鐘硬性倒數，隨機亂數種子，挑戰最高擊殺與完整構築。

2. **快速展示模式 (Demo Mode)**：
   - 75 秒快速體驗，使用固定亂數種子 (`4701`)。
   - 縮短波次間隔與敵人生成數量，適合展示、測試與錄影使用。

---

## 專案結構 (Directory Structure)

```
Game/
├── project.godot                     # Godot 專案設定檔 (1280x720 畫布)
├── README.md                         # 專案說明文件
├── .gitignore                        # Git 忽略設定
├── assets/                           # 美術與音效資源
│   ├── generated/                    # 生成背景與標題圖
│   └── audio/                        # 音效與背景音
├── docs/                             # 課程與驗收文件
│   ├── game-report.md                # 遊戲報告與開發揭露
│   └── recording-guide.md            # 一分鐘影片錄影指南
├── scenes/                           # 遊戲場景
│   ├── main.tscn                     # 遊戲總組合根
│   ├── player/                       # 玩家場景
│   ├── enemies/                      # 敵人與 Boss 場景
│   ├── combat/                       # 投射物場景
│   └── ui/                           # HUD、標題、升級與結算介面
├── src/                              # GDScript 邏輯代碼
│   ├── core/                         # 遊戲狀態、計數器、雙語文案
│   ├── player/                       # 玩家移動與生命 logic
│   ├── enemies/                      # 敵人 AI 與 Boss 招式
│   ├── combat/                       # 自動武器控制器
│   ├── upgrades/                     # 升級目錄與抽選邏輯
│   ├── rooms/                        # 房間生成與門獎勵邏輯
│   └── presentation/                 # 音效與圖形備援渲染
└── tests/                            # 單元與整合測試
    ├── support/                      # 測試斷言工具
    ├── unit/                         # 各模組純邏輯單元測試
    ├── integration/                  # 主流程與場景整合測試
    └── run_all.ps1                   # 一鍵全自動測試腳本
```

---

## 自動測試 (Automated Tests)

本專案具備全自動 Headless 測試與語法編譯檢查。執行以下命令即可跑完所有測試：

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1
```

---

## 匯出 Windows 執行檔 (Windows Export)

1. 在 Godot 4.7.1 編輯器中開啟本專案。
2. 點擊菜單 `專案 (Project) -> 匯出 (Export)`。
3. 新增 `Windows Desktop` 預設範本。
4. 點擊 `匯出專案 (Export Project)` 並選擇匯出路徑與 `.exe` 檔名即可。

---

## 疑難排解 (Troubleshooting)

- **無音效或視覺遺失**：專案內建代碼繪製（Code-drawn fallback）與音效安全檢查機制。即使 `assets/` 遺失，遊戲仍可正常運作而不崩潰。
- **解析度縮放**：預設基準畫布為 `1280x720`，採用 `canvas_items` 與 `keep` 模式，在 `1920x1080` 螢幕下自動等比例清晰縮放。
