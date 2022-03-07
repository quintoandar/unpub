# unpub_auth

Only for Dart 2.15 and later.

Since Dart 2.15:

1. The `accessToken` is only sent to https://pub.dev and https://pub.dartlang.org. See [dart-lang/pub #3007](https://github.com/dart-lang/pub/pull/3007) for details.
2. Since Dart 2.15, the third-party pub's token is stored at `/Users/username/Library/Application Support/dart/pub-tokens.json` (macOS)

So the self-hosted pub server should have its own auth flow. unpub is using Google OAuth2 by default.

- `unpub_auth login` will generate `unpub-credentials.json` locally after developer login the `unpub_auth`.
- Before calling `dart pub publish` or `flutter pub publish`, please call `unpub_auth get | dart pub token add <self-hosted-pub-server>` first.
- `unpub_auth get` will refresh the token. New accessToken will be write to `pub-tokens.json` by `dart pub token add <self-hosted-pub-server>`.
- So you can always use a valid accessToken in `dart pub publish` and `flutter pub publish`.

## Usage

### Overview

unpub is using Google OAuth2 by default. There's two situations where the unpub_auth can be used.

- Login locally, and publish pub packages locally.
  1. Call `unpub_auth login` when you first use it, and it will save credentials locally.
  2. Before calling `dart pub publish` or `flutter pub publish`, call `unpub_auth get | dart pub token add <self-hosted-pub-server>`

- Login locally, and publish pub packages from CI/CD.
  On CI/CD host device, you may not have opportunity to call `unpub_auth login`, so you can use `unpub_auth migrate` to migrate the credentials file.
  1. In local device, call `unpub_auth login` when you first use it, and it will save credentials locally.
  2. Copy the credentials file which was generated in step 1 to CI/CD device.
  3. In CI/CD device, call `unpub_auth migrate <credentials-file-path>`, so the CI/CD will have the same credentials file.
  4. In CI/CD device, before calling `dart pub publish` or `flutter pub publish`, call `unpub_auth get | dart pub token add <self-hosted-pub-server>`

```
Usage: unpub_auth <command> [arguments]

Available commands:
  get             Refresh and get accessToken. Must login first.
  login           Login unpub_auth on Google APIs.
  logout          Delete local credentials file.
  migrate <path>  Migrate existed credentials file from path.
```

### Install and run

``` bash
dart pub global activate unpub_auth # activate the cli app
```

### Uninstall

``` bash
dart pub global deactivate unpub_auth # deactivate the cli app
```

### Get a token and export to Dart Client

``` bash
unpub_auth get | dart pub token add <self-hosted-pub-server>
```

**Please call `unpub_auth login` first before you run the `unpub_auth get` if you never login in 'terminal'.**

## Develop and debug locally

``` bash
dart pub global activate --source path ./  # activate the cli app
unpub_auth  # run it
```
