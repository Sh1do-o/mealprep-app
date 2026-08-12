# Dorm Meal Prep — MVP (static UI)

A Flutter app that recommends meals based on what equipment and ingredients
you have. This version has 5 working screens wired together with dummy
data — no backend yet.

## Screens included
1. **Onboarding** — pick your equipment, set a weekly budget
2. **Home** — tap ingredients you have on hand
3. **Results** — recipe cards, roughly sorted by ingredient match
4. **Recipe detail** — steps, save button, mark as cooked

## How to run this on your own machine

1. **Install Flutter**: follow the official install guide for your OS at
   https://docs.flutter.dev/get-started/install
   Run `flutter doctor` afterward and fix anything it flags in red.

2. **Get a code editor**: VS Code with the Flutter extension is the easiest
   starting point.

3. **Create the project shell** (this generates platform-specific files
   like Android/iOS folders that aren't included in this download):
   ```
   flutter create mealprep_app
   ```

4. **Replace the generated `lib` folder and `pubspec.yaml`** with the ones
   from this download.

5. **Install dependencies**:
   ```
   cd mealprep_app
   flutter pub get
   ```

6. **Run it**:
   - Open an emulator (Android Studio) or connect your phone with USB
     debugging enabled, or run `flutter run -d chrome` to preview in a
     browser (fastest way to see it working, though the mobile emulator
     is a closer preview of the real thing).
   - Then: `flutter run`

## Pushing to GitHub

```
git init
git add .
git commit -m "Static UI: onboarding, home, results, recipe detail screens"
git remote add origin <your empty github repo URL>
git push -u origin main
```
Add a `.gitignore` for Flutter (Android Studio/VS Code will usually offer
to generate one, or grab the standard one from
https://github.com/flutter/flutter/blob/master/.gitignore).

## Roadmap: prototype vision vs. build order

A fuller UI prototype exists showing the long-term vision (Weekly Plan,
Shopping List, live Nutrition Tracker, Favorites). That prototype is the
north star, not the build order. Scope is intentionally staged so each
phase is validated before the next is built on top of it.

### Phase 1 — MVP (this repo, mostly done)
- Onboarding: equipment, budget, dietary preferences (incl. Halal, veg,
  no-vegetables tags — carried over from the prototype)
- Home: tap ingredients on hand
- Results: ranked recipe suggestions ("you have: X, Y, Z")
- Recipe detail: steps, save, mark as cooked
- Local dummy data, no backend, no persistence yet

### Phase 2 — Make it real
- ✅ Real matching logic — `lib/logic/recipe_matcher.dart`. Pure function,
  no UI, so it's easy to reason about (and later, test) on its own.
  Ranks recipes by: equipment you actually have + within budget + matches
  dietary preferences first, then by fewest missing ingredients. Recipes
  failing any of those three still show (dimmed) rather than
  disappearing, so the person knows they exist.
- ✅ Dietary preferences — vegetarian, halal, no-vegetables. Added as
  `dietaryPreferences` on `OnboardingData` (backward-compatible loading
  for anyone who saved onboarding data before this field existed), and
  as explicit `isVegetarian` / `isHalal` / `containsVegetables` booleans
  on `Recipe` (explicit fields rather than a loose tag list - fewer ways
  to get it wrong with only 3 restrictions). Onboarding screen shows
  them as filter chips; matcher treats a mismatch as a hard block, same
  tier as missing equipment or being over budget.
- ✅ Persist onboarding answers + cooked history locally via
  `lib/services/preferences_service.dart` (wraps `shared_preferences`).
  App now checks on startup whether onboarding was completed and skips
  straight to Home if so. "Mark as cooked" writes a timestamped entry
  used later by the weekly summary. Home screen now loads this saved
  data on open and feeds it into the matcher.
- Grow the recipe database with sourced nutrition estimates
  (`NutritionEstimate` field already exists on `Recipe`, mostly
  zero-filled for now)
- **Replace the ingredient chip list with a real ingredient input.**
  `commonIngredients` in `home_screen.dart` is currently just 10
  hardcoded strings for demo purposes, not a real ingredient set.
  Needs: (1) a much larger, categorized ingredient database, and
  (2) a search/autocomplete field so people aren't limited to
  whatever happens to be pre-listed - chips can stay as a fast-tap
  shortcut for frequent/recent ingredients on top of that, but
  shouldn't be the only way in. This also matches the search icon
  already shown in the prototype's "Cook Now" empty state.
- Add empty/error states: zero ingredients tapped, no matches found,
  recipe missing data, etc. (not in the prototype yet — needed before
  this feels like a real app)

### Phase 3 — Weekly summary
- Retrospective, not a live dashboard: "here's roughly what your week
  looked like" using real cooked-history data from Phase 2
- Descriptive framing only — no explicit calorie/macro *targets* or
  goal rings. Targets imply personalized health guidance, which is a
  higher bar of accuracy/responsibility than this app should take on
  at this stage. Revisit only with real nutrition-data sourcing and
  much more caution.
- Only worth building once "mark as cooked" data shows the core loop
  is actually being used

### Phase 4 — Weekly Plan + auto Shopping List (the prototype's
most ambitious screens)
- Weekly Plan: auto-generates a non-repeating week of meals within
  budget, with a "Regenerate Plan" action — this is a planning
  algorithm, meaningfully harder than Phase 1's ranked filtering
- Shopping List: reconciles "already have" vs. what the week's plan
  needs, with a running estimated cost total — depends on the Weekly
  Plan existing first, effectively its own subsystem
- Firebase backend likely becomes necessary around here, once data
  needs to sync/scale beyond local dummy JSON

### Later / not yet scoped
- Favorites / saved meals list (shown in prototype's Nutrition screen)
- Social or roommate features (shared grocery runs, cooking rotation)
- Brand/affiliate partnerships, GCash micro-payment unlocks
- **Substitute ingredients** (e.g. "no fish sauce? try soy sauce") — genuinely
  useful, reduces the "missing 1 ingredient, can't cook" drop-off. Deferred
  because it requires restructuring `ingredients` from a flat `List<String>`
  to a list of small objects (name + optional substitutes), plus real
  content judgment per ingredient (bad substitution advice is worse than
  none). Best done once building out a larger recipe database anyway, so
  the ingredient model only gets redesigned once, not twice.

## What's next (not built yet, on purpose)
- Real ingredient/equipment matching logic (currently just sorts by
  overlap count — see `lib/screens/results_screen.dart`)
- Saving onboarding answers with `shared_preferences`
- A bigger recipe database (currently 4 hardcoded recipes in
  `lib/data/dummy_recipes.dart` — add more here first, it's just a list)
- Firebase backend once the local version feels right

## Why it's structured this way
- `lib/models/` — data shapes (what a Recipe *is*)
- `lib/data/` — the actual recipe content (swap this for Firestore later)
- `lib/screens/` — one file per screen, kept separate so each is easy to
  find and edit without scrolling through unrelated code