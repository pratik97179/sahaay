# Today and History prototype

A throwaway-style reference prototype of Sahaay's redesigned **Today** ruler,
**prints**, the reminder screen and **History** (flipbook and calendar). It is
the visual and interaction reference for `docs/design-system.md` §18.

It is **not part of the app**: it isn't in the pub workspace, the app doesn't
import it, and it uses made-up sample data.

```sh
cd prototypes/day_and_history
flutter pub get
flutter run -d chrome
flutter test   # rapid swipes and frame-by-frame smoothness of the stack
```

What it does not yet reflect (decided after it was built): History in warm
off-white instead of blue-grey, dark mode following the phone, and drawn icons
in place of the few Material icons left. See §18.

Assets:
- `assets/Figtree.ttf`: Figtree, SIL Open Font License (`Figtree-OFL.txt`).
- `assets/pills.jpg`: "Valaciclovir Blister packs", Wikimedia Commons, public
  domain (CC0). A stand-in for a camera photo.
