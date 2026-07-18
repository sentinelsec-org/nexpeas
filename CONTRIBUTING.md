# Contributing to NEXPEAS

Thank you for your interest in contributing to NEXPEAS! We welcome contributions from the security community.

## Code of Conduct

### Our Pledge
We are committed to providing a welcoming and inclusive environment for all contributors, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Expected Behavior
- Use welcoming and inclusive language
- Be respectful of differing opinions and experiences
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior
- Harassment, intimidation, or discrimination
- Personal attacks or derogatory comments
- Trolling or inflammatory comments
- Sharing others' private information
- Any other conduct that could reasonably be considered inappropriate

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating a bug report, please check the [issues list](https://github.com/yourusername/nexpeas/issues) as you might find out that you don't need to create one.

When creating a bug report, include:

- **Title**: Clear and descriptive
- **Description**: Detailed explanation of the behavior
- **Steps to Reproduce**: Exact steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Screenshots**: Visual evidence if applicable
- **Environment**: OS, Bash version, etc.
- **Additional Context**: Any other relevant information

Example:
```
Title: SUID detection fails on Alpine Linux

Description:
The script doesn't detect SUID binaries on Alpine Linux systems.

Steps to Reproduce:
1. Install Alpine Linux
2. Run nexpeas.sh
3. Compare output with standard Ubuntu

Expected Behavior:
Should find same SUID binaries as Ubuntu

Actual Behavior:
Empty SUID section, no binaries detected

Environment:
- OS: Alpine Linux 3.18
- Bash: 5.2
```

---

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/yourusername/nexpeas/issues).

When suggesting an enhancement:
- Use a clear and descriptive title
- Provide a step-by-step description of the enhancement
- Provide specific examples
- Describe the current behavior and expected behavior
- Explain why this enhancement would be useful

Example:
```
Title: Add JSON output format for automated parsing

Description:
Currently, the output is text-based which makes parsing difficult
for automated tools. Adding JSON output would help integration
with SIEM and other security platforms.

Use Case:
We need to ingest NEXPEAS results into Splunk for automated alerting.
```

---

### 📝 Writing Documentation

Documentation improvements are always welcome!

- README improvements
- Better code comments
- Usage examples
- Troubleshooting guides
- Contributing to post_exploit.md

---

### 🔧 Code Contributions

#### Getting Started

1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/nexpeas.git
   cd nexpeas
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```

3. **Make Your Changes**
   - Keep changes focused and minimal
   - Follow the existing code style
   - Add comments for complex logic
   - Test thoroughly

4. **Commit Your Changes**
   ```bash
   git commit -m 'Add AmazingFeature

   - Description of changes
   - Why this change was needed
   - Any related issues: Closes #123
   '
   ```

5. **Push to Your Fork**
   ```bash
   git push origin feature/AmazingFeature
   ```

6. **Open a Pull Request**
   - Use a clear title
   - Reference any related issues
   - Describe the changes in detail
   - Include testing information

---

## Development Guidelines

### Code Style

- Use consistent indentation (4 spaces)
- Use meaningful variable names
- Keep functions focused and small
- Add comments for non-obvious logic
- Follow existing code patterns

### Performance

- Use timeouts on long-running operations
- Limit search depth with `-maxdepth`
- Avoid unnecessary loops
- Test on systems with limited resources

### Security

- Don't hardcode sensitive information
- Validate all user input
- Use quotes around variables
- Be mindful of injection vulnerabilities

### Testing

Before submitting a PR:

1. **Test on multiple systems**
   - Ubuntu 20.04+
   - Debian 10+
   - CentOS 7+
   - Kali Linux
   - Alpine Linux (if applicable)

2. **Test with different Bash versions**
   ```bash
   bash --version
   ```

3. **Verify output clarity**
   - Check color rendering
   - Verify emoji display
   - Ensure no truncation

4. **Performance testing**
   ```bash
   time ./nexpeas.sh
   ```

---

## Pull Request Process

1. Update documentation if needed
2. Ensure all tests pass
3. Follow the code style guidelines
4. Add descriptive commit messages
5. Reference any related issues
6. Wait for review and address feedback

### PR Template

```markdown
## Description
Brief description of changes

## Related Issues
Closes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement

## Testing
- [ ] Tested on Ubuntu 20.04
- [ ] Tested on Debian 10
- [ ] Tested on Kali Linux
- [ ] Performance verified
- [ ] No regressions found

## Screenshots (if applicable)
```

---

## Project Structure

```
nexpeas/
├── nexpeas.sh              # Main script
├── server.py               # HTTP server
├── post_exploit.md         # Guide
├── README.md               # Documentation
├── CHANGELOG.md            # Version history
├── CONTRIBUTING.md         # This file
├── LICENSE                 # MIT License
└── .gitignore              # Git ignore rules
```

---

## Adding Features

### Example: Adding a New Check

1. **Identify the need**
   - What vulnerability/misconfiguration to detect?
   - Is it CRITICAL, HIGH, or MEDIUM severity?

2. **Create the detection logic**
   ```bash
   # Example: Detect world-writable config files
   echo -e "${MAGENTA}╔═══════════════════════════════════╗${NC}"
   echo -e "${MAGENTA}║ NEW CHECK - CONFIGURATION FILES ║${NC}"
   echo -e "${MAGENTA}╚═══════════════════════════════════╝${NC}\n"
   
   CONFIG_PERMS=$(find /etc -perm -002 -type f 2>/dev/null)
   if [ ! -z "$CONFIG_PERMS" ]; then
       echo "$CONFIG_PERMS" | while read file; do
           alert_critical "WORLD-WRITABLE CONFIG: $file"
       done
   else
       info "No world-writable config files found"
   fi
   ```

3. **Add appropriate error handling**
4. **Test thoroughly**
5. **Update documentation**
6. **Submit PR**

---

## Commit Message Guidelines

- Use clear, descriptive titles
- Reference related issues
- Explain the "why", not just the "what"
- Use imperative mood ("Add feature" not "Added feature")

Example:
```
Add detection for world-writable SSH configs

Detects ~/.ssh directories with overly permissive permissions
that could allow unauthorized key injection attacks.

Closes #42
```

---

## Review Process

Your PR will be reviewed by maintainers who will:

- Check code quality
- Verify functionality
- Ensure documentation is updated
- Test on multiple systems
- Provide constructive feedback

Please be patient and respond to feedback professionally.

---

## Recognition

Contributors will be recognized in:
- CHANGELOG.md
- GitHub contributors page
- Project documentation

---

## Questions?

- Open a [Discussion](https://github.com/yourusername/nexpeas/discussions)
- Check [Issues](https://github.com/yourusername/nexpeas/issues)
- Email: support@example.com

---

## License

By contributing to NEXPEAS, you agree that your contributions will be licensed under its MIT License.

---

## Additional Resources

- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Commit Convention](https://www.conventionalcommits.org/)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide)
- [Security Best Practices](https://owasp.org/)

---

Thank you for contributing to NEXPEAS! 🎉
