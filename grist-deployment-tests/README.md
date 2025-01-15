# Deployment tests for Grist

## Motivation

This project aims to provide few simple tests to ensure the target instance is correctly configured. It is based on issues the [ANCT](https://anct.gouv.fr) encountered in the past.

## Installation

After cloning the repository, install the dependencies using npm:

```bash
npm install
```

## Run the tests

You may run the test (api and e2e) using this command:

```bash
GRIST_DOMAIN='https://my-grist.tld' USER_API_KEY='some-user-api-key' \
  ORG_ID='1234' npm run test
```

Where the above env variables are:

- `GRIST_DOMAIN` is the domain of your grist instance (required);
- `USER_API_KEY` is the API Key of a user with whom you want to run the tests (required, for API tests);
- `ORG_ID` is the ID of the organization on which you want to run the tests
(optional, defaults to the Personal organization id, for API tests);

The tests create a dedicated workspace (named `test__<iso formatted date>`), which is automatically deleted after the test run.

### Run a single test

You may run a single test using the `-g` option of mocha. For example, the following 
command run only the tests whose title contain `"snapshots"`:

```bash
GRIST_DOMAIN='https://my-grist.tld' USER_API_KEY='some-user-api-key' [...] npm run test:api -- -g 'snapshots' 
```

### Troubleshooting

If you encounter some issue with your API tests, you may set the
env variable `NO_CLEANUP` to `1` so the workspace created during the tests is not
deleted and you can inspect the created documents.
