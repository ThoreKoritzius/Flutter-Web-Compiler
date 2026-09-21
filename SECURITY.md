# Security

The compiler and inspection command parse source locally. Compilation of Flutter islands invokes the Flutter toolchain and dependency resolution; only build projects you trust. This tool is not a sandbox for untrusted projects.

Generated content must preserve HTML escaping. New URL, script, server-rendering and hydration features need explicit validation and tests. Never treat generated pages as authorization to expose authenticated data.

Report reproducible security problems privately to the repository owner through GitHub's private vulnerability reporting when available. If that channel is unavailable, open a minimal issue requesting private contact without including an exploit, credentials or sensitive source code. This prototype currently has no security support SLA.
