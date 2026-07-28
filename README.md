# 《暮墓餘燼 (Ashes at Dusk)》

---

## 📖 遊戲介紹 (Game Overview)

### 1. 市場痛點與設計回應 (Market Demand Response)
在當今遊戲市場中，玩家對「碎片化時間」、「低學習門檻」與「高視覺辨識度」的需求大幅提升：
- **極簡符號視覺 (Text-Based Visual Art)**：回應當前文字遊戲與簡約暗黑風熱潮，擺脫過度複雜貼圖，將玩家、怪物、彈幕全數以高對比中文書法文字實體（`玩家`、`腐屍`、`骸骨弓手`、`暗影蝙蝠`、`墓園騎士`、`無首守墓人`）繪製，視覺極致清晰且記憶點強烈。
- **快節奏零負擔操作 (Auto-Attacking Combat)**：回應類倖存者（Survivor-like）熱潮，玩家僅需掌控 `WASD` 八方向移動走位，自動鎖定武器（`幽魂彈`、`骨刃環`、`冥火法陣`）全自動打擊周圍敵軍。

### 2. 玩家新手操作指南 (How to Play)
- **移動 (Move)**：按下鍵盤 `W` / `A` / `S` / `D` 或 `方向鍵` 自由控制「玩家」走位。
- **自動戰鬥 (Auto Combat)**：武器自動搜尋打擊最近敵人。
- **能力升級與吸血 (Upgrades & Lifesteal)**：點擊或按鍵 `1/2/3` 選擇卡牌，解鎖新武器或強化「傷害吸血」（每次造成傷害皆回復生命並觸發**亮綠色閃光**）。選擇能力時時間完全暫停。
- **實體門戶進關 (Enter Doors)**：波次清空後，操控主角直接走進左側或右側邊界牆壁即可自動傳送進入下個房間（武器祭壇、禁忌能力、療癒聖泉、詛咒寶箱）。

---

## 🛠️ 開發工具 (Development Tools)

- **遊戲引擎 (Engine)**：Godot Engine `v4.7.1.stable` (GDScript 2.0)
- **AI 協作與生成工具 (AI & Agent Tools)**：
  - **Antigravity AI Agent System**：輔助遊戲架構規劃、領域模型建構、GDScript 代碼生成與重構。
  - **AI 測試驅動套件**：透過 Headless CLI 腳本生成全自動單元測試（11 項測試腳本 100% 自動化驗收）。
  - **AI 圖像生成工具**：輔助生成暗黑墓園場景氛圍素材。
- **著色器與視覺技術 (Shaders & Graphics)**：
  - Godot 2D Canvas Shader (`blur.gdshader` 80% Mipmap Screen Blur 磨砂玻璃效果)。
  - GDScript `draw_string` 與字型基線 `(ascent - descent) / 2.0` 精確對齊演算法。
  - 4-Directional Outline 筆刷演算法。
- **版本控制 (VCS)**：Git & GitHub Remote (`TWTooru/EMBERS_RoguelikeGame`)

---

## 📜 開發過程說明 (Development Process)

### 階段一：市場需求分析與專案立項 (Market Analysis & Ideation)
分析現行 Roguelike 與倖存者遊戲市場，確立「文字符號視覺 + 自動戰鬥 + 房間式成長」的核心定位。利用 AI Agent 完成軟體架構設計，並預先建立 11 個 Headless 自動測試腳本（TDD 測試驅動開發），確保遊戲邏輯健全。

### 階段二：文字符號視覺革新 (Text-Based Visual Art Implementation)
將傳統 2D 貼圖/幾何圖形全面替換為中文文字繪製。克服 Godot 4 中文字體預設懸空的基線問題，計算 `(ascent - descent) / 2.0` 垂直偏移，將中文字文字心精確鎖定於物理碰撞中心，並加上 4 向筆刷深黑描邊以確保文字在高壓戰場中的清晰度。

### 階段三：高質感 UI 與磨砂玻璃著色器 (UI & Shader Enhancement)
針對現代玩家對 UI 質感的期待，編寫 `blur.gdshader` 著色器，為主畫面、升級選單及結算畫面加上 80% 高質感磨砂玻璃模糊背景，並將選單面板提升至獨立 `CanvasLayer 50~70`，徹底防止圖層穿透。

### 階段四：打擊反饋與玩家體驗調校 (Juice & UX Refinement)
1. **吸血機制與即時視覺回饋**：修復子彈傷害記錄，使吸血效果在所有武器上生效，並新增受傷（紅閃）與吸血（亮綠閃）之即時字體光芒。
2. **能力選擇時間暫停**：在能力升級與門戶決策時暫停倒數計時器，提升玩家思考體驗。
3. **快速展示模式**：設定 1 分鐘 / 4 關的極速展示模式，滿足以短影音推廣與簡報試玩的市場需求。

### 階段五：自動化測試與跨平台穩定性 (Verification & Publishing)
實作 `ProjectSettings.globalize_path` 消除所有 Resource 載入與匯出警示，解決 CharacterBody2D 實例化空值問題。最終通過 11 項單元與整合測試，並成功發布與推送到 GitHub 儲存庫。

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

## 展示影片


[TNDA實作－暮墓餘燼 (Ashes at Dusk)](https://youtu.be/oFwzDAdyBKc)

---

## 🔗 GitHub 儲存庫
本專案完整原始碼已同步託管於：[TWTooru/EMBERS_RoguelikeGame](https://github.com/TWTooru/EMBERS_RoguelikeGame)
