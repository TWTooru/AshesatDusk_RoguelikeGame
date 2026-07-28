# 暮墓餘燼 (Ashes at Dusk) - EMBERS Roguelike Game

《暮墓餘燼 Ashes at Dusk》是一款基於 **Godot 4.7.1** 開發的 2D 房間式 Roguelike 自動攻擊生存動作遊戲。遊戲採用獨特的**文字符號視覺風格**，將玩家、怪物、Boss 與彈幕以高對比中文書法文字直接繪製於遊戲世界中。

玩家扮演受詛咒的獵魔人「**玩家**」，在生存極限內透過移動閃避、自動攻擊、房間路線決策（實體走門進關）與武器升級組合，最終戰勝第 7 關 Boss「**無首守墓人**」。

---

## 📖 遊戲介紹 (Game Overview)

### 核心玩法與特點
- **文字符號視覺藝術 (Text-Based Visual Art)**：
  遊戲中無繁雜貼圖，角色與怪物皆為高對比中文字體（`玩家`、`腐屍`、`骸骨弓手`、`暗影蝙蝠`、`墓園騎士`、`無首守墓人`），搭配 4 方向深黑描邊與 HSL 亮彩，兼具視覺衝擊與極致流暢度。
- **自動瞄準與戰鬥 (Auto-Attacking Combat)**：
  玩家專注於 WASD 走位與拉扯，3 種特色自動武器（`幽魂彈`、`骨刃環`、`冥火法陣`）會自動追蹤或繞行打擊敵人。
- **實體走門房間系統 (Physical Door Transition)**：
  每當房間敵人清空，左右兩側牆壁會開啟亮綠色實體門戶（如 `【走進左門: 武器祭壇】`）。玩家只需**控制角色直接走進左門或右門**，即可 seamless 進入下一關！
- **選單與能力暫停 (Pause During Upgrade)**：
  當進入能力選擇卡牌或房間門戶選擇時，遊戲倒數計時器會完全暫停，讓玩家能安心思考路線與構築。
- **磨砂玻璃 UI 著色器 (80% Blur Shader)**：
  標題畫面、能力選擇卡牌與戰報頁面均配備 80% 畫面的 Screen Blur Shader，營造極具質感的暗黑奇幻氛圍。

### 遊戲控制 (Controls)
| 操作 | 按鍵 |
| :--- | :--- |
| **移動** | `WASD` 或 方向鍵（八方向移動） |
| **攻擊** | 自動鎖定最近敵人打擊（無需手動瞄準） |
| **進入下一關** | 控制角色**走進左側或右側牆壁門戶**（或點擊上方按鈕） |
| **升級選擇** | 滑鼠點擊卡片，或使用鍵盤數字鍵 `1` / `2` / `3` |
| **暫停 / 選單** | `Esc` 鍵 |

### 遊戲模式 (Modes)
1. **正式模式（7 分鐘 / 7 關）**：
   - 完整 7 個房間體驗（房間 1~6 為波次戰鬥，房間 7 為 Boss 戰）。
   - 7 分鐘硬性倒數，隨機亂數種子，挑戰最高擊殺與完整構築。
2. **快速展示模式（1 分鐘 / 4 關）**：
   - 1 分鐘（60 秒）快速體驗，固定亂數種子 (`4701`)。
   - 總共 4 個房間，精簡敵人波次與比例，第 4 關直接迎戰 Boss。

---

## 🛠️ 開發工具 (Development Tools)

- **遊戲引擎 (Engine)**：Godot Engine `v4.7.1.stable` (GDScript 2.0)
- **開發與調試環境**：Windows 11 PowerShell, Godot Headless CLI execution
- **測試框架 (Test Framework)**：自研輕量化自動測試套件（11 項單元與整合測試，支援 Headless 執行）
- **著色器與視覺 (Shaders & Rendering)**：
  - Godot 2D Canvas Shader (`hint_screen_texture` 80% Mipmap Blur)
  - GDScript `draw_string` 幾何與字型基線（Ascent/Descent）精確對齊
  - 4-Directional Outline 筆刷演算法
- **圖像處理工具**：Python Pillow (PIL)
- **版本控制 (VCS)**：Git & GitHub (`TWTooru/EMBERS_RoguelikeGame`)

---

## 📜 開發過程說明 (Development Process)

### 階段一：核心框架與遊戲機制建立
1. **架構設計**：確立專案架構（`src/core` 狀態機與領域邏輯、`src/player` 玩家運動學、`src/enemies` 敵人 AI、`src/combat` 武器控制器、`src/rooms` 房間生成器）。
2. **自動測試優先**：編寫 `tests/run_all.ps1` 與 11 個測試腳本，確保所有領域邏輯（傷害計算、房間規劃、升級卡牌抽選）皆可自動驗證。

### 階段二：文字符號視覺革命 (Text-Based Transformation)
1. **視覺風格轉變**：因應設計需求，將幾何圖形實體全面替換為中文文字繪製。
2. **精確字型基線對齊**：解決中文字體偏下問題，採用 `(font.get_ascent() - font.get_descent()) / 2.0` 公式將文字幾何中心完美鎖定於實體 `(0, 0)` 物理碰撞中心。

### 階段三：視覺可見度與高質感 UI 強化
1. **圖層與高對比修正**：將怪物與彈幕文字提升至 `z_index = 10+`，並加入 4 向深黑描邊與放大字體，使實體在暗黑背景上極度清晰。
2. **80% 螢幕模糊背景**：編寫 `blur.gdshader`，為主畫面、升級選單與結算面板加入高級磨砂玻璃模糊背景。

### 階段四：玩家體驗（UX）與操作優化
1. **實體走門進關**：將靜態門框升級為可碰撞互動區域，玩家清空房間後直接操控角色「走進左門/右門」即可進入下一關。
2. **獨立彈幕座標系**：修正彈幕節點掛載層級，將發射物掛載於世界根場景，徹底解決「玩家移動子彈跟著偏移」的現象。
3. **能力選擇時間暫停**：暫停計時器於升級與選門階段，保障玩家思考時間。
4. **展示模式調校**：將展示模式設定為 1 分鐘 / 4 關，便於快速驗收 Boss 戰與流暢展示。

### 階段五：匯出與穩定性修正
1. **匯出警示與讀取修復**：修正 `Image.load_from_file` 的相對路徑警告，採用 `ProjectSettings.globalize_path` 及 `ResourceLoader` 雙軌安全讀取。
2. **空值腳本防護**：修正 `RoomManager._spawn_boss` 中 CharacterBody2D 實例化與腳本掛載順序，消除所有執行階段報錯。

---

## 🚀 快速啟動與測試 (Quick Start)

### 執行遊戲
```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --path .
```

### 執行自動測試套件
```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1
```

---

## 🔗 GitHub 儲存庫
本專案完整原始碼已同步託管於：[TWTooru/EMBERS_RoguelikeGame](https://github.com/TWTooru/EMBERS_RoguelikeGame)
