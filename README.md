# Ordinal API

<br />
<br />

## Deployment

### Requirement

- An indexed ord server
- An ord wallet

<br />

### Configuration

Copy `dotenv` to `.env`.\
Edit `.env` and set proper parameters.

<br />

Install packages:

```javascript
$ npm install
```

<br />

Start:

```sh
$ npm start

# Optional: OR background it with screen
$ ./screen-ordinal-api.sh
```

<br />
<br />

## Usage

### CLI browser API

At the moment, until systemD or daemon is utilised. Run this as a background task using `screen` or `tmux`.\
Because this is a temporary wrapper to the `ord` cli command, this application should not be available to public.\
If it's behind a firewall, simplest option is to access using `SSH` local forwarding:

```sh
$ ssh -N -T -L 3000:localhost:3000 username@host -i /path/to/identity

// Access localy via http://localhost:3000
```

Example is available in [index.html](https://github.com/sadoprotocol/ordinal-api/blob/main/index.html).

<br />
<br />

### Background Indexer

The `ord` cli command is using [Sado's version](https://github.com/sadoprotocol/ord) and on-fly indexing has been disabled to improve API request responses.\
Simply run the following using a cron job for every 3 minutes.

```sh
# Copy the config and change the values accordingly
$ cp ord-index-config .ord-index-config

$ ./ord-index.sh
```

<br />

### Background Snapshots

At the moment, `ord` stops indexing process if there is a reorg.\
Therefore, we create snapshots every 30 blocks. Approximately once in every 6 hours.\
Simply run the following using a cron job for every 5 minutes.

```sh
# Make sure you have done the configuration in the background indexer process above.

$ ./ord-snapshot.sh
```
