# 🚀 GitHub Setup & Publication Guide

## Pre-Publication Checklist

- ✅ README.md with comprehensive documentation
- ✅ LICENSE file (MIT)
- ✅ CHANGELOG.md with version history
- ✅ CONTRIBUTING.md with contribution guidelines
- ✅ .gitignore with appropriate exclusions
- ✅ GitHub Actions workflow for CI/CD
- ✅ Complete nexpeas.sh script (959 lines)
- ✅ server.py HTTP server
- ✅ post_exploit.md guide (560 lines)
- ✅ Git repository initialized
- ✅ Initial commit created

---

## Step 1: Create GitHub Repository

### Via Web Interface
1. Go to https://github.com/new
2. **Repository name**: `nexpeas`
3. **Description**: "Privilege Escalation Assessment Tool - Fast, beautiful, and intelligent enumeration"
4. **Visibility**: Public
5. **Initialize**: Leave unchecked (we already have commits)
6. Click **Create repository**

### Grab Your Repository URL
```
https://github.com/yourusername/nexpeas.git
```

---

## Step 2: Add Remote & Push

```bash
cd /home/kali/nexpeas

# Add remote
git remote add origin https://github.com/yourusername/nexpeas.git

# Rename master to main (recommended)
git branch -M main

# Push initial commit
git push -u origin main
```

### If Using SSH (Recommended for Security)
```bash
git remote add origin git@github.com:yourusername/nexpeas.git
git branch -M main
git push -u origin main
```

### If Using GitHub Token (if needed)
```bash
# Replace with your GitHub token
git remote add origin https://ghp_fCQ4aJPYAXOTfUioYsIMxQrP16dKpB3ggAG@github.com/yourusername/nexpeas.git
git branch -M main
git push -u origin main
```

---

## Step 3: Configure GitHub Repository Settings

### 1. **Repository Settings** → **General**
- ✅ Default branch: `main`
- ✅ Require status checks: Enable
- ✅ Dismiss stale reviews: Check
- ✅ Require code reviews: 1 approval

### 2. **Collaborators & Teams**
- Add collaborators if needed

### 3. **Manage Access**
- Set team permissions

### 4. **Pages** (Optional)
- Enable GitHub Pages
- Source: `main` branch `/root` folder
- Theme: Choose a theme or use custom

### 5. **Secrets & Variables** (if needed)
- Add any required secrets for CI/CD

---

## Step 4: Configure Branch Protection (Recommended)

1. Go to **Settings** → **Branches**
2. Click **Add rule** for `main` branch
3. **Branch name pattern**: `main`

Configure:
- ✅ Require a pull request before merging
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Require code reviews
- ✅ Dismiss stale reviews
- ✅ Require CODEOWNERS review
- ✅ Require approval from code owners
- ✅ Allow auto-merge

---

## Step 5: Create Additional Branches (Optional)

```bash
# Create develop branch
git checkout -b develop
git push -u origin develop

# Create feature branch template
git checkout -b feature/template
git push -u origin feature/template
```

---

## Step 6: Publish Release

### Create GitHub Release

1. Go to **Releases** → **Create a new release**
2. **Tag version**: `v1.0.0`
3. **Target**: `main`
4. **Title**: `NEXPEAS v1.0.0 - Initial Release`

