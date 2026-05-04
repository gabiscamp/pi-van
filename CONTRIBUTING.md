# Contribution Guide

## Branch flow

- main: production
- hml: integration/staging
- sprint_1: current sprint branch
- task branches: created from sprint_1

### Task branch naming

Use one of the following patterns:

- sprint_1/feature-login
- sprint_1/feature-cadastro
- sprint_1/chore-setup

## Pull request flow

1. Create a task branch from sprint_1.
2. Open a PR back to sprint_1.
3. Review and test in sprint_1.
4. Merge sprint_1 into hml.
5. Merge hml into main when stable.

## Commit style (suggested)

- feat: new feature
- fix: bug fix
- chore: maintenance
- docs: documentation
