# Contributing to Nestri

First off, thank you for considering contributing to Nestri! It's people like you that make Nestri such a great tool.

## Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for Nestri. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

- Use a clear and descriptive title for the issue to identify the problem.
- Describe the exact steps which reproduce the problem in as many details as possible.
- Provide specific examples to demonstrate the steps.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for Nestri, including completely new features and minor improvements to existing functionality.

- Use a clear and descriptive title for the issue to identify the suggestion.
- Provide a step-by-step description of the suggested enhancement in as many details as possible.
- Provide specific examples to demonstrate the steps.

### Pull Requests

- Fill in the required template
- Do not include issue numbers in the PR title
- Include screenshots and animated GIFs in your pull request whenever possible.
- Follow the JavaScript/TypeScript styleguides.
- End all files with a newline

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

### JavaScript/Typescript Styleguide

All JavaScript and Typescript must adhere to the eslint and TS rules set in `.eslintrc` and `tsconfig` respectively. Your build will fail, otherwise.

## Additional Notes

### Issue and Pull Request Labels

This section lists the labels we use to help us track and manage issues and pull requests.

* `🐛 fix` - Issues that are bugs.
* `✨ feat` - Issues that are feature requests.
* `📝 docs` - Issues or pull requests related to documentation.
* `🔧 chore` - Pull requests that add or update configuration files
* `💄 style` - Issues or Pull requests related to the UI or style files
* `⚡ perf` - Issues or Pull Requests that are related to performance
* `♻ refactor` - Issues or Pull Requests related to code refactors
* `good first issue` - Good for newcomers.

## Project Structure

Nestri is organized as a monorepo using Turborepo. Here's an overview of the main directories and their purposes:

### Root Directory

- `apps/`: Contains the main applications
  - `www/`: The main Nestri website built with Qwik
- `infra/`: Contains the relevant files to deploy the app using [SST](https://sst.dev)
- `packages/`: Shared packages and configurations
  - `api/`: Core API for Nestri
  - `eslint-config/`: Shared ESLint configurations
  - `typescript-config/`: Shared TypeScript configurations
  - `ui/`: Shared UI components and styles

### Key Files

- `package.json`: Root package file defining workspaces and shared dev dependencies
- `turbo.json`: Turborepo configuration
- `LICENSE`: GNU Affero General Public License v3.0

### Apps

#### www (Nestri Website)

This is the Nestri website hosted on Cloudflare Pages

### Packages

#### api (Nestri Core)

The core API for Nestri, built with Hono and deployed to Cloudflare Workers.

#### eslint-config

Shared ESLint configurations for maintaining consistent code style across the project.

#### typescript-config

Shared TypeScript configurations to ensure consistent TypeScript settings across the project.

#### ui

Shared UI components and styles used across the Nestri project.

### Infrastructure

- `infra/`: Contains infrastructure-as-code files
  - `www.ts`: Defines the deployment configuration for the Nestri website

### Development

When working on Nestri, you'll primarily be dealing with the `apps/www` directory for the main website and the various packages in the `packages/` directory for shared functionality.

For more detailed information about each package or app, refer to their respective README files or package.json scripts.


Thank you for contributing to Nestri!