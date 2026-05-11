# CdM Project
## Build

To compile the project and generate the image in `build/out.img`, run:

```bash
make compile
```

If you want to compile the image into a custom directory, create a `.env` (there is .env.example file) file with an `OUT` variable and run:

```bash
make workspace-compile
```

The final image will be written to the directory specified in `OUT`.
