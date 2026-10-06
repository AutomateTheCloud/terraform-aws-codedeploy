# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A CodeDeploy application for EC2 and on-premises servers, Amazon ECS, or AWS Lambda.
- An IAM service role for the application's deployment groups, which only CodeDeploy can assume, with the AWS managed policy for the compute platform.
- An optional revision bucket and log group names, both returned in the output for other configurations.
- `region`, to create the application in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic application and one with a revision bucket, log groups and a deployment group.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-codedeploy/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-codedeploy/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-codedeploy/releases/tag/v1.0.0
