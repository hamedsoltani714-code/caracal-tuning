# CARACAL TUNING — Educational Vehicle Catalog

This directory contains searchable, bilingual educational metadata for vehicles and ECU identification. It is not a repository for ECU calibration binaries, modified maps, or files intended to alter engine behavior.

## Structure

- `vehicles.json`: vehicle index and supported display metadata.
- `ecu-info/`: educational ECU identification notes (manufacturer, family, connector overview, and references).
- `learning/`: lessons, diagrams, and safe diagnostic theory.

## Contribution rules

1. Add only material you own or are explicitly licensed to redistribute.
2. Keep source attribution and license information with each item.
3. Do not upload personal data, credentials, secrets, or proprietary calibration files.
4. Use stable IDs; keep Persian (`fa`) and English (`en`) labels where possible.
5. Validate JSON before committing.

The app and admin panel should consume this catalog through a read-only catalog layer; administrative publishing and user permissions belong in the backend, not in this public file tree.
