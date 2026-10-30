# Tools

Run these when the handbook says.

| Script | What it does |
|---|---|
| `check_vm.sh` | Is this machine ready? Checks every version and resource the course needs, changes nothing, and prints a fix for each problem. `--day2` adds the Day 2 checks |
| `sheet_rows.sh` | Prints your bactflow results as rows for the class spreadsheet (Day 1 handbook section 5) |
| `update_course.sh` | Brings `~/course` up to date with the course repository. It never overwrites your own work |
| `pull_images.sh` | Downloads every container image the course uses, so nobody waits on the Wi-Fi |
| `gitignore` | For the optional git page (Day 1 handbook section 6): copy it into your pipeline folder as `.gitignore` |

```bash
bash ~/course/tools/check_vm.sh
```

The last line should say `Ready.`
