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
- ✅ **Real matching logic** — `lib/logic/recipe_matcher.dart`. Pure function ranking recipes by equipment owned, budget, dietary preferences, and ingredient overlap.
- ✅ **Dietary preferences** — Vegetarian, Halal, No-vegetables filters in `OnboardingData` and `Recipe` models.
- ✅ **Local persistence** — `lib/services/preferences_service.dart` wrapping `shared_preferences` for onboarding data, cooked history, weekly plan, and favorites.
- ✅ **Expanded recipe database** — Grown to 20 realistic student meals with sourced nutrition estimates in `lib/data/dummy_recipes.dart`.
- ✅ **Categorized ingredient input & autocomplete** — `lib/data/ingredient_database.dart` & `home_screen.dart`. Replaced plain chips with a search/autocomplete field and category filtering chips.
- ✅ **Empty & error states** — Handled zero ingredients tapped, search filter miss, and empty recommendations gracefully.

### Phase 3 — Weekly summary
- ✅ **Weekly Summary Screen** — `lib/logic/weekly_summary_logic.dart` & `lib/screens/weekly_summary_screen.dart`. Retrospective weekly breakdown of meals cooked, total estimated spending, budget saved, and macro totals.

### Phase 4 — Weekly Plan + auto Shopping List
- ✅ **Weekly Plan Generator** — `lib/logic/weekly_planner_logic.dart` & `lib/screens/weekly_plan_screen.dart`. Auto-generates a non-repeating 7-day meal plan under budget, equipment, and dietary constraints, with per-day meal swapping, plan regeneration, and total macro tracking.
- ✅ **Auto Shopping List** — `lib/logic/shopping_list_logic.dart` & `lib/screens/shopping_list_screen.dart`. Reconciles pantry ingredients against planned meals, categorizes grocery items by category, tracks progress, and persists check-offs.
- ✅ **Main Navigation** — `lib/screens/main_navigation_screen.dart`. Seamless Material 3 NavigationBar connecting Cook Now, Weekly Plan, Shopping List, and Summary.

### Phase 5 — Unscoped Features & Enhancements (Completed)
- ✅ **Smart Ingredient Substitutions** — `lib/data/substitutions_database.dart` & `lib/models/recipe.dart`. Enhanced recipe ingredients with `IngredientSpec`, student substitution fallback lookup, match ranking tiers, and UI swap badges on `ResultsScreen` & `RecipeDetailScreen`.
- ✅ **Favorites / Saved Meals** — `lib/screens/favorites_screen.dart`. Bookmark recipes with favorite toggling, local storage persistence, and fast search.
- ✅ **Roommates & Cooking Rotation** — `lib/screens/roommate_deals_screen.dart`. Roommate grocery cost splitter, cooking duty assigner, and 1-tap clipboard exporter for group chats.
- ✅ **Student Deals & Micro-Unlocks** — `lib/screens/roommate_deals_screen.dart`. Partner student discounts showcase & interactive GCash micro-unlock perk demo.

## What's next (Future Roadmap)
- Firebase backend & cloud synchronization (syncing weekly plans, grocery checklists, and saved favorites across devices).
- AI-assisted recipe creation and custom meal generation via Gemini API / Firebase AI Logic.

## Why it's structured this way
- `lib/models/` — data shapes (what a Recipe *is*)
- `lib/data/` — the actual recipe content (swap this for Firestore later)
- `lib/screens/` — one file per screen, kept separate so each is easy to
  find and edit without scrolling through unrelated code