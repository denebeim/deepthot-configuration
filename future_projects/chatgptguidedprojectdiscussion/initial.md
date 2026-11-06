# Deepthot Infrastructure / Hermes Local AI

## Purpose

Deepthot is a long-running home infrastructure and local AI project.

The goal is to build an environment that is self-documenting, maintainable, automated, and capable of preserving the technical and historical context behind its own development.

A central objective is to create a persistent AI-assisted knowledge system: an external memory that allows work to resume without repeatedly reconstructing the entire history of the project.

## About the Owner

The owner is an experienced DevOps engineer and longtime technology enthusiast, with a history dating back to 1979.

Areas of experience include:

- Linux and Unix systems
- Networking and infrastructure
- Virtualization (historically ESXi/VMware, now Proxmox)
- Git and source control
- Python and Ansible
- Identity management and DNS
- Artifact repositories and infrastructure services
- Local AI and automation

Do not assume beginner-level knowledge. Explain underlying mechanisms and reasoning when useful, particularly during troubleshooting.

The owner thinks in interconnected systems and layers. Discussions may move between seemingly unrelated topics because those connections are often relevant to the larger architecture.

Do not prematurely narrow the discussion or discard historical context.

## Collaboration Guidelines

1. Be accurate. Never invent system state, configuration, command output, or hardware capabilities.
2. Explain why a recommendation works, not just what commands to execute.
3. Prefer incremental troubleshooting and read-only inspection before making changes.
4. Preserve existing work, including uncommitted changes and experiments.
5. Never perform destructive Git operations or infrastructure provisioning without discussing the consequences first.
6. Inspect actual local files before proposing structural changes.
7. Avoid replacing existing tools simply because newer alternatives exist.
8. Keep track of decisions and their rationale.
9. When context is missing, acknowledge it and reconstruct it rather than guessing.
10. Do not make the owner repeat information already available in project documentation.

## Infrastructure Philosophy

- Git is the source of truth for configuration and durable project documentation.
- Proxmox VM metadata and tags should drive Ansible inventory grouping and role assignment.
- Infrastructure should be automated and reproducible.
- Configuration should be version-controlled wherever practical.
- Local AI should own its persistent memory and knowledge base.
- Cloud AI should be interchangeable with local inference.
- Knowledge must not become dependent on a particular AI provider.

## Current Technology

- Hypervisor: Proxmox
- Configuration management: Ansible
- Identity and authentication: FreeIPA
- DNS: VM named `services`
- DNS filtering: Pi-hole v6
- Local AI VM: `hermes`
- Intended inference engine: Ollama
- Intended agent: Hermes
- Source repository: `denebeim/deepthot-configuration`

## Documentation Requirements

Maintain the following project records:

- `ARCHITECTURE.md` — infrastructure components and relationships.
- `DECISIONS.md` — decisions, alternatives, and reasoning.
- `CURRENT-STATE.md` — verified operational state.
- `BACKLOG.md` — outstanding work and investigations.
- `SESSION-LOG.md` — dated work summaries and recovery points.

Update documentation as meaningful work is completed.

## Most Important Objective

The system should help its owner recover context, not create more context-management work.

When resuming a session, establish:

1. What was being worked on?
2. What is the verified current state?
3. What decisions were previously made?
4. What remains unfinished?
5. What is the safest useful next action?
