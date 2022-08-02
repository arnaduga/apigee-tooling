# Bundle Compare script

This small script intents to allow the comparison of two Apigee extracted bundle files, whatever the instance/organization they have been extracted.

## Use case

Imagine you have the following org/env architecture for your APIGEE instances:

```
/organizations
├─ /non-prod
│  ├─ /environments
│     ├─ /dev
│     ├─ /test
├─ prod/
│  ├─ /environments
│     ├─ /prod
```

You will develop your PROXY in `organizations/non-prod/environments/dev`.

The proxy revision number will increase on every change you've done (after deployement).

Now, your dev is good enough, you deploy the **revision 52** to `organizations/non-prod/environments/test`.

This is quite straightforward, as can deploy thanks to the Apigee console/API in the same orgnization.

When comes the time to deploy to `organizations/prod/environments/prod`, you have several options:

- [Apigee Sackmesser tool](https://github.com/apigee/devrel/tree/main/tools/apigee-sackmesser)
- Manually export the proxy bundle, to import it
- API

Whatever the solution, _the revision number of the bundle WILL change_ on the new organization.

> Goal of this script is to be able to check if 2 bundles from different orgnizations are the same or not, independently from the proxyname and revision

## Usage

Better than long speech, here is CLI sequences (obfuscated results, do not pay attention to hash, crc, size, etc...):

```bash
$ AUTH=$(gcloud auth print-access-token)

$ curl -H "Authorization: Bearer $AUTH" \
-s -o org1-rev55.zip \
https://apigee.googleapis.com/v1/organizations/org1/apis/proxyname/revisions/55?format=bundle

$ curl -H "Authorization: Bearer $AUTH" \
-s -o org1-rev40.zip \
https://apigee.googleapis.com/v1/organizations/org1/apis/proxyname/revisions/40?format=bundle

$ curl -H "Authorization: Bearer $AUTH" \
-s -o org2-rev3.zip \
https://apigee.googleapis.com/v1/organizations/org2/apis/proxyname/revisions/3?format=bundle

$ ls -l
total 3
-rwxrwxrwx 1 arnaduga arnaduga 2864 Aug  2 09:22 org1-rev55.zip
-rwxrwxrwx 1 arnaduga arnaduga 2865 Aug  2 09:26 org1-rev40.zip
-rwxrwxrwx 1 arnaduga arnaduga 2859 Aug  2 09:28 org2-rev3.zip

# This test will FAIL, as the process.js file changed
$ bundle-compare.sh org1-rev55.zip org1-rev40.zip
5c5 < 539B b66c6a1e apiproxy/resources/jsc/process.js --- > 545B c7a6a3c5 apiproxy/resources/jsc/process.js

$ echo $?
1

# Check if org 2 deployment is the latest available
$ bundle-compare.sh org2-rev3.zip org1-rev55.zip
5c5 < 539B c77d7f1e apiproxy/resources/jsc/process.js --- > 842B da54a3c5 apiproxy/resources/jsc/process.js

$ echo $?
1

# Check if org 2 deployment is same as org 1 / 40
$ bundle-compare.sh org2-rev3.zip org1-rev40.zip
$
$ echo $?
0

## YES, org1 revision 40 is the same code as org2 revision 3

# Dummy test
$ bundle-compare.sh org1-rev40.zip org1-rev40.zip
$
$ echo $?
0

```

### Exit codes

| Code | Description                                        |
| ---- | -------------------------------------------------- |
| `0`  | Bundles are the same (excluding "header" zip file) |
| `1`  | Bundles are NOT the same                           |
| `2`  | Wrong number of script arguments                   |
| `3`  | Argument is not an existing file                   |
| `4`  | Dependencies are not satisfied                     |
