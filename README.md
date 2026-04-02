# Rebble Developer Skill (unofficial)

LLM skill with the full [Rebble/Pebble developer documentation](https://developer.rebble.io), generated from the official [pebble-dev/developer.rebble.io](https://github.com/pebble-dev/developer.rebble.io) source (Apache 2.0).

## Install

Installation is described for Claude Code, but you can use any skills/ folder.

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

## Local project (SSH)

```bash
mkdir -p .claude/skills
git clone git@github.com:simlevesque/rebble-developer-skill-unofficial.git .claude/skills/rebble-developer
```

## Local project (HTTPS)

```bash
mkdir -p .claude/skills
git clone https://github.com/simlevesque/rebble-developer-skill-unofficial.git .claude/skills/rebble-developer
```

## Pull updates

```bash
cd skills/rebble-developer # navigate to skill folder
git pull
```

## Generate from source

Reviewing the script before running it is advised.

```bash
bash build-skill.sh
```

## License

Derivative work of [pebble-dev/developer.rebble.io](https://github.com/pebble-dev/developer.rebble.io) — see [LICENSE](LICENSE).
