# Spotter

An iOS app that builds personalized workout plans, then watches every rep through AR and coaches your form in real-time.

**Stack:** Swift, ARKit (body tracking), RealityKit, SwiftData

---

## How It Works

```
You open the app
  → Pick today's workout (auto-generated from your plan)
  → Tap an exercise
  → Prop your phone up, full body visible
  → Do your set
  → App tracks your skeleton in real-time via ARKit
  → Joints light up green (good) or red (fix this)
  → Audio cue: "Knees out"
  → After the set: summary with per-rep scores
  → Progression engine suggests weight for next session
```

---

## Core Concepts

### 1. Pose Estimation (ARKit Body Tracking)

ARKit provides real-time 3D body tracking on iPhone (A12+ chip). It outputs 91 joint positions in world coordinates at 60fps. No custom ML model needed — Apple handles this.

The app receives a skeleton like:

```
nose, left_shoulder, right_shoulder,
left_elbow, right_elbow,
left_wrist, right_wrist,
left_hip, right_hip,
left_knee, right_knee,
left_ankle, right_ankle
```

Each joint has (x, y, z) coordinates in meters relative to the camera.

### 2. Joint Angles

Raw keypoints are converted to angles using trigonometry:

```
knee_angle = angle_between(hip, knee, ankle)
back_angle = angle_between(shoulder, hip, knee)
elbow_angle = angle_between(shoulder, elbow, wrist)
```

The formula:

```
angle = arctan2(y2 - y1, x2 - x1) - arctan2(y3 - y1, x3 - x1)
```

These angles are what we actually check for form — not the raw coordinates.

### 3. Rep Counter (State Machine)

Each exercise defines a "rep angle" (e.g. knee angle for squats). The state machine tracks:

```
STANDING (knee ~170°)
  → angle decreasing → DESCENDING
    → angle < bottom threshold → BOTTOM (knee ~85°)
      → angle increasing → ASCENDING
        → angle > top threshold → REP COMPLETE → STANDING
```

Detecting peaks and valleys in the angle signal = counting reps.

### 4. Form Rules

Each exercise has a set of rules checked per frame:

```
Squat rules:
  - depth:         knee_angle at bottom should reach 80-100°
  - knee_valgus:   knees should stay >= hip width apart
  - back_rounding: shoulder-hip angle should stay > 45°
  - heel_rise:     ankle position shouldn't shift upward
  - knee_tracking: knees shouldn't pass far beyond toes
```

Each rule returns: `(joint, severity, correction_text, direction)`

For example: `(left_knee, .error, "Push your knees outward", .lateral_out)`

### 5. Ghost Skeleton (Reference Form)

A pre-recorded "perfect rep" skeleton from a trainer, stored as JSON:

```json
[
  {"phase": 0.0, "joints": {"hip": [0, 0.9, 0], "knee": [0, 0.45, 0.02], ...}},
  {"phase": 0.25, "joints": {"hip": [0, 0.7, 0], "knee": [0, 0.35, 0.08], ...}},
  ...
]
```

At runtime:
1. Detect the user's current rep phase (0-100%).
2. Look up the reference skeleton at that phase.
3. Scale to the user's body proportions.
4. Render as a semi-transparent green skeleton in AR.

The user sees their own skeleton (blue) alongside the correct form (green) and tries to match.

### 6. Plan Generation

Two approaches:

**Template-based (offline):** ~20-30 pre-built programs (PPL, Upper/Lower, Full Body, etc.) selected based on onboarding answers (goal, experience, equipment, schedule).

**LLM-assisted (online):** Send onboarding data to GPT-4o-mini with a structured prompt. Returns a periodized program as JSON. Validated against the exercise library.

Hybrid recommended: templates as base, LLM for customization (injury accommodations, exercise swaps).

### 7. Progressive Overload Engine

After each session, the app decides what to suggest next time:

```
All sets completed + good form (>85%) → add weight (+5 lbs)
Sets completed but form broke down    → keep same weight
Failed to complete sets               → keep weight, adjust reps
Every 4th week                        → deload (reduce volume 40%)
```

