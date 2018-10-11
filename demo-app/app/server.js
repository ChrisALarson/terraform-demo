const express = require('express');
const ip = require('ip');

const app = express();

app.get('/', (req, res) => {
  const clientIp = req.ip;
  const myIp = ip.address();
  res.status(200).send(`Hello ${clientIp}! I'm ${myIp}.`);
});

app.listen(1337, console.log('App listening on port 1337!'));