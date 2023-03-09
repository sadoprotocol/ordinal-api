"use strict";

const { spawn } = require("child_process");
const fs = require('fs');
const sha256 = require('crypto-js/sha256');

const cookiePath = process.env.COOKIE_PATH;
const network = process.env.NETWORK;
const uploadKey = process.env.UPLOAD_KEY;
const ORDINAL_UPLOAD_DIR = process.env.UPLOAD_DIR || __dirname + '/uploaded/';

const networkFlag = {
  "mainnet": "",
  "testnet": "-t",
  "regtest": "-r"
}

if (networkFlag[network] === undefined) {
  throw new Error('Unsupported network defined.');
}

exports.rpc = rpc;
exports.upload = upload;



function rpc(arg = []) {
  return new Promise((resolve, reject) => {
    let commandArg = [];

    if (cookiePath) {
      commandArg.push('--cookie-file');
      commandArg.push(cookiePath);
    }

    if (networkFlag[network].trim() !== '') {
      commandArg.push(networkFlag[network].trim());
    }

    // Replace $ORDINAL_UPLOAD_DIR with proper path
    try {
      for (let i = 0; i < arg.length; i++) {
        if (arg[i].includes('server') || arg[i].includes('preview')) {
          throw new Error(arg[i] + ' command is blocked.');
        }

        if (arg[i].includes('$ORDINAL_UPLOAD_DIR')) {
          arg[i] = arg[i].replace('$ORDINAL_UPLOAD_DIR/', ORDINAL_UPLOAD_DIR);
        }
      }
    } catch (err) {
      reject(err);
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

function upload(files) {
  return new Promise((resolve, reject) => {
    if (!files || !files[uploadKey]) {
      reject('Invalid form file [name], expecting ' + uploadKey);
    } else {
      let fileType = files[uploadKey].originalFilename.split('.')[files[uploadKey].originalFilename.split('.').length - 1]
      let oldpath = files[uploadKey].filepath;

      let fileBuffer = fs.readFileSync(oldpath);
      let hex = sha256(fileBuffer).toString();
      let newFilename = hex + '.' + fileType;
      let newpath = ORDINAL_UPLOAD_DIR + newFilename;

      // Change fs.rename to fs.copyFile if the form is in the same machine..
      fs.rename(oldpath, newpath, function (err) {
        if (err) {
          reject(err);
        } else {
          resolve('$ORDINAL_UPLOAD_DIR/' + newFilename);
        }
      });
    }
  });
}
