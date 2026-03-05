# FULL PRODUCT PROMPT — Educational Game App UI + Supabase + Flutter

You are an **expert mobile UI/UX designer, Flutter engineer, and backend architect**.

Your task is to design and generate a **complete educational mobile application system**.

The project includes:

1. Full UI design
2. HTML UI templates
3. Flutter UI implementation
4. Supabase database architecture

The application is a **gamified learning platform** called:

**Surplus Value Simulator**

The app teaches economic concepts about **Surplus Value in a Market Economy**.

Learning methods:

- learning cards
- quizzes
- economic simulation gameplay
- leaderboard competition

The app must feel like:

**Duolingo + Idle Game + Strategy Simulation**

---

# DESIGN SYSTEM

Use a consistent design system across all screens.

### Primary Color

Deep Blue / Indigo

### Secondary Color

Emerald Green

### Accent Color

Gold / Yellow

### Background

Soft light background

### Typography

Headings
Bold

Body text
Clean modern sans-serif

### UI Style

Rounded cards
Soft shadows
Gamified progress bars
Icon-based navigation
Friendly illustrations

---

# GLOBAL UI COMPONENTS

Use reusable components across the app.

Components:

Cards
Progress bars
XP counters
Coin counters
Rounded buttons
Animated icons
Leaderboard rows
Quiz answer buttons
Simulation control panels

---

# NAVIGATION STRUCTURE

Use a **Bottom Navigation Bar**.

Tabs:

Home
Learn
Quiz
Simulation
Leaderboard
Profile

All screens must share the same layout structure.

---

# SCREEN LIST

Design the following screens.

---

# 1 Splash Screen

Elements:

App logo
App name
Animated loading indicator

Layout:

Centered minimal design.

---

# 2 Login Screen

Elements:

Logo
Email input
Password input
Login button
Register button
Continue with Google button

---

# 3 Register Screen

Elements:

Username input
Email input
Password input
Confirm password input
Create account button

---

# 4 Home Dashboard

Elements:

User avatar
Username
XP progress bar
Current level
Daily streak counter

Sections:

Quick actions

Start Quiz
Start Simulation
Continue Learning

Daily challenges card

Example:

Complete 2 quizzes
Win 1 simulation

---

# 5 Learn Screen

Scrollable lesson cards.

Each card contains:

Title
Short explanation
Icon
Example

Example topics:

What is Surplus Value
Absolute Surplus Value
Relative Surplus Value
Capital Accumulation
Profit

---

# 6 Lesson Detail Screen

Elements:

Lesson title
Explanation text
Diagram
Example scenario

Button:

Start Quiz

---

# 7 Quiz Selection Screen

Categories:

Beginner
Intermediate
Advanced

Each card displays:

Number of questions
Difficulty
XP reward

---

# 8 Quiz Question Screen

Layout:

Question text

Answer buttons:

Option A
Option B
Option C
Option D

Timer indicator

Progress indicator

Example:

Question 3 / 10

---

# 9 Quiz Result Screen

Elements:

Score display

Example:

8 / 10

XP gained

Correct answers list

Buttons:

Try again
Return home

---

# 10 Simulation Mode Screen

Factory management dashboard.

Display:

Constant capital (C)
Variable capital (V)
Surplus value

Factory stats:

Workers
Machines
Technology level
Working hours

Action buttons:

Increase working hours
Hire workers
Buy machines
Upgrade technology

Results panel:

Profit
Production output
Surplus value

---

# 11 Simulation Result Screen

Elements:

Profit summary
Surplus value generated
Score gained

Button:

Next level

---

# 12 Leaderboard Screen

Columns:

Rank
Avatar
Username
Score

Top 3 players highlighted.

Tabs:

Daily
Weekly
All Time

---

# 13 Multiplayer Quiz Battle Screen

Elements:

Player vs Player layout

Two avatars
Timer
Question
Answer buttons
Score comparison

---

# 14 Achievement Screen

Grid layout.

Examples:

Surplus Master
Quiz Champion
Profit King
Capital Accumulator

Each achievement includes:

Icon
Title
Progress bar

---

# 15 Profile Screen

Elements:

Avatar
Username
XP
Level

Stats:

Total quizzes completed
Total simulations played
Best score

Buttons:

Edit profile
Settings

---

# 16 Settings Screen

Elements:

Dark mode toggle
Sound toggle
Language selection
Logout button

---

# UI CONSISTENCY REQUIREMENTS

All screens must:

Use the same color palette
Use the same card style
Use the same button style
Use the same typography

Navigation must remain consistent.

---

# HTML UI EXPORT

For each screen:

Generate an HTML version.

Place files in:

```id="yx6pys"
ui-html/
```

Example structure:

```id="ew5nlh"
ui-html/

```

Each HTML page must:

Use the same design system.

---

# CONVERT HTML → FLUTTER

After generating HTML UI:

Convert each page into Flutter screens.

Create Flutter widgets matching the UI layout.

Use Flutter best practices.

Folder structure:

```id="ihryz6"
lib/
  core/
    theme/
    constants/

  features/
    auth/
    home/
    learn/
    quiz/
    simulation/
    leaderboard/
    profile/

  widgets/
  services/
  models/

  main.dart
```

---

# SUPABASE DATABASE DESIGN

Design a complete Supabase schema.

Tables:

---

users

```id="62eckd"
id
email
username
avatar
xp
level
created_at
```

---

quiz_questions

```id="hvc4w5"
id
question
option_a
option_b
option_c
option_d
correct_answer
difficulty
topic
```

---

quiz_results

```id="r88o7k"
id
user_id
score
time_taken
created_at
```

---

simulations

```id="xdipks"
id
user_id
capital_constant
capital_variable
workers
machines
technology_level
profit
surplus_value
created_at
```

---

leaderboard

```id="17n4q0"
user_id
score
rank
season
```

---

achievements

```id="3yq22s"
id
title
description
icon
```

---

user_achievements

```id="ju16jz"
user_id
achievement_id
progress
unlocked
```

---

# SUPABASE FEATURES

Use Supabase for:

Authentication
Database storage
Realtime leaderboard updates

---

# FINAL GOAL

Generate a **complete UI system, HTML templates, Flutter screens, and Supabase backend design** for a **gamified economics learning mobile application**.

The app must feel like a **modern educational game** where users:

learn theory
play simulation
compete on leaderboards
earn achievements