This is what makes it a real training tool vs. just a form checker.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       iPhone App                         │
│                                                          │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │  Plan Engine  │    │  AR Tracker  │                   │
│  │               │    │              │                   │
│  │  Templates /  │    │  ARKit Body  │                   │
│  │  LLM plans   │    │  Tracking    │                   │
│  │  Progression  │    │  ↓           │                   │
│  │  suggestions  │    │  Angles      │                   │
│  └───────┬──────┘    │  ↓           │                   │
│          │            │  Rep Counter │                   │
│          │            │  ↓           │                   │
│          │            │  Form Rules  │                   │
│          │            │  ↓           │                   │
│          │            │  Renderer    │                   │
│          │            │  + Audio     │                   │
│          │            └──────┬──────┘                   │
│          │                   │                           │
│  ┌───────▼───────────────────▼──────┐                   │
│  │          Data Layer               │                   │
│  │                                   │                   │
│  │  UserProfile    WorkoutPlan       │                   │
│  │  WorkoutLog     ExerciseLibrary   │                   │
│  │  ProgressionHistory               │                   │
│  │                                   │                   │
│  │  (SwiftData / Core Data)          │                   │
│  └───────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
Spotter/
├── App/
│   ├── SpotterApp.swift              # App entry point
│   └── ContentView.swift             # Tab bar (Today, Plan, Progress, Profile)
│
├── AR/
│   ├── ARSessionManager.swift        # ARKit setup, body tracking delegate
│   ├── SkeletonRenderer.swift        # Draw joints + bones in RealityKit
│   └── GhostRenderer.swift           # Reference skeleton overlay
│
├── Engine/
│   ├── AngleCalculator.swift         # Keypoints → joint angles (trig)
│   ├── RepCounter.swift              # State machine, rep boundaries
│   ├── FormChecker.swift             # Run rules, return corrections
│   ├── PoseFrame.swift               # Data struct: joints + angles + timestamp
│   └── ProgressionEngine.swift       # Weight suggestions based on history + form
│
├── Exercises/
│   ├── ExerciseConfig.swift          # Protocol for exercise definitions
│   ├── ExerciseLibrary.swift         # Registry of all exercises
│   ├── SquatConfig.swift
│   ├── DeadliftConfig.swift
│   ├── PushupConfig.swift
│   ├── LungeConfig.swift
│   ├── OverheadPressConfig.swift
│   ├── RowConfig.swift
│   ├── PlankConfig.swift
│   └── CurlConfig.swift
│
├── Plan/
│   ├── PlanGenerator.swift           # Template selection + LLM customization
│   ├── Templates/                    # Pre-built program templates (JSON)
│   │   ├── upper_lower_4day.json
│   │   ├── push_pull_legs_6day.json
│   │   ├── full_body_3day.json
│   │   └── ...
│   └── PlanAdjuster.swift            # Auto-adjust plan every 4 weeks
│
├── UI/
│   ├── Onboarding/
│   │   ├── GoalsView.swift
│   │   ├── ExperienceView.swift
│   │   ├── EquipmentView.swift
│   │   └── ScheduleView.swift
│   ├── Today/
│   │   ├── TodayView.swift           # Today's workout overview
│   │   └── ExerciseStartView.swift   # Pre-exercise setup (camera position)
│   ├── Workout/
│   │   ├── WorkoutView.swift         # Main AR camera + overlays
│   │   ├── SetSummaryView.swift      # Post-set form report
│   │   └── WorkoutSummaryView.swift  # Post-workout summary
│   ├── Plan/
│   │   ├── PlanOverviewView.swift    # Current program overview
│   │   └── DayDetailView.swift       # Exercises for a specific day
│   ├── Progress/
│   │   ├── ProgressView.swift        # Charts: volume, form score, 1RM
│   │   └── ExerciseHistoryView.swift # Per-exercise drill-down
│   └── Profile/
│       └── ProfileView.swift         # Settings, onboarding edits
│
├── Audio/
│   ├── CuePlayer.swift               # Plays correction cues
│   └── Cues/                         # Pre-recorded audio files
│       ├── knees_out.m4a
│       ├── chest_up.m4a
│       ├── go_deeper.m4a
│       └── ...
│
├── Data/
│   ├── Models/
│   │   ├── UserProfile.swift
│   │   ├── WorkoutPlan.swift
│   │   ├── WorkoutLog.swift
│   │   ├── SetLog.swift
│   │   ├── RepLog.swift
│   │   └── ExerciseHistory.swift
│   ├── ReferenceData/                # Reference skeleton JSONs per exercise
│   │   ├── squat_reference.json
│   │   ├── deadlift_reference.json
│   │   └── ...
│   └── Persistence.swift             # SwiftData container setup
│
└── Resources/
    └── Assets.xcassets
