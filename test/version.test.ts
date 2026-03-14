import { describe, it, expect } from "vitest";
import { VERSION } from "../src/core/version.ts";

describe("VERSION", () => {
  it("exports a string", () => {
    expect(typeof VERSION).toBe("string");
  });

  it("is 'dev' when not compiled", () => {
    // When running under vitest (not bun compile), the --define replacement
    // hasn't happened, so process.env.SKILL_ROUTER_VERSION is undefined
    // and VERSION falls through to "dev".
    expect(VERSION).toBe("dev");
  });
});
