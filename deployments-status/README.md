# Deployments status

Snapshot of all the proxy, revision and signature on multiple orgnizations and environments.

The notion of SIGNATURE is based on the script `bundle-compare`: it is a `md5sum` of the CRC32 (from the zip) and the proxyname.

As a result: same code, found in two different proxies, in two different organizations will have the same _signature_.

## Getting started

1. Copy the template file

```bash
    $ cp template.json config.json
```

2. Edit the newly created file

Use `vi`, `vim`, `nano`, `VSCode` or any text editor file

The JSON structure must be followed:

```javascript
{
  "instances": [
    {
      "organization": "orgName1",
      "environments": ["env1", "env2"]
    },
    {
      "organization": "orgName2",
      "environments": ["env3"]
    }
  ]
}

```

3. Launch the script: `$ ./deployments-status.sh dev-usefulName.json 2> /dev/null`

> Note: the `2>` allow to display _only_ the results, and not the log.
>
> May you want to save the logs and output into file, call will be `$ ./deployments-status.sh dev-usefulName.json 2> logs.txt 1> result.txt`

## Example

```bash
$ cat config.jon
{
  "instances": [
    {
      "organization": "orgName1",
      "environments": ["env1", "env2"]
    },
    {
      "organization": "orgName2",
      "environments": ["env3"]
    }
  ]
}

$ ./deployments-status.sh -c config.json 1> results.txt 2> logs.txt
$

$ head -n 10 logs.txt
[INFO] MAIN - Config file input: config.json
[INFO] PREREQ - Checking dependencies
[INFO] PARSE - Getting authentication gcloud token
[INFO] AUTH - Generating a new token
[INFO] ORG - Checking organization orgName1
[INFO] ENV - Checking environment env1
[INFO] ENVDEPL - Get deployments on organization/orgName1/environments/env2
[INFO] HASH - Getting BUNDLE for orgName1 // Proxy1 // 2
[INFO] HASH - Getting BUNDLE for orgName1 // Proxy2 // 27
[INFO] HASH - Getting BUNDLE for orgName1 // Proxy3 // 12

$ cat results.txt
orgName1             env1     Proxy1                         2    2022-08-01T17:30:10  6df4d50a41a5d20bc4faad8a6f09aa8f
orgName1             env1     Proxy2                         27   2022-08-01T17:35:35  2c98f873d2dd2968f367b2a9f0fc7fd5
orgName1             env1     Proxy3                         12   2022-08-01T17:38:44  8ea4a3e98928dc9fe56d7293dbb35b66
orgName1             env2     Proxy2                         25   2022-07-25T17:31:32  f6e4a89f41c5faecd687eb29aca37569
orgName1             env1     Proxy3                         7    2022-07-15T14:44:21  6ff5905c684b2a67bff77c1b8d7f17ff
orgName2             env3     Proxy2                         2    2022-07-01T07:13:50  f6e4a89f41c5faecd687eb29aca37569

$ # to SORT based on SIGNATURE
$ cat results.txt | sort -k6
orgName1             env1     Proxy2                         27   2022-08-01T17:35:35  2c98f873d2dd2968f367b2a9f0fc7fd5
orgName1             env1     Proxy1                         2    2022-08-01T17:30:10  6df4d50a41a5d20bc4faad8a6f09aa8f
orgName1             env1     Proxy3                         7    2022-07-15T14:44:21  6ff5905c684b2a67bff77c1b8d7f17ff
orgName1             env1     Proxy3                         12   2022-08-01T17:38:44  8ea4a3e98928dc9fe56d7293dbb35b66
orgName1             env2     Proxy2                         25   2022-07-25T17:31:32  f6e4a89f41c5faecd687eb29aca37569
orgName2             env3     Proxy2                         2    2022-07-01T07:13:50  f6e4a89f41c5faecd687eb29aca37569
```

On the last call (sorted), you can more easily see that proxy2 in **orgName1/env2 - revision 25** is the same code base as proxy2 in **orgName2/env3 - revision 2** \o/
