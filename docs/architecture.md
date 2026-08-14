# 《暮墓餘燼》專案架構

本文件依目前程式碼整理，描述 `Ashes at Dusk` 的技術棧、主要模組、執行期資料流與測試邊界。

## 技術棧

| 分類 | 技術 | 專案用途 |
| --- | --- | --- |
| 遊戲引擎 | Godot Engine 4.7.1 | 2D 場景樹、物理、輸入、音效與 UI 執行環境 |
| 程式語言 | GDScript 2.0 | 遊戲流程、戰鬥、敵人 AI、房間規劃與介面邏輯 |
| 場景與資源 | `.tscn`、PNG、WAV | PackedScene 組裝、背景圖與遊戲音效 |
| 視覺效果 | Godot CanvasItem Shader | UI 模糊與遮罩效果 |
| 測試 | Godot Headless、PowerShell | 單元、整合、場景啟動與資源匯入驗證 |
| 版本控制 | Git、GitHub | 原始碼、文件與資源版本管理 |

## 元件架構圖

```mermaid
flowchart TB
    User([玩家])
    Runtime["Godot 4.7.1 Runtime<br/>輸入・場景樹・2D 物理・音效"]

    subgraph Composition["組裝層｜scenes/main.tscn"]
        Main["Main<br/>Composition Root"]
    end

    subgraph Presentation["呈現層｜src/presentation + src/ui"]
        Backdrop["GraveyardBackdrop<br/>墓園背景與出口提示"]
        UI["CanvasLayer UI<br/>TitleScreen・HUD<br/>UpgradePanel・ResultsScreen"]
        Audio["AudioBus<br/>環境音與 SFX"]
    end

    subgraph Application["應用協調層｜src/core"]
        Controller["GameController<br/>遊戲流程與訊號協調"]
        Phase["GamePhase<br/>狀態轉移規則"]
        Config["RunConfig<br/>正式／展示模式設定"]
    end

    subgraph Gameplay["遊戲層｜src/player + src/combat + src/rooms + src/enemies"]
        Player["Player<br/>移動・生命・受傷"]
        Weapon["WeaponController<br/>自動索敵・武器迴圈"]
        Rooms["RoomManager<br/>生成・追蹤・清理敵人"]
        Enemies["Enemy 系列<br/>Zombie・Archer・Bat<br/>Knight・Boss"]
        Projectile["Projectile<br/>雙陣營碰撞與傷害"]
    end

    subgraph Domain["領域資料與規則｜RefCounted／靜態服務"]
        Stats["PlayerStats<br/>生命與戰鬥屬性"]
        Planner["RoomPlanner<br/>房間、難度與門獎勵"]
        Plan["RoomPlan<br/>單一房間配置"]
        Upgrade["UpgradeCatalog<br/>升級選項與套用規則"]
        Copy["CopyZhTw<br/>繁中介面文案"]
    end

    subgraph Resources["Godot 資源層"]
        Scenes["PackedScene<br/>Player・Enemy・Boss<br/>Projectile・UI"]
        Assets["assets/<br/>PNG 背景・WAV 音效"]
        Shader["blur.gdshader<br/>CanvasItem 後製"]
    end

    subgraph Quality["驗證層｜tests"]
        Runner["tests/run_all.ps1"]
        Unit["7 組單元測試<br/>領域與戰鬥規則"]
        Integration["4 組整合測試<br/>場景啟動・流程・資源"]
    end

    User -->|WASD・選門・選升級・暫停| Runtime
    Runtime --> Main
    Main --> Backdrop
    Main --> UI
    Main --> Audio
    Main --> Controller
    Main --> Player
    Main --> Rooms
    Player --> Weapon

    UI -->|開始、選門、選升級、重試訊號| Controller
    Controller -->|更新畫面| UI
    Controller -->|播放音效| Audio
    Controller -->|檢查合法轉移| Phase
    Controller -->|建立一輪遊戲| Config
    Controller <-->|共用目前屬性| Stats
    Controller -->|規劃下一房| Planner
    Planner --> Plan
    Plan -->|生成指令| Rooms
    Controller -->|套用屬性與武器等級| Player
    Controller -->|設定裝備與清理狀態| Weapon
    Controller -->|取得選項／套用升級| Upgrade
    Upgrade -->|回傳新屬性與武器等級| Controller

    Rooms -->|實例化與追蹤| Enemies
    Weapon -->|玩家攻擊| Projectile
    Enemies -->|弓箭／Boss 彈幕| Projectile
    Projectile -->|碰撞傷害| Player
    Projectile -->|碰撞傷害| Enemies
    Enemies -->|死亡、房間清除訊號| Rooms
    Rooms -->|擊殺、房間清除訊號| Controller
    Player -->|生命、受傷、死亡訊號| Controller
    Weapon -->|實際傷害訊號| Controller

    Scenes -.->|綁定腳本與節點| Main
    Scenes -.-> Player
    Scenes -.-> Enemies
    Scenes -.-> Projectile
    Assets -.-> Backdrop
    Assets -.-> Audio
    Shader -.-> UI
    Copy -.-> UI

    Runner -->|啟動 Godot Headless| Unit
    Runner -->|匯入並啟動專案| Integration
    Unit -.-> Domain
    Unit -.-> Gameplay
    Integration -.-> Main
    Integration -.-> Controller

    classDef external fill:#f7f7f7,stroke:#555,color:#111;
    classDef composition fill:#eadcff,stroke:#6f42c1,color:#211238;
    classDef presentation fill:#d9efff,stroke:#1677a8,color:#102a3a;
    classDef application fill:#ffe1b8,stroke:#b65f00,color:#3d2305;
    classDef gameplay fill:#dff5df,stroke:#2f7d32,color:#143516;
    classDef domain fill:#fff4c2,stroke:#927400,color:#332900;
    classDef resource fill:#ececec,stroke:#666,color:#222;
    classDef quality fill:#ffdfe7,stroke:#a63d58,color:#3b1320;

    class User,Runtime external;
    class Main composition;
    class Backdrop,UI,Audio presentation;
    class Controller,Phase,Config application;
    class Player,Weapon,Rooms,Enemies,Projectile gameplay;
    class Stats,Planner,Plan,Upgrade,Copy domain;
    class Scenes,Assets,Shader resource;
    class Runner,Unit,Integration quality;
```

