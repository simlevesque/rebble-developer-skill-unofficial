# Rebble Developer Skill (unofficial)

Claude Code skill with the full [Rebble/Pebble developer documentation](https://developer.rebble.io), generated from the official [pebble-dev/developer.rebble.io](https://github.com/pebble-dev/developer.rebble.io) source (Apache 2.0).

## Install

### Global (SSH)

```bash
mkdir -p ~/.claude/skills
git clone git@github.com:simlevesque/rebble-developer-skill-unofficial.git ~/.claude/skills/rebble-developer
```

### Global (HTTPS)

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/simlevesque/rebble-developer-skill-unofficial.git ~/.claude/skills/rebble-developer
```

### Local project only

```bash
mkdir -p .claude/skills
git clone git@github.com:simlevesque/rebble-developer-skill-unofficial.git .claude/skills/rebble-developer
```

Or with HTTPS:

```bash
mkdir -p .claude/skills
git clone https://github.com/simlevesque/rebble-developer-skill-unofficial.git .claude/skills/rebble-developer
```

## Usage

Once installed, use `/rebble-developer` in Claude Code to activate the skill.

## Update

```bash
git -C ~/.claude/skills/rebble-developer pull
```

## License

Derivative work of [pebble-dev/developer.rebble.io](https://github.com/pebble-dev/developer.rebble.io) — see [LICENSE](LICENSE).
