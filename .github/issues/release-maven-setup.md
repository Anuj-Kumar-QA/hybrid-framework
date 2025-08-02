---
title: "🚀 Release v0.0.0 - Initial Maven Setup"
milestone: v0.0.0
labels: release, setup, maven, dependencies
assignees:
  - anuj-kumar
reviewers:
  - qa-lead
---

# 🚀 Release: `v0.0.0` – Maven Initial Project Setup

This release merges the foundational setup of the **Java Selenium Hybrid Automation Framework** into the `main` branch. It includes project scaffolding, essential dependencies, and documentation to kickstart further development.

---

## 📦 What’s Included in this Release

### ✅ Framework Initialization

- [x] Initialized Maven project
- [x] Added core dependencies:
  - [x] Selenium Java `v4.34.0`
  - [x] TestNG `v7.11.0`
- [x] Configured Maven plugins:
  - [x] Compiler Plugin `v3.14.0` (Java 21 support)
  - [x] Clean Plugin `v3.5.0`
- [x] Created `.gitignore` for common Java/Maven patterns
- [x] Structured initial directory layout (`src/`, `test/`)
- [x] Added complete `README.md` with:
  - [x] Overview
  - [x] Tech Stack
  - [x] Project Structure
  - [x] Roadmap
  - [x] Author and License
- [x] MIT License file included

---

## 🔀 Merged PRs

- ✅ [#14] `dev → main`: Maven Initial Configuration

---

## 📌 Milestone

- 🎯 Milestone: `v0.0.0 – Maven Initial Setup`

---

## 🔗 Related Issues

- Closes #1 – Initial Maven project setup

---

## 🔖 Version Tag

> This PR introduces version:
> **`v0.0.0`**

Once merged, tag the release:

```bash
git tag -a v0.0.0 -m "Maven initial setup release"
git push origin v0.0.0
```

🟢 **Output**: Clean Maven project scaffold with dependencies and docs.
---

## 👤 Author
**[ANUJ KUMAR](https://www.linkedin.com/in/anuj-kumar-qa/)** 🏅 QA Consultant & Test Automation Engineer

✅ This is the first official release. The foundation is now in place for future enhancements including Page Object Model, logging, reporting, and CI/CD.
