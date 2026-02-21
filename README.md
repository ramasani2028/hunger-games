# 🎮 Hunger Games — Godot 4 Survival Game

A multiplayer survival game built in **Godot 4** using **GDScript**, inspired by the Hunger Games. Players compete in timed levels, collecting items, completing role-based tasks, and surviving an AI antagonist that sabotages and deceives.

---

## 📁 Project Structure

```
hunger-games-main/
├── assets/              # 3D models, textures, images
├── scenes/              # Godot scene files (.tscn)
│   ├── mainscene.tscn
│   ├── level_1.tscn
│   ├── player.tscn
│   ├── house.tscn
│   └── location1.tscn
├── scripts/             # All GDScript files
│   ├── gamemanager.gd   # Central game controller (Autoload)
│   ├── player.gd        # Player character controller
│   ├── playerstate.gd   # Player state machine
│   ├── inventory.gd     # Inventory resource
│   ├── item.gd          # Collectible item
│   ├── interactable.gd  # Base interactable class
│   ├── generator.gd     # Generator (extends Interactable)
│   ├── level1.gd        # Level 1 logic
│   ├── aimaster.gd      # AI antagonist system
│   ├── uimanager.gd     # HUD and UI controller
│   ├── taskmanager.gd   # Role-based task system
│   ├── bomb.gd          # Bomb countdown mechanic
│   └── mainscene.gd     # Scene entry point
└── project.godot        # Godot project config
```

---

## 🧩 Scripts Overview

### 🎯 GameManager (`gamemanager.gd`)
The central Autoload singleton that controls the entire game. Manages:

- **Player Registry** — Register/remove players, query by ID
- **Action Permission System** — Enable/disable actions (MOVE, COLLECT, SNATCH, KILL, HIDE)
- **Action Validation** — Validates collect, interact, snatch, kill, and hide requests
- **Level Flow** — Start game, start/complete levels, track current level
- **Delta-Based Timer** — Frame-accurate countdown with throttled UI updates (0.2s)
- **Pause/Resume** — Pause and resume the level timer
- **Snatch/Kill Cooldowns** — Per-player cooldown tracking (5s snatch, 10s kill)
- **Noise System** — Accumulates noise per player with configurable decay rate
- **Noise Consequences** — 4-tier threshold system:
  - Warning (3.0) → AI warns
  - Detection (5.0) → Player exposed + penalty
  - Sabotage (7.5) → AI sabotages + risk tracked
  - Hazard (10.0) → Severe consequences
- **Detection & Sabotage Tracking** — Per-player penalty/risk with slow decay
- **Fake Objective System** — 35% chance deception triggered on danger/difficulty increase
- **Clue System** — Register clues, threshold-based real objective reveal, counterplay
- **Difficulty Scaling** — Progressive modifiers for timer, noise, AI lies, and bomb speed
- **Elimination & Game Over** — Player elimination with alive-count game over check

### 🧑 Player (`player.gd`)
Character controller with state machine integration:

- WASD movement with noise emission
- Action requests (collect, interact, snatch, kill, hide) — intent-only, validated by GameManager
- Inventory interface wrapper
- State machine-driven alive checks and state transitions
- Elimination handling with GameManager signal connection

### 🧠 PlayerState (`playerstate.gd`)
Finite state machine with guarded transitions:

- **States**: IDLE, MOVING, INTERACTING, HIDING, EXPOSED, DEAD
- **Transition rules**: e.g., HIDING → only IDLE or EXPOSED; DEAD → terminal
- **Force overrides**: `force_dead()` and `force_exposed()` bypass transition rules

### 🎒 Inventory (`inventory.gd`)
Resource-based inventory system:

- Add/remove items with capacity limit (default 5)
- Steal random item mechanic
- Role calculation based on dominant item (Wood→Carpenter, Metal→Mechanic, etc.)
- Required item checks with missing item reporting

