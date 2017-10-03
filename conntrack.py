#!/usr/bin/python
# Author: Lakshmi Prasad Velidi

import sys, json, math, time, commands

start=int(time.time())
stop=start + 3 * 24 * 60 * 60;

conntree = { 'inbound': {}, 'outbound': {} }
while start < stop:
  # construct a delta tree counting similar inbound and outbound connections
  deltatree = { 'inbound': {}, 'outbound': {} }

  conns = commands.getoutput('netstat -nat | tail -n +3 | grep -v LISTEN | awk \'{print $4 ":" $5 }\'').split("\n")
  ports = commands.getoutput('netstat -ntlp 2>/dev/null | grep LISTEN | awk \'{print $4}\' | grep -oP \':\d+$\' | tr -d \':\'').split("\n")
  for conn in conns:
    chunks = conn.split(':')
    if chunks[1] in ports:
      # connection is inbound
      key = "%s:%s:%s" % (chunks[0], chunks[1], chunks[2])
      if key in deltatree['inbound']:
        deltatree['inbound'][key] = deltatree['inbound'][key] + 1
      else:
        deltatree['inbound'][key] = 1
    else:
      # connection is outbound
      key = "%s:%s:%s" % (chunks[0], chunks[2], chunks[3])
      if key in deltatree['outbound']:
        deltatree['outbound'][key] = deltatree['outbound'][key] + 1
      else:
        deltatree['outbound'][key] = 1
    #print key
    #print deltatree

  # keep track of all time max inbound connections observed per source
  for key, value in deltatree['inbound'].iteritems():
    if key in conntree['inbound']:
      if deltatree['inbound'][key] > conntree['inbound'][key]:
        conntree['inbound'][key] = deltatree['inbound'][key]
    else:
      conntree['inbound'][key] = deltatree['inbound'][key]

  # keep track of all time max outbound connections observed per target
  for key, value in deltatree['outbound'].iteritems():
    if key in conntree['outbound']:
      if deltatree['outbound'][key] > conntree['outbound'][key]:
        conntree['outbound'][key] = deltatree['outbound'][key]
    else:
      conntree['outbound'][key] = deltatree['outbound'][key]

  # offloading the accumulated knowledge to a file on disk
  with open('/tmp/conntree', 'w') as outfile:
    outfile.write("%s" % json.dumps(conntree, indent=4, sort_keys=True))

  start = start + 5
  time.sleep(5)
