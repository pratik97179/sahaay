#!/usr/bin/env bash
# Checks the navigation rules in docs/architecture.md (Navigation).
# Run from the repository root, next to `flutter analyze`. Exits 1 and lists
# every line that breaks a rule.
set -u
cd "$(dirname "$0")/.."

failed=0

# Prints matching lines of lib/ outside the allowed files; marks a failure.
# $1: rule text, $2: extended regex, $3: regex of paths allowed to match.
rule() {
  local hits
  hits=$(grep -rnE --include='*.dart' "$2" lib | grep -vE "^($3)" || true)
  if [ -n "$hits" ]; then
    echo "✗ $1"
    echo "$hits" | sed 's/^/    /'
    failed=1
  fi
}

nav='lib/core/navigation/'

rule "Only core/navigation uses go_router." \
  "package:go_router/" "$nav"

rule "Screens move only through AppNavigator, never Flutter's Navigator." \
  "\bNavigator\.(of|push|pop|maybePop|canPop|pushReplacement|popUntil|removeRoute)" "$nav"

rule "No go_router calls on BuildContext; use AppNavigator.of(context)." \
  "context\.(go|push|pop|replace|pushReplacement|canPop|goNamed|pushNamed)\(" "$nav"

rule "No page routes outside core/navigation; a screen is a destination, a layer is AppNavigator.overlay." \
  "\b(PageRouteBuilder|MaterialPageRoute|CupertinoPageRoute|DialogRoute|RawDialogRoute)\b" "$nav"

rule "No dialogs or sheets that push their own route; use AppNavigator.overlay." \
  "\b(showDialog|showGeneralDialog|showModalBottomSheet|showBottomSheet|showCupertinoDialog|showCupertinoModalPopup|showMenu|showSearch|showDatePicker|showTimePicker)\(" "$nav"

rule "Destinations are declared only in a feature's *_destinations.dart, as final classes." \
  "extends Destination\b" "${nav}|lib/features/[a-z_]+/[a-z_]+_destinations\.dart:[0-9]+:final class "

rule "Screens are registered only in a feature's *_screens.dart." \
  "\bScreenRoute<" "${nav}|lib/features/[a-z_]+/[a-z_]+_screens\.dart"

rule "Only *_screens.dart files and app/app_screens.dart import screen_route.dart." \
  "navigation/screen_route\.dart" "${nav}|lib/features/[a-z_]+/[a-z_]+_screens\.dart|lib/app/app_screens\.dart"

rule "Only app/app.dart builds the navigator." \
  "go_router_navigator\.dart" "${nav}|lib/app/app\.dart"

rule "Features open each other's screens through *_destinations.dart, never *_screens.dart." \
  "import '.*_screens\.dart'" "lib/app/"

if [ "$failed" -eq 0 ]; then
  echo "✓ navigation rules hold"
fi
exit "$failed"
