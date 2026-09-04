/**
 * Run Tests Tool
 *
 * Custom OpenCode tool to run test suites with various options.
 * Automatically detects the test framework (Flutter/Dart, Jest, Vitest, etc.).
 */

import { tool, type ToolDefinition } from "@opencode-ai/plugin/tool"
import * as path from "path"
import * as fs from "fs"

const runTestsTool: ToolDefinition = tool({
  description:
    "Run the test suite with optional coverage, watch mode, or specific test patterns. Automatically detects project type (Flutter, npm, pnpm, yarn, bun).",
  args: {
    pattern: tool.schema
      .string()
      .optional()
      .describe("Test file pattern or specific test name to run"),
    coverage: tool.schema
      .boolean()
      .optional()
      .describe("Run with coverage reporting (default: false)"),
    watch: tool.schema
      .boolean()
      .optional()
      .describe("Run in watch mode for continuous testing (default: false)"),
    updateSnapshots: tool.schema
      .boolean()
      .optional()
      .describe("Update snapshots (default: false)"),
  },
  async execute(args, context) {
    const { pattern, coverage, watch, updateSnapshots } = args
    const cwd = context.worktree || context.directory

    // Detect project type
    const projectType = await detectProjectType(cwd)

    // Build command
    let command: string

    if (projectType === "flutter") {
      command = buildFlutterTestCommand(pattern, coverage, watch, updateSnapshots)
    } else {
      command = buildNodeTestCommand(cwd, pattern, coverage, watch, updateSnapshots)
    }

    return JSON.stringify({
      command,
      projectType,
      options: {
        pattern: pattern || "all tests",
        coverage: coverage || false,
        watch: watch || false,
        updateSnapshots: updateSnapshots || false,
      },
      instructions: `Run this command to execute tests:\n\n${command}`,
    })
  },
})

export default runTestsTool

async function detectProjectType(cwd: string): Promise<"flutter" | "node"> {
  if (fs.existsSync(path.join(cwd, "pubspec.yaml"))) {
    return "flutter"
  }
  if (fs.existsSync(path.join(cwd, "analysis_options.yaml"))) {
    return "flutter"
  }
  return "node"
}

function buildFlutterTestCommand(
  pattern?: string,
  coverage?: boolean,
  watch?: boolean,
  updateSnapshots?: boolean
): string {
  const args: string[] = ["flutter test"]

  if (coverage) args.push("--coverage")
  if (watch) args.push("--watch")
  if (updateSnapshots) args.push("--update-goldens")
  if (pattern) args.push(pattern)

  return args.join(" ")
}

function buildNodeTestCommand(
  cwd: string,
  pattern?: string,
  coverage?: boolean,
  watch?: boolean,
  updateSnapshots?: boolean
): string {
  const packageManager = detectPackageManager(cwd)
  const testFramework = detectNodeTestFramework(cwd)

  let cmd: string[] = [packageManager]

  if (packageManager === "npm") {
    cmd.push("run", "test")
  } else {
    cmd.push("test")
  }

  const testArgs: string[] = []

  if (coverage) testArgs.push("--coverage")
  if (watch) testArgs.push("--watch")
  if (updateSnapshots) testArgs.push("-u")
  if (pattern) {
    if (testFramework === "jest" || testFramework === "vitest") {
      testArgs.push("--testPathPattern", pattern)
    } else {
      testArgs.push(pattern)
    }
  }

  if (testArgs.length > 0) {
    if (packageManager === "npm") cmd.push("--")
    cmd.push(...testArgs)
  }

  return cmd.join(" ")
}

function detectPackageManager(cwd: string): string {
  const lockFiles: Record<string, string> = {
    "bun.lockb": "bun",
    "pnpm-lock.yaml": "pnpm",
    "yarn.lock": "yarn",
    "package-lock.json": "npm",
  }

  for (const [lockFile, pm] of Object.entries(lockFiles)) {
    if (fs.existsSync(path.join(cwd, lockFile))) {
      return pm
    }
  }

  return "npm"
}

function detectNodeTestFramework(cwd: string): string {
  const packageJsonPath = path.join(cwd, "package.json")

  if (fs.existsSync(packageJsonPath)) {
    try {
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf-8"))
      const deps = {
        ...packageJson.dependencies,
        ...packageJson.devDependencies,
      }

      if (deps.vitest) return "vitest"
      if (deps.jest) return "jest"
      if (deps.mocha) return "mocha"
      if (deps.ava) return "ava"
      if (deps.tap) return "tap"
    } catch {
      // Ignore parse errors
    }
  }

  return "unknown"
}
