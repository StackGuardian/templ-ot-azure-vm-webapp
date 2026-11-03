# Tests

Tests use the built-in OpenTofu test framework (`tofu test`, OpenTofu 1.8 or later).

| Level | Folder | What it does | Cost | When it runs |
|---|---|---|---|---|
| Unit | `tests/unit` | Plan only with mocked providers. Checks configuration and security settings. | None | Merge requests into `development` or `main`, and tags |
| Integration | `tests/integration` | Deploys real resources, checks them, destroys them. | Cloud cost while running | Tags, when cloud credentials are set (`integration-tests` job) |

## Run locally

```bash
tofu init
tofu test -test-directory=tests/unit
tofu test -test-directory=tests/integration   # needs cloud credentials
```

## Test cases

| ID | Level | Description | Status |
|---|---|---|---|
| U-01 | Unit | Default variables produce a valid plan with all default tags | done |
| U-02 | Unit | Invalid `name_prefix` is rejected | done |
| U-03 | Unit | Custom `tags` are merged with the default tags | done |
| U-04 | Unit | Instances are in the web subnet without public IPs, default outbound access disabled | done |
| U-05 | Unit | Password login disabled, Trusted Launch on, extensions off, managed identity | done |
| U-06 | Unit | Web subnet allows HTTP only from the Application Gateway subnet and denies everything else | done |
| U-07 | Unit | Port 80 on the Application Gateway is open only to `allowed_http_cidrs` | done |
| U-08 | Unit | Application Gateway access logs go to Log Analytics | done |
| I-01 | Integration | HTTP GET on the Application Gateway returns 200 and the demo page (retries while instances boot) | done |

Integration tests are written but have not run against a real cloud account yet.
