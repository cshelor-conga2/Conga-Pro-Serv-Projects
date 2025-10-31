# Conga Lab — Proposal and Quote Manager

This folder contains the source for the "Proposal and Quote Manager" Salesforce package that is part of the Conga Labs project "Proposal and Quote Manager".
This is a Salesforce DX project organized for source-driven development and packaging. The package depends on Conga Composer and Conga Grid managed packages (see `sfdx-project.json` -> `dependencies`).

## Contents

- Overview
- Prerequisites
- Quick start (development + scratch org)
- Deploying to non-scratch orgs and packaging
- Scripts (lint, test, format)
- Project structure
- Contributing

## Overview

This project is structured as a Salesforce DX application using the default `force-app` package directory. Source metadata lives under `force-app/main/default/` and is intended to be pushed to scratch orgs or deployed to sandbox/production orgs.

`manifest/package.xml` contains the complete manifest of all included components in the package. See the `Component Manifest` section for a list as well.

`sfdx-project.json` includes package configuration and package dependencies on the Conga managed packages (Conga Composer and Conga Grid).

## Development and Maintenance

Version development currently happens in the Conga PS Commercial Team DevHub. Access is managed by Tunille Fry, tfry@conga.com.

### DevHub Information
Org Id: `00D8c0000023OxA`

## Component Manifest

This package includes the following components:

#### Applications
- `Conga Lab Proposal and Quote Manager` (Custom App)

#### Visualforce Pages
- `Conga_Lab_AG_MultiTab_Opportunity` - Multi-tab opportunity management interface
- `Conga_Lab_AG_Proposal_Manager` - Proposal management interface

#### Lightning Pages (Flexipages)
- `Conga_Lab_Conga_Query_Record_Page` - Custom record page for Conga Query
- `Conga_Lab_Conga_Template_Record_Page` - Custom record page for Conga Template
- `Conga_Lab_Opportunity_Record_Page` - Custom opportunity record page
- `Conga_Lab_Proposal_and_Quote_Manager_UtilityBar` - Custom utility bar

#### Page Layouts
- `Opportunity-Conga Lab - Opportunity Layout` - Custom opportunity page layout
- `APXTConga4__Conga_Template__c-Conga Lab - Conga Template Layout` - Custom Conga template layout

#### Static Resources
- Grid Action JavaScript:
  - `Conga_Lab_AG_BatchAdd_OppLineItems_From_PricebookEntry`
  - `Conga_Lab_AG_BatchIncreaseAmount`
  - `Conga_Lab_AG_BatchIncreaseQuoteLineUnitPrice`
  - `Conga_Lab_AG_BatchIncreaseUnitPrice`
- Product Images:
  - `Conga_Lab_Bronze_Product_Image`
  - `Conga_Lab_Silver_Product_Image`
  - `Conga_Lab_Diamond_Product_Image`
  - `Conga_Lab_User_Training_Image`

#### Permission Sets
- `Conga_Lab_Proposal_and_Quote_Manager` - Core permission set for the application

## Project structure (high level)

`force-app/` — main package directory containing metadata (Apex, LWC, Aura, pages, static resources, layouts, etc.)

`config/project-scratch-def.json` — scratch org definition used to create consistent development orgs

`manifest/package.xml` — optional package manifest for metadata deploys

`sfdx-project.json` (package configuration and packageAliases)

Other files:

- `package.json` (dev tooling, scripts, lint-staged)
- `jest.config.js`, `eslint.config.js` — test and lint config

## Contributing

This repository is configured with common developer tooling (ESLint, Prettier, jest). To contribute:

1. Create a feature branch from `main`.
2. Run linting and tests locally (`npm run lint`, `npm test`).
3. Open a PR with a clear description and related metadata changes.

Pre-commit hooks will format staged files and run lint/testing on related changes.

## Package dependencies

`sfdx-project.json` lists two managed package aliases used by this package:

- `CongaComposer` (from package version Id -> 04tKe000000syJwIAI)
- `CongaGrid` (from package version Id -> 04tKg000000D2p4IAC)

Ensure these managed packages are installed in the target org before attempting to install this unlocked package.

## Contacts

For questions about this repo, reach out to cshelor@conga.com.