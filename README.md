# SwimOS 🏊‍♂️

**Train. Fuel. Master.**

SwimOS is the complete athletic operating system engineered specifically for competitive swimmers, coaches, and high-performance athletes. Connecting training logs, nutrition planning, technique learning records, and meet performance analytics in a single hub.

---

## 📂 Repository Structure

This monorepo contains the core projects powering SwimOS:

*   **[`swim-tracker/`](./swim-tracker)** — Cross-platform mobile app built with **Flutter**, **Riverpod**, and **Supabase**. Features real-time meet analytics, standard cuts analyzer, training logbook, and meal planning.
*   **[`SwimScraper/`](./SwimScraper)** — Python data scraping and processing engine for retrieving swim meet results, team rosters, and time standards.

---

## 🌟 Core Pillars

1. **Performance & Meet Analytics** — Track swim meets, event entries, seed times, and splits across SCY and LCM courses with instant standard cut calculations (A, AA, AAA, AAAA).
2. **Training Logbook** — Record workout sets, volume, stroke focus, intensity zones, and dryland conditioning.
3. **Nutrition & Fuel Management** — Tailored meal planning, pre-race fueling, hydration strategies, and race-day nutrition.
4. **Learning & Knowledge Base** — Store coach feedback, video drill notes, turn mechanics, and mental preparation logs.

---

## 🚀 Getting Started

### Mobile App (`swim-tracker`)
```bash
cd swim-tracker
flutter pub get
flutter run
```

### Scraper Engine (`SwimScraper`)
```bash
cd SwimScraper
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