## 執行期狀態流

`GameController` 是流程的唯一協調者，所有階段切換都必須通過 `GamePhase.can_transition()`。

```mermaid
stateDiagram-v2
    [*] --> TITLE
    TITLE --> COMBAT: 選擇正式／展示模式
    COMBAT --> DOORS: 清除非最終房間
    DOORS --> UPGRADE: 選擇武器／能力／詛咒門
    DOORS --> COMBAT: 選擇治療門
    UPGRADE --> UPGRADE: 還有升級次數
    UPGRADE --> COMBAT: 套用全部升級
    COMBAT --> PAUSED: Esc
    PAUSED --> COMBAT: Esc
    COMBAT --> RESULTS: 死亡／逾時／擊敗 Boss
    DOORS --> RESULTS: 結束事件
    UPGRADE --> RESULTS: 結束事件
    PAUSED --> RESULTS: 結束事件
    RESULTS --> TITLE: 返回標題
    RESULTS --> TITLE: 重試前重設
    TITLE --> COMBAT: 以原模式重試
```

## 核心資料流

1. `main.tscn` 建立所有長生命週期節點，並把節點引用注入 `GameController`。
2. UI 只送出操作訊號；`GameController` 驗證目前階段後決定房間、升級、暫停或結算流程。
3. `RoomPlanner` 依 `RunConfig`、房間序號與詛咒狀態產生 `RoomPlan`，再由 `RoomManager` 實例化敵人與 Boss。
4. `PlayerStats` 是玩家與武器共用的執行期屬性來源；`UpgradeCatalog` 回傳更新後的屬性與武器等級，由控制器同步套用。
5. 戰鬥結果透過 Godot signal 回到控制器，控制器再更新 HUD、音效、吸血、房間進度與結算畫面。
6. `tests/run_all.ps1` 以 Godot Headless 執行單元與整合測試，並先做專案匯入／解析檢查。
