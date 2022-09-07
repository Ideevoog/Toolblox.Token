#!/usr/bin/env node

import { spawn } from 'child_process';

console.log('🚀 Starting mainnet deployment...');

// Set environment variable and run the main deploy script
const env = { ...process.env, DEPLOY_MODE: 'mainnet' };

const child = spawn('npx', ['hardhat', 'run', 'scripts/deploy.ts'], {
  stdio: 'inherit',
  env: env,
  shell: true
});

child.on('close', (code) => {
  process.exit(code);
});

child.on('error', (error) => {
  console.error('Failed to start deployment:', error);
  process.exit(1);
});
