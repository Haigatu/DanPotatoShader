# Publishing DanPotatoShader

Publish each new user-facing version to this repository before marking the release complete.

- Tag the commit whose README and shaders match the tested installation ZIP.
- Push the source commit and version tag. Create a GitHub Release with the tested ZIP attached. Mark previews and betas as prereleases.
- Update the download link in the README on the default branch. Verify the released ZIP's SHA-256 against the local artifact and give the user the release link.
- Keep benchmark variants and scratch builds local.
