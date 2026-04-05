# Team Git Workflow Guide
## HCS 7004 Integrative Genomics Final Project

This guide teaches you to use Git as a real collaborative tool — the same workflow
used in research software teams and bioinformatics labs. Read it completely before
touching the repository.

---

## 1. Mental model: what is this repository for?

Think of the repository as your **lab notebook and code archive**, not a data storage
system. The sequencing data lives on OSC. The repository holds:

- The exact commands and scripts you ran (reproducibility)
- The results you produced (tables, figures, summaries)
- Your documentation of what you found and why

When your teammate clones this repository six months from now and runs your scripts,
they should be able to reproduce every result.

---

## 2. One-time setup

### 2a. Configure your identity on OSC

```bash
git config --global user.name  "Your Full Name"
git config --global user.email "your.name.N@buckeyemail.osu.edu"
git config --global core.editor "nano"
```

### 2b. Authenticate with GitHub from OSC

The most reliable method on HPC is a Personal Access Token (PAT):

1. Go to **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)**
2. Click **Generate new token** → name it "OSC HCS7004"
3. Set expiration to end of semester; check the **repo** scope
4. Copy the token immediately (you cannot view it again)
5. On OSC, store it so you never have to type it again:

```bash
git config --global credential.helper store
# Do any git push — you will be prompted once for username + token
# Git remembers it afterward
```

### 2c. Clone the repository

```bash
cd $HOME
git clone https://github.com/HCS7004-Sp26/REPO_NAME.git
cd REPO_NAME
```

---

## 3. Branch strategy

The project uses **one branch per module** plus `main`.

```
main          ← stable, reviewed work only — never push here directly
  │
  ├── module-01    ← genome assembly
  ├── module-02    ← genome annotation
  ├── module-03    ← RNA-seq differential expression
  └── module-04    ← ATAC-seq chromatin accessibility
```

**Rules:**
- Never push directly to `main`
- Do all work on your assigned module branch
- When your module is complete, open a Pull Request to merge into `main`
- A teammate reviews and approves before merging

---

## 4. Daily workflow

Every working session follows this sequence:

```bash
# 1. Make sure you are on your module branch
git checkout module-01

# 2. Pull the latest changes (teammates may have pushed)
git pull origin module-01

# 3. Do your work: write scripts, run jobs, save results

# 4. Check what changed
git status
git diff modules/01_assembly/

# 5. Stage files you want to commit (never stage data files)
git add modules/01_assembly/flye.sh
git add results/01_assembly/assembly_stats.txt

# 6. Commit with a meaningful message
git commit -m "module-01: Add Flye SLURM script and N50 summary"

# 7. Push to GitHub
git push origin module-01
```

### Commit message conventions

```
module-01: Add Flye assembly script with 45m genome size flag
module-02: Add minimap2 alignment script for 3 direct RNA-seq conditions
module-03: Add DESeq2 script and volcano plot for WT vs mutant
module-04: Add MACS3 peak calling script and IGV screenshot at candidate locus
docs: Update assembly README with BUSCO interpretation notes
```

Avoid messages like "update", "fix", "changes", or "WIP" alone — they tell your
teammates nothing about what actually changed.

---

## 5. Keeping your branch current with main

When teammates merge their modules into `main`, bring those changes into your branch:

```bash
git checkout module-01
git fetch origin
git merge origin/main
```

If there are merge conflicts, Git marks them in the file:

```
<<<<<<< HEAD
your version
=======
their version
>>>>>>> origin/main
```

Edit the file to keep the correct version, remove the markers, then:

```bash
git add <resolved_file>
git commit -m "Resolve merge conflict in module-01 README"
```

---

## 6. Pull Requests — the review process

When your module is complete:

1. Go to the repository on GitHub → **Pull requests → New pull request**
2. Set **base: main ← compare: module-0X**
3. Write a description of what your module does and what result it produces
4. Assign at least one teammate as **Reviewer**
5. The reviewer reads your scripts and result summaries, leaves inline comments
6. Once approved, click **Merge pull request**

This is not bureaucracy — it catches bugs, documents decisions, and ensures the whole
team understands what every module does.

---

## 7. What a good module contribution looks like

Your Pull Request should contain at minimum:

```
modules/0X_name/
├── README.md          # what the module does, how to run it, expected output
├── 01_step.sh         # SLURM scripts, numbered in run order
└── 02_step.sh

results/0X_name/
├── summary_stats.txt  # key numbers: N50, gene count, DEG count, peak count
└── figure_01.png      # main result figure
```

The `modules/0X/README.md` must answer three questions:
1. What does this module do and why?
2. How do I run it? (exact `sbatch` commands)
3. What does a successful result look like? (output files and expected sizes)

---

## 8. Useful command reference

```bash
git log --oneline -20             # recent commit history
git blame modules/01_assembly/flye.sh  # who changed which line
git stash / git stash pop         # temporarily shelve uncommitted work
git reset --soft HEAD~1           # undo last commit, keep file changes
git branch -a                     # list all local and remote branches
git checkout -b module-01         # create your branch if it does not exist
git push -u origin module-01      # push new branch to GitHub
```

---

## 9. What belongs in the repository — and what does not

| Commit this | Never commit this |
|---|---|
| SLURM `.sh` scripts | `.fastq.gz`, `.fasta`, `.bam` files |
| R / Python analysis scripts | Assembled genome FASTA (>100 MB) |
| Result summaries (TSV, CSV) | Apptainer `.sif` container files |
| Figures (PNG, PDF < 10 MB) | Files > 50 MB of any kind |
| Markdown documentation | Passwords, tokens, API keys |

The `.gitignore` in the repository root blocks the most common large file types.

---

## 10. Common mistakes

| Mistake | Fix |
|---|---|
| Staged a large file accidentally | `git reset HEAD <file>` before committing |
| Pushed to `main` directly | You cannot undo a push to protected branches — ask the instructor |
| Committed a token or password | Contact instructor immediately; rotate the credential |
| Lost work when switching branches | Always commit or `git stash` before `git checkout` |
| Merge conflict you cannot resolve | Ask your teammate — resolve it together |
