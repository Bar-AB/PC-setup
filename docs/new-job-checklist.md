# New job — first days checklist

Generic on purpose: no company names, hosts or account IDs in this repo.

## Before installing anything (ask IT)
- [ ] Mac or Windows? Admin rights? What is allowed to be installed?
- [ ] Docker Desktop license OK? (else: Docker Engine in WSL / Colima on Mac)
- [ ] Is my **personal GitHub account** allowed on the work laptop? (decides how this repo gets there)
- [ ] AI tools policy: which tools are approved, what data/code may be sent to models.
- [ ] Claude Code through **Amazon Bedrock**, Google Vertex or an org Anthropic account? Who provides keys?

## Access to request
- [ ] Git org / repos → clone into `~/work/`
- [ ] Cloud: SSO / Identity Center login, a **dev** account with read-only IAM → `aws sts get-caller-identity`
- [ ] Database: dev DB or read replica + GUI (DBeaver / pgAdmin)
- [ ] VPN, ticketing tool, internal docs/wiki
- [ ] Internal agent / AI platform (if any): who built it, what exists, what's allowed

## Setup (day 1)
- [ ] `windows\install.ps1` (or `macos/install.sh`) from this repo
- [ ] `~/work/.gitconfig` with the work email (see `shared/git/work.gitconfig.example`)
- [ ] New SSH key for this laptop → add to the work Git host
- [ ] `claude` login / Bedrock env vars in `profile.local.ps1` / `~/.zshrc.local`
- [ ] Copy `shared/claude/project-template` into the main work repo; set `PG_REPLICA_URI`, `AWS_READONLY_PROFILE`, `AWS_REGION` locally
- [ ] `graphify update .` on the main repo (re-run after pulls); for languages graphify can't parse: `ctags -R -f .tags .`
- [ ] Make sure `.cc10x/` is in `.gitignore`, or agree with the team to share it
- [ ] `scripts\verify.ps1` + `docker run --rm hello-world`

## Questions for the team
- Architecture: which parts are legacy vs. new services, who owns what?
- Which cloud services (ECS/Lambda/RDS…) and region? Is pgvector installed?
- How do CI/CD, code review and DB migrations work? Who approves schema changes?
- Frontend: build tool, JS vs TS strictness, data fetching, state, UI library (+ RTL handling), routing, how it talks to the backend.
- What is my first onboarding task? Who is my mentor, what are the 30-day expectations?

## Later (week 3+), not now
- Parallel agent sessions in git worktrees (herdr)
- Codex CLI as a second reviewer on important PRs
- Langfuse / promptfoo for tracing, evals and cost tracking of agents you build
- Claude Code status line with context % and cost
