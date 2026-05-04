# Architecture

## Overview

This project uses Clean Architecture with MVVM in the presentation layer.

```
lib/
  core/
    di/
    errors/
    routing/
    utils/
  domain/
    entities/
    enums/
    repositories/
    usecases/
  data/
    datasources/
    models/
    repositories/
  presentation/
    pages/
    viewmodels/
    widgets/
```

## Layers

### Domain

- Pure business rules
- Entities, use cases, and repository interfaces
- No external dependencies

### Data

- Implements repository interfaces
- Talks to Firebase (via data sources)
- Maps raw data into domain entities

### Presentation (MVVM)

- Pages build UI
- ViewModels coordinate use cases and state
- Widgets are reusable UI components

## Dependency direction

- Presentation -> Domain
- Data -> Domain
- Domain has no dependency on other layers

## Notes

- Use cases are the single entry point for business logic.
- Keep UI logic inside ViewModels.
- Keep Firebase details out of the domain layer.