### 📦 Item (`item.gd`)
Collectible item with collision detection:

- Auto-collection on `body_entered` via `request_collect()`
- Noise emission on collect
- Enable/disable collection state
- Double-collection guard

### 🔧 Interactable (`interactable.gd`)
Base class for interactive objects:

- Interaction enable/disable toggle
- Alive check on player
- Noise emission on interaction

### ⚡ Generator (`generator.gd`)
Extends Interactable — repairable generator:

- Required items check
- Single-use support
- TaskManager integration for task completion

### 📋 TaskManager (`taskmanager.gd`)
Role-based task assignment:

- Assigns tasks based on player's inventory role (Mechanic→Generator Fix, etc.)
- Task validation against required items
- Generator repair on task completion (via scene groups)

### 🤖 AIMaster (`aimaster.gd`)
AI antagonist with dialogue and sabotage:

- **Dialogue pools**: Intro, mysterious, warning, and lie lines
- **Corruption escalation**: Progressive behavior from mysterious → warning → lies
- **Sabotage system** with cooldowns (8s per player):
  - Fake Noise — injects noise at player position
  - Control Glitch — forces player to EXPOSED
  - Objective Distortion — triggers fake objective
  - Sensor Distortion — mysterious dialogue
- **Event reactions**: Responds to level start, player noise, elimination, clues, difficulty

### 💣 Bomb (`bomb.gd`)
Countdown bomb mechanic:

- Configurable countdown (default 120s)
- Delta-based timer
- Diffuse (safe deactivation) and explode (eliminates owner)
- GameManager elimination integration

### 🖥️ UIManager (`uimanager.gd`)
HUD and notification controller:

- Timer display, objective text, message/warning display
- Signal-driven updates from GameManager
- Level transition messages
- Game over display

### 🏠 Level1 (`level1.gd`)
Level 1 game logic:

- 4-minute timer
- Spawns 20 items at random spawn points
- Assigns 2-4 required items per player from item pool
- Tracks collection per player
- Eliminates incomplete players on timer end

### 🎬 MainScene (`mainscene.gd`)
Scene entry point:

- Registers all Player nodes with GameManager
- Connects to level start/complete signals

---

## 🔧 Systems Architecture

```
MainScene
├── GameManager (Autoload)
│   ├── Timer System (delta-based)
│   ├── Action Validator
│   ├── Noise System (accumulation + decay + thresholds)
│   ├── Fake Objective System
│   ├── Clue System
│   ├── Difficulty Scaler
│   └── Elimination System
├── AIMaster (Autoload)
│   ├── Dialogue System
│   ├── Corruption Escalation
│   └── Sabotage System (cooldown-managed)
├── UIManager
│   └── HUD (timer, objective, messages)
├── Level1
│   ├── Item Spawner
│   └── Objective Tracker
├── TaskManager
│   └── Role-Based Tasks
└── Players
    ├── PlayerState (FSM)
    └── Inventory (Resource)
```

---

## 🎮 How It Works

1. **MainScene** registers all players with **GameManager**
2. **Level1** starts → timer begins, items spawn, required items assigned
3. Players move (WASD) → noise accumulates → AI reacts at thresholds
4. Players collect items → inventory fills → role determined
5. **TaskManager** assigns role-based tasks → players interact with generators
6. **AIMaster** sabotages players (fake noise, glitches, fake objectives)
7. Players find clues → can detect fake objectives → reveal truth
8. Timer ends → incomplete players eliminated
9. Difficulty increases each level → shorter timers, more noise, more AI lies

---

## 🛠️ Setup

1. Open in **Godot 4.x**
2. Set `GameManager` and `AIMaster` as **Autoloads** in Project Settings
3. Add `PlayerState` as a child node of the Player scene
4. Add Generator nodes to the `"generators"` group
5. Configure input actions: `move_forward`, `move_backward`, `move_left`, `move_right`

---

## 👤 Author

**Sai Kiran Maruri**

---