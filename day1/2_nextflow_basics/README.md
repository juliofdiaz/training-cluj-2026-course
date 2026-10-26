# Nextflow exercises (S3)

Run everything **from this folder**:

```bash
cd ~/course/day1/2_nextflow_basics
```

| File | Session time | What you practise |
|---|---|---|
| `01_hello.nf` | 11:15 | Running a pipeline, the `work/` directory, `.command.*` files, params, `-resume` |
| `02_channels.nf` | 11:35 | Samplesheet → `[meta, [R1, R2]]`, `map`, `count`, `collect`, `groupTuple` (solution: `solutions/02_channels_solution.nf`) |
| `03_first_process.nf` | 11:55 | A real tool (fastp) in a container, `task.cpus`, declaring outputs (solution: `solutions/03_first_process_solution.nf`) |
| `04_config.nf` + `04.config` | stretch | Moving container/resources into config, profiles |

```bash
nextflow run 01_hello.nf
nextflow run 02_channels.nf --input ~/course/data/reads/samplesheet.csv
nextflow run 03_first_process.nf -with-docker --input ~/course/data/reads/samplesheet_test.csv
nextflow run 04_config.nf -c 04.config -profile docker
```

Useful while you work:

```bash
nextflow lint 02_channels.nf                      # syntax check
nextflow log                                      # previous runs
nextflow log <run_name> -f name,hash,status,workdir
```
