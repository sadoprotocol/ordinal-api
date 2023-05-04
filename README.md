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

Because this is a temporary wrapper to the ord cli, this application should not be available to public.\
If it's behind a firewall, simplest option is to access using `SSH` local forwarding:

```sh
$ ssh -N -T -L 3000:localhost:3000 username@host -i /path/to/identity

// Access localy via http://localhost:3000
```

Example is available if you open [index.html](https://github.com/cakespecial/ordinal-api/blob/main/index.html).


<br />
<br />

## Pending items

- Replace screen with SystemD or some kind of daemon management
- Create alias for ord executable file, ord@cake to be able to use with ord@afwcxx
- Git workflow deploy server

