# Nix Configuration Integration Tests

This directory contains integration tests for the Nix configurations in this repository.

## Test Scripts

### `integration.sh`

A comprehensive test script that verifies the buildability of Nix configurations.

#### Features

- Tests both home-manager and nix-darwin configurations
- Color-coded output for better readability
- Detailed error reporting
- Test summary with pass/fail counts
- Dependency checking
- Skip tests when configurations are not present

#### Prerequisites

- Nix package manager
- (Optional) home-manager for home configurations
- (Optional) nix-darwin for Darwin configurations

#### Usage

```bash
# Make the script executable
chmod +x tests/integration.sh

# Run all tests
./tests/integration.sh
```

#### Exit Codes

- `0`: All tests passed successfully
- `1`: One or more tests failed
- `2`: Invalid arguments or missing dependencies

#### Examples

Run all tests:
```bash
./tests/integration.sh
```

Run in verbose mode (shows all Nix output):
```bash
DEBUG=1 ./tests/integration.sh
```

## CI/CD Integration

These tests are designed to be run in a CI/CD pipeline. The GitHub Actions workflow will automatically run these tests on push and pull requests.

## Adding New Tests

1. Create a new test script in this directory
2. Make it executable: `chmod +x tests/your_test.sh`
3. Update this README with documentation for your test
4. Update the CI workflow if needed

## Troubleshooting

### Common Issues

1. **Missing Nix**
   - Ensure Nix is installed and in your PATH
   - Run `nix-shell -p nix` to enter a shell with Nix available

2. **Permission Denied**
   - Make the script executable: `chmod +x tests/integration.sh`

3. **Test Failures**
   - Run with `DEBUG=1` to see detailed output
   - Check the Nix build logs for specific errors

### Debugging

To enable debug output:
```bash
DEBUG=1 ./tests/integration.sh
```

## License

[Specify your license here, e.g., MIT, GPL-3.0, etc.]
