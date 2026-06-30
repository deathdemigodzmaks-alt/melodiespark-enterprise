# Contributing to MelodieSpark

Thank you for your interest in contributing to MelodieSpark! This document provides guidelines and instructions for contributing.

## 🎯 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Welcome diverse perspectives
- Report issues responsibly

## 📋 Getting Started

### 1. Fork & Clone

```bash
# Fork on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/melodiespark-enterprise.git
cd MelodieSpark

# Add upstream
git remote add upstream https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise.git
```

### 2. Setup Development Environment

```bash
# Install dependencies
pnpm install

# Setup environment
cp .env.example .env

# Setup database
pnpm db:push

# Start development
pnpm dev
```

### 3. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
# or
git checkout -b docs/your-documentation
```

## 🚀 Development Workflow

### Making Changes

```bash
# Make your changes
# Test locally
pnpm test

# Check code quality
pnpm lint
pnpm format
pnpm type-check

# Build
pnpm build
```

### Commit Messages

Follow conventional commits:

```bash
# Features
git commit -m "feat: add new feature description"

# Bug fixes
git commit -m "fix: fix bug description"

# Documentation
git commit -m "docs: update documentation"

# Refactoring
git commit -m "refactor: refactor code section"

# Performance
git commit -m "perf: improve performance"

# Tests
git commit -m "test: add tests for feature"

# Chores
git commit -m "chore: update dependencies"
```

### Keep Your Branch Updated

```bash
# Fetch latest changes
git fetch upstream

# Rebase on main
git rebase upstream/main
```

### Push Changes

```bash
# Push to your fork
git push origin feature/your-feature-name
```

## ✅ Pull Request Process

### 1. Create Pull Request

1. Go to https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise
2. Click "New Pull Request"
3. Select your branch
4. Fill in the PR description

### 2. PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Fixes #(issue number)

## Testing
How to test changes:
- Step 1
- Step 2

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings generated
```

### 3. Code Review

- Address reviewer feedback
- Make requested changes
- Push updates to same branch
- Request re-review

### 4. Merge

Once approved, your PR will be merged by maintainers.

## 📝 Code Style

### TypeScript

```typescript
// ✅ Good
function getUserById(id: string): Promise<User | null> {
  // Implementation
}

const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
  // Implementation
}

// ❌ Avoid
function get_user_by_id(id) {
  // Implementation
}
```

### React Components

```typescript
// ✅ Good
interface ButtonProps {
  label: string
  onClick: () => void
  disabled?: boolean
}

export const Button: React.FC<ButtonProps> = ({
  label,
  onClick,
  disabled = false,
}) => {
  return <button onClick={onClick} disabled={disabled}>{label}</button>
}

// ❌ Avoid
const Button = (props) => {
  return <button onClick={props.onClick}>{props.label}</button>
}
```

### Formatting

```bash
# ESLint
pnpm lint

# Prettier
pnpm format

# Type checking
pnpm type-check
```

## 🧪 Testing

### Run Tests

```bash
# All tests
pnpm test

# Specific test
pnpm test path/to/test.spec.ts

# Watch mode
pnpm test:watch

# Coverage
pnpm test:coverage
```

### Writing Tests

```typescript
// ✅ Good test example
describe('getUserById', () => {
  it('should return user when found', async () => {
    const user = await getUserById('123')
    expect(user).toEqual({ id: '123', name: 'John' })
  })

  it('should return null when not found', async () => {
    const user = await getUserById('999')
    expect(user).toBeNull()
  })
})
```

## 📚 Documentation

### Update Docs When

- Adding new features
- Changing behavior
- Updating configuration
- Adding new commands
- Fixing documented bugs

### Documentation Format

```markdown
# Feature Name

Brief description of feature.

## Usage

```bash
# Command example
pnpm command
```

## Configuration

Options and settings.

## Examples

Real-world usage examples.

## Troubleshooting

Common issues and solutions.
```

## 🐛 Bug Reports

### Report Bugs

1. Go to [Issues](https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise/issues)
2. Click "New Issue"
3. Select "Bug Report"
4. Fill in the template

### Bug Report Template

```markdown
## Description
Clear description of bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: Windows 10
- Node: 20.0.0
- npm: 10.0.0

## Logs
Error messages or screenshots
```

## 💡 Feature Requests

### Request Features

1. Go to [Discussions](https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise/discussions)
2. Create new discussion
3. Select "Ideas"
4. Describe your feature

### Feature Template

```markdown
## Description
What is the feature?

## Problem It Solves
What problem does this solve?

## Proposed Solution
How should it work?

## Examples
Show use cases
```

## 📦 Release Process

Maintainers follow semantic versioning:

- **MAJOR** - Breaking changes
- **MINOR** - New features (backward compatible)
- **PATCH** - Bug fixes

## 🎓 Learning Resources

- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React Documentation](https://react.dev/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Fastify Guide](https://www.fastify.io/docs/latest/)
- [Prisma Documentation](https://www.prisma.io/docs/)

## 🤝 Community

- **Issues**: Questions and bug reports
- **Discussions**: Ideas and features
- **GitHub**: https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise

## 📋 Checklist Before PR

- [ ] Fork and clone repository
- [ ] Create feature branch
- [ ] Made changes following code style
- [ ] Added/updated tests
- [ ] Updated documentation
- [ ] Run `pnpm lint`
- [ ] Run `pnpm format`
- [ ] Run `pnpm test`
- [ ] Run `pnpm build`
- [ ] Commit with conventional message
- [ ] Pushed to fork
- [ ] Created pull request
- [ ] Filled in PR description
- [ ] Linked related issues

## ✨ Recognition

Contributors are recognized in:
- [CONTRIBUTORS.md](./CONTRIBUTORS.md)
- GitHub release notes
- Project README

Thank you for contributing! 🎉

---

**Have questions?** Open an [issue](https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise/issues) or start a [discussion](https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise/discussions)!