**Description**:
```markdown
## NEXPEAS v1.0.0 - Initial Release 🚀

### What's Included
- Complete privilege escalation enumeration script
- Flag detection (user.txt, root.txt, etc)
- SUID binaries analysis with GTFOBins integration
- HTTP server for remote deployment
- Comprehensive post-exploitation guide
- Professional UI with vibrant colors
- Performance optimized with timeouts

### Features
- 🚩 Flag hunting
- 💀 SUID analysis
- 📊 System enumeration
- 🔐 Sensitive data discovery
- 📡 Remote deployment
- 📚 Educational content

### Installation
```bash
git clone https://github.com/yourusername/nexpeas.git
cd nexpeas
chmod +x nexpeas.sh
./nexpeas.sh
```

### Usage
- Local: `./nexpeas.sh`
- Remote: `python3 server.py` then use HTTP server
- One-liner: `bash <(curl -s https://raw.githubusercontent.com/yourusername/nexpeas/main/nexpeas.sh)`

### Documentation
- See [README.md](README.md) for full documentation
- See [post_exploit.md](post_exploit.md) for post-exploitation guide

### License
MIT License - See [LICENSE](LICENSE)

**Note**: This is for authorized security testing only.
```

5. Click **Publish release**

---

## Step 7: Create Topics

1. Go to **Settings** → **General**
2. Under **Repository topics**, add:
   - `penetration-testing`
   - `privilege-escalation`
   - `security-assessment`
   - `ctf`
   - `enumeration`
   - `bash`
   - `suid`
   - `gtfobins`
   - `linux-security`
   - `red-team`

---

## Step 8: Setup README Badges

Your README.md already includes:
```markdown
![nexpeas](https://img.shields.io/badge/nexpeas-v1.0-red?style=for-the-badge)
![Bash](https://img.shields.io/badge/bash-5.0+-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)
```

Additional badges you can add:

**Downloads**: (after getting downloads)
```markdown
[![Downloads](https://img.shields.io/github/downloads/yourusername/nexpeas/total?style=for-the-badge)](https://github.com/yourusername/nexpeas/releases)
```

**Stars**:
```markdown
[![Stars](https://img.shields.io/github/stars/yourusername/nexpeas?style=for-the-badge)](https://github.com/yourusername/nexpeas)
```

**GitHub Workflow Status**:
```markdown
[![Lint](https://github.com/yourusername/nexpeas/actions/workflows/lint.yml/badge.svg)](https://github.com/yourusername/nexpeas/actions)
```

---

## Step 9: Enable Discussions (Optional)

1. Go to **Settings** → **Features**
2. Enable **Discussions**
3. Create discussion categories:
   - Announcements
   - General
   - Ideas
   - Q&A
   - Show and tell

---

## Step 10: Create Wiki (Optional)

1. Go to **Wiki** tab
2. Create pages:
   - Home
   - Installation Guide
   - Usage Examples
   - Troubleshooting
   - Contributing

---

## Step 11: Add CODEOWNERS (Optional)

Create `.github/CODEOWNERS`:
```
* @yourusername
/post_exploit.md @yourusername
/nexpeas.sh @yourusername
```

---

## Step 12: Add Issue Templates (Optional)

Create `.github/ISSUE_TEMPLATE/bug_report.md`:
```markdown
---
name: Bug report
about: Create a report to help us improve
---

## Describe the bug
A clear description of what the bug is.

## Steps to reproduce
1. Go to '...'
2. Run '...'
3. See error

## Expected behavior
What you expected to happen.

## Actual behavior
What actually happened.

## Environment
- OS: [e.g., Ubuntu 20.04]
- Bash version: [e.g., 5.0]
- NEXPEAS version: [e.g., 1.0.0]
```

---

## Step 13: Promote Your Repository

After publishing:

### Share on Platforms
- **Twitter**: Share with #InfoSec #Hacking #Security hashtags
- **Reddit**: Post to r/cybersecurity, r/redteam
- **HackerNews**: Submit to news.ycombinator.com
- **LinkedIn**: Announce to security professionals
- **Medium**: Write an article about NEXPEAS

### Example Tweet
```
🔓 Introducing NEXPEAS v1.0 - A modern privilege escalation 
assessment tool that's fast, beautiful, and intelligent.

✨ Flag hunting
💀 SUID analysis
📊 Smart enumeration
📚 Educational content

GitHub: https://github.com/yourusername/nexpeas

#InfoSec #Hacking #Security #OpenSource
```

### Example Blog Post Title
- "NEXPEAS: A Better Alternative to LinPEAS"
- "Fast Privilege Escalation Enumeration with NEXPEAS"
- "Why We Built NEXPEAS"

---

## Step 14: Maintain the Project

### Regular Updates
```bash
# Create develop branch for development
git checkout -b develop

# Make changes
# Commit
git add .
git commit -m "Feature: Add new capability"

# Create pull request on GitHub
git push origin develop

# After review and merge:
git checkout main
git pull origin main

# Tag release
git tag v1.0.1
git push origin v1.0.1
```

### Update Version
- Update version in badges
- Update CHANGELOG.md
- Update version references

---

## Post-Publication Checklist

After pushing to GitHub:

- ✅ Repository is public
- ✅ README renders correctly
- ✅ Badges display properly
- ✅ Code syntax highlighting works
- ✅ Links are functional
- ✅ Release is published
- ✅ Topics are added
- ✅ Description is complete
- ✅ Social sharing done
- ✅ Initial stars received

---

## Troubleshooting

### Push rejected
```bash
# If main branch already exists on remote
git push -f origin main
```

### Authentication failed
```bash
# Use GitHub token or SSH key
# For token-based auth:
git config --global credential.helper store
# Then input your GitHub token when prompted
```

### Merge conflicts
```bash
# Pull latest changes
git pull origin main

# Resolve conflicts manually
# Then push
git push origin main
```

---

## Next Steps

1. **Get feedback** - Enable discussions
2. **Improve based on feedback** - Accept issues and PRs
3. **Add features** - Follow CONTRIBUTING.md
4. **Release updates** - Follow semantic versioning
5. **Engage community** - Respond to issues quickly
6. **Document progress** - Update CHANGELOG.md

---

## Resources

- [GitHub Guides](https://guides.github.com/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Semantic Versioning](https://semver.org/)
- [Open Source Guides](https://opensource.guide/)

---

## Support

For questions about GitHub setup:
- [GitHub Help](https://help.github.com/)
- [GitHub Community](https://github.community/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/github)

---

**🎉 Congratulations! NEXPEAS is now on GitHub!**

Make sure to monitor issues, respond to PRs, and keep the project active!

---

Last Updated: July 18, 2026
