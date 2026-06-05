# Contributing to dscli.el

Welcome to the dscli.el project! This guide will help you understand how to participate in project development.

## Project Philosophy

dscli.el is an Emacs plugin providing an interface for the [dscli](https://github.com/dscli/dscli) command-line tool. Our goals are:

1. Provide clean, efficient DeepSeek AI integration
2. Maintain strong integration with the Emacs and Org mode ecosystem
3. Follow best practices and code quality standards
4. Practice the tools and methodologies we advocate

## Development Standards

### Code Style

- Use Emacs Lisp standard coding style
- Follow lexical binding mode
- Use meaningful names for functions and variables
- Add appropriate docstrings

### Documentation Standards

- All documentation uses Markdown format
- Code examples use code blocks
- Keep documentation synchronized with code changes

### Commit Standards

- Use conventional commit format for commit messages
- Each commit should focus on a single feature or fix
- Use dscli to help write commit messages (encouraged)

## Commit Guidelines

### Core Principle

We encourage using dscli to assist in writing commit messages, ensuring standardization and consistency.

### Why This Approach?

1. Maintain project consistency
2. Practice the tools we advocate
3. Ensure standardized commit messages
4. Demonstrate real-world AI-assisted development

### How It Works

After a human developer writes code:

1. Use dscli to analyze code changes
2. Let dscli assist in writing the commit message
3. Review and refine the commit message manually
4. Execute the commit

### Commit Message Format

Use conventional commit format:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation update
- `style:` Code formatting adjustment
- `refactor:` Code refactoring
- `test:` Testing related
- `chore:` Build process or auxiliary tools

Example:

```
feat: Add model selection support

- Add dscli-chat-model custom variable
- Support deepseek-chat and deepseek-reasoner models
- Update relevant documentation and examples
```

## Development Flow

### 1. Environment Setup

1. Clone the repository
2. Install the dscli tool: `go install github.com/dscli/dscli@latest`
3. Configure development environment

### 2. Create a Branch

- Create a feature branch from `main`
- Branch naming: `feat/xxx`, `fix/xxx`, `docs/xxx`, etc.

### 3. Development & Implementation

- Write code and tests
- Ensure code quality
- Update relevant documentation
- Use dscli to assist with code writing and review

### 4. Commit Changes

- Stage changes: `git add .`
- Write commit message (using dscli is encouraged)
- Execute commit: `git commit -m "message"`

### 5. Create a Pull Request

- Push to remote repository
- Create a pull request
- Wait for code review

## Documentation Requirements

### Required Documentation

1. Code docstrings
2. User documentation (README.md)
3. API documentation (if applicable)
4. Change history (CHANGELOG.md)

### Documentation Format

- Use Markdown
- Use correct syntax highlighting for code blocks
- Maintain consistent heading levels
- Use Markdown syntax for links

## Testing Requirements

### Unit Tests

- Critical functionality should have unit tests
- Tests should cover major logic paths
- Test files use the `.el` extension

### Integration Tests

- Test integration with dscli
- Test user interaction workflows
- Ensure backward compatibility

## Code Review

### Review Focus

1. Code correctness and security
2. Compliance with project standards
3. Adequate test coverage
4. Documentation is synchronized
5. Commit message is well-formatted

### Review Process

1. At least one core contributor must review
2. All review comments must be addressed
3. After approval, a maintainer merges

## Release Process

### Version Number Convention

- Major version: Breaking changes, potentially backward-incompatible
- Minor version: New features, backward-compatible
- Patch version: Bug fixes, backward-compatible

### Release Steps

1. Update CHANGELOG.md
2. Update version number
3. Create Git tag
4. Update version info in README.md
5. Release announcement

## Communication Channels

### Issue Reporting

- Use GitHub Issues
- Provide detailed reproduction steps
- Include environment information and relevant logs

### Discussions

- Use GitHub Discussions
- Maintain a professional and friendly atmosphere
- Respect all contributors

## Code of Conduct

### Basic Principles

1. Respect others
2. Provide constructive feedback
3. Embrace diversity and inclusion
4. Professional behavior

### Unacceptable Behavior

1. Personal attacks or abusive language
2. Harassment or discrimination
3. Posting inappropriate content
4. Other unprofessional conduct

## License

This project is licensed under the Apache License 2.0. All contributors agree to its terms.

## Acknowledgments

Thank you to all the developers who have contributed to the dscli.el project! Your efforts make this project better.

## Contact

- Project maintainer: Nan Jun Jie <nanjunjie@139.com>
- Project repository: https://github.com/dscli/dscli.el
- Issue tracker: https://github.com/dscli/dscli.el/issues
