# Course data

The data itself is not in the repository: these scripts download it. On a course machine it is already here.

| Script | What it does |
|---|---|
| `get_data.sh` | Downloads the course reads (about 1 GB, 20 *S. aureus* isolates, SA01–SA20) into `reads/`, checks them, and writes the samplesheets |
| `get_data.sh mash` | Downloads the species database for Day 2's species check (0.75 GB) into `mash/` |
| `make_samplesheets.sh` | Writes the samplesheets again, with full paths for the machine you are on. Run it if the reads move |

```bash
bash ~/course/data/get_data.sh
bash ~/course/data/get_data.sh mash
```

Read the files in `reads/`, but don't change them. The reads come from ENA project PRJEB2510, subsampled to about 20× coverage.
