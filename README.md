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

Example is available in [index.html](https://github.com/cakespecial/ordinal-api/blob/main/index.html).

### Background Indexer

The `ord` cli command is using [Cake's version](https://github.com/cakespecial/ord) and on-fly indexing has been disabled to improve API request responses.\
Simply run the following using a cron job for every 5 minutes.

```sh
# At the time being, parameter to run on network specific
# is hardcoded. They can be identified with the // TODO

$ ./ord-index.sh
```

<br />
<br />

## Pending items

- Run network specific by command flag
- Replace screen with SystemD or some kind of daemon management
- Create alias for ord executable file, `ord@cake` to be able to use with `ord@afwcxx`
- Git workflow deploy server

