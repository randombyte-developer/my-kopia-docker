# my-kopia-docker
## kopia image
Runs one instance of kopia. It always connects to a local network share as its source and supports SMB (CIFS driver), B2 targets and S3 targets.

## scheduler image
Runs a given command each day for all specified containers with a delay inbetween.