```

---

## Data Model

```
UserProfile
  ├── goals: [String]           # ["build_muscle", "get_stronger"]
  ├── experience: String        # "intermediate"
  ├── equipment: [String]       # ["full_gym"]
  ├── injuries: [String]        # ["lower_back"]
  ├── daysPerWeek: Int          # 4
  ├── height, weight, age

WorkoutPlan
  ├── name: String              # "Hypertrophy Block 1"
  ├── weeks: Int                # 4
  ├── days[]
  │     ├── dayName: String     # "Upper Push"
  │     └── exercises[]
  │           ├── exerciseId    # "bench_press"
  │           ├── sets: Int     # 4
  │           ├── repsTarget    # 8
  │           └── restSeconds   # 120

WorkoutLog
  ├── date
  ├── duration
  ├── exercises[]
  │     ├── exerciseId
  │     ├── sets[]
  │     │     ├── weight
  │     │     ├── repsCompleted
  │     │     ├── formScore        # 0.0 - 1.0
  │     │     ├── arTrackingUsed   # true/false
  │     │     └── reps[]
  │     │           ├── repNumber
  │     │           ├── score       # good / okay / fix_form
  │     │           ├── corrections # ["knee_valgus"]
  │     │           └── angles      # snapshot of key angles
  │     └── notes: String?
```

---

## MVP Exercises (8)

| Exercise | Key Angles | Common Errors to Detect |
|---|---|---|
| Barbell Squat | knee, hip, back | Depth, knee valgus, forward lean, heel rise |
| Deadlift / RDL | hip hinge, back | Back rounding, lockout, bar path |
| Overhead Press | shoulder, elbow, back | Excessive arch, elbow flare, lockout |
| Push-up | elbow, hip | Sagging hips, flared elbows, depth |
| Lunge | front knee, torso | Knee over toe, torso lean, step length |
| Barbell Row | hip, back, elbow | Back rounding, excessive body swing |
| Plank | hip line | Hip sag, hip pike (isometric, track time) |
| Bicep Curl | elbow, shoulder | Shoulder swing, incomplete ROM |

---

## Build Phases

| Phase | Weeks | Milestone |
|---|---|---|
| **1 — AR Core** | 1-3 | ARKit body tracking, angle engine, skeleton renderer, squat form rules, rep counter |
| **2 — Workout Flow** | 4-5 | Exercise picker, set/rep logging, set summary, 5 exercises with AR |
| **3 — Plan Engine** | 6-7 | Template-based plans, onboarding, progression engine, weight suggestions |
| **4 — History** | 8 | Progress charts, form trends, workout history |
| **5 — Polish** | 9-10 | Ghost skeleton, audio cues, film reference data, TestFlight beta |
| **6 — AI Plan** | 11-12 | LLM plan generation, exercise swaps, injury accommodations |

---

## Tech Decisions

| Decision | Choice | Why |
|---|---|---|
| Platform | iOS only | ARKit body tracking is far ahead of ARCore |
| Min iOS | 17.0 | SwiftData, latest ARKit APIs |
| Min device | iPhone XS (A12) | Required for body tracking |
| Pose estimation | ARKit `ARBodyTrackingConfiguration` | Built-in, 3D, 60fps, no model to ship |
| Rendering | RealityKit | Apple's modern AR renderer, works with ARKit |
| Persistence | SwiftData | Modern, Swift-native, simpler than Core Data |
| Plan generation | Templates + optional GPT-4o-mini | Works offline by default, LLM for personalization |
| Audio | AVSpeechSynthesizer + pre-recorded | Pre-recorded for common cues, TTS for dynamic |

---

## Not Needed

- No custom ML training (ARKit handles pose)
- No backend server (everything on-device, iCloud sync later)
- No Android (maybe later via MediaPipe, but ARKit is the moat)
- No video recording/storage (just keypoint data per rep, tiny)
