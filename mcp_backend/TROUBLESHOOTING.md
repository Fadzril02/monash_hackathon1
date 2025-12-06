# Troubleshooting Guide

## Common Issues and Solutions

### Issue: esbuild Platform Mismatch

**Symptom:**
```
Error [TransformError]: 
You installed esbuild for another platform than the one you're currently using.
...
Specifically the "@esbuild/win32-x64" package is present but this platform
needs the "@esbuild/linux-x64" package instead.
```

**Root Cause:**
The `node_modules` directory was installed on one platform (e.g., Windows) and then used on a different platform (e.g., Linux). This commonly happens when:
- Copying `node_modules` between different operating systems
- Committing `node_modules` to git and cloning on a different OS
- Moving between Windows and WSL/Docker environments

**Solution:**
1. Delete the `node_modules` directory:
   ```bash
   rm -rf node_modules
   ```

2. Delete `package-lock.json` (optional but recommended):
   ```bash
   rm package-lock.json
   ```

3. Reinstall dependencies:
   ```bash
   npm install
   ```

4. Verify the correct platform is installed:
   ```bash
   ls node_modules/@esbuild/
   # Should show: linux-x64 (on Linux) or darwin-x64 (on macOS) or win32-x64 (on Windows)
   ```

**Prevention:**
- **Never commit `node_modules` to git**. Always add it to `.gitignore`
- Use `npm ci` in CI/CD pipelines for deterministic builds
- When using Docker, always run `npm install` inside the container, not before copying files

---

### Issue: Permission Denied on tsx

**Symptom:**
```
sh: 1: tsx: Permission denied
```

**Root Cause:**
The `tsx` executable in `node_modules/.bin/` doesn't have execute permissions. This can happen when node_modules is committed to git and then checked out, as git may not preserve executable permissions correctly.

**Solution:**
Fix permissions on the tsx executable:
```bash
chmod +x node_modules/.bin/tsx
```

Or better yet, reinstall node_modules (which will set correct permissions automatically):
```bash
rm -rf node_modules && npm install
```

---

### Issue: Server Won't Start

**Symptom:**
Server fails to start or crashes immediately

**Common Causes and Solutions:**

1. **Missing Environment Variables**
   - Check that `.env` file exists in `mcp_backend/` directory
   - Verify required variables are set:
     ```bash
     DATABASE_URL=mysql://user:pass@host:4000/database
     ANTHROPIC_API_KEY=sk-ant-...
     ```

2. **Database Connection Issues**
   - Verify database credentials in `.env`
   - Check network connectivity to database
   - Ensure SSL is enabled for TiDB Cloud connections

3. **Port Already in Use**
   - Check if port 3001 is already in use:
     ```bash
     lsof -i :3001
     ```
   - Stop the conflicting process or change the PORT in server.ts

---

## Best Practices

### Development Setup

1. **Always install dependencies fresh on a new machine:**
   ```bash
   cd mcp_backend
   npm install
   ```

2. **Use environment-specific .env files:**
   ```bash
   cp .env.example .env
   # Edit .env with your local values
   ```

3. **Run in development mode:**
   ```bash
   npm run dev
   ```

### Deployment

1. **For Vercel deployment:**
   - Vercel automatically runs `npm install` with the correct platform
   - Ensure `vercel.json` is properly configured
   - Set environment variables in Vercel dashboard

2. **For Docker:**
   - Run `npm install` inside the Docker container, not on host
   - Use multi-stage builds to optimize image size
   - Don't COPY `node_modules` from host

### Version Management

- **Node.js Version:** This project requires Node.js 24.x (as specified in `package.json`)
- Check your version: `node --version`
- Use nvm to manage Node versions: `nvm use 24`

---

## Getting Help

If you encounter issues not covered here:

1. Check the main README.md for setup instructions
2. Review recent git commits for changes that might affect your environment
3. Search for similar issues in the project's issue tracker
4. When reporting issues, include:
   - Your operating system
   - Node.js version (`node --version`)
   - npm version (`npm --version`)
   - Full error message with stack trace
   - Steps to reproduce
