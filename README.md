# apigee-tooling

Google APIGEE X administration tasks helpers.

The scripts and programs in this report probably have more limitations than [Apigee Sackmesser](https://github.com/apigee/devrel/tree/main/tools/apigee-sackmesser) tool, provided by Google Apigee team, but it was required for my job.

However, it may help some folks.

> **_DISCLAIMER_**
>
> Use these scripts at your own risks. Developer can not be considered as responsible in case of KVM or entries deletion or modification in case of script bug or misusage.

## `kvm-terraforming` shell script

### Description

This script is _freely inspired_ by [Terraform](https://www.terraform.io/) logic: apply a config/variable file to create KeyValueMap and keys.

Thanks to that, you can manage one file by org/env, with all the required key and their value.

> **Note**: obviously, you need to keep secret the config file ... as a `.tfvars` file and its `.tfstate`

### Pre-requisites

The script is trying to use as less dependencies as possible.

Software requirements are:

- `jq` tool: [jq website](https://stedolan.github.io/jq/)
- `gcloud` CLI tool: [gcloud CLI website](https://cloud.google.com/sdk/docs/install-sdk)

> Note: `gcloud` is used _only_ to get an access token. A future version may make it optional for those who retrieve token by another way.

Google Cloud permissions:

- `apigee.keyvaluemaps.create`
- `apigee.keyvaluemaps.list`
- `apigee.keyvaluemapentries.create`
- `apigee.keyvaluemapentries.delete`
- `apigee.keyvaluemapentries.get`: the script itself does not require this permission. Useful if you need to check if everything went well.

### Usages

`./kvm-terraform.sh <filename>`:

where `<filename>` is the JSON file to apply.

That's it! No other options as-of-now.

### Getting started

1. Copy the template file

```bash
    $ cp template.json dev-usefulName.json
```

2. Edit the newly created file

Use `vi`, `vim`, `nano`, `VSCode` or any text editor file

The JSON structure must be followed:

```javascript
{
    "name": "<KeyValueMapName>",
    "organization": "<Organization>",
    "environment": "<Environment>",
    "keys": [
        {
        "name": "<KeyName>",
        "value": "<KeyValue>"
        }
    ]
}
```

3. Launch the script: `$ ./kvm-terraform.sh dev-usefulName.json`

Example:

```bash
$ ./kvm-terraforming.sh ./dev-backend-x-credentials.json
[INFO] Checking dependencies
[INFO] Getting GCloud credentials
[INFO] Processing KEYMAP backend-x-credentials // myOrganizationName // dev
[INFO] The KVM does NOT exist. Requesting creation.
[INFO] Keyvaluemap backend-x-credentials successfully created.
[INFO] Processing keys for myOrganizationName // dev // backend-x-credentials
[INFO] Creation key 'myFirstKey' with value 'whatA...' (hidden for confidentiality)
[INFO] Keys 'myFirstKey': created
[INFO] Creation key 'myKey2' with value 'Anoth...' (hidden for confidentiality)
[INFO] Keys 'myKey2': created

$ curl -X GET -H "Authorization: Bearer $AUTH" https://apigee.googleapis.com/v1/organizations/myOrganizationName/environments/dev/keyvaluemaps/backend-x-credentials/entries
{
    "keyValueEntries": [
        {
            "name": "myKey2",
            "value": "AnotherValue"
        },
        {
            "name": "myFirstKey",
            "value": "whatAWonderfulValue"
        }
    ],
    "nextPageToken": ""
}
```

### Known limitations (and then possible TODO)

- The script consider only **environment level** KVM. Not the [organization level](https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.keyvaluemaps) nor the [product level](https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.apis.keyvaluemaps)
- Pre-existing keys, not present anymore into the config file are NOT DELETED.
- As of June 24th, there is no `PUT` verbs for key entries. The script will then `DELETE` and `POST` keys.
- One config file by map: may your project need more than one KVM, you need to create several files
