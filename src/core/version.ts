/** Compile-time version, injected by build.ts via --define. Defaults to "dev" for tsx runs. */
export const VERSION: string = process.env.SKILL_ROUTER_VERSION || "dev";
