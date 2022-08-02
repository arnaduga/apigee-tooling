# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.2 - 2022-08-02]

### Added

- Script creation/initialization
- Documentation

### Changed

- HASH to SIGNATURE calculation: the signature is a concatenation of CRC32 + filename.

### Fixed

- `logutils.sh` in which a bug was introduced (`logdebug` wasn't working as expected anymore)
