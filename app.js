require('dotenv').config();

const express = require('express')
const cors = require('cors')
const app = express()
const port = 3000

const { spawn } = require("child_process");
const formidable = require('formidable');
const fs = require('fs');
const sha256 = require('crypto-js/sha256');

const ORDINAL_UPLOAD_DIR = __dirname + '/uploaded/';

console.log('ORDINAL_UPLOAD_DIR', ORDINAL_UPLOAD_DIR);

app.use(cors());

app.use(express.json()) // for parsing application/json
app.use(express.urlencoded({ extended: true })) // for parsing application/x-www-form-urlencoded

// === FILE UPLOAD

app.all('/fileupload', (req, res) => {
  let form = new formidable.IncomingForm();

  form.parse(req, function (err, fields, files) {
    if (!files || !files.ordinalupload) {
      res.status(500).json('Invalid form file [name]');
    } else {
      let fileType = files.ordinalupload.originalFilename.split('.')[files.ordinalupload.originalFilename.split('.').length - 1]
      let newFilename = sha256(files.ordinalupload.originalFilename).toString() + '.' + fileType;
      let oldpath = files.ordinalupload.filepath;
      let newpath = ORDINAL_UPLOAD_DIR + newFilename;

      // Change fs.rename to fs.copyFile if the form is in the same machine..
      fs.rename(oldpath, newpath, function (err) {
        if (err) {
          console.log('err', err);
          res.status(500).json(err.message);
        } else {
          res.json('$ORDINAL_UPLOAD_DIR/' + newFilename);
        }
      });
    }
  });
});

// === COMMANDS

app.all('/', (req, res) => {
  if (req.body && Array.isArray(req.body)) {
    ordinal(req.body).then(data => {
      res.json(data);
    }).catch(err => {
      res.status(500).json(err);
    });
  } else {
    res.json('KO');
  }
});

// ===

app.listen(port, () => {
  console.log(`Listening on port ${port}`)
});

// ===

function ordinal(arg = []) {
  return new Promise((resolve, reject) => {
    let commandArg = ["--cookie-file", "/home/bitcoin/.bitcoin/testnet3/.cookie", "-t"];

    // Replace $ORDINAL_UPLOAD_DIR with proper path
    for (let i = 0; i < arg.length; i++) {
      if (arg[i].includes('$ORDINAL_UPLOAD_DIR')) {
        arg[i] = arg[i].replace('$ORDINAL_UPLOAD_DIR/', ORDINAL_UPLOAD_DIR);
      }
    }

    commandArg = commandArg.concat(arg);

    const exec = spawn("ord", commandArg);

    let output = '';

    exec.stdout.on("data", data => {
      output += data;
    });

    exec.stderr.on("data", data => {
      output += data;
    });

    exec.on('error', (error) => {
      console.log(`error: ${error.message}`);
      reject(`${error.message}`);
    });

    exec.on("close", code => {
      resolve(`${output}`);
    });
  });
}
